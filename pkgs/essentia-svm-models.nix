{ stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "essentia-svm-models";
  version = "2.1_beta5";

  src = fetchurl {
    url = "https://essentia.upf.edu/svm_models/essentia-extractor-svm_models-v2.1_beta5.tar.gz";
    hash = "sha256-3ILxMbLNXkJWWaKd3Zj9ePNniEZ19xuGVBOTSKHIzAE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/essentia/svm_models
    cp -r . $out/share/essentia/svm_models
    runHook postInstall
  '';
}
