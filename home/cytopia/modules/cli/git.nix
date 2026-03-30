{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # https://git-scm.com/docs/git-config
    settings = {
      user = {
        name  = "cytopia";
        email = "cytopia@everythingcli.org";
        signingkey = "A02C56F0";
      };

      core = {
        # Highlight spaces in red during git diff/log/apply
        # blank-at-eol:     Spaces or tabs at the very end of a line.
        # blank-at-eof:     Blank lines at the very end of a file.
        # trailing-space:   Combines 'blank-at-eol' and 'blank-at-eof'
        # space-before-tab: A space used before a tab for indentation (usually a typo).
        whitespace = "trailing-space,space-before-tab";

        # Configure Git to ensure line endings in files you checkout are correct for Linux
        autocrlf = "input";

        # It provides side-by-side diffs, syntax highlighting, and line numbers.
        # Install via: 'cargo install git-delta' or your package manager.
        pager = "delta";
      };

      interactive = {
        diffFilter = "delta --color-only";
      };

      status = {
        submodulesummary = true;
        short = false;
        branch = true;
      };

      commit = {
        verbose = true;
      };

      apply = {
        whitespace = "warn";
      };

      pull = {
        rebase = true;
      };

      merge = {
        log = true;
        ff = false;
        tool = "nvimdiff";
        conflictstyle = "zdiff3";
      };

      mergetool = {
        keepBackup = false;
        prompt = false;
      };
      mergetool."nvimdiff" = {
        layout = "LOCAL,BASE,REMOTE / MERGED";
      };

      diff = {
        tool = "nvimdiff";
        algorithm = "histogram";
        renames = "copies";
      };
      difftool = {
        prompt = false;
        trustExitCode = true;
      };

      alias = {
        uncommit = "reset HEAD~1 --mixed";
        ls-ign = "ls-files -o -i --exclude-standard";
        ign = "ls-files -o -i --exclude-standard";
        tree = "log --graph --decorate --oneline --all";
        tags = "tag --list --sort=-creatordate --format='%(color:yellow)%(refname:short)%(color:reset) \t%(creatordate:short) \t%(contents:subject)'";
        sig = "log --show-signature";
      };

      delta = {
        navigate = true;  # use n and N to move between diff sections
        dark = true;      # or light = true, or omit for auto-detection
        #side-by-side = true;
        #line-numbers = true;
      };

      gpg = {
        program = "gpg";
        };

      column = {
        ui = "never";
      };

      color = {
        ui = "auto";
        status = {
          #header = "blue";
          branch = "green bold";
          localBranch = "green bold";
          remoteBranch = "green bold";
          unmerged = "red bold";

          added = "green bold";
          changed = "yellow bold";
          untracked = "red bold";
        };
      };
    };
  };

  # syntax highlighter for git diff
  # https://github.com/dandavison/delta
  programs.delta = {
    enable = true;
    #options = {
    #  decorations = {
    #    commit-decoration-style = "bold yellow box ul";
    #    file-decoration-style = "none";
    #    file-style = "bold yellow ul";
    #  };
    #  features = "decorations";
    #  whitespace-error-style = "22 reverse";
    #};
  };
}
