{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rgd";
  version = "1.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "Rolv-Apneseth";
    repo = pname;
    rev = "v${version}"; # NOTE: UPDATE
    sha256 = "sha256-GZpG+jnoyL9/6A1tBF0fqnVkn47tAkNUyzA2epn4gR4="; # NOTE: UPDATE
  };

  cargoHash = "sha256-3kCU1wHDcbgcY7sBtuTkjG8HR4AqRZqZWziSlD33lcU=";

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