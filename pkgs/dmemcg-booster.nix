{ lib, rustPlatform, fetchFromGitHub, dbus, pkg-config }:

rustPlatform.buildRustPackage rec {
  pname = "dmemcg-booster";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "evlaV";
    repo = "dmemcg";
    rev = "9983fdee95c4705e8481f5b5eb4f5edbd2606054";
    hash = "sha256-g4rm8Oh1vDuuK2VXNs5A0HANyGWuY80wM0v69LCphf0=";
  };

  cargoHash = "sha256-T0z191ssrkxJB/x3l6wvXJ70UMEmLBD9e2ZjNTBrk+Y=";

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
  buildInputs = [ dbus ];

  meta = {
    description = "Enable and configure dmem cgroup limits for DRM device memory";
    homepage = "https://github.com/evlaV/dmemcg";
    license = lib.licenses.mit;
    mainProgram = "dmemcg-booster";
  };
}
