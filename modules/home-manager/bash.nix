{ config, lib, pkgs, ... }:

let
  cfg = config.cytopia.cli.bash;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.cli.bash = {
    enable = lib.mkEnableOption "Enable bash customizations";

    # Completion
    enableCompletion = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Bash completion for all interactive Bash shells.";
    };

    # Aliases
    aliases = {
      extra = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "An attribute set of extra shell aliases.";
        example = { g = "git"; };
      };
    };

    # bashrc
    bashrc = {
      extraFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Add a custom shell file that will be added into bashrc";
      };
    };

    # Tmux
    autoAttachTmux = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to always start a tmux session in bash.";
    };

    # External helper programms
    enableStarship = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Starship for bash.";
    };
    enableFzf = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable FZF for bash.";
    };
    enableZoxide = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable zoxide for bash.";
    };
    enableDirenv = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable direnv for bash.";
    };
    enableEza = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable eza for bash.";
    };
    enableDircolors = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable dircolors for bash.";
    };
    enableBat = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable bat for bash.";
    };

  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    programs.bash = {
      enable = true;
      enableCompletion = cfg.enableCompletion;

      # Sane defaults for history
      historyControl = [
        "ignoredups"   # Do not save duplicates
        "ignorespace"  # Do not save, if prefixed by a space
      ];

      # Aliases
      shellAliases = {
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
        rgrep = "grep -r --color=auto --binary-file=without-match";
      }
      // (if cfg.autoAttachTmux then {
        refresh-tmux-env = "eval $(tmux show-environment -s)";
      } else {})
      // (if cfg.enableBat then {
        cat = "bat --plain";
        man = "batman";
      } else {})
      // (if cfg.enableEza then {
        # Listings: eza
        #l = "eza -l";
        #ll = "eza -la";
        #ls = "eza --icons";
        #la = "eza -a";
      } else {
        # Listings: ls
        l = "ls --color=always --group-directories-first --classify -l";
        ll = "ls --color=always --group-directories-first --classify -al";
        ls = "ls --color=always --group-directories-first --classify";
        la = "ls --color=always --group-directories-first --classify -a";
      })
      //  cfg.aliases.extra;


      # Very bottom of ~/.bashrc
      # Extra functions to be added to bashrc
      initExtra = lib.optionalString (cfg.bashrc.extraFile != null)
        (builtins.readFile cfg.bashrc.extraFile);

      # Very top of ~/.bashrc
      # Do we attach Tmux for every interactive shell?
      bashrcExtra = lib.optionalString cfg.autoAttachTmux ''
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
              # ADD: Refreshes the local client environment upon attachment.
              exec tmux -u attach-session -t "$_TMUX_SESSION"
            fi
          fi
        fi
      '';
    };

    programs.starship = lib.mkIf cfg.enableStarship {
      enable = true;
      enableBashIntegration = true;
    };

    programs.zoxide = lib.mkIf cfg.enableZoxide {
      enable = true;
      enableBashIntegration = true;
    };

    programs.fzf = lib.mkIf cfg.enableFzf {
      enable = true;
      enableBashIntegration = true;
    };

    programs.direnv = lib.mkIf cfg.enableDirenv {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    programs.eza = lib.mkIf cfg.enableEza {
      enable = true;
      colors = "auto";
      git = true;
      enableBashIntegration = true;
      extraOptions = [
        "--group-directories-first"
      ];
    };
    programs.dircolors = lib.mkIf cfg.enableDircolors {
      enable = true;
      enableBashIntegration = true;
    };
    programs.bat = lib.mkIf cfg.enableBat {
      enable = true;
      extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch batpipe prettybat ];
    };

    # Install required packages
    home.packages = [
      pkgs.xdg-utils  # used for 'open' alias (xdg-open)
    ]
    ++ lib.optionals cfg.enableCompletion [ pkgs.bash-completion pkgs.nix-bash-completions ]
    ++ lib.optionals cfg.autoAttachTmux [ pkgs.tmux ];
  };
}

