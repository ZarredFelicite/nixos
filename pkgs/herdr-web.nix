{ buildNpmPackage
, fetchFromGitHub
, nodejs
}:

buildNpmPackage rec {
  pname = "herdr-web";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "barnuri";
    repo = "herdr-web";
    rev = "198546e47350fc88d013889fea06f26a0daceda6";
    hash = "sha256-EqvB94KQbJTabCCGn5SJjbXHhCd4vtt4frr+aeSNfm4=";
  };

  npmDepsHash = "sha256-+RfiK2DlGeIVR7l5cZpkNM+g6ZIpHDNCg5SqHYUrnjo=";
  inherit nodejs;
  dontNpmBuild = true;
  postPatch = ''
    substituteInPlace herdr-plugin.toml --replace-fail 'command = ["node", "server.js"]' 'command = ["${nodejs}/bin/node", "server.js"]' --replace-fail 'command = ["node", "bin/open-url.js"]' 'command = ["${nodejs}/bin/node", "bin/open-url.js"]' --replace-fail 'command = ["node", "bin/open-url.js", "--notify-only"]' 'command = ["${nodejs}/bin/node", "bin/open-url.js", "--notify-only"]'
    substituteInPlace herdr-plugin.toml --replace-fail '[[startup]]' "" --replace-fail 'command = ["${nodejs}/bin/node", "server.js"]' ""
  '';

  # node-pty's helper is built by node-gyp as part of npm's postinstall.
  nativeBuildInputs = [ nodejs ];

  meta = {
    description = "Mobile-first web UI plugin for Herdr";
    homepage = "https://github.com/barnuri/herdr-web";
    license = "mit";
  };
}
