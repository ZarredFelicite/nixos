{ pkgs, config, lib, ... }: {
  #  lib.mkIf config.services.klipper.enable
  virtualisation.oci-containers.containers."mainsail" = {
    image = "ghcr.io/mainsail-crew/mainsail";
    ports = [ "8001:80" ];
    #extraOptions = ["--network=host"];
    volumes = [
      "/var/lib/mainsail/config.json:/usr/share/nginx/html/config.json"
    ];
  };
  networking.firewall.allowedTCPPorts = [ 7125 ];
  #services.mainsail = {
  #  enable = lib.mkIf config.services.klipper.enable true;
  #  hostName = "mainsail.zar.red";
  #};
  #services.fluidd = {
  #  enable = true;
  #  hostName = "fluidd.zar.red";
  #  nginx.acmeRoot = null;
  #};
  services.moonraker = {
    enable = lib.mkIf config.services.klipper.enable true;
    user = "zarred";
    group = "users";
    stateDir = "/var/lib/moonraker";
    port = 7125;
    address = "0.0.0.0";
    klipperSocket = config.services.klipper.apiSocket;
    allowSystemControl = true;
    settings = {
      authorization = {
        cors_domains = [
          "https://mainsail.zar.red"
          "http://192.168.86.200:8001"
        ];
        trusted_clients = [
          "192.168.86.0/24"
        ];
      };
      file_manager.enable_object_processing = true;
      announcements.subscriptions = [ "mainsail" ];
    };
  };
  services.klipper = {
    user = "zarred";
    group = "users";
    mutableConfig = true;
    mutableConfigFolder = "/var/lib/moonraker/config";
    logFile = "/var/lib/moonraker/logs/klipper.log";
    inputTTY = "/run/klipper/tty";
    apiSocket = "/run/klipper/api";
    configFile = "/var/lib/moonraker/config/printer.cfg";
    #settings = {
    #  # This file contains a configuration for the Anycubic Kobra Go printer.
    #  #
    #  # See docs/Config_Reference.md for a description of parameters.
    #  #
    #  # To build the firmware, use the following configuration:
    #  #   - Micro-controller: Huada Semiconductor HC32F460
    #  #   - Communication interface: Serial (PA3 & PA2) - Anycubic
    #  #
    #  # Installation:
    #  #  1. Rename the klipper bin to `firmware.bin` and copy it to an SD Card.
    #  #  2. Power off the Printer, insert the SD Card and power it on.
    #  #  3. The the LCD will be stuck on the Firmware-update screen.
    #  #     Just Wait for 3-5 minutes to ensure the firmware is flashed.
    #  #  4. After waiting, shutdown the printer and remove the SD Card.

    #  stepper_x = {
    #    step_pin = "PA12";
    #    dir_pin = "PA11";
    #    enable_pin = "!PA15";
    #    microsteps = 16;
    #    rotation_distance = 40;
    #    endstop_pin = "!PH2";
    #    position_endstop = -13;
    #    position_min = -13;
    #    position_max = 236;
    #    homing_speed = 60;
    #  };

    #  stepper_y = {
    #    step_pin = "PA9";
    #    dir_pin = "PA8";
    #    enable_pin = "!PA15";
    #    microsteps = 16;
    #    rotation_distance = 40;
    #    endstop_pin = "^!PC13";
    #    position_endstop = -9;
    #    position_min = -9;
    #    position_max = 230;
    #    homing_speed = 60;
    #  };

    #  stepper_z = {
    #    step_pin = "PC7";
    #    dir_pin = "!PC6";
    #    enable_pin = "!PA15";
    #    microsteps = 16;
    #    rotation_distance = 8;
    #    endstop_pin = "^PC14";
    #    position_endstop = 0;
    #    position_min = -10;
    #    position_max = 255;
    #    homing_speed = 6;
    #    second_homing_speed = 1;
    #    homing_retract_dist = 2.3;
    #  };

    #  extruder = {
    #    step_pin = "PB15";
    #    dir_pin = "PB14";
    #    enable_pin = "!PA15";
    #    microsteps = 16;
    #    rotation_distance = 31.07;
    #    max_extrude_only_velocity = 25;
    #    max_extrude_only_accel = 1000;
    #    nozzle_diameter = 0.400;
    #    filament_diameter = 1.750;
    #    heater_pin = "PB8";
    #    sensor_type = "ATC Semitec 104GT-2";
    #    sensor_pin = "PC3";
    #    min_extrude_temp = 230;
    #    min_temp = 0;
    #    max_temp = 250;
    #    control = "pid";
    #    pid_kp = 19.56;
    #    pid_ki = 1.62;
    #    pid_kd = 200.00;
    #  };

    #  firmware_retraction = {
    #    retract_length = 6;
    #    retract_speed = 4;
    #    unretract_extra_length = 0;
    #    unretract_speed = 20;
    #  };

    #  heater_bed = {
    #    heater_pin = "PB9";
    #    sensor_type = "EPCOS 100K B57560G104F";
    #    sensor_pin = "PC1";
    #    min_temp = 0;
    #    max_temp = 120;
    #    control = "pid";
    #    pid_kp = 97.1;
    #    pid_ki = 1.41;
    #    pid_kd = 1675.16;
    #  };

    #  bed_mesh = {
    #    speed = 400;
    #    horizontal_move_z = 3.5;
    #    mesh_min = "5, 5";
    #    mesh_max = "215, 215";
    #    probe_count = "6, 6";
    #  };

    #  probe = {
    #    pin = "PA1";
    #    x_offset = -19;
    #    y_offset = 0;
    #    z_offset = 0;
    #    samples = 3;
    #    samples_result = "average";
    #    samples_tolerance_retries = 3;
    #    sample_retract_dist = 0.5;
    #    speed = 2;
    #    lift_speed = 4;
    #  };

    #  safe_z_home = {
    #    home_xy_position = "0, 0";
    #    speed = 5;
    #    z_hop = 10;
    #    z_hop_speed = 15;
    #  };

    #  "controller_fan controller_fan" = {
    #    pin = "PB12";
    #    max_power = 0.75;
    #  };

    #  "heater_fan extruder_fan" = {
    #    pin = "PB13";
    #  };

    #  fan = {
    #    pin = "PB5";
    #    cycle_time = 0.00005;
    #  };

    #  "output_pin enable_pin" = {
    #    pin = "PB6";
    #    static_value = 1;
    #  };

    #  mcu = {
    #    serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
    #    restart_method = "command";
    #  };

    #  printer = {
    #    kinematics = "cartesian";
    #    max_velocity = 500;
    #    max_accel = 2500;
    #    max_accel_to_decel = 2000;
    #    max_z_velocity = 20;
    #    max_z_accel = 50;
    #  };

    #  "gcode_macro G29" = [''
    #    gcode =
    #      G28
    #      BED_MESH_CALIBRATE
    #      G0 X0 Y0 Z10 F6000
    #      BED_MESH_PROFILE save=default
    #  ''];

    #  "gcode_macro START_PRINT" = [''
    #    gcode =
    #      {% set X_MAX = printer.toolhead.axis_maximum.x|default(100)|float %}
    #      {% set Y_MAX = printer.toolhead.axis_maximum.y|default(100)|float %}
    #      {% set Z_MAX = printer.toolhead.axis_maximum.z|default(100)|float %}

    #      {% set NOZZLE = printer.extruder.nozzle_diameter|default(0.4)|float %}
    #      {% set FILADIA = printer.extruder.filament_diameter|default(1.75)|float %}

    #      {% set X_START = 10.0|default(10.0)|float %}
    #      {% set Y_START = 20.0|default(20.0)|float %}

    #      {% set PRIMER_WIDTH = 0.75 * NOZZLE %}
    #      {% set PRIMER_HEIGHT = 0.70 * NOZZLE %}
    #      {% set PRIMER_SECT = PRIMER_WIDTH * PRIMER_HEIGHT %}
    #      {% set PRIMER_VOL = PRIMER_SECT * (X_MAX - 3 * X_START) %}
    #      {% set FILA_SECT = 3.1415 * ( FILADIA / 2.0)**2 %}
    #      {% set FILA_LENGTH = 1.55 * PRIMER_VOL / FILA_SECT %}

    #      {% set BED_TEMP = params.BED_TEMP|default(100)|float %}
    #      {% set EXTRUDER_TEMP = params.EXTRUDER_TEMP|default(245)|float %}

    #      M104 S{EXTRUDER_TEMP} T0
    #      M140 S{BED_TEMP}

    #      G28

    #      M190 S{BED_TEMP}
    #      M109 S{EXTRUDER_TEMP} T0

    #      G92 E0
    #      G1 X{X_START} Y{Y_START} Z{PRIMER_HEIGHT} F6000.0
    #      G1 X{X_MAX - 2 * X_START} Y{Y_START} Z{PRIMER_HEIGHT} F2000.0
    #      G1 X{X_MAX - 2 * X_START} Y{Y_START + PRIMER_WIDTH} Z{PRIMER_HEIGHT}
    #      G1 X{X_START} Y{Y_START + PRIMER_WIDTH} Z{PRIMER_HEIGHT} F2000.0
    #      G1 X{X_START} Y{Y_START + 2 * PRIMER_WIDTH} Z{PRIMER_HEIGHT} F2000.0
    #      G1 X{X_MAX - 2 * X_START} Y{Y_START + 2 * PRIMER_WIDTH} Z{PRIMER_HEIGHT} F2000.0
    #      G1 X{X_MAX - 2 * X_START} Y{Y_START + 3 * PRIMER_WIDTH} Z{PRIMER_HEIGHT} F2000.0
    #      G1 X{X_START} Y{Y_START + 3 * PRIMER_WIDTH} Z{PRIMER_HEIGHT} F2000.0
    #      G92 E0
    #      G1 Z2.0 F600
    #      G1 Z0.2 F600
    #      G1 Z2.0 F600
    #  ''];

    #  "gcode_macro END_PRINT" = [''
    #    gcode =
    #      {% set X_MAX = printer.toolhead.axis_maximum.x|default(100)|float %}
    #      {% set Y_MAX = printer.toolhead.axis_maximum.y|default(100)|float %}

    #      G91
    #      G1 E-2 F2700
    #      G1 E-1.5 Z0.2 F2400
    #      G1 X5 Y5 F6000
    #      G1 Z10
    #      G90

    #      G1 Z{printer.toolhead.position.z + 10} F600
    #      G1 X{X_MAX / 2} Y{Y_MAX} F6000
    #      M106 S0
    #      M104 S0
    #      M140 S0

    #      M84 X Y E
    #  ''];
    #  #[include mainsail.cfg]
    #};
  };
}
