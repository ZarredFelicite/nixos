{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rgd";
  version = "1.2.2";

  src = pkgs.fetchFromGitHub {
    owner = "Rolv-Apneseth";
    repo = pname;
    rev = "v${version}"; # NOTE: UPDATE
    sha256 = "sha256-wnUn/MmbXTvwxF4QiWzcLWNPT+XUoKbFwl0l+v51CSE="; # NOTE: UPDATE
  };

  cargoHash = "sha256-a4MqS1AUcXhlZGImeqzUnDVxYuje5dm4SaebeEPjlEE=";

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ sqlite ];

  meta = with pkgs.lib; {
    description = "Installed game detection utility for Linux";
    homepage = "https://github.com/rolv-apneseth/rgd";
    license = with licenses; [ agpl3Only ];
    maintainers = with maintainers; [ ];  # Add yourself if you want
    mainProgram = "rgd";
  };
}