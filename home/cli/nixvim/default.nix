{ config, pkgs, inputs, ... }: {
imports = [
  inputs.nixvim.homeModules.nixvim
  ./conform.nix
];
  stylix.targets.nixvim.enable = false;
  programs.nixvim = {
    nixpkgs.config.allowUnfree = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      imagemagick
    ];
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
      { mode = "n"; key = "<leader>pi"; action = "<cmd>PasteImage<CR>"; options.desc = "Paste image from clipboard"; }
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
    extraConfigLua = ''
      local function set_render_markdown_rose_pine_hl()
        local set = vim.api.nvim_set_hl

        -- Rose Pine palette.
        local base = '#191724'
        local surface = '#1f1d2e'
        local overlay = '#26233a'
        local muted = '#6e6a86'
        local text = '#e0def4'
        local love = '#eb6f92'
        local rose = '#ebbcba'
        local pine = '#31748f'
        local foam = '#9ccfd8'
        local iris = '#c4a7e7'
        local h1_bg = '#171521'
        local h2_bg = surface
        local h3_bg = overlay
        local h4_bg = overlay
        local h5_bg = surface
        local h6_bg = base

        set(0, 'RenderMarkdownCode', { bg = surface })
        set(0, 'RenderMarkdownCodeInfo', { fg = muted, bg = surface })
        set(0, 'RenderMarkdownCodeBorder', { fg = overlay, bg = surface })
        set(0, 'RenderMarkdownCodeInline', { fg = rose, bg = surface })
        set(0, 'RenderMarkdownInlineHighlight', { bg = overlay })

        set(0, 'RenderMarkdownH1', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH2', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH3', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH4', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH5', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH6', { fg = rose, bold = true })
        set(0, 'RenderMarkdownH1Bg', { fg = rose, bg = h1_bg, bold = true })
        set(0, 'RenderMarkdownH2Bg', { fg = rose, bg = h2_bg, bold = true })
        set(0, 'RenderMarkdownH3Bg', { fg = rose, bg = h3_bg, bold = true })
        set(0, 'RenderMarkdownH4Bg', { fg = rose, bg = h4_bg, bold = true })
        set(0, 'RenderMarkdownH5Bg', { fg = rose, bg = h5_bg, bold = true })
        set(0, 'RenderMarkdownH6Bg', { fg = rose, bg = h6_bg, bold = true })

        set(0, '@markup.heading.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.1.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.2.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.3.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.4.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.5.markdown', { fg = rose, bold = true })
        set(0, '@markup.heading.6.markdown', { fg = rose, bold = true })

        set(0, 'RenderMarkdownBullet', { fg = iris })
        set(0, 'RenderMarkdownDash', { fg = muted })
        set(0, 'RenderMarkdownQuote', { fg = muted, italic = true })
        set(0, 'RenderMarkdownIndent', { fg = overlay })
        set(0, 'RenderMarkdownLink', { fg = foam })
        set(0, 'RenderMarkdownLinkTitle', { fg = iris, underline = true })
        set(0, 'RenderMarkdownWikiLink', { fg = iris })
        set(0, 'RenderMarkdownUnchecked', { fg = muted })
        set(0, 'RenderMarkdownChecked', { fg = foam })
        set(0, 'RenderMarkdownTodo', { fg = rose })
        set(0, 'RenderMarkdownTableHead', { fg = text, bg = overlay, bold = true })
        set(0, 'RenderMarkdownTableRow', { fg = text })
        set(0, 'RenderMarkdownSign', { bg = base })
        set(0, 'RenderMarkdownSuccess', { fg = foam })
        set(0, 'RenderMarkdownInfo', { fg = pine })
        set(0, 'RenderMarkdownHint', { fg = iris })
        set(0, 'RenderMarkdownWarn', { fg = love })
        set(0, 'RenderMarkdownError', { fg = love })

        -- Make YAML/frontmatter values stand out from keys.
        set(0, '@property.yaml', { fg = iris })
        set(0, '@field.yaml', { fg = iris })
        set(0, '@string.yaml', { fg = foam })
        set(0, '@number.yaml', { fg = foam })
        set(0, '@boolean.yaml', { fg = rose })
        set(0, '@constant.yaml', { fg = rose })

        -- URLs should be visually distinct from normal links and wiki links.
        set(0, 'MarkdownUrl', { fg = love, underline = true, italic = true })
        set(0, '@markup.link.url.markdown_inline', { fg = love, underline = true, italic = true })
        set(0, '@markup.link.url.markdown', { fg = love, underline = true, italic = true })
        set(0, '@string.special.url', { fg = love, underline = true, italic = true })
      end

      set_render_markdown_rose_pine_hl()
      vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter', 'FileType' }, {
        pattern = '*',
        callback = set_render_markdown_rose_pine_hl,
      })

      vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter', 'ColorScheme' }, {
        pattern = { 'markdown', '*' },
        callback = function()
          set_render_markdown_rose_pine_hl()
          if vim.bo.filetype == 'markdown' then
            if vim.w.markdown_url_match then
              pcall(vim.fn.matchdelete, vim.w.markdown_url_match)
            end
            vim.w.markdown_url_match = vim.fn.matchadd('MarkdownUrl', [[https\?://\S\+]], 200)
          end
        end,
      })

      if #vim.api.nvim_list_uis() > 0 then
        local image_ok, image = pcall(require, 'image')
        if image_ok then
          image.setup({
            backend = 'kitty',
            processor = 'magick_cli',
            kitty_direct_chunk_size = 4096,
            integrations = {
              markdown = { enabled = true },
              typst = { enabled = true },
              neorg = { enabled = true },
              syslang = { enabled = true },
              html = { enabled = false },
              css = { enabled = false },
            },
            max_width_window_percentage = 90,
            max_height_window_percentage = 50,
            window_overlap_clear_enabled = false,
            tmux_show_only_in_active_window = false,
          })

          local term_ok, image_term = pcall(require, 'image/utils/term')
          if term_ok and vim.env.TMUX then
            local original_get_size = image_term.get_size
            image_term.get_size = function()
              if vim.fn.executable('tmux') == 1 then
                local out = vim.fn.systemlist({
                  'tmux',
                  'display-message',
                  '-p',
                  '#{pane_width} #{pane_height} #{client_cell_width} #{client_cell_height}',
                })
                if vim.v.shell_error == 0 and out[1] then
                  local cols, rows, cell_width, cell_height = out[1]:match('^(%d+)%s+(%d+)%s+(%d+)%s+(%d+)')
                  cols = tonumber(cols)
                  rows = tonumber(rows)
                  cell_width = tonumber(cell_width)
                  cell_height = tonumber(cell_height)
                  if cols and rows and cell_width and cell_height and cell_width > 0 and cell_height > 0 then
                    return {
                      screen_x = cols * cell_width,
                      screen_y = rows * cell_height,
                      screen_cols = cols,
                      screen_rows = rows,
                      cell_width = cell_width,
                      cell_height = cell_height,
                    }
                  end
                end
              end

              return original_get_size()
            end
          end

          local function render_obsidian_image_embeds()
          if vim.bo.filetype ~= 'markdown' then
            return
          end

          local bufnr = vim.api.nvim_get_current_buf()
          local win = vim.api.nvim_get_current_win()
          local doc = vim.api.nvim_buf_get_name(bufnr)
          if doc == "" then
            return
          end

          for _, img in ipairs(image.get_images({ window = win, buffer = bufnr, namespace = 'obsidian-wikilink' })) do
            img:clear()
          end

          local doc_dir = vim.fn.fnamemodify(doc, ':h')
          for row, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
            local start = 1
            while true do
              local s, e, target = line:find('!%[%[(.-)%]%]', start)
              if not s then
                break
              end

              target = target:gsub('|.*$', "")
              local lower_target = target:lower()
              if lower_target:match('%.png$') or lower_target:match('%.jpg$') or lower_target:match('%.jpeg$') or lower_target:match('%.gif$') or lower_target:match('%.webp$') or lower_target:match('%.avif$') then
                local path = target
                if not path:match('^/') and not path:match('^~') then
                  path = vim.fn.fnamemodify(doc_dir .. '/' .. path, ':p')
                end

                local img = image.from_file(path, {
                  id = ('obsidian-wikilink:%d:%s'):format(row, path),
                  window = win,
                  buffer = bufnr,
                  with_virtual_padding = true,
                  namespace = 'obsidian-wikilink',
                })
                if img then
                  img:render({ x = s - 1, y = row - 1 })
                end
              end

              start = e + 1
            end
          end
        end

          vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'FileType', 'TextChanged', 'TextChangedI', 'WinScrolled' }, {
            pattern = { '*.md', 'markdown' },
            callback = function()
              vim.schedule(render_obsidian_image_embeds)
            end,
          })

          local redraw_timer = nil
          local function redraw_images_after_layout_change()
            if redraw_timer then
              redraw_timer:stop()
              redraw_timer:close()
            end
            redraw_timer = vim.loop.new_timer()
            redraw_timer:start(100, 0, vim.schedule_wrap(function()
              pcall(vim.cmd, 'redraw!')

              local function rerender_visible_images()
                for _, img in ipairs(image.get_images({})) do
                  pcall(function()
                    img:render()
                  end)
                end
                render_obsidian_image_embeds()
                pcall(vim.cmd, 'redraw!')
              end

              vim.defer_fn(rerender_visible_images, 50)
              vim.defer_fn(rerender_visible_images, 500)
            end))
          end

          vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized', 'WinEnter', 'BufEnter' }, {
            callback = redraw_images_after_layout_change,
          })

          vim.schedule(render_obsidian_image_embeds)
        end
      end

      local img_clip_ok, img_clip = pcall(require, 'img-clip')
      if img_clip_ok then
        img_clip.setup({
          default = {
            dir_path = 'attachments',
            file_name = '%Y-%m-%d-%H-%M-%S',
            use_absolute_path = false,
            relative_to_current_file = false,
          },
          filetypes = {
            markdown = {
              template = '![$CURSOR]($FILE_PATH)',
              url_encode_path = true,
              download_images = true,
            },
          },
        })
      end
    '';
    autoGroups = {
      kickstart-highlight-yank = {
        clear = true;
      };
      kickstart-lsp-attach = {
        clear = true;
      };
      tmux-window-title = {
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
      {
        event = ["BufEnter"];
        desc = "Set tmux window name to the active Neovim buffer filename";
        group = "tmux-window-title";
        callback.__raw = ''
          function()
            if vim.env.TMUX == nil then
              return
            end

            local name = vim.fn.expand("%:t")
            if name == nil or name == "" then
              name = vim.bo.filetype
            end
            if name == nil or name == "" then
              name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end

            vim.fn.system({ "tmux", "rename-window", name })
          end
        '';
      }
      {
        event = ["VimLeavePre"];
        desc = "Hand tmux window naming back to tmux-window-name";
        group = "tmux-window-title";
        callback.__raw = ''
          function()
            if vim.env.TMUX == nil then
              return
            end

            vim.fn.system({ "tmux", "rename-window", "" })
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
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
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
          legacy_commands = false;
          new_notes_location = "current_dir";
          picker.name = "telescope.nvim";
          search = {
            sort_by = "modified";
            sort_reversed = true;
          };
          templates.folder = "templates";
          daily_notes = {
            folder = "daily";
            date_format = "%Y-%m-%d";
          };
          attachments.folder = "attachments";
          ui = {
            enable = false;
          };
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
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "image.nvim";
        version = "2026-06-13";
        src = pkgs.fetchFromGitHub {
          owner = "3rd";
          repo = "image.nvim";
          rev = "88351f1f7d9dbae286e671ce3690a49660dd8a5c";
          sha256 = "0dy0nw7gvw408v2smw29jsbbs3r7lziinsvj96i7cf7k4lrj49lz";
        };
        nvimSkipModules = [ "minimal-setup" ];
      })
      config.programs.nixvim.plugins.img-clip.package
      (pkgs.vimUtils.buildVimPlugin {
        name = "render-markdown.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "MeanderingProgrammer";
          repo = "render-markdown.nvim";
          rev = "76b6602a88f9c4f31e73fab4c94d0a168055e990";
          hash = "sha256-ukJUaqEYI60o/lyLM5GaKsRdMW/24IZnzVzPB9/Q/zo=";
        };
      })
    ];
  };
}

