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
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true; # Enables SSD TRIM
                  bypassWorkqueues = true; # Reduces latency on fast NVMe drives
                };
                extraFormatArgs = [
                  "--type luks2"
                  "--cipher aes-xts-plain64"
                  "--key-size 512"
                  "--pbkdf argon2id"
                  "--iter-time 5000"
                  "--sector-size 4096"
                ];
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
            size = "36G"; # 41Gi RAM + 5GB buffer for hibernation
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
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
