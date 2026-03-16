{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name  = "cytopia";
        email = "cytopia@everythingcli.org";
        signingkey = "A02C56F0";
      };
      #signing = {
      #  key = "A02C56F0";
      #  signByDefault = false;
      #};

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

      delta = {
        navigate = true;  # use n and N to move between diff sections
        dark = true;      # or light = true, or omit for auto-detection
        #side-by-side = true;
        #line-numbers = true;
      };


      commit = {
        verbose = true;
      };

      pull = {
        # When pulling do not create a merge commit.
        ff = "only";
      };

      merge = {
        summary = true;

        # No fast forward merge
        # I want to see the merge tree instead
        # of a flat merge
        ff = false;
      };

      alias = {
        uncommit = "reset HEAD~1 --mixed";
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
