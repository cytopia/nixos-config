{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.programs.chromium;

  # Map the package names to their exact /etc directory roots
  policyPaths = {
    "chromium" = "chromium";
    "brave" = "brave";
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
  options.mySystem.programs.chromium = {
    enable = lib.mkEnableOption "Chromium-based browser with advanced GPU Acceleration and Privacy.";

    browser = lib.mkOption {
      type = lib.types.enum [
        "google-chrome"
        "chromium"
        "brave"
      ];
      default = "chromium";
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
      "${policyPath}/policies/managed/policies.json".text = builtins.toJSON (privacyPolicies.policies);
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

          # 5. Define the base package with flags first to keep the code readable
          #baseChrome = prev.${cfg.browser}.override {
          #  commandLineArgs = combined.flags ++ enableFeatureFlag ++ disableFeatureFlag ++ scalingFlag;
          #};

          # 1. Define the base package with command line flags.
          # We map escapeShellArg to safely handle flags with spaces (like dates).
          baseChrome = prev.${cfg.browser}.override {
            commandLineArgs = map lib.escapeShellArg (
              combined.flags ++ enableFeatureFlag ++ disableFeatureFlag ++ scalingFlag
            );
          };

          # 2. Map the extraEnvVars to makeWrapper arguments safely
          wrapperEnvArgs = lib.concatStringsSep " " (
            lib.mapAttrsToList (key: value: "--set ${lib.escapeShellArg key} ${lib.escapeShellArg value}") (
              privacyVars.default // cfg.startup.extraEnvVars
            )
          );
        in
        {
          # 3. Use symlinkJoin to wrap the browser and inject environment variables.
          # This works universally across Chromium, Brave, and Google Chrome.
          ${cfg.browser} = prev.symlinkJoin {
            name = "${baseChrome.name}-env-wrapped";
            paths = [ baseChrome ];
            nativeBuildInputs = [ prev.makeWrapper ];

            postBuild = ''
              # A. Wrap all binaries to inject our environment variables (like VK_LOADER_LAYERS_DISABLE)
              for binPath in $out/bin/*; do
                if [ -f "$binPath" ] && [ -x "$binPath" ]; then
                  wrapProgram "$binPath" ${wrapperEnvArgs}
                fi
              done

              # B. Fix the Desktop files so application launchers CANNOT bypass our wrapper
              if [ -e "$out/share/applications" ]; then
                # 1. Get the true path of the original read-only applications folder
                orig_apps=$(readlink -f "$out/share/applications")
                # 2. Delete the symlink from our $out directory
                rm -rf "$out/share/applications"
                # 3. Recreate it as a REAL directory owned by our wrapper
                mkdir -p "$out/share/applications"
                # 4. Copy the actual files into our new real directory
                cp -a "$orig_apps"/* "$out/share/applications/"
                # 5. Make the new copies writable so sed can edit them
                chmod -R +w "$out/share/applications"
                # 6. Finally, update the Exec= lines
                for desktop in "$out/share/applications"/*.desktop; do
                  for binPath in $out/bin/*; do
                    # Skip hidden wrapped files created by wrapProgram
                    [[ "$binPath" == *"-wrapped" ]] && continue
                    binName=$(basename "$binPath")
                    # Fix relative paths (Chromium: Exec=chromium -> Exec=$out/bin/chromium)
                    sed -i "s|^Exec=''${binName} |Exec=$out/bin/''${binName} |g" "$desktop"
                    sed -i "s|^Exec=''${binName}$|Exec=$out/bin/''${binName}|g" "$desktop"
                    # Fix absolute paths (Google Chrome: Exec=/nix/store/.../bin/google-chrome)
                    sed -i "s|^Exec=[^ ]*/bin/''${binName} |Exec=$out/bin/''${binName} |g" "$desktop"
                    sed -i "s|^Exec=[^ ]*/bin/''${binName}$|Exec=$out/bin/''${binName}|g" "$desktop"
                  done
                done
              fi
            '';
          };
        }
      )
    ];

    # --- Install the globally overridden package
    environment.systemPackages = [
      pkgs.${cfg.browser}
    ];
  };
}
