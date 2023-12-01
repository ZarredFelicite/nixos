{ stdenv, buildPythonApplication, fetchFromGitHub, setuptools,
  requests, feedparser, }:
buildPythonApplication rec {
  pname = "persepolis";
  version = "3.1.0";
  src = fetchFromGitHub {
    owner = "persepolisdm";
    repo = "persepolis";
    rev = "df743546baf64f852229f2bf056a26eafa89f67f";
    sha256 = "0xngk8wgj5k27mh3bcrf2wwzqr8a3g0d4pc5i5vcavnnaj03j44m";
  };
  nativeBuildInputs = [ setuptools ];
  propagatedBuildInputs=[
    aria aria2 libnotify libpulseaudio psutils pyqt5 requests setproctitle youtube-dl sound-theme-freedesktop
  ];
  preBuild=''substituteInPlace setup.py --replace "answer = input(" "answer = 'y'#"''; # Who the **** thought of using input in setup.py?
  meta=with stdenv.lib; {
    description="A plugin for mkdocs to exclude arbitrary paths and files";
    homepage="https://persepolisdm.github.io/";
    license=licenses.gpl3;
    maintainers=[maintainers.linarcx];
  };
}
