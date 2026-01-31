{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  hatchling,

  # dependencies
  beartype,
  einops,
  fastapi,
  huggingface-hub,
  numpy,
  pydantic,
  python-multipart,
  requests,
  safetensors,
  scipy,
  sentencepiece,
  torch,
  typer,
  typing-extensions,
  uvicorn,

  # optional-dependencies
  soundfile,
}:

buildPythonPackage rec {
  pname = "pocket-tts";
  version = "1.0.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "kyutai-labs";
    repo = "pocket-tts";
    tag = "v${version}";
    hash = "sha256-zGZySn8nXCjwfcXYglJIrS/u1cqiJrErx1wQkC7H93k=";
  };

  nativeBuildInputs = [
    hatchling
  ];

  propagatedBuildInputs = [
    beartype
    einops
    fastapi
    huggingface-hub
    numpy
    pydantic
    python-multipart
    requests
    safetensors
    scipy
    sentencepiece
    torch
    typer
    typing-extensions
    uvicorn
  ];

  pythonRelaxDeps = [
    "beartype"
    "python-multipart"
  ];

  pythonImportsCheck = [ "pocket_tts" ];

  # All tests are failing as the model cannot be downloaded from the sandbox
  doCheck = false;

  meta = {
    description = "Lightweight text-to-speech (TTS) application designed to run efficiently on CPUs";
    homepage = "https://github.com/kyutai-labs/pocket-tts";
    changelog = "https://github.com/kyutai-labs/pocket-tts/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ GaetanLepage ];
    mainProgram = "pocket-tts";
  };
}
