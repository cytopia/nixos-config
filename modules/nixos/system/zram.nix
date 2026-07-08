{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.system.zram;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.zram = {
    enable = lib.mkEnableOption "Compressed RAM swap (zram) as a fast first-line swap device";

    memoryPercent = lib.mkOption {
      type = lib.types.ints.positive;
      default = 50;
      description = ''
        Size of the zram device as a percentage of total RAM (uncompressed).
        Kept moderate on purpose: zram itself consumes real RAM to hold its
        compressed pages, so a huge zram device competes with the memory
        it is supposed to relieve pressure on. This is independent of the
        on-disk swap device, which stays sized for full hibernation.
      '';
    };

    algorithm = lib.mkOption {
      type = lib.types.str;
      default = "zstd";
      description = "Compression algorithm used for the zram device.";
    };

    priority = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = ''
        Swap priority for zram. Must be higher than the on-disk swap
        device's priority so the kernel prefers zram for regular
        swapping and only spills over to disk once zram is full.
        Priority has no effect on hibernation: the resume image is
        always written to 'boot.resumeDevice', never to zram.
      '';
    };

    swappiness = lib.mkOption {
      type = lib.types.ints.between 0 200;
      default = 100;
      description = ''
        vm.swappiness while zram is enabled. Deliberately set higher than
        the NixOS default (60): swappiness is a single global knob that
        governs how eagerly the kernel swaps out to *whichever* swap tier
        is currently active, zram and disk alike. Since zram sits above
        the on-disk swap in priority, raising swappiness pushes more
        pages into the cheap/fast zram tier (good) while the on-disk
        swap still stays effectively idle, only touched once zram's
        capacity ('memoryPercent') is exhausted. A low swappiness would
        instead just suppress zram usage entirely, wasting the tier.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # WARNING: zram is volatile (RAM-backed) and can NEVER be used as the
    # hibernation resume target. The real, on-disk swap device (sized for
    # full RAM + buffer, see disko-config.nix) must remain in place and
    # 'boot.resumeDevice' must keep pointing at it. See ZRAM.md for details.
    zramSwap = {
      enable = true;
      algorithm = cfg.algorithm;
      memoryPercent = cfg.memoryPercent;
      priority = cfg.priority;
    };

    boot.kernel.sysctl."vm.swappiness" = cfg.swappiness;
  };
}
