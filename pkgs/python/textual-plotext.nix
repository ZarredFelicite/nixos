{
  pkgs ? import <nixpkgs> {}
}:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "textual-plotext";
  version = "1.0.1";
  pyproject = true;
  src = pkgs.fetchPypi {
    inherit version;
    pname = "textual_plotext";
    sha256 = "sha256-g29TozFnVmCeGUEpo1wodWOOeVjCYfVB4KeU98mAEb4=";
  };
  build-system = [ pkgs.python3Packages.setuptools ];
  nativeBuildInputs = [ pkgs.python3Packages.poetry-core ];
  dependencies = [
    pkgs.python3Packages.requests
    pkgs.python3Packages.plotext
    pkgs.python3Packages.textual
  ];
  pythonRelaxDeps = true;
  #doCheck = false;
  #pythonImportsCheck = [ "ibind" ];

  meta = with pkgs.lib; {
    description = "A Textual widget wrapper for the Plotext plotting library";
    homepage = "https://github.com/Textualize/textual-plotext";
    changelog = "https://github.com/Textualize/textual-plotext/blob/${src.tag}/CHANGELOG.rst";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
