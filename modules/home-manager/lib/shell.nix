{ pkgs, lib }:

# This library provides:
#
#   aliases.default
#   aliases.ls
#   aliases.tmux
#   aliases.bat
#   tmuxAttach.posix
#   tmuxAttach.fish

{
  ###
  ### Shell aliases
  ###
  aliases = {
    default = {
      # Default aliases
      open = "xdg-open";
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
      rgrep = "grep -r --color=auto --binary-file=without-match";
      df = "df -h";
      du = "du -h";
    };
    ls = {
      # Listings: ls (LC_COLLATE=C ensures that dot files/dirs come first)
      l = "LC_COLLATE=C ls --color=always --group-directories-first --classify -hl";
      ll = "LC_COLLATE=C ls --color=always --group-directories-first --classify -hla";
      ls = "LC_COLLATE=C ls --color=always --group-directories-first --classify";
      la = "LC_COLLATE=C ls --color=always --group-directories-first --classify -a";
    };
    tmux = {
      refresh-tmux-env = "eval $(tmux show-environment -s)";
    };
    bat = {
      cat = "bat --plain";
      man = "batman";
    };
  };

  ###
  ### Script that automatically attaches to tmux
  ###
  tmuxAttach = {
    posix = ''
      # 1. We are in an interactive shell ($- == *i*)
      # 2. We are NOT already inside a tmux session ($TMUX is empty)
      # 3. We are NOT in a plain TTY (ensures tmux only starts in Wayland)
      if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -n "$WAYLAND_DISPLAY" ]]; then

        if command -v tmux >/dev/null; then
          # Update the tmux server's environment variables.
          # This ensures that if you restart Sway/Wayland, new panes in OLD sessions
          # still have the correct socket paths for the clipboard and windows.
          REFS_VARS=(
            # Core Wayland/Sway
            WAYLAND_DISPLAY SWAYSOCK DISPLAY
            XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS

            # Identity & Portals
            XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_ID XDG_SESSION_TYPE

            # Toolkits & NixOS Specifics
            GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND
            NIXOS_OZONE_WL ELECTRON_OZONE_PLATFORM_HINT

            # Auth
            SSH_AUTH_SOCK
          )
          for var in "''${REFS_VARS[@]}"; do
            if [[ -n "''${!var}" ]]; then
              tmux setenv -g "$var" "''${!var}" 2>/dev/null
            fi
          done

          # We look for the first session  that is not attached (session_attached == 0).
          _TMUX_SESSION=$(tmux list-sessions -F "#{session_name}:#{session_attached}" 2>/dev/null | awk -F: '$2=="0" {print $1; exit}')

          if [[ -z "$_TMUX_SESSION" ]] ;then
            exec tmux -u new-session
          else
            # Refreshes the local client environment upon attachment.
            exec tmux -u attach-session -t "$_TMUX_SESSION"
          fi
        fi
      fi
    '';
    fish = ''
      # 1. We are in an interactive shell (status is-interactive)
      # 2. We are NOT already inside a tmux session ($TMUX is empty)
      # 3. We are NOT in a plain TTY (ensures tmux only starts in Wayland)
      if status is-interactive; and test -z "$TMUX"; and test -n "$WAYLAND_DISPLAY"

        if type -q tmux
          # Update the tmux server's environment variables.
          # This ensures that if you restart Sway/Wayland, new panes in OLD sessions
          # still have the correct socket paths for the clipboard and windows.
          set REFS_VARS \
            # Core Wayland/Sway
            WAYLAND_DISPLAY SWAYSOCK DISPLAY \
            XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
            \
            # Identity & Portals
            XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_ID XDG_SESSION_TYPE \
            \
            # Toolkits & NixOS Specifics
            GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND \
            NIXOS_OZONE_WL ELECTRON_OZONE_PLATFORM_HINT \
            \
            # Auth
            SSH_AUTH_SOCK

          for var in $REFS_VARS
            # In Fish, ''$''$var provides indirect variable expansion (value of the variable named by $var)
            if test -n "''$''$var"
              tmux setenv -g "$var" "''$''$var" 2>/dev/null
            end
          end

          # We look for the first session that is not attached (session_attached == 0).
          set _TMUX_SESSION (tmux list-sessions -F "#{session_name}:#{session_attached}" 2>/dev/null | awk -F: '$2=="0" {print $1; exit}')

          if test -z "$_TMUX_SESSION"
            exec tmux -u new-session
          else
            # Refreshes the local client environment upon attachment.
            exec tmux -u attach-session -t "$_TMUX_SESSION"
          end
        end
      end
    '';
  };

}
