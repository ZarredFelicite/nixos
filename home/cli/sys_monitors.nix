{ pkgs, ... }: {
  programs.htop = {
    enable = true;
    package = pkgs."htop-vim";
    settings = {
      tree_view = 1;
      hide_userland_threads = 1;
      highlight_changes = 1;
      show_cpu_frequency = 1;
      show_cpu_temperature = 1;
      show_program_path = 0;
      highlight_base_name = 1;
    };
  };
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = false;
      truecolor = true;
      force_tty = false;
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default proc:0:braille";
      vim_keys = true;
      rounded_corners = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "cpu mem net proc";
      update_ms = 500;
      proc_sorting = "cpu direct";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = true;
      proc_left = false;
      proc_filter_kernel = true;
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      check_temp = true;
      cpu_sensor = "k10temp/Tctl";
      show_coretemp = false;
      cpu_core_map = "";
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      clock_format = "%H:%M";
      background_update = false;
      custom_cpu_name = "";
      disks_filter = "/persist /mnt/gargantua /mnt/dagobah /mnt/eros /mnt/ceres";
      mem_graphs = false;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = false;
      show_disks = true;
      only_physical = false;
      use_fstab = false;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = true;
      ro_graph_combined = true;
      io_graph_speeds = "";
      net_download = 50;
      net_upload = 50;
      net_auto = false;
      net_sync = true;
      show_battery = true;
      selected_battery = "Auto";
      log_level = "ERROR";
    };
  };
  home.packages = [
    pkgs.nvtop-nvidia
  ];
  xdg.configFile."nvtop/interface.ini".text = ''
    ; Please do not edit this file.
    ; The file is automatically generated and modified by nvtop by pressing F12.
    ; If you wish to modify an option, use nvtop's setup window (F2) and follow up by saving the preference (F12).
    [GeneralOption]
    UseColor = true
    UpdateInterval = 500
    ShowInfoMessages = true

    [HeaderOption]
    UseFahrenheit = false
    EncodeHideTimer = 3.000000e+01

    [ChartOption]
    ReverseChart = false

    [ProcessListOption]
    HideNvtopProcess = true
    SortOrder = descending
    SortBy = gpuRate
    DisplayField = pId
    DisplayField = type
    DisplayField = gpuRate
    DisplayField = encRate
    DisplayField = decRate
    DisplayField = memory
    DisplayField = cmdline

    [Device]
    Pdev = 0000:2D:00.0
    Monitor = true
    ShownInfo = gpuRate
    ShownInfo = gpuMemRate
    ShownInfo = temperature
    ShownInfo = fanSpeed
  '';
}
