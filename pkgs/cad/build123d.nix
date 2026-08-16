{ pkgs, lib }:
assert pkgs.stdenv.hostPlatform.system == "x86_64-linux";
let
  python = pkgs.python313;
  pyPkgs = python.pkgs;

  # build123d's OCP binding is only available as a prebuilt CPython 3.13
  # wheel. Keep the wheel and all Python sources pinned here rather than
  # importing the upstream build123d-nix flake into this configuration.
  installWheel = ''
    runHook preInstall
    mkdir -p "$out/${python.sitePackages}"
    ${python.interpreter} -m zipfile -e dist/*.whl "$out/${python.sitePackages}"
    runHook postInstall
  '';

  ocpWheel = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/f3/31/82baf17406c0a13f2eb98c1d46d09a640795fc7d6b373a69bc5f44344db3/cadquery_ocp_novtk-7.9.3.1.1-cp313-cp313-manylinux_2_31_x86_64.whl";
    hash = "sha256-/80E1O+gh9OqlCNgAgJloawOEkB717z+s35wtNHuct8=";
  };

  lib3mfWheel = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/88/83/8b987ba95ac0ed9cc7e9c407a579bf43eff6349b1792b4a66c992ce4f76b/lib3mf-2.5.0-py3-none-manylinux2014_x86_64.whl";
    hash = "sha256-tMAAM8R8/qyTt9qgaftG6N6kOR1VIrec1un2r3XjMBM=";
  };

  ocpProxy = pyPkgs.buildPythonPackage {
    pname = "cadquery-ocp-proxy";
    version = "7.9.3.1.1";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/30/c0/04e9363a99fee892de2776820e3dcf04f8825b6edc9580efe3416c9465a7/cadquery_ocp_proxy-7.9.3.1.1-py3-none-any.whl";
      hash = "sha256-ykFk7EtUlW2fw+aMZ9VVtUhsuWPC9x4Y3wBboWuSHJE=";
    };
    doCheck = false;
    installPhase = installWheel;
    pythonImportsCheck = [ "cadquery_ocp_proxy" ];
    meta = with lib; {
      description = "Version marker for the CadQuery OpenCASCADE bindings";
      homepage = "https://github.com/CadQuery/OCP";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  cadqueryOcp = pyPkgs.buildPythonPackage {
    pname = "cadquery-ocp-novtk";
    version = "7.9.3.1.1";
    format = "wheel";
    src = ocpWheel;
    doCheck = false;
    propagatedBuildInputs = [ ocpProxy ];
    dontPatchELF = true;
    dontStrip = true;
    buildInputs = [
      pkgs.libGL
      pkgs.libx11
      pkgs.expat
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
    ];
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    installPhase = installWheel;
    pythonImportsCheck = [ "OCP" ];
    meta = with lib; {
      description = "Python bindings for the OpenCASCADE geometry kernel";
      homepage = "https://github.com/CadQuery/OCP";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  };

  lib3mf = pyPkgs.buildPythonPackage {
    pname = "lib3mf";
    version = "2.5.0";
    format = "wheel";
    src = lib3mfWheel;
    doCheck = false;
    dontPatchELF = true;
    dontStrip = true;
    # lib3mf.so has an unbundled libstdc++ dependency. Patch its RUNPATH so
    # importing lib3mf works before any other extension has loaded libstdc++.
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    installPhase = installWheel;
    pythonImportsCheck = [ "lib3mf" ];
    meta = with lib; {
      description = "Python bindings for the 3MF file format library";
      homepage = "https://github.com/3MFConsortium/lib3mf";
      license = licenses.bsd3;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  };

  mkPySdist = {
    src,
    pname,
    version,
    propagatedBuildInputs ? [ ],
    build-system ? [ pyPkgs.setuptools pyPkgs.wheel ],
    pythonImportsCheck ? [ pname ],
    postPatch ? "",
    meta ? { },
  }:
    pyPkgs.buildPythonPackage {
      inherit pname version src propagatedBuildInputs build-system pythonImportsCheck postPatch meta;
      pyproject = true;
      doCheck = false;
      dontCheckRuntimeDeps = true;
      SETUPTOOLS_SCM_PRETEND_VERSION = version;
    };

  ocpsvg = mkPySdist {
    pname = "ocpsvg";
    version = "0.6.0";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/89/48/f121f459dc6e184ca2ee99b8fba0a2f51b1ef710d829eafb43d9acd1100d/ocpsvg-0.6.0.tar.gz";
      hash = "sha256-8I2kNHzJDs01ZTlem9pXRtRquKr9aiaBuwOpwyG1QDk=";
    };
    build-system = [ pyPkgs.setuptools pyPkgs.wheel pyPkgs."setuptools-scm" ];
    propagatedBuildInputs = [ ocpProxy pyPkgs.svgelements cadqueryOcp ];
    meta = with lib; {
      description = "SVG import and export helpers for OCP geometry";
      homepage = "https://github.com/gumyr/ocpsvg";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  ocpGordon = mkPySdist {
    pname = "ocp-gordon";
    version = "0.2.2";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/87/b4/01487c528cdaef6c4b795f633bece21de465d589a6852474df7ea05066b9/ocp_gordon-0.2.2.tar.gz";
      hash = "sha256-QDwmKKjem2lPGOzS2YwZVtOq98hp9y41VlddM9jfA/E=";
    };
    build-system = [ pyPkgs.setuptools pyPkgs.wheel pyPkgs."setuptools-scm" ];
    propagatedBuildInputs = [ ocpProxy pyPkgs.numpy pyPkgs.scipy cadqueryOcp ];
    pythonImportsCheck = [ "ocp_gordon" ];
    meta = with lib; {
      description = "Gordon surface construction for OCP geometry";
      homepage = "https://github.com/gongfan99/ocp_gordon";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  trianglesolver = pyPkgs.buildPythonPackage {
    pname = "trianglesolver";
    version = "1.2";
    format = "setuptools";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/6f/52/18f909fcc652b2a4de75a274aa3de0d567a5d592b13d57e65b76c550bdf1/trianglesolver-1.2.tar.gz";
      hash = "sha256-SvGKreV51cDWQ4mz5lrq8Gz/JjGXYszYWeMmhVmnauo=";
    };
    nativeBuildInputs = [ pyPkgs.setuptools ];
    doCheck = false;
    pythonImportsCheck = [ "trianglesolver" ];
    meta = with lib; {
      description = "Solve triangles from side and angle constraints";
      homepage = "https://pypi.org/project/trianglesolver/";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

  ocpTessellate = mkPySdist {
    pname = "ocp-tessellate";
    version = "3.4.1";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/26/93/5497c58730e5103a12a1e1678c95869067bb1bdfa361d878183ef4dfc15b/ocp_tessellate-3.4.1.tar.gz";
      hash = "sha256-Y/84fWW3qNmgpUloq6dCC/2x029ii2KImpgcVVjxG5A=";
    };
    propagatedBuildInputs = [
      cadqueryOcp
      pyPkgs.numpy
      pyPkgs.webcolors
      pyPkgs.cachetools
      pyPkgs.imagesize
    ];
    pythonImportsCheck = [ "ocp_tessellate" ];
    meta = with lib; {
      description = "Web tessellation and visualization helpers for OCP";
      homepage = "https://github.com/bernhard-42/ocp-tessellate";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  threejsMaterials = mkPySdist {
    pname = "threejs-materials";
    version = "1.2.3";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/f2/93/6b0a674c3a268c4804c1866b12475bf3b286689cf85b8f375b9112798f5b/threejs_materials-1.2.3.tar.gz";
      hash = "sha256-ids0HasKAideWX76l82XmCMHRlS8ori6MEKjN4rLmQE=";
    };
    propagatedBuildInputs = [
      pyPkgs.pillow
      pyPkgs.pygltflib
      pyPkgs.requests
      pyPkgs.platformdirs
      pyPkgs.numpy
    ];
    pythonImportsCheck = [ "threejs_materials" ];
    meta = with lib; {
      description = "Three.js material definitions and utilities";
      homepage = "https://github.com/bernhard-42/threejs-materials";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  bdMaterials = mkPySdist {
    pname = "bd-materials";
    version = "0.2.4";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/19/28/940946d9cc9f1489c3d3f0c6a8f2acaf2a1240ba1cf24df69ac385f9c0d7/bd_materials-0.2.4.tar.gz";
      hash = "sha256-2uqClTwYzvBL6fhRnHVRjSMN8beEV/SpKn2ocl5TO7g=";
    };
    # nixpkgs currently provides setuptools 80.x; this package's metadata
    # needlessly requires 81 although it builds and imports on 80.x.
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail 'setuptools>=81' 'setuptools>=80'
    '';
    propagatedBuildInputs = [ threejsMaterials pyPkgs.webcolors ];
    pythonImportsCheck = [ "bd_materials" ];
    meta = with lib; {
      description = "Typical-value engineering materials for build123d";
      homepage = "https://github.com/bernhard-42/bd_materials";
      # Upstream 0.2.4 does not declare a license or ship a license file.
      license = [ ];
      platforms = [ "x86_64-linux" ];
    };
  };

  build123d = pyPkgs.buildPythonPackage {
    pname = "build123d";
    version = "0.11.1";
    src = pkgs.fetchFromGitHub {
      owner = "gumyr";
      repo = "build123d";
      rev = "8371dca80715d041872929e2163ab8e5fb5a2864";
      hash = "sha256-Ua5njNi82iMJQciPSeg+fkdQlnVtLPaNW3JDjiJDDNo=";
    };
    pyproject = true;
    doCheck = false;
    dontCheckRuntimeDeps = true;
    build-system = [ pyPkgs.setuptools pyPkgs.wheel pyPkgs."setuptools-scm" ];
    SETUPTOOLS_SCM_PRETEND_VERSION = "0.11.1";
    propagatedBuildInputs = [
      cadqueryOcp
      pyPkgs.numpy
      pyPkgs."typing-extensions"
      pyPkgs.svgpathtools
      pyPkgs.anytree
      pyPkgs.ezdxf
      pyPkgs.fonttools
      pyPkgs.ipython
      ocpsvg
      ocpGordon
      trianglesolver
      pyPkgs.sympy
      pyPkgs.scipy
      pyPkgs."scikit-learn"
      pyPkgs.webcolors
      pyPkgs.requests
      lib3mf
      bdMaterials
      threejsMaterials
    ];
    pythonImportsCheck = [ "build123d" ];
    meta = with lib; {
      description = "Python toolkit for parametric CAD modeling";
      homepage = "https://github.com/gumyr/build123d";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  };

  build123dEnv = (python.withPackages (ps: [ build123d ps.trimesh ])).overrideAttrs (_: {
    pname = "build123d-cad-environment";
    version = "0.11.1";
    meta = with lib; {
      description = "Isolated Python environment for build123d CAD tooling";
      homepage = "https://github.com/gumyr/build123d";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  });
  build123dPython = (pkgs.writeShellScriptBin "build123d-python" ''
    exec ${build123dEnv}/bin/python3 "$@"
  '').overrideAttrs (_: {
    meta = with lib; {
      description = "Run Python with the isolated build123d CAD environment";
      homepage = "https://github.com/gumyr/build123d";
      license = licenses.asl20;
      mainProgram = "build123d-python";
      platforms = [ "x86_64-linux" ];
    };
  });

in {
  environment = build123dEnv;
  wrapper = build123dPython;
}
