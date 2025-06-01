{ pkgs, ... }: {
  services.ollama = {
    host = "127.0.0.1";
    port = 11434;
  };
  #services.llama-cpp = {
  #  host = "127.0.0.1";
  #  port = 8083;
  #  openFirewall = true;
  #  model = 'path';
  #};
}
