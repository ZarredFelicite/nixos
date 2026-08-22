{
  lib,
  pkgs,
  stdenvNoCC,
  src,
  sourceRevision,
  serviceVersion,
  nemotronPython,
  parakeetPython,
  nemotronEnvironmentMarker,
  parakeetEnvironmentMarker,
}:
let
  runtimeLibraries = with pkgs; [
    cudaPackages.cuda_cudart
    cudaPackages.cudatoolkit
    stdenv.cc.cc.lib
    libuv
    zlib
    portaudio
    xorg.libX11
    xorg.libXtst
  ];
  libraryPath = lib.makeLibraryPath runtimeLibraries;
in
stdenvNoCC.mkDerivation {
  pname = "private-asr-services";
  version = builtins.substring 0 12 sourceRevision;
  inherit src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm0444 SERVICE_VERSION "$out/share/private-asr-services/SERVICE_VERSION"
    install -Dm0444 auth_token.py "$out/libexec/private-asr-services/auth_token.py"
    install -Dm0444 nemotron_batch_api.py "$out/libexec/private-asr-services/nemotron_batch_api.py"
    install -Dm0444 nemotron_stream_runner.py "$out/libexec/private-asr-services/nemotron_stream_runner.py"
    install -Dm0444 parakeet_batch_server.py "$out/libexec/private-asr-services/parakeet_batch_server.py"

    mkdir -p "$out/bin"
    install -m0555 /dev/stdin "$out/bin/nemotron-asr-service" <<SCRIPT
#!${pkgs.runtimeShell}
export ASR_SOURCE_REVISION='${sourceRevision}'
export PYTHONDONTWRITEBYTECODE=1
export CUDA_PATH='${pkgs.cudaPackages.cudatoolkit}'
export XLA_FLAGS='--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}'
export LD_LIBRARY_PATH='${libraryPath}:/run/opengl-driver/lib:/run/opengl-driver-32/lib'
export PATH='${lib.makeBinPath [ pkgs.ffmpeg pkgs.coreutils ]}'
exec '${nemotronPython}' '$out/libexec/private-asr-services/nemotron_stream_runner.py' --expected-service-version '${serviceVersion}' "\$@"
SCRIPT

    install -m0555 /dev/stdin "$out/bin/parakeet-batch-service" <<SCRIPT
#!${pkgs.runtimeShell}
export ASR_SOURCE_REVISION='${sourceRevision}'
export PYTHONDONTWRITEBYTECODE=1
export CUDA_PATH='${pkgs.cudaPackages.cudatoolkit}'
export XLA_FLAGS='--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}'
export LD_LIBRARY_PATH='${libraryPath}:/run/opengl-driver/lib:/run/opengl-driver-32/lib'
export PATH='${lib.makeBinPath [ pkgs.ffmpeg pkgs.coreutils ]}'
exec '${parakeetPython}' '$out/libexec/private-asr-services/parakeet_batch_server.py' --expected-service-version '${serviceVersion}' "\$@"
SCRIPT

    install -m0555 /dev/stdin "$out/bin/check-asr-health" <<'SCRIPT'
#!${pkgs.python3}/bin/python
import argparse
import json
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'libexec/private-asr-services'))
from auth_token import load_auth_token

parser = argparse.ArgumentParser()
parser.add_argument('--url', required=True)
parser.add_argument('--auth-token-file')
args = parser.parse_args()
try:
    headers = {}
    if args.auth_token_file:
        headers['Authorization'] = 'Bearer ' + load_auth_token(args.auth_token_file).decode('utf-8')
    request = urllib.request.Request(args.url, headers=headers)
    with urllib.request.urlopen(request, timeout=3) as response:
        payload = json.loads(response.read(4096))
    if payload.get('status') != 'ok':
        raise RuntimeError
except Exception:
    print('ASR health probe failed', file=sys.stderr)
    raise SystemExit(1)
SCRIPT

    install -m0555 /dev/stdin "$out/bin/check-nemotron-asr-environment" <<'SCRIPT'
#!${pkgs.runtimeShell}
set -eu
marker='${nemotronEnvironmentMarker}'
expected='nemotron35-transformers-5.14.1-torch-2.7.1'
[ -x '${nemotronPython}' ] || { echo 'Nemotron ASR interpreter is not provisioned' >&2; exit 1; }
[ -r "$marker" ] || { echo 'Nemotron ASR environment marker is missing' >&2; exit 1; }
IFS= read -r actual < "$marker"
[ "$actual" = "$expected" ] || { echo 'Nemotron ASR environment marker mismatch' >&2; exit 1; }
exec '${nemotronPython}' -c 'import fastapi, numpy, torch, transformers; assert transformers.__version__ == "5.14.1"; assert torch.__version__.split("+")[0] == "2.7.1"'
SCRIPT

    install -m0555 /dev/stdin "$out/bin/check-parakeet-asr-environment" <<'SCRIPT'
#!${pkgs.runtimeShell}
set -eu
marker='${parakeetEnvironmentMarker}'
expected='parakeet-nemo-2.3.0-torch-2.7.1'
[ -x '${parakeetPython}' ] || { echo 'Parakeet ASR interpreter is not provisioned' >&2; exit 1; }
[ -r "$marker" ] || { echo 'Parakeet ASR environment marker is missing' >&2; exit 1; }
IFS= read -r actual < "$marker"
[ "$actual" = "$expected" ] || { echo 'Parakeet ASR environment marker mismatch' >&2; exit 1; }
exec '${parakeetPython}' -c 'import importlib.metadata as m, fastapi, nemo.collections.asr, numpy, torch; assert m.version("nemo_toolkit") == "2.3.0"; assert torch.__version__.split("+")[0] == "2.7.1"'
SCRIPT

    runHook postInstall
  '';

  passthru = {
    inherit sourceRevision serviceVersion;
  };

  meta = {
    description = "Pinned private Nemotron streaming and Parakeet batch ASR service sources";
    platforms = [ "x86_64-linux" ];
  };
}
