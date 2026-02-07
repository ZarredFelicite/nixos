{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  packaging,
  torch,
  torchaudio,
  onnxruntime,
}:

buildPythonPackage rec {
  pname = "silero-vad";
  version = "6.2.0";
  format = "pyproject";

  src = fetchPypi {
    pname = "silero_vad";
    inherit version;
    hash = "sha256-J/kOmUvFf989DRol9w9l2BhUwRl0pPkR9+YXkueok/0=";
  };

  build-system = [ hatchling ];

  dependencies = [
    packaging
    torch
    torchaudio
    onnxruntime
  ];

  doCheck = false;

  meta = with lib; {
    description = "Voice Activity Detector (VAD) by Silero";
    homepage = "https://github.com/snakers4/silero-vad";
    license = licenses.mit;
  };
}
