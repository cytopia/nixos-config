{ config, pkgs, ... }:


{
  # Disable the old PulseAudio server
  services.pulseaudio.enable = false;

  # Required for PipeWire to get high-priority CPU time (avoids crackling in games)
  security.rtkit.enable = true; # High-priority scheduling for real-time audio (low-latency)

  # Pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;  # modern default session manager
  };
}
