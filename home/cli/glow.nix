{ pkgs, ... }: {
  home.packages = [ pkgs.glow ];
  # TODO: better theme for glow
  xdg.configFile."glow/glow.yml".text = ''
      # style name or JSON path (default "auto")
      style: "dark"
      # show local files only; no network (TUI-mode only)
      local: false
      # mouse support (TUI-mode only)
      mouse: false
      # use pager to display markdown
      pager: false
      # word-wrap at width
      # width: 80
    '';
  xdg.configFile."glow/dracula.json".text = ''
      {
        "document": {
          "block_prefix": "\n",
          "block_suffix": "\n",
          "color": "#f8f8f2",
          "margin": 2
        },
        "block_quote": {
          "indent": 2,
          "color": "#f1fa8c",
          "italic": true
        },
        "paragraph": {},
        "list": {
          "level_indent": 2,
          "color": "#f8f8f2"
        },
        "heading": {
          "block_suffix": "\n",
          "color": "#bd93f9",
          "bold": true
        },
        "h1": {
          "prefix": "# "
        },
        "h2": {
          "prefix": "## "
        },
        "h3": {
          "prefix": "### "
        },
        "h4": {
          "prefix": "#### "
        },
        "h5": {
          "prefix": "##### "
        },
        "h6": {
          "prefix": "###### "
        },
        "text": {},
        "strikethrough": {
          "crossed_out": true
        },
        "emph": {
          "italic": true,
          "color": "#f1fa8c"
        },
        "strong": {
          "bold": true,
          "color": "#ffb86c"
        },
        "hr": {
          "color": "#6272A4",
          "format": "\n--------\n"
        },
        "item": {
          "block_prefix": "• "
        },
        "enumeration": {
          "block_prefix": ". ",
          "color": "#8be9fd"
        },
        "task": {
          "ticked": "[✓] ",
          "unticked": "[ ] "
        },
        "link": {
          "color": "#8be9fd",
          "underline": true
        },
        "link_text": {
          "color": "#ff79c6"
        },
        "image": {
          "color": "#8be9fd",
          "underline": true
        },
        "image_text": {
          "color": "#ff79c6",
          "format": "Image: {{.text}} →"
        },
        "code": {
          "color": "#50fa7b"
        },
        "code_block": {
          "color": "#ffb86c",
          "margin": 2,
          "chroma": {
            "text": {
              "color": "#f8f8f2"
            },
            "error": {
              "color": "#f8f8f2",
              "background_color": "#ff5555"
            },
            "comment": {
              "color": "#6272A4"
            },
            "comment_preproc": {
              "color": "#ff79c6"
            },
            "keyword": {
              "color": "#ff79c6"
            },
            "keyword_reserved": {
              "color": "#ff79c6"
            },
            "keyword_namespace": {
              "color": "#ff79c6"
            },
            "keyword_type": {
              "color": "#8be9fd"
            },
            "operator": {
              "color": "#ff79c6"
            },
            "punctuation": {
              "color": "#f8f8f2"
            },
            "name": {
              "color": "#8be9fd"
            },
            "name_builtin": {
              "color": "#8be9fd"
            },
            "name_tag": {
              "color": "#ff79c6"
            },
            "name_attribute": {
              "color": "#50fa7b"
            },
            "name_class": {
              "color": "#8be9fd"
            },
            "name_constant": {
              "color": "#bd93f9"
            },
            "name_decorator": {
              "color": "#50fa7b"
            },
            "name_exception": {},
            "name_function": {
              "color": "#50fa7b"
            },
            "name_other": {},
            "literal": {},
            "literal_number": {
              "color": "#6EEFC0"
            },
            "literal_date": {},
            "literal_string": {
              "color": "#f1fa8c"
            },
            "literal_string_escape": {
              "color": "#ff79c6"
            },
            "generic_deleted": {
              "color": "#ff5555"
            },
            "generic_emph": {
              "color": "#f1fa8c",
              "italic": true
            },
            "generic_inserted": {
              "color": "#50fa7b"
            },
            "generic_strong": {
              "color": "#ffb86c",
              "bold": true
            },
            "generic_subheading": {
              "color": "#bd93f9"
            },
            "background": {
              "background_color": "#282a36"
            }
          }
        },
        "table": {
          "center_separator": "┼",
          "column_separator": "│",
          "row_separator": "─"
        },
        "definition_list": {},
        "definition_term": {},
        "definition_description": {
          "block_prefix": "\n🠶 "
        },
        "html_block": {},
        "html_span": {}
      }
  '';
  xdg.configFile."glow/email.json".text = ''
      {
        "document": {
          "block_prefix": "\n",
          "block_suffix": "\n",
          "color": "7",
          "margin": 2
        },
        "block_quote": {
          "indent": 0,
          "color": "3",
          "indent_token": "│ ",
          "italic": true,
          "margin": 1
        },
        "paragraph": {},
        "list": {
          "level_indent": 2,
          "color": "7"
        },
        "heading": {
          "block_suffix": "\n",
          "color": "4",
          "bold": true
        },
        "h1": {
          "prefix": " ",
          "suffix": " ",
          "color": "7",
          "background_color": "4",
          "bold": true
        },
        "h2": {
          "prefix": "## "
        },
        "h3": {
          "prefix": "### "
        },
        "h4": {
          "prefix": "#### "
        },
        "h5": {
          "prefix": "##### "
        },
        "h6": {
          "prefix": "###### ",
          "color": "5",
          "bold": false
        },
        "text": {},
        "strikethrough": {
          "crossed_out": true
        },
        "emph": {
          "italic": true,
          "color": "3"
        },
        "strong": {
          "bold": true,
          "color": "3"
        },
        "hr": {
          "color": "0",
          "format": "\n―――――――――――――――――――\n"
        },
        "item": {
          "block_prefix": "• "
        },
        "enumeration": {
          "block_prefix": ". ",
          "color": "6"
        },
        "task": {
          "ticked": "[✓] ",
          "unticked": "[ ] "
        },
        "link": {
          "color": "6",
          "underline": true
        },
        "link_text": {
          "color": "5",
          "bold": true
        },
        "image": {
          "color": "6",
          "underline": true
        },
        "image_text": {
          "color": "5",
          "format": "Image: {{.text}} →"
        },
        "code": {
          "color": "7",
          "prefix": " ",
          "suffix": " ",
          "background_color": "#44475a"
        },
        "code_block": {
          "color": "3",
          "margin": 2,
          "chroma": {
            "text": {
              "color": "#ansilightgray"
            },
            "error": {
              "color": "#ansilightgray",
              "background_color": "#ansidarkred"
            },
            "comment": {
              "color": "#ansidarkgray"
            },
            "comment_preproc": {
              "color": "#ansipurple"
            },
            "keyword": {
              "color": "#ansipurple"
            },
            "keyword_reserved": {
              "color": "#ansipurple"
            },
            "keyword_namespace": {
              "color": "#ansipurple"
            },
            "keyword_type": {
              "color": "#ansiteal"
            },
            "operator": {
              "color": "#ansipurple"
            },
            "punctuation": {
              "color": "#ansilightgray"
            },
            "name": {
              "color": "#ansiteal"
            },
            "name_builtin": {
              "color": "#ansiteal"
            },
            "name_tag": {
              "color": "#ansipurple"
            },
            "name_attribute": {
              "color": "#ansidarkgreen"
            },
            "name_class": {
              "color": "#ansiteal"
            },
            "name_constant": {
              "color": "#ansidarkblue"
            },
            "name_decorator": {
              "color": "#ansidarkgreen"
            },
            "name_exception": {},
            "name_function": {
              "color": "#ansidarkgreen"
            },
            "name_other": {},
            "literal": {},
            "literal_number": {
              "color": "#ansiturquoise"
            },
            "literal_date": {},
            "literal_string": {
              "color": "#ansibrown"
            },
            "literal_string_escape": {
              "color": "#ansipurple"
            },
            "generic_deleted": {
              "color": "#ansidarkred"
            },
            "generic_emph": {
              "color": "#ansibrown",
              "italic": true
            },
            "generic_inserted": {
              "color": "#ansidarkgreen"
            },
            "generic_strong": {
              "color": "#ansiyellow",
              "bold": true
            },
            "generic_subheading": {
              "color": "#ansidarkblue"
            },
            "background": {
              "background_color": "#44475"
            }
          }
        },
        "table": {
          "center_separator": "┼",
          "column_separator": "│",
          "row_separator": "─"
        },
        "definition_list": {},
        "definition_term": {},
        "definition_description": {
          "block_prefix": "\n🠶 "
        },
        "html_block": {},
        "html_span": {}
      }
  '';
}
