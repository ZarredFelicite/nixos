{
  pkgs ? import <nixpkgs> {},
  #lib,
#python3Packages,
#fetchPypi,
#ffmpeg-headless,
#rtmpdump,
#atomicparsley,
  atomicparsleySupport ? true,
  ffmpegSupport ? true,
  rtmpSupport ? true,
  withAlias ? false, # Provides bin/youtube-dl for backcompat
#update-python-libraries,
}:
 pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "yt-dlp";
  # The websites yt-dlp deals with are a very moving target. That means that
  # downloads break constantly. Because of that, updates should always be backported
  # to the latest stable release.
  version = "2025.3.25";
  pyproject = true;

  src = pkgs.fetchPypi {
    inherit version;
    pname = "yt_dlp";
    hash = "sha256-x/QlFvnfMdrvU8yiWQI5QBzzHbfE6spnZnz9gvLgric=";
  };

  build-system = with pkgs.python3.pkgs; [
    hatchling
  ];

  # expose optional-dependencies, but provide all features
  dependencies = pkgs.lib.flatten (pkgs.lib.attrValues optional-dependencies);

  optional-dependencies = {
    default = with pkgs.python3.pkgs; [
      brotli
      certifi
      mutagen
      pycryptodomex
      requests
      urllib3
      websockets
    ];
    curl-cffi = [ pkgs.python3.pkgs.curl-cffi ];
    secretstorage = with pkgs.python3.pkgs; [
      cffi
      secretstorage
    ];
  };

  pythonRelaxDeps = [ "websockets" ];

  # Ensure these utilities are available in $PATH:
  # - ffmpeg: post-processing & transcoding support
  # - rtmpdump: download files over RTMP
  # - atomicparsley: embedding thumbnails
  makeWrapperArgs =
    let
      packagesToBinPath =
        [ ]
        ++ pkgs.lib.optional atomicparsleySupport pkgs.atomicparsley
        ++ pkgs.lib.optional ffmpegSupport pkgs.ffmpeg-headless
        ++ pkgs.lib.optional rtmpSupport pkgs.rtmpdump;
    in
    pkgs.lib.optionals (packagesToBinPath != [ ]) [
      ''--prefix PATH : "${pkgs.lib.makeBinPath packagesToBinPath}"''
    ];

  setupPyBuildFlags = [
    "build_lazy_extractors"
  ];

  # Requires network
  doCheck = false;

  postInstall = pkgs.lib.optionalString withAlias ''
    ln -s "$out/bin/yt-dlp" "$out/bin/youtube-dl"
  '';

  passthru.updateScript = [
    pkgs.update-python-libraries
    (toString ./.)
  ];

  meta = with pkgs.lib; {
    homepage = "https://github.com/yt-dlp/yt-dlp/";
    description = "Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)";
    longDescription = ''
      yt-dlp is a youtube-dl fork based on the now inactive youtube-dlc.

      youtube-dl is a small, Python-based command-line program
      to download videos from YouTube.com and a few more sites.
      youtube-dl is released to the public domain, which means
      you can modify it, redistribute it or use it however you like.
    '';
    changelog = "https://github.com/yt-dlp/yt-dlp/blob/HEAD/Changelog.md";
    license = licenses.unlicense;
    maintainers = with maintainers; [
      SuperSandro2000
      donteatoreo
    ];
    mainProgram = "yt-dlp";
  };
}
