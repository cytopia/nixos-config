{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.programs.google-chrome;

  # Import the hardware flag library
  chromeHwLib = import ../lib/chromium-flags-gpu.nix;
  chromePrivacyLib = import ../lib/chromium-flags-privacy.nix { inherit lib; };
  managedPolicies = import ../lib/chromium-managed-policies.nix;

  activePolicies =
    managedPolicies.disableAccount
    // managedPolicies.disablePasswords
    // managedPolicies.disableAutofill
    // managedPolicies.disableDownloadRestrictions
    // managedPolicies.disableSafeBrowsing
    // managedPolicies.disableSpellcheck
    // managedPolicies.disableGoogleUi
    // managedPolicies.disableTelemetry
    // managedPolicies.disableCloudReporting
    // managedPolicies.disableDiagnostics
    // managedPolicies.disableTracking
    // managedPolicies.disableDns
    // managedPolicies.disableIntranet
    // managedPolicies.disableHardwarePermissions
    // managedPolicies.disableOsPermissions
    // managedPolicies.disableContentPermissions
    // managedPolicies.disableNetworkPermissions
    // managedPolicies.disableCloudAssist
    // managedPolicies.disableCloudAi
    // managedPolicies.disableLocalAi
    // managedPolicies.disableAutoplay
    // managedPolicies.disableUpdates
    // managedPolicies.enableCoreSecurity;

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
  };
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.google-chrome = {
    enable = lib.mkEnableOption "Google Chrome with advanced Hardware Acceleration";

    scalingFactor = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = ''
        The ui scaling factor for the browser.
        Leave at 1.0 for native scaling. Use 1.5 for 150%, etc.
      '';
    };

    gpuEngine = {
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
      engine = lib.mkOption {
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
    engineOptimizations = {
      enableGpuRasterization = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Offload painting operations from the CPU to the GPU.";
      };
      enableMemoryManagement = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable zero-copy and native GPU memory buffers.";
      };
      enableIgnoreGpuBlocklist = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Force hardware acceleration on experimental/uncertified drivers.";
      };
      enableSafetyOverrides = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          DANGEROUS: If true, disables Chromium's internal driver bug workarounds. 
          Keep this FALSE on Intel Xe to maintain high WebGL draw-call performance.
        '';
      };
    };
    engineFeatures = {
      enableVideoAcceleration = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable hardware-accelerated video decoding/encoding (VA-API).";
      };
      enableTreesInViz = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Moves the Display Tree to the Viz compositor thread to reduce input latency.";
      };
      enableSkiaGraphite = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Replaces Ganesh with the next-gen Skia Graphite 2D renderer.
          Currently hard-blocked by Chromium on X11; keep FALSE until supported.
        '';
      };
      enableWebNn = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enables Web Neural Network API for GPU-accelerated ML (e.g., Google Meet blur).";
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- Chrome Enterprise Policies
    environment.etc."opt/chrome/policies/managed/policies.json".text = builtins.toJSON (
      activePolicies
      // {
        "RestoreOnStartup" = 1;
        "DefaultBrowserSettingEnabled" = false;
      }
    );
    environment.etc."opt/chrome/policies/managed/search.json".text = builtins.toJSON ({
      "DefaultSearchProviderEnabled" = true;
      "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}";
      "DefaultSearchProviderSuggestURL" = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
      "SearchSuggestEnabled" = false;
    });
    environment.etc."opt/chrome/policies/managed/extensions.json".text = builtins.toJSON ({
      "ExtensionSettings" = {
        # Vimium
        "dbepggeogbaibhgnhhndojpepiihcmeb" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
          "toolbar_pin" = "default_unpinned";
        };
        # uBlock Origin Lite
        "ddkjiahejlhfcafbddmgiahcphecmpfh" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
          "toolbar_pin" = "force_pinned";
        };
        # AWS Extend Roles
        "jpmkfafbacpgapdghgdpembnojdlgkdl" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
          "toolbar_pin" = "force_pinned";
        };
        # KeePassXC
        "oboonakemofpalcgghocfoadofidjkkk" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
          "toolbar_pin" = "default_unpinned";
        };
      };
    });
    environment.etc."opt/chrome/initial_preferences".text = builtins.toJSON firstRunDefaults;

    # --- Overwrite Chrome with startup flags
    nixpkgs.overlays = [
      (
        final: prev:
        let
          # We use let...in here to process the library logic before passing it to the package
          #  environment.systemPackages =
          #    let

          # 1. Call the library function using the evaluated NixOS options
          hwConfig = chromeHwLib.getChromeHardwareFlags {
            display_server = cfg.gpuEngine.displayServer;
            engine = cfg.gpuEngine.engine;
            enableGpuRasterization = cfg.engineOptimizations.enableGpuRasterization;
            enableMemoryManagement = cfg.engineOptimizations.enableMemoryManagement;
            enableIgnoreGpuBlocklist = cfg.engineOptimizations.enableIgnoreGpuBlocklist;
            enableSafetyOverrides = cfg.engineOptimizations.enableSafetyOverrides;
            enableVideoAcceleration = cfg.engineFeatures.enableVideoAcceleration;
            enableFeatureTreesInViz = cfg.engineFeatures.enableTreesInViz;
            enableFeatureSkiaGraphite = cfg.engineFeatures.enableSkiaGraphite;
            enableFeatureWebNn = cfg.engineFeatures.enableWebNn;
          };

          # 2. Get Privacy Set
          privacyConfig = chromePrivacyLib.getPrivacyFlags {
            enableDisableCrossOriginReferrer = true;
            enableReduceSystemInfo = true;
          };

          # 3. Merge the two sets (Combines flags, enableFeatures, and disableFeatures lists)
          combined = lib.zipAttrsWith (name: values: lib.concatLists values) [
            hwConfig
            privacyConfig
            {
              enableFeatures = [
                "WaylandFractionalScaleV1"
              ];
            }
          ];

          # 4. Generate final strings from the combined set
          enableFlag = lib.optional (
            combined.enableFeatures != [ ]
          ) "--enable-features=${lib.concatStringsSep "," combined.enableFeatures}";
          disableFlag = lib.optional (
            combined.disableFeatures != [ ]
          ) "--disable-features=${lib.concatStringsSep "," combined.disableFeatures}";
          scalingFlag = lib.optional (
            cfg.scalingFactor != 1.0
          ) "--force-device-scale-factor=${builtins.toString cfg.scalingFactor}";

          # 3. Concatenate the standalone flags with the feature flags
          finalCommandLineArgs = combined.flags ++ enableFlag ++ disableFlag ++ scalingFlag;
        in
        {
          # Rewrite the google-chrome package system-wide
          google-chrome = prev.google-chrome.override {
            commandLineArgs = finalCommandLineArgs;
          };
        }
      )
    ];

    # --- Install the globally overridden package
    environment.systemPackages = [
      pkgs.google-chrome
    ];
  };
}
