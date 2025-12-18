{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "bambulabs_api";
  version = "2.6.5";
  format = "pyproject";
  src = pkgs.fetchFromGitHub {
    owner = "mchrisgm";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-uKQIP87bG7xs8g3scqGvHlzEYDi2j8sAxbeNYMhwo8w=";
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
