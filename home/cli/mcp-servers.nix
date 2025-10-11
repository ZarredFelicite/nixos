{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

let
  mcp-servers-nix = inputs.mcp-servers-nix;
  
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
  opencodeConfig = mcp-servers-nix.lib.mkConfig pkgs {
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
  home.packages = with pkgs; [
    nodejs
  ] ++ (with mcp-servers-nix.packages.${pkgs.system}; [
    mcp-server-fetch
    mcp-server-filesystem
    mcp-server-git
    mcp-server-memory
    mcp-server-time
    playwright-mcp
  ]);
}
