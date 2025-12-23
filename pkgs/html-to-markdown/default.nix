{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
}:

let
  version = "2.3.2";
in
buildGoModule {
  pname = "html-to-markdown";
  inherit version;

  src = fetchFromGitHub {
    owner = "JohannesKaufmann";
    repo = "html-to-markdown";
    rev = "v${version}"; # NOTE: UPDATE
    hash = "sha256-3Ww28RXFP9Su2+MJYufCCAjseWaF2JgEoigwY93KcqM="; # NOTE: UPDATE
  };

  vendorHash = "sha256-nMb4moiTMzLSWfe8JJwlH6H//cOHbKWfnM9SM366ey0=";

  meta = with lib; {
    homepage = "https://github.com/JohannesKaufmann/html-to-markdown";
    description = "Convert HTML to Markdown.";
    license = licenses.mit;
    maintainers = with maintainers; [ zsenai ];
  };
}
