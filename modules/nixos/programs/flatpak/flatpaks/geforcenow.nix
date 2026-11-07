{
  config,
  lib,
  ...
}:

# NVIDIA GeForce NOW as a Flatpak, installed through the generic Flatpak layer
# (modules/nixos/programs/flatpak/flatpak.nix).
#
# Values taken from NVIDIA's repo, fetched 2026-11-06:
#   app ref   app/com.nvidia.geforcenow/x86_64/master
#   runtime   org.freedesktop.Platform/x86_64/24.08
#   sdk       org.freedesktop.Sdk/x86_64/24.08
#   command   GeForceNOW
#   repo      Title GeForceNOW, Homepage https://geforcenow.com,
#             Url https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow_repo
#   The .flatpakrepo file carries a GPGKey= line, so no gpg-import is needed.
#
# Wayland only: NVIDIA lists Wayland as required for Intel and AMD GPUs, and
# H.264 and H.265 decoding go through Vulkan Video, which needs Mesa 24.2.8 or
# newer.
#
# The stock NVIDIA manifest is deliberately broad: filesystems home and host-etc,
# devices=all, sockets including session-bus and system-bus, and it talks to
# org.freedesktop.secrets. It stays the default so a failure is never caused by
# our own overrides. `hardened` opts into trimming it.
#
# UNTESTED at runtime on sway, Intel and NixOS; NVIDIA documents Ubuntu 24.04 only.

let
  cfg = config.mySystem.programs.geforcenow;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.geforcenow = {
    enable = lib.mkEnableOption "NVIDIA GeForce NOW (Flatpak)";

    hardened = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Drop the broad `home` and `host-etc` filesystem access from the NVIDIA manifest. Untested: keyring login, gamepad and HDR may break.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        mySystem.programs.flatpak = {
          # mkDefault so a host that sets this to false trips the assertion below
          # instead of a "conflicting definition" error.
          enable = lib.mkDefault true;

          # The .flatpakrepo file embeds the GPG key, so no gpg-import.
          remotes = [
            {
              name = "GeForceNOW";
              location = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
            }
          ];

          # origin must equal the remote name exactly: nix-flatpak matches it
          # case-sensitively, a mismatch makes the install fail loudly in the
          # flatpak-managed-install journal.
          packages = [
            {
              appId = "com.nvidia.geforcenow";
              origin = "GeForceNOW";
            }
          ];
        };

        assertions = [
          {
            assertion = config.mySystem.programs.flatpak.enable;
            message = "mySystem.programs.geforcenow: requires mySystem.programs.flatpak.enable = true; the GeForce NOW app is installed through the Flatpak layer.";
          }
        ];
      }

      (lib.mkIf cfg.hardened {
        # Hardening removes broad access from the NVIDIA manifest. It may break
        # things (untested): keyring login, gamepad, HDR.
        # devices=all (gamepads), all sockets and all bus names stay untouched.
        mySystem.programs.flatpak.overrides."com.nvidia.geforcenow".Context.filesystems = [
          # removes home access; login state lives under ~/.var/app, so this
          # should not matter
          "!home"
          # removes read access to host /etc; may break certificate or font lookups
          "!host-etc"
          # keeps downloads
          "xdg-download"
        ];
      })
    ]
  );
}
