{ ... }:

{
  # Preserve the existing desktop/server appearance: the shared Nixvim
  # module itself must also evaluate on ROCK, which has no Stylix module.
  stylix.targets.nixvim.enable = false;
  stylix.targets.tmux.enable = false;
  programs.nixvim.plugins.treesitter.nixGrammars = true;
}
