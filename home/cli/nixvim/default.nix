{ pkgs, inputs, ... }: {
imports = [
  inputs.nixvim.homeModules.nixvim
  ./conform.nix
];
  stylix.targets.nixvim.enable = false;
  programs.nixvim = {
    nixpkgs.config.allowUnfree = true;
    defaultEditor = true;
    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };
    clipboard.providers.wl-copy.enable = true;
    opts = {
      undofile = true;
      spell = true;
      number = true;
      relativenumber = true;
      cursorline = false;
      linebreak = true;
      breakindent = true;
      fileencoding = "utf-8";
      fileencodings = "utf-8,sjis";
      spelllang = "en_us,cjk";
      showmode = false;  # already in status line
      mouse = "a";
      ignorecase = true;
      smartcase = true; # Case-insensitive searching UNLESS \C or one or more capital letters in search term
      sidescrolloff = 5;
      scrolloff = 10;
      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      foldmethod = "indent";
      wrap = false;
      foldlevelstart = 99;
      completeopt = ["menu" "menuone" "noselect"];

      swapfile = false;
      backup = false;

      hlsearch = false;
      incsearch = true;
      inccommand = "split";

      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 2000;

      splitright = true;
      splitbelow = true;

      list = true;
      listchars.__raw = "{ tab = '» ', trail = '·', nbsp = '␣' }"; # NOTE: .__raw here means that this field is raw lua code

      termguicolors = true;
      background = "dark";
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
    colorschemes = {
      poimandres = {
        enable = false;
        settings = {
          bold_vert_split = false;
          dim_nc_background = true;
          disable_background = true;
          disable_float_background = false;
        };
      };
      rose-pine = {
        enable = true;
        settings.dim_inactive_windows = false;
      };
      catppuccin = {
        settings = {
          flavour = "mocha";
          transparent_background = true;
        };
      };
    };
    autoGroups = {
      kickstart-highlight-yank = {
        clear = true;
      };
      kickstart-lsp-attach = {
        clear = true;
      };
    };
    autoCmd = [
      # Highlight when yanking (copying) text
      #  Try it with `yap` in normal mode
      #  See `:help vim.highlight.on_yank()`
      {
        event = ["TextYankPost"];
        desc = "Highlight when yanking (copying) text";
        group = "kickstart-highlight-yank";
        callback.__raw = ''
          function()
            vim.highlight.on_yank()
          end
        '';
      }
    ];
    plugins = {
      #web-devicons.enable = true;
      lspkind.enable = true;
      lualine = {
        enable = true;
        settings = {
          extensions = [ "fzf" "fugitive" ];
          #theme = "palenight";
        };
      };
      # TODO: another option is codecompanion https://github.com/olimorris/codecompanion.nvim
      avante = {
        enable = true;
        settings = {
          provider = "claude";
          providers = {
            claude = {
              endpoint = "https://api.anthropic.com";
              model = "claude-sonnet-4-20250514";
              timeout = 30000;
              extra_request_body = {
                temperature = 0.75;
                max_tokens = 20480;
              };
            };
          };
        };
      };
      copilot-vim = {
        enable = true;
        settings = {
          filetypes = {
            "*" = false;
            python = true;
          };
        };
      };
      cmp-treesitter.enable = true;
      # TODO: invgestigate blink.cmp, newer and simpler completion system
      cmp = {
        enable = true;
        settings = {
          sources = [
            # TODO:. Does CoPilot need to be added?
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; option.get_bufnrs.__raw = "vim.api.nvim_list_bufs"; }
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
            "<C-y>" = "cmp.mapping.confirm({ select = true })";
            "<S-Up>" = "cmp.mapping.scroll_docs(4)";
            "<S-Down>" = "cmp.mapping.scroll_docs(-4)";
            "<Esc>" = "cmp.mapping.close()";
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-Space>" = "cmp.mapping.complete({})";
          };
        };
      };
      cmp-nvim-lsp.enable = true;
      fidget.enable = true;
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          lua_ls.enable = true;
          texlab.enable = true;
          bashls.enable = true;
          # python
          pyright.enable = true;
          ruff.enable = true;
        };
        keymaps = {
          # Diagnostic keymaps
          diagnostic = {
            "<leader>q" = {
              #mode = "n";
              action = "setloclist";
              desc = "Open diagnostic [Q]uickfix list";
            };
          };
          extra = [
            # Jump to the definition of the word under your cusor.
            #  This is where a variable was first declared, or where a function is defined, etc.
            #  To jump back, press <C-t>.
            {
              mode = "n";
              key = "gd";
              action.__raw = "require('telescope.builtin').lsp_definitions";
              options = {
                desc = "LSP: [G]oto [D]efinition";
              };
            }
            # Find references for the word under your cursor.
            {
              mode = "n";
              key = "gr";
              action.__raw = "require('telescope.builtin').lsp_references";
              options = {
                desc = "LSP: [G]oto [R]eferences";
              };
            }
            # Jump to the implementation of the word under your cursor.
            #  Useful when your language has ways of declaring types without an actual implementation.
            {
              mode = "n";
              key = "gI";
              action.__raw = "require('telescope.builtin').lsp_implementations";
              options = {
                desc = "LSP: [G]oto [I]mplementation";
              };
            }
            # Jump to the type of the word under your cursor.
            #  Useful when you're not sure what type a variable is and you want to see
            #  the definition of its *type*, not where it was *defined*.
            {
              mode = "n";
              key = "<leader>D";
              action.__raw = "require('telescope.builtin').lsp_type_definitions";
              options = {
                desc = "LSP: Type [D]efinition";
              };
            }
            # Fuzzy find all the symbols in your current document.
            #  Symbols are things like variables, functions, types, etc.
            {
              mode = "n";
              key = "<leader>ds";
              action.__raw = "require('telescope.builtin').lsp_document_symbols";
              options = {
                desc = "LSP: [D]ocument [S]ymbols";
              };
            }
            # Fuzzy find all the symbols in your current workspace.
            #  Similar to document symbols, except searches over your entire project.
            {
              mode = "n";
              key = "<leader>ws";
              action.__raw = "require('telescope.builtin').lsp_dynamic_workspace_symbols";
              options = {
                desc = "LSP: [W]orkspace [S]ymbols";
              };
            }
            {
              mode = "n";
              key = "K";
              action.__raw = "vim.lsp.buf.hover";
              options = {
                desc = "Hover Documentation";
              };
            }
          ];
          lspBuf = {
            # Rename the variable under your cursor.
            #  Most Language Servers support renaming across files, etc.
            "<leader>rn" = {
              action = "rename";
              desc = "LSP: [R]e[n]ame";
            };
            # Execute a code action, usually your cursor needs to be on top of an error
            # or a suggestion from your LSP for this to activate.
            "<leader>ca" = {
              #mode = "n";
              action = "code_action";
              desc = "LSP: [C]ode [A]ction";
            };
            # WARN: This is not Goto Definition, this is Goto Declaration.
            #  For example, in C this would take you to the header.
            "gD" = {
              action = "declaration";
              desc = "LSP: [G]oto [D]eclaration";
            };
          };
        };
        onAttach = ''
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- The following two autocommands are used to highlight references of the
          -- word under the cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        '';
      };
      luasnip.enable = true; # TODO Setup luasnip https://piped.video/watch?v=FmHhonPjvvA
      #cmp_luasnip.enable = true;
      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight = {
            enable = true;
            # Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
            additional_vim_regex_highlighting = true;
          };
        };
        folding.enable = true;
        nixGrammars = true;
        #grammarPackages = [
        #  # Default: config.plugins.treesitter.package.passthru.allGrammars
        #  pkgs.vimPlugins.nvim-treesitter-parsers.python
        #];
      };
      telescope = {
        enable = true;
        settings = {
          extensions.__raw = "{ ['ui-select'] = { require('telescope.themes').get_dropdown() } }";
        };
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
        keymaps = {
          "<C-p>" = {
            action = "git_files";
            options.desc = "Telescope Git Files";
          };
          "<leader>fg" = "live_grep";
          "<leader>ff" = "find_files";
          "<leader>sh" = {
            mode = "n";
            action = "help_tags";
            options = {
              desc = "[S]earch [H]elp";
            };
          };
          "<leader>sk" = {
            mode = "n";
            action = "keymaps";
            options = {
              desc = "[S]earch [K]eymaps";
            };
          };
          "<leader>sf" = {
            mode = "n";
            action = "find_files";
            options = {
              desc = "[S]earch [F]iles";
            };
          };
          "<leader>ss" = {
            mode = "n";
            action = "builtin";
            options = {
              desc = "[S]earch [S]elect Telescope";
            };
          };
          "<leader>sw" = {
            mode = "n";
            action = "grep_string";
            options = {
              desc = "[S]earch current [W]ord";
            };
          };
          "<leader>sg" = {
            mode = "n";
            action = "live_grep";
            options = {
              desc = "[S]earch by [G]rep";
            };
          };
          "<leader>sd" = {
            mode = "n";
            action = "diagnostics";
            options = {
              desc = "[S]earch [D]iagnostics";
            };
          };
          "<leader>sr" = {
            mode = "n";
            action = "resume";
            options = {
              desc = "[S]earch [R]esume";
            };
          };
          "<leader>s" = {
            mode = "n";
            action = "oldfiles";
            options = {
              desc = "[S]earch Recent Files ('.' for repeat)";
            };
          };
          "<leader><leader>" = {
            mode = "n";
            action = "buffers";
            options = {
              desc = "[ ] Find existing buffers";
            };
          };
        };
      };
      undotree = {
        enable = true;
        settings = {
          focusOnToggle = true;
          diffCommand = null; # TODO
        };
      };
      fugitive.enable = true;
      todo-comments = {
        enable = true;
        settings = {
          signs = true;
        };
      };
      obsidian = {
        enable = true;
        settings = {
          completion = {
            min_chars = 2;
            nvim_cmp = true;
          };
          new_notes_location = "current_dir";
          workspaces = [
            {
              name = "home";
              path = "~/notes/home";
            }
          ];
        };
      };
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
      web-devicons.enable = true;
      mini.enable = true;
    };
    extraPlugins = [(pkgs.vimUtils.buildVimPlugin {
      name = "render-markdown.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "MeanderingProgrammer";
        repo = "render-markdown.nvim";
        rev = "07d088bf8bdadd159eb807b90eaee86a4778383f"; # NOTE: UPDATE
        hash = "sha256-A7pm8sBQWsZl3Kc7JBh3gBUyKb6GfJ5J0zfn3mSGjKs="; # NOTE: UPDATE
      };
    })];
  };
}

