{ lib
, fetchFromGitHub
, python3
, deno
, ffmpeg-headless
, rtmpdump
, atomicparsley
, pandoc
, installShellFiles
}:

let
  atomicparsleySupport = true;
  ffmpegSupport = true;
  javascriptSupport = true;
  rtmpSupport = true;
  withAlias = false; # Provides bin/youtube-dl for backcompat
in

python3.pkgs.buildPythonPackage rec {
  pname = "yt-dlp";
  # The websites yt-dlp deals with are a very moving target. That means that
  # downloads break constantly. Because of that, updates should always be backported
  # to the latest stable release.
  version = "unstable-2026-01-29";
  rev = "309b03f2ad09fcfcf4ce81e757f8d3796bb56add";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    inherit rev;
    hash = "sha256-Lg/b3LWMeKwiU14GiH+oH2H/e9ysUgICOEzGLqyFFMU=";
  };

  postPatch = ''
    substituteInPlace yt_dlp/version.py \
      --replace-fail "UPDATE_HINT = None" 'UPDATE_HINT = "Nixpkgs/NixOS likely already contain an updated version.\n       To get it run nix-channel --update or nix flake update in your config directory."'
    ${lib.optionalString javascriptSupport ''
      # deno is required for full YouTube support (since 2025.11.12).
      # This makes yt-dlp find deno even if it is used as a python dependency, i.e. in kodiPackages.sendtokodi.
      # Crafted so people can replace deno with one of the other JS runtimes.
      substituteInPlace yt_dlp/utils/_jsruntime.py \
        --replace-fail "path = _determine_runtime_path(self._path, '${deno.meta.mainProgram}')" "path = '${lib.getExe deno}'"
    ''}
  '';

  build-system = with python3.pkgs; [ hatchling ];

  nativeBuildInputs = [
    installShellFiles
    pandoc
  ];

  # expose optional-dependencies, but provide all features
  dependencies = lib.flatten (lib.attrValues optional-dependencies);

  optional-dependencies = {
    default = with python3.pkgs; [
      brotli
      certifi
      mutagen
      pycryptodomex
      requests
      urllib3
      websockets
      yt-dlp-ejs
    ];
    curl-cffi = [ python3.pkgs.curl-cffi ];
    secretstorage = with python3.pkgs; [
      cffi
      secretstorage
    ];
  };

  pythonRelaxDeps = [ "websockets" ];

  preBuild = ''
    python devscripts/make_lazy_extractors.py
  '';

  postBuild = ''
    python devscripts/prepare_manpage.py yt-dlp.1.temp.md
    pandoc -s -f markdown-smart -t man yt-dlp.1.temp.md -o yt-dlp.1
    rm yt-dlp.1.temp.md

    mkdir -p completions/{bash,fish,zsh}
    python devscripts/bash-completion.py completions/bash/yt-dlp
    python devscripts/zsh-completion.py completions/zsh/_yt-dlp
    python devscripts/fish-completion.py completions/fish/yt-dlp.fish
  '';

  # Ensure these utilities are available in $PATH:
  # - ffmpeg: post-processing & transcoding support
  # - rtmpdump: download files over RTMP
  # - atomicparsley: embedding thumbnails
  makeWrapperArgs =
    let
      packagesToBinPath =
        lib.optional atomicparsleySupport atomicparsley
        ++ lib.optional ffmpegSupport ffmpeg-headless
        ++ lib.optional rtmpSupport rtmpdump;
    in
    lib.optionals (packagesToBinPath != [ ]) [
      ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"''
    ];

  checkPhase = ''
    # Check for "unsupported" string in yt-dlp -v output.
    output=$($out/bin/yt-dlp -v 2>&1 || true)
    if echo $output | grep -q "unsupported"; then
      echo "ERROR: Found \"unsupported\" string in yt-dlp -v output."
      exit 1
    fi
  '';

  postInstall = ''
    installManPage yt-dlp.1

    installShellCompletion \
      --bash completions/bash/yt-dlp \
      --fish completions/fish/yt-dlp.fish \
      --zsh completions/zsh/_yt-dlp

    install -Dm644 Changelog.md README.md -t "$out/share/doc/yt_dlp"
  ''
  + lib.optionalString withAlias ''
    ln -s "$out/bin/yt-dlp" "$out/bin/youtube-dl"
  '';

  passthru = {
    updateScript = null;
  };

  meta = {
    changelog = "https://github.com/yt-dlp/yt-dlp/blob/${rev}/Changelog.md";
    description = "Feature-rich command-line audio/video downloader";
    homepage = "https://github.com/yt-dlp/yt-dlp/";
    license = lib.licenses.unlicense;
    longDescription = ''
      yt-dlp is a youtube-dl fork based on the now inactive youtube-dlc.

      youtube-dl is a small, Python-based command-line program
      to download videos from YouTube.com and a few more sites.
      youtube-dl is released to the public domain, which means
      you can modify it, redistribute it or use it however you like.
    '';
    mainProgram = "yt-dlp";
    maintainers = with lib.maintainers; [
      SuperSandro2000
      FlameFlag
    ];
  };
}
