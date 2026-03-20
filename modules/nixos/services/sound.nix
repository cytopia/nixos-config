{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.services.sound;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.services.sound = {
    enable = lib.mkEnableOption "PipeWire-based audio stack";

    enable32Bit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable 32-bit ALSA/Pulse support (Essential for Steam/Wine).";
    };

    enableLowLatency = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Optimize PipeWire for low-latency (Pro-audio/Music production).";
    };

    supportBluetooth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable high-quality Bluetooth audio profiles (LDAC, aptX, mSBC).";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- ARCHITECTURAL FOUNDATION ---
    # We MUST disable the legacy PulseAudio daemon to let PipeWire take over.
    services.pulseaudio.enable = false;

    # RTKit is mandatory for PipeWire to get real-time priority (prevents audio crackling).
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;

      # Standard compatibility layers
      alsa.enable = true;
      alsa.support32Bit = cfg.enable32Bit;
      pulse.enable = true; # Seamlessly mimics PulseAudio for apps like Zoom/Discord
      jack.enable = true;  # For pro-audio apps like Ardour/Bitwig

      # --- WIREPLUMBER (The Session Manager) ---
      wireplumber = {
        enable = true;
        # In modern NixOS, WirePlumber handles Bluetooth profile switching (HSP/HFP)
        # and codec negotiation automatically. This replaces the old 'hsphfpd'.
        extraConfig = lib.mkIf cfg.supportBluetooth {
          # https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html
          "10-bluez" = {
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true; # High-quality mic audio for calls
              "bluez5.enable-hw-volume" = true;
              "bluez5.roles" = [ "hsp_hs" "hfp_ag" "hfp_hf" "a2dp_sink" "a2dp_source" ];
            };
          };
        };
      };

      # --- LOW LATENCY TUNING ---
      # https://docs.pipewire.org/page_man_pipewire_conf_5.html
      # https://search.nixos.org/options?query=services.pipewire.extraConfig
      extraConfig.pipewire = lib.mkIf cfg.enableLowLatency {
        "99-lowlatency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 512;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 1024;
          };
        };
      };
    };

    # --- DIAGNOSTIC & MIXER TOOLS ---
    environment.systemPackages = with pkgs; [
      wireplumber  # Provides 'wpctl' (The modern CLI controller)
      pavucontrol  # The gold standard GUI mixer
      pulsemixer   # A beautiful TUI (terminal) mixer
      helvum       # A graphical patchbay for PipeWire (great for debugging)
    ];
  };
}
