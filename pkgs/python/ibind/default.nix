{
# lib,
# buildPythonPackage,
# fetchFromGitHub,
# websocket-client,
# requests,
# setuptools,
  pkgs ? import <nixpkgs> {}
}:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "ibind";
  version = "0.1.12";
  pyproject = true;

  #src = pkgs.fetchFromGitHub {
  #  owner = "Voyz";
  #  repo = "ibind";
  #  tag = "v${version}";
  #  hash = "sha256-Ymv9UU/dhzaG9ae4D7Wm5YDQp4ie0poivU5IxvaC3SE="; # NOTE: UPDATE
  #};
  src = pkgs.python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-UT3eElyPCYbEkudUs/Q4iVFQ7yGunk40YVzADbcL9Z4="; # NOTE: UPDATE
  };


  build-system = [ pkgs.python3Packages.setuptools ];

  dependencies = with pkgs.python3Packages; [
    requests
    websocket-client
    pycryptodome
    urllib3
  ];

  pythonRelaxDeps = true;
  # Tests require internet access
  doCheck = false;

  #pythonImportsCheck = [ "ibind" ];

  meta = with pkgs.lib; {
    description = "IBind is a REST and WebSocket client library for Interactive Brokers Client Portal Web API";
    homepage = "https://github.com/Voyz/ibind";
    changelog = "https://github.com/Voyz/ibind/blob/${src.tag}/CHANGELOG.rst";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
