{ config, pkgs, ... }:

{
  environment.variables = { EDITOR = "vim"; };

  nixpkgs.overlays = [
    (final: prev: {
      # We define 'vim' by taking the 'prev' (original) vim-full and customizing it.
      # This prevents the recursion because we aren't calling the version we just defined.
      vim = prev.vim-full.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          set nocompatible                " Use vim instead of vi
          set backspace=indent,eol,start  " Allow backspacing over everything in insert mode
          set autoread                    " Automatically reload file contents when changed from outside
          "set signcolumn=yes              " Always show signs column
          set number                      " Always show line numbers
          set errorbells                  " Trigger bell on error
          set visualbell                  " Use visual bell instead of beeping

          " Turn on syntax highlighting by default
          syntax on

          " Statusbar
          hi User1 guifg=#ffdad8  guibg=#880c0e           ctermfg=15 ctermbg=52
          hi User2 guifg=#000000  guibg=#F4905C           ctermfg=16 ctermbg=166
          hi User3 guifg=#292b00  guibg=#f4f597           ctermfg=16 ctermbg=192
          hi User4 guifg=#112605  guibg=#aefe7B           ctermfg=16 ctermbg=84
          hi User5 guifg=#051d00  guibg=#7dcc7d           ctermfg=16 ctermbg=72
          hi User7 guifg=#ffffff  guibg=#880c0e gui=bold  ctermfg=15 ctermbg=52 cterm=bold
          hi User8 guifg=#ffffff  guibg=#5b7fbb           ctermfg=15 ctermbg=25
          hi User9 guifg=#ffffff  guibg=#810085           ctermfg=15 ctermbg=90
          hi User0 guifg=#ffffff  guibg=#094afe           ctermfg=15 ctermbg=16

          set showmode                    " Show INSERT, REPLACE or VISUAL in Statusbar
          set ruler                       " Show line and column number
          set laststatus=2                " Always show status line
          set cmdheight=1

          " Helper function
          function! HighlightSearch()
            if &hls
              return "H"
            else
              return ""
            endif
          endfunction

          " Format status bar
          set statusline=
          set statusline+=%7*\[%n]                                  " buffernr
          set statusline+=%1*\ %<%F\                                " File+path
          set statusline+=%2*\ %y\                                  " FileType
          set statusline+=%3*\ %{'' + "''" + ''.(&fenc!='' + "''" + ''?&fenc:&enc).'' + "''" + ''} " Encoding
          set statusline+=%3*\ %{(&bomb?\",BOM\":\"\")}\            " Encoding2
          set statusline+=%4*\ %{&ff}\                              " FileFormat (dos/unix..)
          set statusline+=%5*\ %{&spelllang}\%{HighlightSearch()}\  " Spellanguage & Highlight on?
          set statusline+=%8*\ %=\ row:%l/%L\ (%03p%%)\             " Rownumber/total (%)
          set statusline+=%9*\ col:%03c\                            " Colnr
          set statusline+=%0*\ \ %m%r%w\ %P\ \                      " Modified? Readonly? Top/bot
      '';
      };
      # Also point vim-full to our custom version to be safe
      vim-full = final.vim;
    })
  ];

  # Now just install the 'vim' from our newly overlaid pkgs
  environment.systemPackages = [ pkgs.vim ];
}
