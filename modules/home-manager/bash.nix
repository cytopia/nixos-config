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
      use_bat = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to alias cat to 'bat'.";
      };
      use_eza = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to alias ls to 'eza'.";
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
      // (if cfg.aliases.use_bat then {
        cat = "bat --plain";
      } else {})
      // (if cfg.aliases.use_eza then {
        # Listings: eza
        ll = "eza -la";
        ls = "eza --icons";
        la = "eza -a";
        l = "eza -l";
      } else {
        # Listings: ls
        ll = "ls --color=always --group-directories-first --classify -al";
        ls = "ls --color=always --group-directories-first --classify";
        la = "ls --color=always --group-directories-first --classify -a";
        l = "ls --color=always --group-directories-first --classify -l";
      })
      //  cfg.aliases.extra;


      # Extra functions to be added to bashrc
      bashrcExtra = lib.optionalString (cfg.bashrc.extraFile != null)
        (builtins.readFile cfg.bashrc.extraFile);

      # Do we attach Tmux for every interactive shell?
      initExtra = lib.optionalString cfg.autoAttachTmux ''
        # Only run if:
        # 1. We are in an interactive shell ($- == *i*)
        # 2. We are NOT already inside a tmux session ($TMUX is empty)
        # 3. We are NOT in a plain TTY (optional, ensures tmux only starts in Wayland)
        if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -n "$WAYLAND_DISPLAY" ]]; then

          # Ensure the tmux server process knows about our current Sway environment
          # We 'setenv' BEFORE attaching to ensure all panes get the new socket
          if command -v tmux >/dev/null; then
            # TODO: check if we need to set the env here
            #tmux setenv -g SWAYSOCK "$SWAYSOCK" 2>/dev/null
            #tmux setenv -g WAYLAND_DISPLAY "$WAYLAND_DISPLAY" 2>/dev/null
            #tmux setenv -g DISPLAY "$DISPLAY" 2>/dev/null

            # Attach to a session named 'main', or create it if it doesn't exist.
            # 'exec' replaces the bash process so closing tmux closes the terminal.
            _TMUX_SESSION="$( tmux ls 2>/dev/null | grep -vm1 attached | cut -d: -f1 )"
            if [[ -z "$_TMUX_SESSION" ]] ;then
              exec tmux -2 -u new-session
            # if detached session available attach to it
            else
              exec tmux -2 -u attach-session -t "$_TMUX_SESSION"
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

    # Install required packages
    home.packages = [
      pkgs.xdg-utils  # used for 'open' alias (xdg-open)
    ]
    ++ lib.optionals cfg.aliases.use_bat [ pkgs.bat ]
    ++ lib.optionals cfg.aliases.use_eza [ pkgs.eza ]
    ++ lib.optionals cfg.autoAttachTmux [ pkgs.tmux ];
  };

}

