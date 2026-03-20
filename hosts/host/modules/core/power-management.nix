{ config, pkgs, ... }:


{
  # 1. LOGIN DAEMON: Handles the "Lid" and "Idle" timers.
  services.logind.settings.Login = {
    # Closing the Lid
    HandleLidSwitchDocked = "ignore";                         # Docked or ext display attached
    HandleLidSwitchExternalPower = "suspend-then-hibernate";  # AC connected
    HandleLidSwitch = "suspend-then-hibernate";               # On battery

    # Idle Action
    # IMPORTANT: Will be ignored when e.g. swayidle is running
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "30m";

    # Ensure lock/mute scripts finish before hardware cuts power
    # E.g.: swayidle can set 'before-sleep' action
    LidSwitchIgnoreInhibited = "no";
    SuspendKeyIgnoreInhibited = "no";
    HibernateKeyIgnoreInhibited = "no";
  };

  # 2. SLEEP LOGIC: Defines the behavior of 'suspend-then-hibernate'.
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
    # Check battery every 30min to see if we are below 5% (hardcoded)
    # If yes, then hibernate. Note, it will calculate a new checktime
    # based on how much battery was drained. So after the initial check
    # it might check again in 10min or 56min
    SuspendEstimationSec=30min
  '';

  # 3. UPOWER: The "Awake" watchdog (Safety while you use the PC).
  services.upower = {
    enable = true;

    # Choose the action: "PowerOff", "Hibernate", or "HybridSleep"
    # Note: Hibernate requires a swap partition/file larger than your RAM.
    criticalPowerAction = "Hibernate";

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
}

