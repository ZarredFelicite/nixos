{ pkgs, ... }: {
  services.ollama = {
    host = "127.0.0.1";
    port = 11434;
  };

  systemd.services.ollama.serviceConfig.Environment = [
    "VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json"
  ];
  #services.llama-cpp = {
  #  host = "127.0.0.1";
  #  port = 8083;
  #  openFirewall = true;
  #  model = 'path';
  #};
}
