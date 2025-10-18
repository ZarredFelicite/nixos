{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

let
  mcp-servers-nix = inputs.mcp-servers-nix;

  playwright-mcp-fixed = mcp-servers-nix.packages.${pkgs.system}.playwright-mcp.overrideAttrs (old: {
    doInstallCheck = false;
  });

  # Claude Desktop configuration
  claudeConfig = mcp-servers-nix.lib.mkConfig pkgs {
    format = "json";
    fileName = "claude_desktop_config.json";

    programs = {
      filesystem = {
        enable = true;
        args = [
          "/home/zarred/dev"
          "/home/zarred/notes"
          "/home/zarred/dots"
          "/home/zarred/scripts"
        ];
      };

      fetch.enable = true;

      git = {
        enable = true;
      };

      memory = {
        enable = true;
      };

      time.enable = true;

      playwright = {
        enable = true;
        package = playwright-mcp-fixed;
      };
    };

    settings.servers = {
      mcp-obsidian = {
        command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
        args = [
          "-y"
          "mcp-obsidian"
          "/home/zarred/notes"
        ];
      };
    };
  };

  # OpenCode/VSCode configuration
  opencodeConfig = mcp-servers-nix.lib.mkConfig pkgs-unstable {
    format = "json";
    flavor = "vscode";
    fileName = "opencode_mcp_config.json";

    programs = {
      filesystem = {
        enable = true;
        args = [
          "/home/zarred/dev"
          "/home/zarred/notes"
          "/home/zarred/dots"
          "/home/zarred/scripts"
        ];
      };

      fetch.enable = true;

      git = {
        enable = true;
      };

      memory = {
        enable = true;
      };

      time.enable = true;

      playwright = {
        enable = true;
        package = playwright-mcp-fixed;
      };
    };

    settings.servers = {
      mcp-obsidian = {
        command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
        args = [
          "-y"
          "mcp-obsidian"
          "/home/zarred/notes"
        ];
      };
    };
  };

in
{
  home.file.".config/Claude/claude_desktop_config.json" = {
    source = claudeConfig;
  };

  home.file.".config/opencode/mcp_config.json" = {
    source = opencodeConfig;
  };

  # Add MCP server packages to user environment
  home.packages = with pkgs-unstable; [
    nodejs
  ];
}
