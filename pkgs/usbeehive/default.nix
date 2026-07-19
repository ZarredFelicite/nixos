{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, systemdLibs
}:

rustPlatform.buildRustPackage rec {
  pname = "usbeehive";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "abrauchli";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-5aqEqt0zwzG4O+roq0p4vs59z7s2ERPE+FzyW9waegw=";
  };

  cargoHash = "sha256-YX72/E1N59U6EU54SWpL8Ew/eMelAjnBF7xqpLYCNIo=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ systemdLibs ];

  meta = {
    description = "Inspect USB and USB-C capabilities and charging diagnostics on Linux";
    homepage = "https://github.com/abrauchli/usbeehive";
    license = lib.licenses.mit;
    mainProgram = "usbeehive";
    platforms = lib.platforms.linux;
  };
}
