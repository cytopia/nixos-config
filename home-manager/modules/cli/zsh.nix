{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Performance optimizations
    initContent = ''
      # Fast-syntax-highlighting is often smoother than the default
      # ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE is key for performance in large repos
      export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
      export ZSH_AUTOSUGGEST_USE_ASYNC=1

      # Clean up completions - only check once a day
      autoload -Uz compinit
      for dump in ~/.zcompdump(N.mh+24); do
        compinit
      done
      compinit -C
    '';

    shellAliases = {
      k = "kubectl";
      tf = "terraform";
      g = "git";
      cat = "bat";        # Modern cat with syntax highlighting

      # Listings
      ll = "eza -la";
      ls = "eza --icons";
      la = "eza -a";
      l = "eza -l";

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

      open = "xdg-open";
    };

    # Essential plugins for DevOps/Platform
    plugins = [
      {
        name = "zsh-nix-shell";
        src = pkgs.zsh-nix-shell;
        file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
      }
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };

  # The 'Modern Trinity' Tools
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  # Crucial for DevOps: Auto-loading nix shells when entering directories
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    bat
    eza
  ];

}
