{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.services.power-management;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.services.power-management = {
    enable = lib.mkEnableOption "Advanced Power Management (logind & upower and ppd & thermald)";

    sleepAction = lib.mkOption {
      type = lib.types.enum [
        "suspend"
        "suspend-then-hibernate"
        "hibernate"
        "ignore"
      ];
      default = "suspend-then-hibernate";
      description = ''
        The default action for lid closing and idling on battery.
        WARNING: If you use 'suspend-then-hibernate', you MUST have a swap partition
        larger than your RAM and 'boot.resumeDevice' configured in your system!
      '';
    };

    # Only for suspend-then-hibernate action
    hibernateDelay = lib.mkOption {
      type = lib.types.str;
      default = "2h";
      description = "Time before suspending to disk (hibernation) when using 'suspend-then-hibernate'.";
    };

    # Only for suspend-then-hibernate action
    hibernateOnACPower = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether 'suspend-then-hibernate' may hibernate while on AC power.
        If false, the system stays suspended on AC and the 'hibernateDelay'
        countdown only starts once AC power is disconnected.
      '';
    };

    criticalBatteryAction = lib.mkOption {
      type = lib.types.enum [
        "PowerOff"
        "Hibernate"
        "HybridSleep"
      ];
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
      # --- Lid ---
      # Lid closed while docked: do nothing, on AC or battery.
      # Docked = external monitor on, or a dock switch reports a dock.
      HandleLidSwitchDocked = "ignore";
      # Lid closed on AC power, not docked.
      HandleLidSwitchExternalPower = cfg.sleepAction;
      # Lid closed on battery, not docked.
      HandleLidSwitch = cfg.sleepAction;
      # If an app asks logind to block sleep, the lid still sleeps (systemd default).
      # A laptop in a bag must sleep. swayidle lock-before-sleep is a delay lock and is always honoured.
      LidSwitchIgnoreInhibited = "yes";
      # After boot and after each resume, lid events are ignored for 30 s (systemd default).
      HoldoffTimeoutSec = "30s";

      # --- Power key ---
      # Short press: same as the lid.
      HandlePowerKey = cfg.sleepAction;
      # Hold for 5 s: power off.
      HandlePowerKeyLongPress = "poweroff";
      # An app that blocks sleep or shutdown also stops the power key (systemd default).
      PowerKeyIgnoreInhibited = "no";

      # --- Suspend key (XF86Sleep) ---
      # Key does nothing. Sleep comes from the lid, the power key, idle timers and the sway menu.
      HandleSuspendKey = "ignore";
      HandleSuspendKeyLongPress = "ignore";
      SuspendKeyIgnoreInhibited = "no";

      # --- Hibernate key (XF86Hibernate) ---
      # Key does nothing. Hibernate comes from suspend-then-hibernate after its timer,
      # from upower at 5 % and from the sway menu.
      HandleHibernateKey = "ignore";
      HandleHibernateKeyLongPress = "ignore";
      HibernateKeyIgnoreInhibited = "no";

      # --- Reboot key (XF86Reboot) ---
      # Key does nothing. Reboot via the sway menu only.
      HandleRebootKey = "ignore";
      HandleRebootKeyLongPress = "ignore";
      RebootKeyIgnoreInhibited = "no";

      # --- Secure attention key ---
      # Only sends a D-Bus signal, no action (systemd default).
      HandleSecureAttentionKey = "secure-attention-key";

      # --- Idle ---
      # swayidle owns idle. logind must not sleep on its own. With "ignore" nothing happens here.
      IdleAction = "ignore";
      # Unused while IdleAction is "ignore". Kept explicit.
      IdleActionSec = "30m";

      # --- Inhibitor timing ---
      # Apps (swayidle lock-before-sleep) may delay a sleep by at most 5 s (systemd default).
      InhibitDelayMaxSec = "5s";

      # --- Sessions ---
      # Keep tmux and background jobs alive at logout (NixOS default).
      KillUserProcesses = false;
    };

    # --- 2. SLEEP LOGIC (systemd-sleep) ---
    # Defines the behavior of 'suspend-then-hibernate'.
    systemd.sleep.settings = {
      Sleep = {
        HibernateDelaySec = "${cfg.hibernateDelay}";

        # systemd v254+: On AC, stay suspended instead of hibernating.
        # The HibernateDelaySec countdown restarts until AC is disconnected.
        HibernateOnACPower = cfg.hibernateOnACPower;

        # systemd v253+ battery estimation logic
        # Checks battery every 30min to see if we are below 5%.
        # If yes, hibernates to save remaining charge.
        SuspendEstimationSec = "30min";
      };
    };

    # --- 3. UPOWER (The Safety Watchdog) ---
    services.upower = {
      enable = true;

      # Action to take when battery is dying
      # Note: Hibernate requires a swap partition/file larger than your RAM.
      criticalPowerAction = cfg.criticalBatteryAction;

      # Define the thresholds
      usePercentageForPolicy = true;
      percentageLow = 15; # Status bar usually turns orange/yellow
      percentageCritical = 10; # Status bar usually turns red
      percentageAction = 5; # The point of no return where hibernation triggers

      # Security/Safety toggle
      # If you want to use "Suspend" as a critical action (risky if battery dies),
      # you must set this to true. For Hibernate, it's not needed.
      allowRiskyCriticalPowerAction = false;
    };

    ###
    ### toggles
    ###
    ### powerprofilesctl get
    ### powerprofilesctl set performance
    ### powerprofilesctl set balanced
    ### powerprofilesctl set power-saver
    ###

    # --- 4. HARDWARE POWER PROFILES (Active Power Management) ---
    # Manages CPU/GPU frequencies and thermals while the system is awake.

    # Thermald: Prevents the Intel Tiger Lake CPU from prematurely throttling.
    # Interfaces directly with Intel's Dynamic Platform and Thermal Framework.
    services.thermald.enable = true;

    # Power-Profiles-Daemon: The modern standard for ACPI power management.
    # Native Wayland/Desktop integration. Relies on upower (configured above)
    # to automatically shift the Intel P-State and GPU power budgets when unplugged.
    services.power-profiles-daemon.enable = true;

    # Explicitly disable legacy and conflicting tools to ensure PPD and
    # the Linux kernel have exclusive control over the hardware states.
    services.tlp.enable = false;
    services.auto-cpufreq.enable = false;
  };
}
