{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "bambulabs_api";
  version = "2.5.2";
  format = "pyproject";
  src = pkgs.fetchFromGitHub {
    owner = "mchrisgm";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-IdZL/QnI422MKZXf6K3VPCEXeADxXxLHLPnsmHeOlvo=";
  };
  propagatedBuildInputs = with pkgs; [
    python3Packages.setuptools
    python3Packages.setuptools_scm
    python3Packages.paho-mqtt_2
    python3Packages.pillow
  ];
  #nativeBuildInputs = with pkgs; [ pkg-config ];
  #buildInputs = with pkgs; [ alsa-lib.dev openssl ];
  meta = with pkgs.lib; {
    description = "Unofficial BambuLab 3D Printers Python API";
    homepage = "mchrisgm.github.io/bambulabs_api";
    license = with licenses; [ mit ];
    #maintainers = with maintainers; [ ];
    mainProgram = "bambulabs_api";
  };
}
