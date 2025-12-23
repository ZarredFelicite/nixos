{ pkgs ? import <nixpkgs> {} }:

let
  webvtt-py = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "webvtt-py";
    version = "0.5.1";
    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "glut23";
      repo = pname;
      rev = "${version}";
      sha256 = "sha256-rsxhZ/O/XAiiQZqdsAfCBg+cdP8Hn56EPbZARkKamdA="; # NOTE: UPDATE
    };
    pythonRelaxDeps = true;
    propagatedBuildInputs = with pkgs.python3Packages; [
      setuptools
    ];
  };
in
pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "yt-fts";
  version = "0.1.62";
  format = "pyproject";
  src = pkgs.fetchFromGitHub {
    owner = "NotJoeMartinez";
    repo = pname;
    rev = "v${version}";
    sha256 = "6z//Oi0Sz40fSffFE7kPCCuSz5xiPe71bWBEF+XZZDg="; # NOTE: UPDATE
  };
  pythonRelaxDeps = true;
  propagatedBuildInputs = with pkgs.python3Packages; [
    setuptools
    click
    openai
    chromadb
    requests
    rich
    sqlite-utils
    beautifulsoup4
    yt-dlp
    webvtt-py
  ];
  #nativeBuildInputs = with pkgs; [ pkg-config ];
  #buildInputs = with pkgs; [ alsa-lib.dev openssl ];
  meta = with pkgs.lib; {
    description = "Search all of a YouTube channel from the command line";
    homepage = "https://github.com/NotJoeMartinez/yt-fts";
    license = with licenses; [ mit ];
    #maintainers = with maintainers; [ ];
    mainProgram = "yt_fts";
  };
}
