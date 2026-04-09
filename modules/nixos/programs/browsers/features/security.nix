{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security;
        in
        {

          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security = {

            strictProcessIsolation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces strict site-per-process isolation and cross-origin checks.
                Prevents compromised iframes or cross-site scripting from leaking memory.
                Forces the browser to spin up completely separate OS-level processes
                for every domain (even iframes). This is your primary defense against
                Spectre/Meltdown style attacks leaking data between tabs.
                Note: This imposes a 10% to 20% RAM tax and CPU/IPC overhead.
              '';
            };

            disableJit = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                DANGEROUS/EXTREME: Disables the V8 JavaScript JIT (Just-In-Time) compiler.
                This eliminates an entire class of zero-day exploits and WASM attacks,
                but heavily impacts the performance of complex web apps.
              '';
            };

            forceStrictTls = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks mixed insecure (HTTP) content on secure pages.
                Additionally, it explicitly routes the TLS pre-master secret log to /dev/null,
                ensuring rogue Wayland processes cannot dump and decrypt your secure HTTPS web traffic.
              '';
            };

            preventSslBypass = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Removes the "Proceed anyway" button from SSL/TLS warning pages.
                Forces the browser to strictly drop connections to invalid certificates.
              '';
            };

            disableExperimental = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Turns off experimental Chrome features (Browser Labs) that lack full security audits,
                and strictly prevents the installation of Progressive Web Apps (PWAs) by the user.
              '';
            };

            disableOsKeyring = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Severs integration with the host OS keyring (GNOME Keyring/KWallet).
                Forces Chrome to use a dummy basic password store to prevent dbus exploits.
              '';
            };

            disableBackgroundMode = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly prevents Chrome from silently running background processes, apps,
                or extensions after the last visible browser window is explicitly closed.
              '';
            };

            strictHardwarePermissions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) before granting access to Location, Bluetooth, HID, USB,
                and Serial devices. Strictly blocks access to raw device Sensors.
              '';
            };

            strictOsPermissions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) before granting access to Window Management, Local Fonts,
                Clipboard, and File System (Read/Write). Strictly blocks Idle Detection tracking.
              '';
            };

            strictContentPermissions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) for web notifications and strictly denies/blocks popups.
              '';
            };

            blockDirectSockets = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks websites from opening raw TCP/UDP sockets (Direct Sockets API).
              '';
            };

            disablePasswordManager = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hardens the local browser profile by disabling the built-in Chrome password manager
                and passkeys. Guarantees malware cannot extract credentials from local SQLite databases.
              '';
            };

            disableAutofill = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hardens the local browser profile by disabling form autofill for addresses
                and credit cards. Prevents malicious scripts from triggering hidden autofills.
              '';
            };

            disableAutoplay = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Blocks HTML5 media from auto-playing globally, preventing drive-by audio/video
                parser exploits. Exceptions can be configured via the autoplayWhitelist option.
              '';
            };

            autoplayWhitelist = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "[*.]youtube.com" ];
              description = ''
                A list of URL patterns to whitelist for media autoplay.
                This is only applied if disableAutoplay is enabled.
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            # A. Command Line Flags
            internal.flags = lib.mkMerge [
              (lib.optionals cfg.strictProcessIsolation [
                # Forces Chromium to allocate dedicated OS-level processes for each site.
                "--site-per-process"
                # Ensures that cross-origin iframes are also put into different processes.
                "--isolate-origins"
              ])
              (lib.optionals cfg.disableJit [
                # Instructs the V8 JavaScript engine to run purely in interpreter mode.
                "--js-flags=--jitless"
              ])
              (lib.optionals cfg.disableOsKeyring [
                # Mapped precisely to the new disableOsKeyring option
                "--password-store=basic"
              ])
            ];

            # B. Environment Variables
            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.forceStrictTls {
                # Points the SSL key dump explicitly to /dev/null.
                "SSLKEYLOGFILE" = "/dev/null";
              })
            ];

            # C. Chrome Features
            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.strictProcessIsolation [
                # Hardens the Origin API to strictly separate origins on the backend.
                "StrictOriginIsolation"
                # Runs the internal browser network service in a heavily restricted sandbox.
                "NetworkServiceSandbox"
              ])
            ];

            # D. Enterprise Policies
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableJit {
                # A value of 2 strictly blocks all Just-In-Time Javascript compilation.
                "DefaultJavaScriptJitSetting" = 2;
              })

              (lib.mkIf cfg.preventSslBypass {
                # Disables the ability for a user to click through certificate errors.
                "SSLErrorOverrideAllowed" = false;
              })

              (lib.mkIf cfg.forceStrictTls {
                # A value of 2 strictly blocks loading HTTP content on an HTTPS page.
                "DefaultInsecureContentSetting" = 2;
              })

              (lib.mkIf cfg.disableExperimental {
                # Disables the "chrome://flags" experiments and Browser Labs.
                "BrowserLabsEnabled" = false;
                # Prevents websites from installing Progressive Web Apps to the OS.
                "WebAppInstallByUserEnabled" = false;
              })

              (lib.mkIf cfg.disableBackgroundMode {
                "BackgroundModeEnabled" = false;
              })

              (lib.mkIf cfg.strictHardwarePermissions {
                # A value of 3 forces the browser to "Ask" the user before granting access.
                "DefaultGeolocationSetting" = 3;
                "DefaultWebBluetoothGuardSetting" = 3;
                "DefaultWebHidGuardSetting" = 3;
                "DefaultWebUsbGuardSetting" = 3;
                "DefaultSerialGuardSetting" = 3;
                # A value of 2 strictly blocks access.
                "DefaultSensorsSetting" = 2;
              })

              (lib.mkIf cfg.strictOsPermissions {
                # A value of 3 forces the browser to "Ask" before granting OS interactions.
                "DefaultWindowManagementSetting" = 3;
                "DefaultLocalFontsSetting" = 3;
                "DefaultClipboardSetting" = 3;
                "DefaultFileSystemReadGuardSetting" = 3;
                "DefaultFileSystemWriteGuardSetting" = 3;
                # A value of 2 strictly blocks access.
                "DefaultIdleDetectionSetting" = 2;
              })

              (lib.mkIf cfg.strictContentPermissions {
                # A value of 3 forces a prompt. A value of 2 strictly blocks.
                "DefaultNotificationsSetting" = 3;
                "DefaultPopupsSetting" = 2;
              })

              (lib.mkIf cfg.blockDirectSockets {
                # A value of 2 blocks raw TCP/UDP socket creation.
                "DefaultDirectSocketsSetting" = 2;
              })

              (lib.mkIf cfg.disablePasswordManager {
                "PasswordManagerEnabled" = false;
                "PasswordManagerPasskeysEnabled" = false;
                "PasswordManagerBlocklist" = [ "*" ];
              })

              (lib.mkIf cfg.disableAutofill {
                "AutofillAddressEnabled" = false;
                "AutofillCreditCardEnabled" = false;
              })

              (lib.mkIf cfg.disableAutoplay {
                "AutoplayAllowed" = false;
                "AutoplayAllowlist" = cfg.autoplayWhitelist;
              })
            ];
          };
        }
      )
    );
  };
}
