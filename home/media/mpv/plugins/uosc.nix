{ stdenvNoCC, lib, fetchFromGitHub, makeFontsConf }:

stdenvNoCC.mkDerivation (finalAttrs: {
  name = "uosc";

  src = fetchFromGitHub {
    owner = "tomasklaen";
    repo = "uosc";
    rev = "af04ab1e746b45ffdecb58663e6ecc35270a6ad7";
    hash = "sha256-GMUDn8TdgQymWxIJp6ckbKZW4Ubj2JJFM/Paanq9V54=";
  };

  postPatch = ''
    substituteInPlace scripts/uosc/main.lua \
      --replace "mp.find_config_file('scripts')" "\"$out/share/mpv/scripts\""
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mpv/
    cp -r scripts $out/share/mpv
    cp -r fonts $out/share
    cp -r src/textures $out/share

    runHook postInstall
  '';

  passthru.scriptName = "uosc.lua";
  # the script uses custom "texture" fonts as the background for ui elements.
  # In order for mpv to find them, we need to adjust the fontconfig search path.
  passthru.extraWrapperArgs = [
    "--set"
    "FONTCONFIG_FILE"
    (toString (makeFontsConf {
      fontDirectories = [
        "${finalAttrs.finalPackage}/share/fonts"
        "${finalAttrs.finalPackage}/share/textures"
      ];
    }))
  ];

  meta = with lib; {
    description = "Feature-rich minimalist proximity-based UI for MPV player";
    homepage = "https://github.com/tomasklaen/uosc";
    license = licenses.gpl3Only;
    maintainers = with lib.maintainers; [ apfelkuchen6 ];
  };
})
