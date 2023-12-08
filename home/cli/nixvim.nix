{ config, pkgs, inputs, ... }: {
imports = [
  inputs.nixvim.homeManagerModules.nixvim
];
  programs.nixvim = {
    globals.mapleader = " ";
    clipboard.providers.wl-copy.enable = true;
    options = {
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
    maps = {
      normal."<leader>u".action = "<cmd>UndotreeToggle<CR>";
      normal."<leader>gs".action = "<cmd>Git<CR>";
      # keep search in middle
      normal."n".action = "nzzzv";
      normal."N".action = "Nzzzv";
      visual."<S-Up>".action = ":m '<-2<CR>gv=gv";
      visual."<S-Down>".action = ":m '>+1<CR>gv=gv";
      visual."<leader>p".action = "\"_dP"; # paste over selection and keep clipboard
      # yank to global clipboard
      normal."<leader>y".action = "\"+y";
      visual."<leader>y".action = "\"+y";
      normal."<leader>Y".action = "\"+Y";
    };
    colorschemes.catppuccin = {
      enable = true;
      transparentBackground = true;
    };
    plugins = {
      lualine = {
        enable = true;
        extensions = [ "fzf" "fugitive" ];
        theme = "palenight";
      };
      nvim-cmp = {
        enable = true;
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "cmdline"; }
          { name = "cmdline_history"; }
          { name = "cmp-latex-symbols"; }
          #{ name = "rg"; }
          { name = "tmux"; }
          { name = "treesitter"; }
        ];
        mapping = {
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = {
            action = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expandable() then
                  luasnip.expand()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                elseif check_backspace() then
                  fallback()
                else
                  fallback()
                end
              end
            '';
            modes = [ "i" "s" ];
          };
        };
      };
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          pyright.enable = true;
          texlab.enable = true;
          bashls.enable = true;
          ruff-lsp.enable = true;
        };
      };
      luasnip.enable = true;
      cmp_luasnip.enable = true;
      treesitter = {
        enable = true;
        indent = true;
      };
      telescope = {
        enable = true;
        keymaps = {
          "<C-p>" = {
            action = "git_files";
            desc = "Telescope Git Files";
          };
          "<leader>fg" = "live_grep";
          "<leader>ff" = "find_files";
        };
      };
      undotree = {
        enable = true;
        focusOnToggle = true;
        diffCommand = null; #TODO
      };
      fugitive.enable = true;
      vimtex = {
        enable = true;
        extraConfig = {
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

