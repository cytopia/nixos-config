{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.programs.thunar;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.thunar = {
    enable = lib.mkEnableOption "Thunar File Manager with full infrastructure support";
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- THE APPLICATION ---
    programs.thunar = {
      enable = true;
      # ADDITION: volman is best handled here as a plugin for auto-mounting UI integration
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
        # REMOVAL: thunar-vcs-plugin is notoriously heavy and often broken on Wayland.
        # Only add it back if you specifically need Git/SVN icons in your file manager.
      ];
    };

    # --- THE SETTINGS ENGINE ---
    # REQUIRED: Thunar stores view preferences (List vs Icons), hidden file toggles,
    # and custom actions in xfconf. Without this, your changes won't survive a reboot.
    programs.xfconf.enable = true;

    # PRESERVATION: dconf is required for GTK file pickers and theme consistency.
    # NOTE: Since we have this in wayland.nix, this is technically redundant,
    # but we keep it here as a 'defensive' measure so Thunar works even without our Wayland module.
    programs.dconf.enable = true;

    # --- THE MOUNTING & NETWORK LAYER (GVFS) ---
    services.gvfs = {
      enable = true;
      # ADDITION: Enables 'Network' browsing in Thunar (Samba/FTP/NFS)
      # This is the "Industry Standard" way to handle network drives in GTK apps.
      package = lib.mkDefault pkgs.gvfs;
    };

    # --- THE HARDWARE LAYER ---
    # PRESERVATION: Essential for mounting USB sticks and external drives.
    services.udisks2.enable = true;

    # --- THE VISUAL LAYER (Thumbnails) ---
    services.tumbler.enable = true;

    # ADDITION: Thumbnailers
    # Tumbler is the 'engine', but it needs 'workers' to see specific files.
    # Without these, you won't get thumbnails for videos or PDFs.
    environment.systemPackages = with pkgs; [
      ffmpegthumbnailer # For Video thumbnails
      poppler_utils     # For PDF thumbnails
      libgsf            # For ODF (Office) thumbnails
    ];

    # --- ARCHITECTURAL ADDITION: ARCHIVE INTEGRATION ---
    # The archive-plugin is useless without a backend.
    # We install 'file-roller' (GNOME) or 'ark' (KDE) or 'engrampa' (MATE).
    # Engrampa is the most 'Thunar-native' feeling archiver.
    environment.systemPackages = [ pkgs.mate.engrampa ];
  };
}
