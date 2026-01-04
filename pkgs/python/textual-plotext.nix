{
  lib,
  buildPythonPackage,
  requests,
  setuptools,
  plotext,
  textual,
  fetchPypi,
  poetry-core,
  pkgs ? import <nixpkgs> {}
}:

buildPythonPackage rec {
  pname = "textual-plotext";
  version = "1.0.1";
  pyproject = true;
  src = fetchPypi {
    inherit version;
    pname = "textual_plotext";
    sha256 = "sha256-g29TozFnVmCeGUEpo1wodWOOeVjCYfVB4KeU98mAEb4=";
  };
  build-system = [ setuptools ];
  nativeBuildInputs = [ poetry-core ];
  dependencies = [
    requests
    plotext
    textual
  ];
  pythonRelaxDeps = true;
  #doCheck = false;
  #pythonImportsCheck = [ "ibind" ];

  meta = with lib; {
    description = "A Textual widget wrapper for the Plotext plotting library";
    homepage = "https://github.com/Textualize/textual-plotext";
    changelog = "https://github.com/Textualize/textual-plotext/blob/${src.tag}/CHANGELOG.rst";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
