{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "lowfi";
  version = "1.5.6";

  src = pkgs.fetchFromGitHub {
    owner = "talwat";
    repo = pname;
    rev = version;
    sha256 = "sha256-pfvTOoWsXukZTfev9+Ifcp3YYIqtYZgmEVPHuqD4IsM="; # NOTE: UPDATE
  };

  cargoHash = "sha256-TGj3xH18xanhA25r+gTtLPa7KQKS9WEyGl412pnFZdw=";

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ alsa-lib.dev openssl ];
  buildFeatures = [ "mpris" ];

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
