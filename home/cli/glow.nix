{ pkgs, ... }: {
  home.packages = [ pkgs.glow ];
  xdg.configFile."glow/glow.yml".text = ''
      style: "/home/zarred/.config/glow/rose-pine.json"
      local: false
      mouse: false
      pager: true
      # width: 80
      showLineNumbers: false
    '';
  xdg.configFile."glow/rose-pine.json".text = ''
      {
        "document": {
          "block_prefix": "\n",
          "block_suffix": "\n",
          "color": "#e0def4",
          "margin": 2
        },
        "block_quote": {
          "indent": 2,
          "color": "#f6c177",
          "italic": true
        },
        "paragraph": {},
        "list": {
          "level_indent": 2,
          "color": "#e0def4"
        },
        "heading": {
          "block_suffix": "\n",
          "color": "#c4a7e7",
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
          "color": "#f6c177"
        },
        "strong": {
          "bold": true,
          "color": "#ebbcba"
        },
        "hr": {
          "color": "#908caa",
          "format": "\n--------\n"
        },
        "item": {
          "block_prefix": "• "
        },
        "enumeration": {
          "block_prefix": ". ",
          "color": "#9ccfd8"
        },
        "task": {
          "ticked": "[✓] ",
          "unticked": "[ ] "
        },
        "link": {
          "color": "#9ccfd8",
          "underline": true
        },
        "link_text": {
          "color": "#eb6f92"
        },
        "image": {
          "color": "#9ccfd8",
          "underline": true
        },
        "image_text": {
          "color": "#eb6f92",
          "format": "Image: {{.text}} →"
        },
        "code": {
          "color": "#31748f"
        },
        "code_block": {
          "color": "#ebbcba",
          "margin": 2,
          "chroma": {
            "text": {
              "color": "#e0def4"
            },
            "error": {
              "color": "#e0def4",
              "background_color": "#eb6f92"
            },
            "comment": {
              "color": "#6e6a86"
            },
            "comment_preproc": {
              "color": "#eb6f92"
            },
            "keyword": {
              "color": "#eb6f92"
            },
            "keyword_reserved": {
              "color": "#eb6f92"
            },
            "keyword_namespace": {
              "color": "#eb6f92"
            },
            "keyword_type": {
              "color": "#9ccfd8"
            },
            "operator": {
              "color": "#eb6f92"
            },
            "punctuation": {
              "color": "#e0def4"
            },
            "name": {
              "color": "#9ccfd8"
            },
            "name_builtin": {
              "color": "#9ccfd8"
            },
            "name_tag": {
              "color": "#eb6f92"
            },
            "name_attribute": {
              "color": "#31748f"
            },
            "name_class": {
              "color": "#9ccfd8"
            },
            "name_constant": {
              "color": "#c4a7e7"
            },
            "name_decorator": {
              "color": "#31748f"
            },
            "name_exception": {},
            "name_function": {
              "color": "#31748f"
            },
            "name_other": {},
            "literal": {},
            "literal_number": {
              "color": "#f6c177"
            },
            "literal_date": {},
            "literal_string": {
              "color": "#f6c177"
            },
            "literal_string_escape": {
              "color": "#eb6f92"
            },
            "generic_deleted": {
              "color": "#eb6f92"
            },
            "generic_emph": {
              "color": "#f6c177",
              "italic": true
            },
            "generic_inserted": {
              "color": "#31748f"
            },
            "generic_strong": {
              "color": "#ebbcba",
              "bold": true
            },
            "generic_subheading": {
              "color": "#c4a7e7"
            },
            "background": {
              "background_color": "#191724"
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
