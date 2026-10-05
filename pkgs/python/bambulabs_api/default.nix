{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "bambulabs_api";
  version = "2.6.6";
  format = "pyproject";
  src = pkgs.fetchFromGitHub {
    owner = "mchrisgm";
    repo = pname;
    rev = "${version}"; # NOTE: UPDATE
    sha256 = "sha256-o3S2zCr0x3BpEoBp8r2DcvG3TAF758hJsYpClm2IgF4="; # NOTE: UPDATE
  };
  propagatedBuildInputs = with pkgs; [
    python3Packages.setuptools
    python3Packages.setuptools-scm
    python3Packages.paho-mqtt
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
