{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.programs.google-chrome;

  # Map the package names to their exact /etc directory roots
  policyPaths = {
    "google-chrome" = "opt/chrome";
  };

  # Resolve the correct path based on the user's selection
  policyPath = policyPaths.${cfg.browser};

  # Import libraries
  gpuFlags = import ../lib/chromium-flags-gpu.nix;
  privacyFlags = import ../lib/chromium-flags-privacy.nix { inherit lib; };
  privacyVars = import ../lib/chromium-env-vars-privacy.nix;
  privacyPolicies = import ../lib/chromium-managed-policies.nix { inherit lib; };

  searchEnginePolicy = {
    "DefaultSearchProviderEnabled" = true;
    "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}";
    "DefaultSearchProviderSuggestURL" = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    "SearchSuggestEnabled" = false;
  };
  defaultSettingsPolicy = {
    "RestoreOnStartup" = 1;
    "DefaultBrowserSettingEnabled" = false;
  };

  firstRunDefaults = {
    "browser" = {
      "show_home_button" = false;
      "custom_chrome_frame" = false;
      "show_bookmarks_bar" = true;
    };
    "bookmarks" = {
      "show_on_all_tabs" = true;
    };
    "extensions" = {
      "theme" = {
        "id" = "";
        "system_theme" = 1; # 1 = Follow OS Dark/Light mode, 2 = Force Dark
      };
    };
    "distribution" = {
      "do_not_create_desktop_shortcut" = true;
      "do_not_create_quick_launch_shortcut" = true;
      "import_bookmarks" = false;
      "import_history" = false;
    };
    # chrome://settings/content/federatedIdentityApi
    # Setting: Block sign-in prompts from identity services
    "profile" = {
      "content_settings" = {
        "exceptions" = {
          "federated-identity-api" = {
            "*,*" = {
              "setting" = 2;
            };
          };
        };
      };
    };
  };
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.google-chrome = {
    enable = lib.mkEnableOption "Chromium-based browser with advanced GPU Acceleration and Privacy.";

    browser = lib.mkOption {
      type = lib.types.enum [
        "google-chrome"
        "chromium"
        "brave"
      ];
      default = "google-chrome";
      description = "Which browser to install and wrap.";
    };

    scalingFactor = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = ''
        The ui scaling factor for the browser.
        Leave at 1.0 for native scaling. Use 1.5 for 150%, etc.
      '';
    };
    waylandFractionalScalingSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enables native Wayland fractional scaling support.
        Allows Chrome to render text and UI perfectly crisp at non-integer display scales
        (like 125% or 150%) in Sway, rather than relying on blurry Xwayland downscaling.
        --enable-feature=WaylandFractionalScaleV1
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        A list of Chrome extension IDs to silently force-install.
        All extensions in this list will be unpinned from the toolbar by default.
      '';
      example = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      ];
    };

    customCaCerts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Unique name for the cert. Used in the NSS database alias.";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Full path to the .pem file.";
            };
          };
        }
      );
      default = [ ];
      description = "List of CA certificates to sync with the browser's NSS database on launch.";
    };

    extraPolicies = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        An attribute set of Chromium Enterprise Policies to append or overwrite.
        Keys defined here will strictly overwrite identical keys from the hardened base library.
      '';
      example = {
        "DnsOverHttpsMode" = "secure";
      };
    };

    startup = {
      extraFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Add addtional startup flags to the browser";
      };
      extraEnableFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Add addtional features that will be appended to the startup flag --enable-features=";
      };
      extraDisableFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Add addtional features that will be appended to the startup flag --disable-features=";
      };
      extraEnvVars = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Environment variables to export before launching Chrome. These are applied via makeWrapper.";
        default = { };
      };
    };

    gpu = {
      engine = {
        displayServer = lib.mkOption {
          type = lib.types.enum [
            "wayland"
            "xwayland"
          ];
          default = "xwayland";
          description = ''
            The display server protocol Chrome should use.
            "xwayland" is currently recommended for Intel Xe to prevent EGL context crashes.
          '';
        };
        backend = lib.mkOption {
          type = lib.types.enum [
            "vulkan"
            "gl"
            "gles"
          ];
          default = "vulkan";
          description = ''
            The underlying graphics rendering API to translate to via ANGLE.
          '';
        };
      };
      optimizations = {
        gpuRasterization = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Offload painting operations from the CPU to the GPU.";
        };
        memoryManagement = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable zero-copy and native GPU memory buffers.";
        };
        ignoreGpuBlocklist = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Force hardware acceleration on experimental/uncertified drivers.";
        };
        safetyOverrides = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            DANGEROUS: If true, disables Chromium's internal driver bug workarounds.
            Keep this FALSE on Intel Xe to maintain high WebGL draw-call performance.
          '';
        };
      };
      features = {
        videoAcceleration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable hardware-accelerated video decoding/encoding (VA-API).";
        };
        treesInViz = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Moves the Display Tree to the Viz compositor thread to reduce input latency.";
        };
        skiaGraphite = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Replaces Ganesh with the next-gen Skia Graphite 2D renderer.
            Currently hard-blocked by Chromium on X11; keep FALSE until supported.
          '';
        };
        webNn = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enables Web Neural Network API for GPU-accelerated ML (e.g., Google Meet blur).";
        };
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- Chrome Enterprise Policies
    environment.etc = {
      # Merging the base policies with our new extraPolicies.
      "${policyPath}/policies/managed/policies.json".text = builtins.toJSON (
        privacyPolicies.policies // cfg.extraPolicies
      );
      "${policyPath}/policies/managed/settings.json".text = builtins.toJSON (defaultSettingsPolicy);
      "${policyPath}/policies/managed/search.json".text = builtins.toJSON (searchEnginePolicy);
      "${policyPath}/policies/managed/extensions.json".text = builtins.toJSON {
        "ExtensionSettings" = lib.genAttrs cfg.extensions (extId: {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
          "toolbar_pin" = "default_unpinned";
        });
      };
      "${policyPath}/initial_preferences".text = builtins.toJSON firstRunDefaults;
    };

    # --- Overwrite Chrome with startup flags
    nixpkgs.overlays = [
      (
        final: prev:
        let
          # 1. get desired GPU flags
          hwConfig = gpuFlags.getFlags {
            display_server = cfg.gpu.engine.displayServer;
            engine = cfg.gpu.engine.backend;
            enableGpuRasterization = cfg.gpu.optimizations.gpuRasterization;
            enableMemoryManagement = cfg.gpu.optimizations.memoryManagement;
            enableIgnoreGpuBlocklist = cfg.gpu.optimizations.ignoreGpuBlocklist;
            enableFeatureVideoAcceleration = cfg.gpu.features.videoAcceleration;
            enableFeatureTreesInViz = cfg.gpu.features.treesInViz;
            enableFeatureSkiaGraphite = cfg.gpu.features.skiaGraphite;
            enableFeatureWebNn = cfg.gpu.features.webNn;
            enableSafetyOverrides = cfg.gpu.optimizations.safetyOverrides;
          };

          # 2. get desired Privacy flags
          privacyConfig = privacyFlags.getFlags {
            enableReferrerPrivacy = true;
            enableSystemIsolation = true;
            enableBackgroundTelemetryRemoval = true;
            enableTrackingApiRemoval = true;
          };

          # 3. Merge the two sets (Combines flags, enableFeatures, and disableFeatures lists)
          combined = lib.zipAttrsWith (name: values: lib.concatLists values) [
            hwConfig
            privacyConfig
            {
              flags = cfg.startup.extraFlags;
              enableFeatures =
                cfg.startup.extraEnableFeatures
                ++ lib.optional cfg.waylandFractionalScalingSupport "WaylandFractionalScaleV1";
              disableFeatures = cfg.startup.extraDisableFeatures;
            }
          ];

          # 4. Generate final strings from the combined set
          enableFeatureFlag = lib.optional (
            combined.enableFeatures != [ ]
          ) "--enable-features=${lib.concatStringsSep "," combined.enableFeatures}";

          disableFeatureFlag = lib.optional (
            combined.disableFeatures != [ ]
          ) "--disable-features=${lib.concatStringsSep "," combined.disableFeatures}";

          scalingFlag = lib.optional (
            cfg.scalingFactor != 1.0
          ) "--force-device-scale-factor=${builtins.toJSON cfg.scalingFactor}";

          # 5. Define the base package with command line flags.
          # We must use escapeShellArg on the flags so Nixpkgs' internal wrapper
          # doesn't strip quotes from flags that contain spaces (like the update blocker).
          baseChrome = prev.${cfg.browser}.override {
            commandLineArgs = map lib.escapeShellArg (
              combined.flags ++ enableFeatureFlag ++ disableFeatureFlag ++ scalingFlag
            );
          };

          # Certificate Synchronization Script Logic
          # This logic constructs a bash snippet to be executed via --run in makeWrapper.
          # We use nssTools because the standard 'nss' package only contains libs, not binaries.
          nssBin = "${pkgs.nssTools}/bin/certutil";

          # 6.1 Generate 'add' commands for current Nix-defined certs
          addCertsSnippet = lib.concatStringsSep "\n" (
            map (cert: ''
              if [ -f "${cert.path}" ]; then
                echo "  [+] Syncing: NixOS-Managed-${cert.name}"
                # trust flags are "CT,C,C" (Standard for Root CAs)
                ${nssBin} -d sql:$HOME/.pki/nssdb -A -t "CT,C,C" -n "NixOS-Managed-${cert.name}" -i "${cert.path}" 2>/dev/null
              fi
            '') cfg.customCaCerts
          );

          # 6.2 Identify active Nix-managed cert nicknames
          activeNicknames = map (cert: "NixOS-Managed-${cert.name}") cfg.customCaCerts;

          # 6.3 Generate 'cleanup' logic to prune orphaned Nix-managed certs
          cleanupSnippet = ''
            if [ -d "$HOME/.pki/nssdb" ]; then
              ${nssBin} -d sql:$HOME/.pki/nssdb -L | grep "NixOS-Managed-" | while read -r line; do
                # Robust nickname extraction.
                # certutil -L uses fixed-width columns. This regex strips the trust
                # flags AND all trailing whitespace/padding from the nickname.
                nickname=$(echo "$line" | sed 's/ \{2,\}.*//; s/[[:space:]]*$//')

                case "$nickname" in
                  ${
                    if activeNicknames == [ ] then
                      "\"FORCE_EMPTY_MATCH\""
                    else
                      lib.concatStringsSep "|" (map (n: "\"${n}\"") activeNicknames)
                  })
                    # This cert is in our Nix config, do nothing
                    ;;
                  *)
                    # log message for visibility
                    echo "  [-] Pruning orphaned certificate: $nickname"
                    ${nssBin} -d sql:$HOME/.pki/nssdb -D -n "$nickname" 2>/dev/null
                    ;;
                esac
              done
            fi
          '';
          # 6.4 Final combined command for the wrapper
          fullCertSyncCmd = ''
            # header for terminal visibility
            echo "[*] Synchronizing Browser Certificates..."
            if [ ! -d "$HOME/.pki/nssdb" ]; then
              mkdir -p "$HOME/.pki/nssdb"
              ${nssBin} -d sql:$HOME/.pki/nssdb -N --empty-password 2>/dev/null
            fi
            ${cleanupSnippet}
            ${addCertsSnippet}
          '';

          # 7. Map the extraEnvVars to makeWrapper arguments safely
          wrapperEnvArgs =
            (lib.concatStringsSep " " (
              lib.mapAttrsToList (key: value: "--set ${lib.escapeShellArg key} ${lib.escapeShellArg value}") (
                privacyVars.default // cfg.startup.extraEnvVars
              )
            ))
            + " --run ${lib.escapeShellArg fullCertSyncCmd}";

          # The command that will re-wrap the binaries natively
          wrapCmd = ''
            for bin in $out/bin/*; do
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                wrapProgram "$bin" ${wrapperEnvArgs}
              fi
            done
          '';

        in
        {
          # Natively override the derivation's build attributes.
          # This rebuilds the wrapper natively, meaning the package's own .desktop
          # file generation logic will automatically resolve to our new $out path.
          ${cfg.browser} = baseChrome.overrideAttrs (
            oldAttrs:
            {
              nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.makeWrapper ];
            }
            # Chromium uses a monolithic `buildCommand`
            // lib.optionalAttrs (oldAttrs ? buildCommand) {
              buildCommand = oldAttrs.buildCommand + wrapCmd;
            }
            # Google Chrome uses standard phases like `postFixup`
            // lib.optionalAttrs (!(oldAttrs ? buildCommand)) {
              postFixup = (oldAttrs.postFixup or "") + wrapCmd;
            }
          );
        }
      )
    ];

    # --- Install the globally overridden package
    environment.systemPackages = [
      pkgs.${cfg.browser}
    ];
  };
}
