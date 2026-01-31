{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  accelerate,
  fastapi,
  gradio,
  huggingface-hub,
  numpy,
  scipy,
  sounddevice,
  torch,
  transformers,
  unidecode,
  uvicorn,
  inflect,
}:

buildPythonPackage rec {
  pname = "soprano-tts";
  version = "0.2.0";
  format = "pyproject";

  src = fetchPypi {
    pname = "soprano_tts";
    inherit version;
    sha256 = "de83303ae0ff67372b98ee2b37bc5d8c0167fed5d7072801a13d7d9f399c2f6e";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    accelerate
    fastapi
    gradio
    huggingface-hub
    numpy
    scipy
    sounddevice
    torch
    transformers
    unidecode
    uvicorn
    inflect
  ];

  pythonRelaxDeps = [
    "torch"
    "transformers"
  ];

  pythonImportsCheck = [ "soprano" ];

  doCheck = false;

  meta = {
    description = "Soprano: Instant, Ultra-Realistic Text-to-Speech";
    homepage = "https://github.com/ekwek1/soprano";
    license = lib.licenses.asl20;
    mainProgram = "soprano";
  };
}
