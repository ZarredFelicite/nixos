{
  general = {
    mode = "viewer";
    size = "1280,720";
    position = "auto";
    overlay = "no";
    decoration = "no";
    sigusr1 = "reload";
    sigusr2 = "next_file";
    app_id = "swayimg";
  };
  viewer = {
    window = "#00000000";
    transparency = "grid";
    scale = "optimal";
    position = "center";
    antialiasing = "mks13";
    loop = "yes";
    history = 1;
    preload = 1;
  };
  slideshow = {
    time = 3;
    window = "auto";
    transparency = "#000000ff";
    scale = "fit";
    position = "center";
    antialiasing = "mks13";
  };
  gallery = {
    size = 200;
    cache = 100;
    preload = "no";
    pstore = "no";
    fill = "yes";
    antialiasing = "mks13";
    window = "#00000000";
    background = "#202020ff";
    select = "#404040ff";
    border = "#000000ff";
    shadow = "#000000ff";
  };
  list = {
    order = "alpha";
    reverse = "no";
    recursive = "no";
    all = "no";
    fsmon = "yes";
  };
  font = {
    name = "monospace";
    size = 14;
    color = "#ccccccff";
    shadow = "#000000d0";
    background = "#00000000";
  };
  info = {
    show = "yes";
    padding = 10;
    info_timeout = 5;
    status_timeout = 3;
  };
  "info.viewer" = {
    top_left = "+name,+format,+filesize,+imagesize,+exif";
    top_right = "index";
    bottom_left = "scale,frame";
    bottom_right = "status";
  };
  "info.slideshow" = {
    top_left = "none";
    top_right = "none";
    bottom_left = "none";
    bottom_right = "dir,status";
  };
  "info.gallery" = {
    top_left = "none";
    top_right = "index";
    bottom_left = "none";
    bottom_right = "name,status";
  };

  "keys.viewer" = {
    F1 = "help";
    Home = "first_file";
    End = "last_file";
    Prior = "prev_file";
    p = "prev_file";
    Next = "next_file";
    Space = "next_file";
    "Shift+r" = "rand_file";
    "Shift+d" = "prev_dir";
    d = "next_dir";
    "Shift+n" = "prev_frame";
    "Shift+o" = "next_frame";
    n = "prev_file";
    o = "next_file";
    c = "skip_file";
    s = "mode slideshow";
    f = "fullscreen";
    Return = "mode gallery";
    Left = "step_left 10";
    Right = "step_right 10";
    Up = "step_up 10";
    Down = "step_down 10";
    Equal = "zoom +10";
    Plus = "zoom +10";
    Minus = "zoom -10";
    w = "zoom width";
    "Shift+w" = "zoom height";
    z = "zoom fit";
    "Shift+z" = "zoom fill";
    "0" = "zoom real";
    BackSpace = "zoom optimal";
    k = "zoom keep";
    "Alt+s" = "zoom";
    bracketleft = "rotate_left";
    bracketright = "rotate_right";
    m = "flip_vertical";
    "Shift+m" = "flip_horizontal";
    a = "antialiasing";
    "Shift+a" = "animation";
    r = "reload";
    i = "info";
    "Shift+Delete" = "exec rm -f '%' && echo \"File removed: %\"; skip_file";
    Escape = "exit";
    q = "exit";

    ScrollLeft = "step_right 5";
    ScrollRight = "step_left 5";
    ScrollUp = "zoom +5";
    ScrollDown = "zoom -5";
    "Ctrl+ScrollUp" = "zoom +10";
    "Ctrl+ScrollDown" = "zoom -10";
    "Shift+ScrollUp" = "prev_file";
    "Shift+ScrollDown" = "next_file";
    "Alt+ScrollUp" = "prev_frame";
    "Alt+ScrollDown" = "next_frame";
    MouseLeft = "drag";
    MouseSide = "prev_file";
    MouseExtra = "next_file";
  };

  "keys.slideshow" = {
    F1 = "help";
    Home = "first_file";
    End = "last_file";
    Prior = "prev_file";
    Next = "next_file";
    "Shift+r" = "rand_file";
    "Shift+d" = "prev_dir";
    d = "next_dir";
    Space = "pause";
    i = "info";
    f = "fullscreen";
    Return = "mode";
    Escape = "exit";
    q = "exit";
  };

  "keys.gallery" = {
    F1 = "help";
    Home = "first_file";
    End = "last_file";
    Left = "step_left";
    Right = "step_right";
    Up = "step_up";
    Down = "step_down";
    Prior = "page_up";
    Next = "page_down";
    c = "skip_file";
    s = "mode slideshow";
    f = "fullscreen";
    Return = "mode viewer";
    a = "antialiasing";
    r = "reload";
    i = "info";
    Equal = "thumb +20";
    Plus = "thumb +20";
    Minus = "thumb -20";
    "Shift+Delete" = "exec rm -f '%' && echo \"File removed: %\"; skip_file";
    Escape = "exit";
    q = "exit";

    ScrollLeft = "step_right";
    ScrollRight = "step_left";
    ScrollUp = "step_up";
    ScrollDown = "step_down";
    "Ctrl+ScrollUp" = "thumb +20";
    "Ctrl+ScrollDown" = "thumb -20";
    MouseLeft = "mode viewer";
  };
}
