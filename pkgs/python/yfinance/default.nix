{
  lib,
  beautifulsoup4,
  buildPythonPackage,
  cryptography,
  fetchFromGitHub,
  frozendict,
  html5lib,
  lxml,
  multitasking,
  numpy,
  pandas,
  peewee,
  platformdirs,
  pytz,
  requests-cache,
  requests-ratelimiter,
  requests,
  scipy,
  setuptools,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

buildPythonPackage rec {
  pname = "yfinance";
  version = "0.2.58";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ranaroussi";
    repo = "yfinance";
    tag = version;
    hash = "sha256-Xndky4sMVn0sPH4CFdLuwcfhPzMXtH4rdakQdve3RK0=";
  };

  build-system = [ setuptools ];

  dependencies = [
    beautifulsoup4
    cryptography
    frozendict
    html5lib
    lxml
    multitasking
    numpy
    pandas
    peewee
    platformdirs
    pytz
    requests
    (buildPythonPackage rec {
      pname = "curl-cffi";
      version = "0.11.3";
      src = {
        x86_64-linux = fetchurl {
          url = "https://github.com/lexiforest/curl_cffi/releases/download/v${version}/curl_cffi-${version}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-6DBlvIm2clpNcrr688vd31a7TwFLxjvnP4fxs5A/0K4=";
        };
      }."${stdenv.hostPlatform.system}";
      format = "wheel";
      buildInputs = [ stdenv.cc.cc.lib ];
      nativeBuildInputs = [
        stdenv.cc.cc.lib
        autoPatchelfHook
      ];
    })
  ];

  optional-dependencies = {
    nospam = [
      requests-cache
      requests-ratelimiter
    ];
    repair = [
      scipy
    ];
  };

  # Tests require internet access
  doCheck = false;

  #pythonImportsCheck = [ "yfinance" ];

  meta = with lib; {
    description = "Module to doiwnload Yahoo! Finance market data";
    homepage = "https://github.com/ranaroussi/yfinance";
    changelog = "https://github.com/ranaroussi/yfinance/blob/${src.tag}/CHANGELOG.rst";
    license = licenses.asl20;
    maintainers = with maintainers; [ drewrisinger ];
  };
}
