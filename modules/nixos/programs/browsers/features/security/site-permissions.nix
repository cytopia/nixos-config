{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security.sitePermissions;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security.sitePermissions = {

            strictHardwarePermissions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) before granting access to Location, Bluetooth, HID, USB,
                and Serial devices.
              '';
            };

            blockSensors = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks access to raw device Sensors (accelerometer, gyroscope, etc).
              '';
            };

            strictOsPermissions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) before granting access to Window Management, Local Fonts,
                and File System (Read/Write).
              '';
            };

            blockIdleDetection = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks Idle Detection tracking.
              '';
            };

            strictClipboardAccess = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) before allowing websites to read the clipboard.
                Also strictly prevents reading cross-device synced clipboard history.
              '';
            };

            blockSilentPrinting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Prevents websites from bypassing the print dialog (silent printing).
                Stops a malicious site from silently dumping files to your local printer.
              '';
            };

            strictNotifications = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces a prompt (Ask) for web notifications.
              '';
            };

            blockPopups = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly denies/blocks popups.
              '';
            };

            preventCrossSiteAuth = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Prevents phishing attacks by strictly blocking HTTP Basic Auth
                prompts that are triggered by cross-origin subresources or iframes.
              '';
            };

            blockDirectSockets = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks websites from opening raw TCP/UDP sockets (Direct Sockets API).
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
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.strictHardwarePermissions {
                # A value of 3 forces the browser to "Ask" the user before granting access.
                "DefaultGeolocationSetting" = 3;
                "DefaultWebBluetoothGuardSetting" = 3;
                "DefaultWebHidGuardSetting" = 3;
                "DefaultWebUsbGuardSetting" = 3;
                "DefaultSerialGuardSetting" = 3;
              })

              (lib.mkIf cfg.blockSensors {
                # A value of 2 strictly blocks access.
                "DefaultSensorsSetting" = 2;
              })

              (lib.mkIf cfg.strictOsPermissions {
                # A value of 3 forces the browser to "Ask" before granting OS interactions.
                "DefaultWindowManagementSetting" = 3;
                "DefaultLocalFontsSetting" = 3;
                "DefaultFileSystemReadGuardSetting" = 3;
                "DefaultFileSystemWriteGuardSetting" = 3;
              })

              (lib.mkIf cfg.blockIdleDetection {
                # A value of 2 strictly blocks access.
                "DefaultIdleDetectionSetting" = 2;
              })

              (lib.mkIf cfg.strictClipboardAccess {
                # A value of 3 forces a prompt for basic clipboard access.
                "DefaultClipboardSetting" = 3;
                # Prevents websites from reading clipboard history synced across devices.
                "SharedClipboardEnabled" = false;
              })

              (lib.mkIf cfg.blockSilentPrinting {
                # Prevents a malicious site from silently dumping files to your local printer.
                "SilentPrintingEnabled" = false;
              })

              (lib.mkIf cfg.strictNotifications {
                # A value of 3 forces a prompt.
                "DefaultNotificationsSetting" = 3;
              })

              (lib.mkIf cfg.blockPopups {
                # A value of 2 strictly blocks.
                "DefaultPopupsSetting" = 2;
              })

              (lib.mkIf cfg.preventCrossSiteAuth {
                # Deny third-party images on a page to show an authentication prompt.
                "AllowCrossOriginAuthPrompt" = false;
              })

              (lib.mkIf cfg.blockDirectSockets {
                # A value of 2 blocks raw TCP/UDP socket creation.
                "DefaultDirectSocketsSetting" = 2;
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
