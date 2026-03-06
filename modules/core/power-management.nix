{ config, pkgs, ... }:


{
  services.upower = {
    enable = true;

    # 1. Choose the action: "PowerOff", "Hibernate", or "HybridSleep"
    # Note: Hibernate requires a swap partition/file larger than your RAM.
    criticalPowerAction = "Hibernate";

    # 2. Define the thresholds
    percentageLow = 15;       # Status bar usually turns orange/yellow
    percentageCritical = 10;  # Status bar usually turns red
    percentageAction = 5;     # The point of no return where hibernation triggers

    # 3. Security/Safety toggle
    # If you want to use "Suspend" as a critical action (risky if battery dies),
    # you must set this to true. For Hibernate, it's not needed.
    allowRiskyCriticalPowerAction = false;
  };
}

