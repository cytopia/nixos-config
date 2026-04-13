{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cytopia.programs.browsers;

  # Only process browsers where enable = true
  activeBrowsers = lib.filterAttrs (name: browserCfg: browserCfg.enable) cfg;

  policyPaths = {
    "chromium" = "chromium";
    "brave" = "brave";
    "google-chrome" = "opt/google/chrome";
  };

  # -------------------------------------------------------------
  # The Build Function: Takes a browser name and its config,
  # returns the wrapped package derivation.
  # -------------------------------------------------------------
  buildWrappedBrowser = name: browserCfg:
    let
      enableFeatureFlag = lib.optional (browserCfg.internal.enableFeatures != [ ])
        "--enable-features=${lib.concatStringsSep "," browserCfg.internal.enableFeatures}";

      disableFeatureFlag = lib.optional (browserCfg.internal.disableFeatures != [ ])
        "--disable-features=${lib.concatStringsSep "," browserCfg.internal.disableFeatures}";

      baseChrome = pkgs.${name}.override {
        commandLineArgs = map lib.escapeShellArg (
          browserCfg.internal.flags ++ enableFeatureFlag ++ disableFeatureFlag
        );
      };

      envArgs = lib.mapAttrsToList (
        key: value: "--set ${lib.escapeShellArg key} ${lib.escapeShellArg value}"
      ) browserCfg.internal.envVars;

      wrapperEnvArgs = lib.concatStringsSep " " envArgs;

      # Abstracted the wrap loop so both build methods (chromium/brave & google chrome) can share it.
      # This simple loop finds the executable binary and injects our env vars.
      wrapCmd = ''
        for binPath in $out/bin/*; do
          if [ -f "$binPath" ] && [ -x "$binPath" ]; then
            wrapProgram "$binPath" ${wrapperEnvArgs}
          fi
        done
      '';

    in
    # Introduced conditional logic. We branch the build strategy based
    # on whether we are building Google Chrome or Chromium/Brave.
    if name == "google-chrome" then
      # =======================================================================
      # STRATEGY 1: NATIVE OVERRIDE (For Google Chrome)
      # =======================================================================
      # Because google-chrome is a simple .deb unpack, it is safe and fast to
      # override its native build attributes. We inject our wrapper directly
      # into its standard build phases.
      baseChrome.overrideAttrs (oldAttrs: {
        # ADD: Ensure makeWrapper is available in the native build environment
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      }
      # Some older versions of Chrome might use buildCommand instead of phases
      // lib.optionalAttrs (oldAttrs ? buildCommand) {
        buildCommand = oldAttrs.buildCommand + "\n" + wrapCmd;
      }
      # Standard Nixpkgs google-chrome uses postFixup. We append our wrapping here.
      # By doing this, we avoid symlinkJoin and do NOT need to run sed on .desktop files!
      // lib.optionalAttrs (!(oldAttrs ? buildCommand)) {
        postFixup = (oldAttrs.postFixup or "") + "\n" + wrapCmd;
      })
    else
      # =======================================================================
      # STRATEGY 2: SYMLINK JOIN (For Chromium & Brave)
      # =======================================================================
      # Because Chromium/Brave are highly complex, source-built derivations,
      # overriding them natively can trigger massive recompilations or breakages.
      # Instead, we treat them as black boxes, link their outputs, and wrap them.
      pkgs.symlinkJoin {
        name = "${baseChrome.name}-custom-wrapped";
        paths = [ baseChrome ];
        nativeBuildInputs = [ pkgs.makeWrapper ];

        postBuild = ''
          # 1. Wrap the binaries using the shared wrapCmd block
          ${wrapCmd}

          # 2. Safely copy and rewrite desktop files
          if [ -d "${baseChrome}/share/applications" ]; then
            # Remove the symlinked directory created by symlinkJoin
            rm -rf "$out/share/applications"
            mkdir -p "$out/share/applications"

            # Copy the REAL files directly from the base package
            cp -a "${baseChrome}/share/applications"/* "$out/share/applications/"
            chmod -R +w "$out/share/applications"

            # Safely patch the Exec lines to use our wrapper.
            # This regex specifically captures the 'Exec=' key (1), ignores any existing
            # absolute/relative paths (2), matches our binary name, and captures any
            # trailing arguments like %U or --incognito (3) to preserve them perfectly.
            for desktop in "$out/share/applications"/*.desktop; do
              for binPath in $out/bin/*; do
                [[ "$binPath" == *"-wrapped" ]] && continue
                binName=$(basename "$binPath")

                sed -i -E "s|^(Exec=)([^ ]*/)?''${binName}( .*)?$|\1$out/bin/''${binName}\3|" "$desktop"
              done
            done

          fi
        '';
      };
in
{
  config = lib.mkIf (activeBrowsers != { }) {

    # 1. Map policies
    environment.etc = lib.mkMerge (lib.mapAttrsToList (name: browserCfg:
      let pPath = policyPaths.${name}; in {
        "${pPath}/policies/managed/policies.json" = lib.mkIf (browserCfg.internal.policies != { }) {
          text = builtins.toJSON browserCfg.internal.policies;
        };
        "${pPath}/initial_preferences" = lib.mkIf (browserCfg.internal.initialPreferences != { }) {
          text = builtins.toJSON browserCfg.internal.initialPreferences;
        };
      }
    ) activeBrowsers);

    # 2. Map Systemd Services (e.g., Cert sync logic passed from features)
    systemd.user.services = lib.mkMerge (lib.mapAttrsToList (name: browserCfg:
      browserCfg.internal.systemdUserServices
    ) activeBrowsers);

    # 3. Build and install packages
    environment.systemPackages = lib.mapAttrsToList (name: browserCfg:
      buildWrappedBrowser name browserCfg
    ) activeBrowsers;

  };
}
