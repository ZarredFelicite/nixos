{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "youtube-transcript-api";
  version = "1.1.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "jdepoix";
    repo = "youtube-transcript-api";
    tag = "v${version}";
    hash = "sha256-RCyv0RhJkxZ4RcM0Hv9Qd4KBBpbakjhhuX8V15GcMQA="; # NOTE: UPDATE
  };


  build-system = [ pkgs.python3Packages.poetry-core ];

  pythonRelaxDeps = [
    "defusedxml"
  ];

  dependencies = with pkgs.python3Packages; [
    defusedxml
    requests
  ];

  nativeCheckInputs = with pkgs.python3Packages; [
    httpretty
    pytestCheckHook
  ];

  doCheck = false;

  meta = with pkgs.lib; {
    description = "Python API which allows you to get the transcripts/subtitles for a given YouTube video";
    mainProgram = "youtube_transcript_api";
    homepage = "https://github.com/jdepoix/youtube-transcript-api";
    changelog = "https://github.com/jdepoix/youtube-transcript-api/releases/tag/${src.tag}";
    license = licenses.mit;
    maintainers = [ ];
  };
}
