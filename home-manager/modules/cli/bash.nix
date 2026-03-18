{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Configure history control to ignore duplicates
    historyControl = [
      "ignoredups"   # Do not save duplicates
      "ignorespace"  # Do not save, if prefixed by a space
    ];

    shellAliases = {
      # Overwrites
      cat = "bat --plain";     # Modern cat with syntax highlighting
      open = "xdg-open";

      # Listings
      ll = "ls --color=always --group-directories-first --classify -al";
      ls = "ls --color=always --group-directories-first --classify";
      la = "ls --color=always --group-directories-first --classify -a";
      l = "ls --color=always --group-directories-first --classify -l";

      # Safeguards
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      ln = "ln -i";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "......" = "cd ../../../../..";

      # Default args
      grep = "grep --color=auto --binary-file=without-match";
    };

    # Extra functions to be added to bashrc
    bashrcExtra = builtins.readFile ./scripts/shell-functions.sh;

    # This is where your custom shell logic goes
    initExtra = ''
      # Only run if:
      # 1. We are in an interactive shell ($- == *i*)
      # 2. We are NOT already inside a tmux session ($TMUX is empty)
      # 3. We are NOT in a plain TTY (optional, ensures tmux only starts in Wayland)
      if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -n "$WAYLAND_DISPLAY" ]]; then

        # Ensure the tmux server process knows about our current Sway environment
        # We 'setenv' BEFORE attaching to ensure all panes get the new socket
        if command -v tmux >/dev/null; then
          tmux setenv -g SWAYSOCK "$SWAYSOCK" 2>/dev/null
          tmux setenv -g WAYLAND_DISPLAY "$WAYLAND_DISPLAY" 2>/dev/null
          tmux setenv -g DISPLAY "$DISPLAY" 2>/dev/null

          # Attach to a session named 'main', or create it if it doesn't exist.
          # 'exec' replaces the bash process so closing tmux closes the terminal.
          _TMUX_SESSION="$( tmux ls | grep -vm1 attached | cut -d: -f1 )"
          if [[ -z "$_TMUX_SESSION" ]] ;then
            exec tmux -2 -u new-session
          # if detached session available attach to it
          else
            exec tmux -2 -u attach-session -t "$SESS_ID"
          fi
        fi
      fi
    '';

    sessionVariables = {
      EDITOR = "vim";
      XDG_CURRENT_DESKTOP = "sway";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
    };
  };

  home.packages = [
    pkgs.tmux
  ];
}
