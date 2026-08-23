let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  fixtureSource = pkgs.runCommand "private-asr-test-source" { } ''
    mkdir -p "$out"
    printf '%s\n' 'test' > "$out/SERVICE_VERSION"
    touch "$out/nemotron_batch_api.py"
    touch "$out/nemotron_stream_runner.py"
    touch "$out/parakeet_batch_server.py"
  '';

  checkerPython = pkgs.writeShellScript "private-asr-checker-python" ''
    test "$1" = -c
    exec ${pkgs.python3}/bin/python -c \
      'import ctypes; ctypes.CDLL("libuv.so.1")'
  '';

  parakeetEnvironment = pkgs.runCommand "parakeet-nemo-2.3.1-test-environment" { } ''
    mkdir -p "$out/bin"
    ln -s ${checkerPython} "$out/bin/python"
    printf '%s\n' 'parakeet-nemo-2.3.1-torch-2.7.1' > "$out/ASR_ENVIRONMENT"
  '';

  servicePackage = pkgs.callPackage ../pkgs/asr-services.nix {
    src = fixtureSource;
    sourceRevision = "0000000000000000000000000000000000000000";
    serviceVersion = "test";
    nemotronPython = "${parakeetEnvironment}/bin/python";
    parakeetPython = "${parakeetEnvironment}/bin/python";
    nemotronEnvironmentMarker = "${parakeetEnvironment}/ASR_ENVIRONMENT";
    parakeetEnvironmentMarker = "${parakeetEnvironment}/ASR_ENVIRONMENT";
  };
in
pkgs.runCommand "private-asr-environment-check" { } ''
  if env -i ${parakeetEnvironment}/bin/python -c ignored; then
    echo "test native library unexpectedly resolved without the ASR runtime environment" >&2
    exit 1
  fi
  env -i ${servicePackage}/bin/check-parakeet-asr-environment
  touch "$out"
''
