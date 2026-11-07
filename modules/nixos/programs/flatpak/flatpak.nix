{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.programs.flatpak;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.flatpak = {
    enable = lib.mkEnableOption "Declarative Flatpak (nix-flatpak) with flathub";

    remotes = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
      description = "Extra remotes besides flathub.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
      description = "Flatpak apps to install: app id strings or { appId; origin; } attrsets.";
    };

    overrides = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Per-app overrides, same shape as services.flatpak.overrides.settings.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # UNTESTED at runtime: nobody has run this module on this sway, Intel and
    # greetd setup yet (Flatpak apps under Wayland). Evaluation is verified
    # only. The manual checklist in
    # docs/superpowers/specs/2026-11-06-geforcenow-flatpak-design.md covers it.

    # Flatpak apps need portals (file chooser, login) and the host DRI devices.
    # Fail at evaluation with a short message instead of a deep nixpkgs trace.
    assertions = [
      {
        assertion = config.xdg.portal.enable;
        message = "mySystem.programs.flatpak: requires xdg.portal.enable = true (set by modules/nixos/desktop/wayland.nix). Flatpak apps need portals for file chooser and login.";
      }
      {
        # Flatpak apps use the host DRI devices through the runtime's Mesa,
        # so the host must expose /dev/dri.
        assertion = config.hardware.graphics.enable;
        message = "mySystem.programs.flatpak: requires hardware.graphics.enable = true (set by modules/nixos/hardware/gpu-intel.nix). Flatpak apps use the host DRI devices through the runtime's Mesa, so the host must expose /dev/dri.";
      }
    ];

    services.flatpak = {
      enable = true;

      # flathub is declared here because the runtime org.freedesktop.Platform//24.08
      # lives on flathub. Declaring any remote replaces nix-flatpak's default,
      # hence [ flathub ] ++ cfg.remotes. Host and app modules must add remotes
      # through mySystem.programs.flatpak.remotes, never services.flatpak.remotes.
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ]
      ++ cfg.remotes;

      inherit (cfg) packages;
      overrides.settings = cfg.overrides;

      # Flatpak updates are manual only: "sudo flatpak update". Nothing updates
      # at boot, on switch or by timer. update.onActivation = true would add
      # "--or-update" to the install unit (flatpak-managed-install.service, a
      # oneshot, wantedBy default.target), which runs at every boot and on
      # every switch. update.auto.enable = true would add a timer. Both are
      # pinned to false as plain definitions on purpose (the user wants manual
      # updates, and nix-flatpak's own rationale is that repeated
      # nixos-rebuild switch stays idempotent), so any module that enables
      # them fails evaluation. To change this, edit this file.
      # The first switch blocks while the oneshot installs missing apps.
      # Offline the unit fails and systemd retries every 60 s
      # (Restart=on-failure, RestartSec=60s). The exit status of
      # nixos-rebuild switch in that case was not verified.
      update.onActivation = false;
      update.auto.enable = false;

      # The repo is the source of truth: any remote or app added by hand
      # disappears on the next switch. nix-flatpak only treats apps as
      # unmanaged, never runtimes. Runtimes go only through uninstallUnused,
      # and a runtime used by an installed app is not unused, so the 24.08
      # runtime survives.
      uninstallUnmanaged = lib.mkDefault true;
      # Explicit so the intent is visible; nix-flatpak defaults it to the
      # previous option anyway.
      uninstallUnused = lib.mkDefault true;
    };

    # XDG_DATA_DIRS is deliberately not set here. The nixpkgs module
    # nixos/modules/services/desktops/flatpak.nix:54-57 adds
    # $HOME/.local/share/flatpak/exports and /var/lib/flatpak/exports to
    # environment.profiles. greetd sources /etc/profile (source_profile
    # default) and its PAM stack loads /etc/pam/environment; both carry the
    # Flatpak export dirs. A fresh login is needed after the first switch.
  };
}
