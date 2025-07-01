{ pkgs ? import <nixpkgs> {} }:

pkgs.python3.pkgs.buildPythonPackage rec {
  # TODO: yt_feed database needs to be migrated if reader is updated
  pname = "reader";
  version = "3.18";
  format = "pyproject";
  src = pkgs.python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-tt9vqGrsHP/3UgEHzmnjNW8UMdYm6fyR3LSGxcyhkdg=";
  };
  propagatedBuildInputs = with pkgs; [
    python3Packages.setuptools
    python3Packages.feedparser
    python3Packages.requests
    python3Packages.werkzeug
    python3Packages.iso8601
    python3Packages.typing-extensions
    python3Packages.beautifulsoup4
  ];
  meta = with pkgs.lib; {
    description = "A Python feed reader library.";
    homepage = "https://github.com/lemon24/reader";
    #license = with licenses; [ bsd ];
    #maintainers = with maintainers; [ ];
    mainProgram = "reader";
  };
}
