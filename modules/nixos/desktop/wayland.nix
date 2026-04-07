{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.wayland;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.desktop.wayland = {
    enable = lib.mkEnableOption "Core Wayland enablement layer";

    enableXwayland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable XWayland compatibility layer for X11 applications.";
    };

    useGtkPortal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to include xdg-desktop-portal-gtk.
        Highly recommended even on non-GTK desktops for file-picker and app-interop compatibility.
      '';
    };

    extraPortals = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional portal backends:
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-wlr
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- SECURITY & PERMISSIONS ---
    # Polkit is essential. Wayland compositors often need to talk to systemd/logind
    # via Polkit to manage 'seats' (keyboard/mouse/display ownership).
    security.polkit.enable = true;

    # Screen Lockers: On NixOS, screen lockers (swaylock, hyprlock, etc.)
    # require a PAM service entry or they will be unable to verify your password.
    # We define them here globally so any locker you choose 'just works'.
    security.pam.services = {
      swaylock = { };
      hyprlock = { };
      # 'gtklock' or 'greetd''s ags/regreet often use the 'login' or 'lock' PAM paths
    };

    # --- DBUS ---
    # Wayland relies heavily on D-Bus for IPC (Inter-Process Communication).
    services.dbus.enable = true;

    # --- XWayland ---
    programs.xwayland.enable = cfg.enableXwayland;

    # This ensures the dconf database (GTK's settings backend) is available globally.
    # Without this, many apps won't save settings or find themes.
    # Required for GTK/Gnome apps (like Seahorse) to talk to the Keyring service.
    programs.dconf.enable = true;

    # Minimal Qt infrastructure
    # Ensure that qtwayland is installed and visible to the whole system.
    # (gtk is different and handled via home-manager)
    qt.enable = true;

    # --- XDG DESKTOP PORTALS ---
    # Portals are the 'Modern Wayland API'. They handle screen sharing,
    # screenshots, file picking, and dark mode detection.
    xdg.portal = {
      enable = true;

      # Problem: Not opening links from Electron Apps (Signal/Slack)
      # Electron apps poison their local environment variables (like LD_LIBRARY_PATH).
      # This forces xdg-open to route requests through the D-Bus portal, ensuring
      # our custom browser spawns in a clean system environment instead of silently crashing.#
      xdgOpenUsePortal = true;

      # We combine the GTK portal (for standardized UI elements)
      # with any compositor-specific portals you pass via the module parameters.
      extraPortals =
        (if cfg.useGtkPortal then [ pkgs.xdg-desktop-portal-gtk ] else [ ]) ++ cfg.extraPortals;

      # ARCHITECTURAL BEST PRACTICE:
      # Modern Portal (2.0+) requires an explicit 'default' config to prevent
      # 30-second delays when apps try to find a portal backend.
      # We use lib.mkDefault here so that specific compositor modules
      # can easily override or augment these settings.
      config = {
        common.default = lib.mkDefault [ "gtk" ];
      };
    };

    # --- SYSTEM PACKAGES ---
    # Essential low-level utilities that every Wayland user needs.
    environment.systemPackages = with pkgs; [
      slurp # Region selector for grim/screen-sharing
      grim # Screenshot utility (Required for most sharing setups)
      wayland-utils # Provides 'wayland-info' for debugging
      wl-clipboard # Standard Wayland copy/paste CLI (wl-copy/wl-paste)
      libinput # For 'libinput debug-events' and debugging
      wayprompt # provides wayprompt-ssh-askpass and wayprompt-gpg-pinentry
      gtk4-layer-shell # library that allows GTK4 applications to use the Wayland Layer Shell protocol
    ];

    # --- ENVIRONMENT VARIABLES ---
    # These variables tell toolkits (GTK, Qt, Java) to use Wayland natively.
    # This prevents 'blurry' windows caused by XWayland scaling.
    environment.sessionVariables = {
      # --- General Session ---
      XDG_SESSION_TYPE = "wayland";

      # We use lib.mkDefault for toolkit backends.
      # This allows your Sway/Hyprland modules to override these
      # (e.g., to remove the ',x11' fallback) without using mkForce.

      # --- GTK (Gnome-based apps) ---
      GDK_BACKEND = lib.mkDefault "wayland,x11"; # Wayland preferred, X11 fallback for safety

      # --- QT (KDE/OBS/vlc) ---
      QT_QPA_PLATFORM = lib.mkDefault "wayland;xcb";
      QT_QPA_PLATFORMTHEME = lib.mkDefault "xdgdesktopportal"; # Add this here
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      # --- Electrom & Chromium ---
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # --- Firefox ---
      MOZ_ENABLE_WAYLAND = "1";

      # --- Gaming (SDL & Clutter) ---
      SDL_VIDEODRIVER = lib.mkDefault "wayland";
      CLUTTER_BACKEND = lib.mkDefault "wayland";

      # --- Java (The modern way) ---
      _JAVA_AWT_WM_NONREPARENTING = "1"; # Fixes gray-scale bug
      # WARNING: Only enable this if you are using OpenJDK 21 or newer.
      JAVA_TOOL_OPTIONS = "-Dawt.toolkit.name=WLToolkit"; # Might break older Java apps
    };
  };
}
