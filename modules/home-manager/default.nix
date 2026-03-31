{ ... }: {
  imports = [
    # --- Modules ---
    ./bash.nix
    ./fish.nix
    ./signal-desktop.nix
    ./telegram-desktop.nix
    ./slack.nix
    ./theme.nix
  ];
}
