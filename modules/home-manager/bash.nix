{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cytopia.cli.bash;
  shell = import ./lib/shell.nix { inherit pkgs lib; };
in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.cli.bash = {
    enable = lib.mkEnableOption "Shell customization module";

    # Completion
    enableCompletion = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable completion for all interactives shells.";
    };

    # Aliases
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "An attribute set of extra shell aliases.";
      example = {
        g = "git";
      };
    };

    # ~/.bashrc
    extraRcFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "A custom shell file that will be pasted into the end of the shell rc file.";
    };

    # Tmux
    autoAttachTmux = lib.mkEnableOption "attach tmux to every shell";

    # External helper programms
    enableBat = lib.mkEnableOption "Bat integration";
    enableDircolors = lib.mkEnableOption "Dircolors integration";
    enableDirenv = lib.mkEnableOption "Direnv integration";
    enableEza = lib.mkEnableOption "Eza integration";
    enableFzf = lib.mkEnableOption "Fzf integration";
    enableStarship = lib.mkEnableOption "Starship integration";
    enableZoxide = lib.mkEnableOption "Zoxide integration";
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # 1. Shell configuration
    programs.bash = {
      enable = true;
      enableCompletion = cfg.enableCompletion;

      # Sane defaults for history
      historyControl = [
        "ignoredups" # Do not save duplicates
        "ignorespace" # Do not save, if prefixed by a space
      ];

      # Aliases
      shellAliases =
        shell.aliases.default
        // (if cfg.autoAttachTmux then shell.aliases.tmux else { })
        // (if cfg.enableEza then { } else shell.aliases.ls)
        // (if cfg.enableBat then shell.aliases.bat else { })
        // cfg.aliases;

      # Very top of ~/.bashrc
      # Do we attach Tmux for every interactive shell?
      bashrcExtra = lib.optionalString cfg.autoAttachTmux shell.tmuxAttach.posix;

      # Very bottom of ~/.bashrc
      # Extra functions to be added to bashrc
      initExtra = lib.optionalString (cfg.extraRcFile != null) (builtins.readFile cfg.extraRcFile);
    };

    # 2. External helper shell integration
    # This ensures that the helper defined below have the corresponding
    # shell integration enabled automatically.
    home.shell.enableBashIntegration = true;

    # 3. External helper
    programs.bat = lib.mkIf cfg.enableBat {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        batgrep
        batwatch
        batpipe
        prettybat
      ];
    };
    programs.dircolors = lib.mkIf cfg.enableDircolors {
      enable = true;
    };
    programs.direnv = lib.mkIf cfg.enableDirenv {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.eza = lib.mkIf cfg.enableEza {
      enable = true;
      colors = "auto";
      git = true;
      extraOptions = [
        "--group-directories-first"
      ];
    };
    programs.fzf = lib.mkIf cfg.enableFzf {
      enable = true;
    };
    programs.starship = lib.mkIf cfg.enableStarship {
      enable = true;
    };
    programs.zoxide = lib.mkIf cfg.enableZoxide {
      enable = true;
    };

    # 3. Install required packages
    home.packages = [
      pkgs.xdg-utils # used for 'open' alias (xdg-open) in shell.aliases.default
    ]
    ++ lib.optionals cfg.enableCompletion [
      pkgs.bash-completion
      pkgs.nix-bash-completions
    ]
    ++ lib.optionals cfg.autoAttachTmux [ pkgs.tmux ];
  };
}
