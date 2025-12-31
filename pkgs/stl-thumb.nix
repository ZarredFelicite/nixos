{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  libX11,
  libXcursor,
  libXrandr,
  libXi
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "stl-thumb";
  version = "v0.5.0-dec70d8";
  src = fetchFromGitHub {
    owner = "unlimitedbacon";
    repo = pname;
    rev = "dec70d8d8cfbb6c635ecbd8c1f3d3959ea42f5e8"; # NOTE: UPDATE
    sha256 = "sha256-xF3sl3LOno3MeLK11cP48KlkbQDIZ/7Ax17dD8DL+po="; # NOTE: UPDATE
  };

  doCheck = false;

  cargoHash = "sha256-UqyRlcrvn0G7H4XeVKRPmFBx2IDdAo/1YyZlKxvpCxI=";

  #   # libs are loaded dynamically; make make sure we'll find them
  #  postFixup = with pkgs; ''
  #    patchelf \
  #      --add-needed ${xorg.libX11}/lib/libX11.so \
  #      --add-needed ${wayland}/lib/libwayland-client.so \
  #      --add-needed ${libGL}/lib/libEGL.so \
  #      $out/bin/stl-thumb
  #  '';
  postInstall = ''
    mkdir $out/include
    cp libstl_thumb.h $out/include
    mkdir -p $out/thumbnailers
    mkdir -p $out/mime/packages
    cp stl-thumb.thumbnailer $out/thumbnailers/stl-thumb.thumbnailer
    cp stl-thumb-mime.xml $out/mime/packages/stl-thumb-mime.xml
  '';

  meta = with lib; {
    description = "Thumbnail generator for STL files";
    homepage = "https://github.com/unlimitedbacon/stl-thumb";
    license = licenses.mit;
    maintainers = [];
  };
  buildInputs = with pkgs; [
    fontconfig
    libX11
    expat
  ];
  propagatedBuildInputs = [
    libXcursor
    libXrandr
    libXi
  ];
  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
  ];
}
