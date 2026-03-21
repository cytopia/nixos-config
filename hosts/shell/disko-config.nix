{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;     # Enables SSD TRIM
                  bypassWorkqueues = true;  # Reduces latency on fast NVMe drives
                };
                extraFormatArgs = [ "--type luks2" "--iter-time 2000" ];
                # allowDiscards = true; # Set to true in config.nix for SSD health
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "20G"; # 15Gi RAM + 5GB buffer for hibernation
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" ]; };
                "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
