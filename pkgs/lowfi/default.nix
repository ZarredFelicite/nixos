{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "lowfi";
  version = "2.0.7";

  src = pkgs.fetchFromGitHub {
    owner = "talwat";
    repo = pname;
    rev = version;
    sha256 = "sha256-/GU1e01AjeS4AVBvQUi/GZKeQ0X+hnmt+kyW3gp0jgg="; # NOTE: UPDATE
  };

  cargoHash = "sha256-iuC0YBhzK8mATJekTgBDMiXATRdThem35p5AyDXQNGo=";

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ alsa-lib.dev openssl ];
  buildFeatures = [ "mpris" ];
  # This test downloads tracks; the Nix build sandbox cannot access the network.
  checkFlags = [ "--skip" "tests::tracks::list::download" ];

  #  preFixup = ''
  #    installManPage $releaseDir/build/ripgrep-*/out/rg.1
  #
  #    installShellCompletion $releaseDir/build/ripgrep-*/out/rg.{bash,fish}
  #    installShellCompletion --zsh complete/_rg
  #  '';

  #doInstallCheck = true;
  #installCheckPhase = ''
  #  file="$(mktemp)"
  #  echo "abc\nbcd\ncde" > "$file"
  #  $out/bin/rg -N 'bcd' "$file"
  #  $out/bin/rg -N 'cd' "$file"
  #'' + lib.optionalString withPCRE2 ''
  #  echo '(a(aa)aa)' | $out/bin/rg -P '\((a*|(?R))*\)'
  #'';

  meta = with pkgs.lib; {
    description = "An extremely simple lofi player.";
    homepage = "https://github.com/talwat/lowfi";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ tailhook globin ma27 zowoq ];
    mainProgram = "lowfi";
  };
}
