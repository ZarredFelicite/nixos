{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  onnxruntime,
  silero_vad,
  librosa,
  sounddevice,
  soundfile,
  numpy,
  portaudio,
}:

buildPythonPackage rec {
  pname = "local-wake";
  version = "0.1.0";
  format = "pyproject";

  src = fetchPypi {
    pname = "local_wake";
    inherit version;
    hash = "sha256-G6Md4lUG5jmjtSMFR3PhiLfjpwfzHCRvNrGDWAcPai8=";
  };

  build-system = [ setuptools ];

  dependencies = [
    onnxruntime
    silero_vad
    librosa
    sounddevice
    soundfile
    numpy
    portaudio
  ];

  doCheck = false;

  meta = with lib; {
    description = "Lightweight local wake word detection with custom phrase recordings";
    homepage = "https://github.com/st-matskevich/local-wake";
    license = licenses.mit;
    mainProgram = "lwake";
  };
}
