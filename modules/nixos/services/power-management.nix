{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.services.power-management;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.services.power-management = {
    enable = lib.mkEnableOption "Advanced Power Management (logind & upower)";

    sleepAction = lib.mkOption {
      type = lib.types.enum [ "suspend" "suspend-then-hibernate" "hibernate" "ignore" ];
      default = "suspend-then-hibernate";
      description = ''
        The default action for lid closing and idling on battery.
        WARNING: If you use 'suspend-then-hibernate', you MUST have a swap partition
        larger than your RAM and 'boot.resumeDevice' configured in your system!
      '';
    };

    hibernateDelay = lib.mkOption {
      type = lib.types.str;
      default = "2h";
      description = "Time before suspending to disk (hibernation) when using 'suspend-then-hibernate'.";
    };

    criticalBatteryAction = lib.mkOption {
      type = lib.types.enum [ "PowerOff" "Hibernate" "HybridSleep" ];
      default = "Hibernate";
      description = "What upower should do when battery hits the critical action threshold (5%).";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- 1. LOGIN DAEMON (Hardware Events) ---
    services.logind.settings.Login = {
      # Closing the Lid
      HandleLidSwitchDocked = "ignore";                # Docked or ext display attached
      HandleLidSwitchExternalPower = cfg.sleepAction;  # AC connected
      HandleLidSwitch = cfg.sleepAction;               # On battery

      # Idle Action
      # IMPORTANT: Will be ignored when e.g. swayidle is running
      IdleAction = cfg.sleepAction;
      IdleActionSec = "30m";

      # Ensure lock/mute scripts finish before hardware cuts power
      # E.g.: swayidle can set 'before-sleep' action
      LidSwitchIgnoreInhibited = "no";
      SuspendKeyIgnoreInhibited = "no";
      HibernateKeyIgnoreInhibited = "no";
    };


    # --- 2. SLEEP LOGIC (systemd-sleep) ---
    # Defines the behavior of 'suspend-then-hibernate'.
    systemd.sleep.extraConfig = ''
      HibernateDelaySec=${cfg.hibernateDelay}

      # systemd v253+ battery estimation logic
      # Checks battery every 30min to see if we are below 5%.
      # If yes, hibernates to save remaining charge.
      SuspendEstimationSec=30min
    '';

    # --- 3. UPOWER (The Safety Watchdog) ---
    services.upower = {
      enable = true;

      # Action to take when battery is dying
      # Note: Hibernate requires a swap partition/file larger than your RAM.
      criticalPowerAction = cfg.criticalBatteryAction;

      # Define the thresholds
      usePercentageForPolicy = true;
      percentageLow = 15;       # Status bar usually turns orange/yellow
      percentageCritical = 10;  # Status bar usually turns red
      percentageAction = 5;     # The point of no return where hibernation triggers

      # Security/Safety toggle
      # If you want to use "Suspend" as a critical action (risky if battery dies),
      # you must set this to true. For Hibernate, it's not needed.
      allowRiskyCriticalPowerAction = false;
    };
  };
}
