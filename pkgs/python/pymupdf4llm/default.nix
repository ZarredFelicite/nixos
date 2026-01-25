{ pkgs
, buildPythonPackage
, fetchPypi
, pymupdf
, setuptools
}:

buildPythonPackage rec {
  pname = "pymupdf4llm";
  version = "0.2.9";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "04p0pky3g09gx6h77swrhl6wrvsy9imvh62cwhx3a92p3xniagka";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    pymupdf
    pkgs.python3Packages.tabulate
  ];

  # Skip tests for now
  doCheck = false;

  pythonImportsCheck = [ "pymupdf4llm" ];

  meta = with pkgs.lib; {
    description = "PyMuPDF Utilities for LLM/RAG - converts PDF pages to Markdown format";
    homepage = "https://github.com/pymupdf/RAG";
    license = licenses.agpl3Plus;
  };
}
