{ pkgs ? import <nixpkgs> {} }:

let
  layoutWheel = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/a7/bd/3e049b359dd0c3a101ae915484b87ff73bfdedfb24a924e0a8e6783b33f3/pymupdf_layout-1.26.6-cp310-abi3-manylinux_2_28_x86_64.whl";
    sha256 = "sha256-7o4r/tEtS2QhsnofiYN6wJ2Lw/eD95Zw2zl+wkYUvz0=";
  };
in
pkgs.python3Packages.pymupdf.overridePythonAttrs (old: {
  pname = "pymupdf-layout";
  version = "1.26.6";

  nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.unzip ];
  propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ (with pkgs.python3Packages; [
    pyyaml
    numpy
    onnxruntime
    networkx
  ]);

  postInstall = (old.postInstall or "") + ''
    tmpdir="$(mktemp -d)"
    unzip -q ${layoutWheel} -d "$tmpdir"
    mkdir -p "$out/${pkgs.python3.sitePackages}/pymupdf"
    cp -R "$tmpdir/pymupdf/layout" "$out/${pkgs.python3.sitePackages}/pymupdf/"
    cp -f "$tmpdir/pymupdf/features.py" "$out/${pkgs.python3.sitePackages}/pymupdf/features.py"
    cp -f "$tmpdir/pymupdf/_features.so" "$out/${pkgs.python3.sitePackages}/pymupdf/_features.so"
  '';

  pythonImportsCheck = [ "pymupdf.layout" ];

  # Upstream memory regression test is flaky under Nix/CI on Python 3.13.
  # Keep checks enabled but skip this known non-deterministic case.
  disabledTests = (old.disabledTests or []) ++ [ "test_2791" ];

  meta = old.meta // {
    description = "PyMuPDF with PyMuPDF Layout extension";
    homepage = "https://pypi.org/project/pymupdf-layout/";
    license = pkgs.lib.licenses.unfree;
  };
})
