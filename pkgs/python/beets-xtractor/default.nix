{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, pyyaml
}:

buildPythonPackage rec {
  pname = "beets-xtractor";
  version = "0.4.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "adamjakab";
    repo = "BeetsPluginXtractor";
    rev = "v${version}";
    hash = "sha256-it4qQ2OS4qBEaGLJK8FVGpjlvg0MQICazV7TAM8lH9s=";
  };

  build-system = [ setuptools ];
  dependencies = [ pyyaml ];
  pythonRelaxDeps = [ "beets" ];
  dontCheckRuntimeDeps = true;

  # Tests expect a beets runtime/library fixture and external extractor assets.
  doCheck = false;

  meta = {
    description = "Beets plugin for extracting acoustic metadata with Essentia";
    homepage = "https://github.com/adamjakab/BeetsPluginXtractor";
    license = lib.licenses.mit;
  };
}
