{ config, pkgs, ... }: {
  programs.neovim = {
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = /* lua */ ''
          local lspconfig = require('lspconfig')
          lspconfig.nil_ls.setup {}
          lspconfig.rust_analyzer.setup {}
          lspconfig.marksman.setup {}
          lspconfig.gopls.setup {}
          lspconfig.lua_ls.setup {}
          lspconfig.clangd.setup {}
          lspconfig.texlab.setup {}
          lspconfig.crystalline.setup {}
          vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
          vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
          vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
              local opts = { buffer = ev.buf }
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
              vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
              vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
              vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
              vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            end,
          })
        '';
      }
      {
        plugin = nvim-base16;
        type = "lua";
        #config = "vim.cmd('colorscheme base16-${config.lib.stylix.scheme.slug}')";
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = /* lua */ ''
          local theme = require("lualine.themes.base16")
          theme.normal.b.bg = nil
          theme.normal.c.bg = nil
          theme.replace.b.bg = nil
          theme.insert.b.bg = nil
          theme.visual.b.bg = nil
          theme.inactive.a.bg = nil
          theme.inactive.b.bg = nil
          theme.inactive.c.bg = nil

          require('lualine').setup {
            options = {
              theme = theme,
              disabled_filetypes = {'NvimTree'}
            },
            sections = { lualine_c = {'%f'} }
          }
        '';
      }
      #{
      #  plugin = image-nvim;
      #  type = "lua";
      #  config = /* lua */ ''
      #    require("image").setup({
      #      backend = "kitty",
      #      integrations = {
      #        markdown = {
      #          enabled = true,
      #          sizing_strategy = "auto",
      #          download_remote_images = false,
      #          clear_in_insert_mode = true,
      #        },
      #        neorg = {
      #          enabled = false,
      #        },
      #      },
      #      max_width = nil,
      #      max_height = nil,
      #      max_width_window_percentage = nil,
      #      max_height_window_percentage = 50,
      #      kitty_method = "normal",
      #      kitty_tmux_write_delay = 10,
      #      window_overlap_clear_enabled = false,
      #      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      #    })
      #  '';
      #}
      {
        plugin = git-blame-nvim;
        type = "lua";
      }
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''require('Comment').setup()'';
      }
      {
        plugin = vimtex;
        config = /* vim */ ''
          let g:vimtex_mappings_enabled = 0
          let g:vimtex_imaps_enabled = 0
          let g:vimtex_view_method = 'zathura'
          let g:vimtex_compiler_latexmk = {'build_dir': '.tex'}

          nnoremap <localleader>f <plug>(vimtex-view)
          nnoremap <localleader>g <plug>(vimtex-compile)
          nnoremap <localleader>d <plug>(vimtex-env-delete)
          nnoremap <localleader>c <plug>(vimtex-env-change)
        '';
      }
    ];
    extraConfig = /* vim */ ''
      filetype plugin indent on
      set undofile
      set spell
      set number
      set linebreak
      set clipboard=unnamedplus
      set fileencoding=utf-8         " Ensure that we always save files as utf-8
      set fileencodings=utf-8,sjis   " Automatically open shiftjis files with their proper encoding
      set spelllang=en_us,cjk        " Don't show errors for CJK characters
      set noshowmode                 " Disable the --MODE-- text (enable if not using the status line)
      set mouse=a
      set ignorecase                 " By default use case-insensitive search (combine with smartcase)
      set smartcase                  " Make search case-sensitive when using capital letters
      set scrolloff=1                " The minimal number of rows to show when scrolling up/down
      set sidescrolloff=5            " The minimal number of columns to show when scrolling left/right
      set tabstop=4                  " Show a tab character as 4 spaces
      set softtabstop=0              " Edit soft tabs as if they're regular spaces
      set shiftwidth=4               " Make autoindent appear as 4 spaces

      set foldmethod=indent
      set foldlevelstart=99

      map <MiddleMouse> <Nop>
      imap <MiddleMouse> <Nop>
      map <2-MiddleMouse> <Nop>
      imap <2-MiddleMouse> <Nop>
      map <3-MiddleMouse> <Nop>
      imap <3-MiddleMouse> <Nop>
      map <4-MiddleMouse> <Nop>
      imap <4-MiddleMouse> <Nop>

      highlight Search ctermbg=240 ctermfg=255
      highlight IncSearch ctermbg=255 ctermfg=240
    '';
  };
}
