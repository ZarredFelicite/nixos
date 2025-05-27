{ pkgs, ... }: {
  services.ollama = {
    host = "127.0.0.1";
    port = 11434;
  };
  systemd.services.parakeet-devenv = {
    description = "Devenv service parakeet";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "zarred";
      Group = "users";
      WorkingDirectory = "/home/zarred/dev/asr2";
      ExecStart = "${pkgs.nix}/bin/nix develop --command 'start'";
      Restart = "on-failure";
    };
  };
  #services.llama-cpp = {
  #  host = "127.0.0.1";
  #  port = 8083;
  #  openFirewall = true;
  #  model = 'path';
  #};
}
