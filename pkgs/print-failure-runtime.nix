{ lib
, python313Packages
, python313
, fetchurl
}:
let
  litert = python313Packages.buildPythonPackage rec {
    pname = "ai-edge-litert";
    version = "2.2.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/38/ab/5dc29f748a835410274d6742cc9cff6af9d296331ac00f45076cdf10c87b/ai_edge_litert-2.2.0-cp313-cp313-manylinux_2_27_x86_64.whl";
      hash = "sha256-" + "RvVqc+O9YgM0URDF1Y5ZvuLlTiB9QMVppVbJqkFBjAo=";
    };
    propagatedBuildInputs = with python313Packages; [
      flatbuffers
      ml-dtypes
      numpy
      protobuf
      tqdm
      typing-extensions
    ];
    doCheck = false;
    meta = {
      description = "Google LiteRT Python runtime (CPU)";
      homepage = "https://ai.google.dev/edge/litert";
      license = lib.licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };
  model = fetchurl {
    name = "print-failure-model.tflite";
    url = "https://raw.githubusercontent.com/CookiezRGood/klipper-print-failure-detection/main/model.tflite";
    hash = "sha256-" + "jmk80NIcwUfZ5LH4t9MVm4ycXxof6Wkvgg8LzvPnEBs=";
  };
  python = python313.withPackages (ps: [
    litert
    ps.numpy
    ps.opencv4
    ps.requests
  ]);
in
{
  inherit python model;
}
