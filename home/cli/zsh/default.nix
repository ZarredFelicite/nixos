{ config, pkgs, ... }: {
home.packages = with pkgs; [
  #zsh-completions
  zsh-autosuggestions
  spaceship-prompt
  #zsh-fzf-history-search
  cod
];
programs.direnv = {
  enableBashIntegration = true;
  enableZshIntegration = true;
  nix-direnv.enable = true;
  config = {
    whitelist = {
      prefix = [
        "/home/zarred/dev"
        "/home/zarred/scripts"
      ];
    };
  };
};
programs.zsh = {
  dotDir = ".config/zsh";
  enableAutosuggestions = true;
  enableCompletion = true;
  syntaxHighlighting.enable = true;
  autocd = true;
  cdpath = [
    #"/mnt/gargantua/media"
  ];
  completionInit = "autoload -U compinit && compinit";
  defaultKeymap = "viins";
  history = {
    path = "$HOME/.cache/zsh_history";
    expireDuplicatesFirst = true;
    extended = true;
    ignorePatterns = [ "*porn*" ];
    ignoreSpace = true;
    save = 1000000;
    size = 1000000;
    share = true;
  };
  historySubstringSearch.enable = true;
  initExtra = ''
    for d in ~/scripts/*/; do
      for dd in $d*; do
        if [ -d "$dd" ]; then
          PATH+=":$dd"
        fi
      done
      PATH+=":$d"
    done

    bindkey '^H' backward-kill-word
    bindkey '5~' kill-word

    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 100 100
    # disable sort when completing options of any command
    zstyle ':completion:complete:*:options' sort false
    # disable sort when completing `git checkout`
    zstyle ':completion:*:git-checkout:*' sort false
    # set descriptions format to enable group support
    zstyle ':completion:*:descriptions' format '[%d]'
    # set list-colors to enable filename colorizing
    # zstyle ':completion:*' list-colors $\{(s.:.)LS_COLORS}
    # preview directory's content with exa when completing cd
    zstyle ':fzf-tab:complete:cd:*' fzf-preview '~/scripts/previewers/mini_previewer $realpath'
    zstyle ':fzf-tab:complete:*:*' fzf-preview '~/scripts/previewers/mini_previewer $realpath'
    # switch group using `,` and `.`
    zstyle ':fzf-tab:*' switch-group ',' '.'

    bindkey -s '^a' 'buku_fzf\n'
    bindkey -s '^e' 'n\n'
    bindkey -s '^k' '~/scripts/nova/fzf-nova\n'
    bindkey -s '^f' 'fzf | xargs -I {} wtype linkhandler.sh "$(pwd)/{}"\n'
    # Calculator
    calc() { printf "%s\n" "$@" | bc -l; }
    batdiff() { git diff --name-only --relative --diff-filter=d | xargs bat --diff; }
    video() { nohup mpv $@ >/dev/null 2>&1 &; }
    # auto completion generation from --help page
    source <(cod init $$ zsh)
  '';
  initExtraBeforeCompInit = "";
  initExtraFirst = "";
  loginExtra = "";
  logoutExtra = "";
  plugins = [
    #{
    #  # will source zsh-autosuggestions.plugin.zsh
    #  name = "zsh-autosuggestions";
    #  src = pkgs.fetchFromGitHub {
    #    owner = "zsh-users";
    #    repo = "zsh-autosuggestions";
    #    rev = "v0.4.0";
    #    sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
    #  };
    #}
    { name = "functions"; file = "./plugins/functions.sh"; src = ./plugins;}
    { name = "fzf"; file = "./plugins/fzf_zsh.sh"; src = ./plugins;}
    { name = "completions"; src = ./completions;}
    #{ name = "_hyprctl"; file = "_hyprctl"; src = ./plugins; }
    {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
        sha256 = "sha256-gvZp8P3quOtcy1Xtt1LAW1cfZ/zCtnAmnWqcwrKel6w=";
      };
    }
    {
      name = "fzf-tab-source";
      src = pkgs.fetchFromGitHub {
        owner = "Freed-Wu";
        repo = "fzf-tab-source";
        rev = "b1a236e34d68a3f76c20d9035679a3ec8bfa325d";
        sha256 = "sha256-tGCpEfbCh2qzHWMIr6zLokjS9g9cGZ78XIXxA1ptWvk=";
      };
    }
    {
      name = "jq-zsh-plugin";
      src = pkgs.fetchFromGitHub {
        owner = "reegnz";
        repo = "jq-zsh-plugin";
        rev = "e61804e35a593ada9c4d23ee5c957d08974ac382";
        sha256 = "0x64g0sr4j6kkbnr8hqjgnpbasazljppx612zihgdisc6b074jk0";
      };
    }
    #{
    #  src = pkgs.fetchgit {
    #    url = "https://github.com/zsh-users/zsh-syntax-highlighting";
    #    rev = "1386f1213eb0b0589d73cd3cf7c56e6a972a9bfd";
    #    sha256 = "1sykb0a8jwndrdf5sfy0mi0j763rcyli62w7h4zd0zcwwkckac7a";
    #  };
    #};
  ];
  sessionVariables = {
    BLK = "04"; CHR = "04"; DIR = "04"; EXE = "00"; REG = "00"; HARDLINK = "00"; SYMLINK = "06"; MISSING = "00"; ORPHAN = "01"; FIFO = "0F"; SOCK = "0F"; OTHER = "02";
    # Colors
    FG = "\\033[38;2;";
    BG = "\\033[48;2;";
    PINE_FG = "$\\{FG}49;116;143m";
    PINE_BG = "$\\{BG}49;116;143m";
    BASE_FG = "$\\{FG}25;23;36m";
    BASE_BG = "$\\{BG}25;23;36m";
    ROSE_FG = "$\\{FG}235;188;186m";
    ROSE_BG = "$\\{BG}235;188;186m";
    RED = "\\033[0;31m";
    GREEN = "\\033[0;32m";
    YELLOW = "\\033[0;33m";
    BLUE = "\\033[0;34m";
    PURPLE = "\\033[0;35m";
    CYAN = "\\033[0;36m";
    NC = "\\033[0m";
  };
  shellAliases = {
    reboot = "~/scripts/sys/reboot";
    mon-off = "xset dpms force off";
    tw = "wtwitch";
    c-awesome = "nvim ~/.config/awesome/rc.lua";
    c-picom = "nvim ~/.config/picom/picom.conf";
    c-auto = "nvim ~/.dotfiles/autostart.sh";
    yt-subs = "nvim ~/.config/ytfzf/grouped_subscriptions.csv";
    ytc = "/home/zarred/yt-subscription-terminal/sub_term.py";
    copy = "rsync -rh --info=progress2";
    vi = "nvim";
    fzf = "fzf -m --reverse --border --inline-info --bind=ctrl-l:accept";
    mkdir = "mkdir -pv";
    mv = "mv -i";
    software = "nvim ~/bookmarks/software.md";
    tv = "tidy-viewer";
    skl = "lychee - --dump | sk";
    b = "buku --suggest";
    d = "trash";
    c = "cp-p";
    mm = "micromamba";
    mmact = "eval '$(micromamba shell hook --shell=zsh)'; micromamba activate";
    mpa = "mpv --force-window=no --vid=no --osd-fractions --osd-level=2";
    open = "~/scripts/file-ops/linkhandler.sh";
    word_count = "tr ' ' '\n' | wc -l";
    code = "code --enable-features=UseOzonePlatform --ozone-platform=wayland";
    sex = "sudo chmod +x";
    cura = "QT_QPA_PLATFORM=xcb; cura -platformtheme gtk3 & disown";
    drag = "dragon-drop -x";
    snvim = "sudo nvim -u ~/.config/nvim/init.lua";
    nvidia-settings = "nvidia-settings --config=\${XDG_CONFIG_HOME}/nvidia/settings";
    svn = "svn --config-dir \${XDG_CONFIG_HOME}/subversion";
    wget = "wget --hsts-file=\${XDG_DATA_HOME}/wget-hsts";
    ls = "eza";
    lsa = "eza -a";
    lsl = "eza -l";
    lsla = "eza -al";
    lst = "eza --tree";
    lsta = "eza --tree -a";
    lstl = "eza --tree -l";
    lstla = "eza --tree -la";
  };
};
}
