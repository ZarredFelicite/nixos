{ config, lib, pkgs, ... }:
let
  runtime = pkgs.callPackage ../../pkgs/print-failure-runtime.nix { };
in
{
  systemd.user.services.print-failure-monitor = {
    Unit = {
      Description = "Alert on suspected 3D-print failures";
      After = [ "graphical-session.target" "bambu-gateway.service" "network.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/dev/print-failure-monitor";
      ExecStart = "${runtime.python}/bin/python %h/dev/print-failure-monitor/monitor.py --model ${runtime.model}";
      Restart = "on-failure";
      RestartSec = "10s";
      MemoryMax = "512M";
      Environment = [
        "PATH=${lib.makeBinPath [ runtime.python pkgs.libnotify ]}"
        "LD_LIBRARY_PATH=${pkgs.opencv}/lib:${pkgs.stdenv.cc.cc.lib}/lib"
        "CUDA_VISIBLE_DEVICES=-1"
        "OMP_NUM_THREADS=2"
        "OPENBLAS_NUM_THREADS=2"
        "TF_NUM_INTRAOP_THREADS=2"
        "TF_NUM_INTEROP_THREADS=1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
