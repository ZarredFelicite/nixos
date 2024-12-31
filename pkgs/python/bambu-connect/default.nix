{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "bambu-connect";
  version = "0.3.1";
  format = "pyproject";
  src = pkgs.fetchFromGitHub {
    owner = "mattcar15";
    repo = pname;
    rev = "50bf2dc561d17a391db40a72f76bf764a36087a2";
    sha256 = "sha256-obiMDhT8tKD+k55L7W5Pkpu8dII7COwjMWJzw0JvGCk=";
  };
  propagatedBuildInputs = with pkgs; [
    python3Packages.setuptools
    python3Packages.paho-mqtt_1
    python3Packages.moviepy
  ];
  meta = with pkgs.lib; {
    description = "Connect to the stats, controls, and camera of your bambu printer";
    homepage = "https://github.com/mattcar15/bambu-connect";
    license = with licenses; [ mit ];
    #maintainers = with maintainers; [ ];
    mainProgram = "bambu-connect";
  };
}
