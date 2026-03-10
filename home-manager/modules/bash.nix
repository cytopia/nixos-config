{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
    };

    sessionVariables = {
      EDITOR = "vim";
      XDG_CURRENT_DESKTOP = "sway";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
    };

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

      echo "Welcome back! Wayland environment synced to tmux."
    '';
  };

  home.packages = [ pkgs.tmux ];
}
