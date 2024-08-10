{ config, pkgs, inputs, ... }: {
imports = [
  inputs.nixvim.homeManagerModules.nixvim
];
  programs.nixvim = {
    globals.mapleader = " ";
    clipboard.providers.wl-copy.enable = true;
    opts = {
      undofile = true;
      spell = true;
      number = true;
      relativenumber = true;
      linebreak = true;
      fileencoding = "utf-8";
      fileencodings = "utf-8,sjis";
      spelllang = "en_us,cjk";
      showmode = false;
      mouse = "a";
      ignorecase = true;
      smartcase = true;
      sidescrolloff = 5;
      scrolloff = 6;
      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      foldmethod = "indent";
      wrap = false;
      foldlevelstart = 99;

      swapfile = false;
      backup = false;

      hlsearch = false;
      incsearch = true;
    };
    keymaps = [
      { key = "<leader>u"; action = "<cmd>UndotreeToggle<CR>"; }
      { key = "<leader>gs"; action = "<cmd>Git<CR>"; }
      # keep search in middle
      { key = "n"; action = "nzzzv"; }
      { key = "N"; action = "Nzzzv"; }
      # yank to global clipboard
      { key = "<leader>y"; action = "\"+y"; }
      { key = "<leader>Y"; action = "\"+Y"; }
      { mode = "v"; key = "<S-Up>"; action = ":m '<-2<CR>gv=gv"; }
      { mode = "v"; key = "<S-Down>"; action = ":m '>+1<CR>gv=gv"; }
      { mode = "v"; key = "<leader>p"; action = "\"_dP"; } # paste over selection and keep clipboard
      { mode = "v"; key = "<leader>y"; action = "\"+y"; }
    ];
    colorschemes.catppuccin = {
      enable = false;
      settings.transparent_background = true;
    };
    plugins = {
      lualine = {
        enable = true;
        extensions = [ "fzf" "fugitive" ];
        #theme = "palenight";
      };
      cmp = {
        enable = false;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            {
              name = "buffer";
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
            { name = "cmdline"; }
            { name = "cmdline_history"; }
            { name = "cmp-latex-symbols"; }
            #{ name = "rg"; }
            { name = "tmux"; }
            { name = "treesitter"; }
          ];
          snippet.expand = "luasnip";
          completion.keywordLength = 2;
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-Up>" = "cmp.mapping.scroll_docs(4)";
            "<S-Down>" = "cmp.mapping.scroll_docs(-4)";
            "<Esc>" = "cmp.mapping.close()";
            "<S-Tab>" = ''
                function(fallback)
                  local luasnip = require('luasnip')
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                  else
                    fallback()
                  end
                end
            '';
            "<Tab>" = ''
                function(fallback)
                  local luasnip = require('luasnip')
                  local has_words_before = function()
                    unpack = unpack or table.unpack
                    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
                  end
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif luasnip.expandable() then
                    luasnip.expand()
                  elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                  elseif has_words_before() then
                    fallback()
                  else
                    fallback()
                  end
                end
            '';
          };
        };
      };
      lsp = {
        enable = false; #TODO
        servers = {
          nil_ls.enable = true;
          pyright.enable = true;
          texlab.enable = true;
          bashls.enable = true;
          ruff-lsp.enable = true;
        };
      };
      luasnip.enable = false; #TODO
      #cmp_luasnip.enable = true;
      treesitter = {
        enable = false; #TODO
        indent = true;
        nixGrammars = false;
        grammarPackages = [
          #TODO complete list
          pkgs.vimPlugins.nvim-treesitter-parsers.python
        ];
      };
      telescope = {
        enable = true;
        keymaps = {
          "<C-p>" = {
            action = "git_files";
            options.desc = "Telescope Git Files";
          };
          "<leader>fg" = "live_grep";
          "<leader>ff" = "find_files";
        };
      };
      undotree = {
        enable = true;
        settings = {
          focusOnToggle = true;
          diffCommand = null; #TODO
        };
      };
      fugitive.enable = true;
      vimtex = {
        enable = true;
        settings = {
          compiler_enabled = true;
          view_method = "zathura";
        };
        #installTexLive = true;
        #texLivePackage = nixpkgs.texlive.combined.scheme-basic;
        #viewMethod = "zathura";
      };
    };
  };
}

