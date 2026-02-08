{ pkgs, pkgs-unstable, lib, config, inputs, ... }:

let
  customPythonPackages = python-final: python-prev: {
    #yfinance = python-final.callPackage ../pkgs/python/yfinance {};
    yt-dlp = pkgs.callPackage ../pkgs/python/yt-dlp { python3 = python-final.python; };
  };
in
{
  #nixpkgs.overlays = [
  #  (final: prev: {
  #    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
  #      customPythonPackages
  #    ];
  #  })
  #];

  environment.systemPackages = with pkgs; [
    # PYTHON Tools from home/cli-apps.nix
    uv # Extremely fast Python package installer and resolver, written in Rust
    ruff # Extremely fast Python linter
    geckodriver # Proxy for using W3C WebDriver-compatible clients to interact with Gecko-based browsers
    #( pkgs.callPackage ../pkgs/python/yt-dlp {} ) # Custom yt-dlp package
    (python3.withPackages(ps: with ps; [
      # CLI related or general purpose from cli-apps.nix
      pip # PyPA recommended tool for installing Python packages
      jwt # JSON Web Token library for Python 3
      yt-dlp # yt-dlp (custom via pythonPackagesExtensions)
      rich # Render rich text, tables, progress bars, syntax highlighting, markdown and more to the terminal
      psutil # Process and system utilization information interface
      mutagen # Python module for handling audio metadata (often CLI)
      beautifulsoup4 # Useful for CLI scripting
      aiofiles
      playwright
      faker
      backoff
      sqlalchemy
      html2text # Convert HTML to plain text
      markitdown # Python tool for converting files and office documents to Markdown
      libtmux # for tmux scripting
      cloudscraper # for web scraping
      jupyter-core # jupyter support (CLI aspects)
      nbconvert # notebook conversion (CLI aspects)
      dbus-next # dbus lib for python (can be CLI related)
      requests-futures # async requests
      requests
      pysocks # SOCKS module for Python
      openai # For CLI AI tools
      transformers # Often used by CLI AI tools
      onnxruntime # Often used by CLI AI tools
      tensorboard # Can be CLI for viewing logs
      pyrss2gen # rss generation
      feedgen # newer rss generator
      feedparser # Universal feed parser
      selenium # Bindings for Selenium WebDriver
      pydantic-settings # Settings management using Pydantic (type-safe configuration)
      networkx # graph lib (can be CLI related)
      pygraphviz # graphviz python (can be CLI related)
      pdf2image # pdf utility (CLI usage)
      reportlab # pdf generation (CLI usage)
      ( pkgs.callPackage ../pkgs/python/pymupdf-layout {}) # PyMuPDF with layout extension
      ( ps.callPackage ../pkgs/python/pymupdf4llm { pymupdf = pkgs.callPackage ../pkgs/python/pymupdf-layout {}; }) # PyMuPDF Utilities for LLM/RAG - converts PDF pages to Markdown format for Retrieval-Augmented Generation
      tabulate # Pretty-print tabular data
      fontforge # font editor (CLI/scriptable)
      ( pkgs.callPackage ../pkgs/python/reader {}) # feed reader (CLI)
      ( pkgs.callPackage ../pkgs/python/ibind {}) # Interactive Brokers (CLI/API)
      youtube-transcript-api # Python API which allows you to get the transcripts/subtitles for a given YouTube video
      google-cloud-texttospeech # Google Cloud Text-to-Speech API client library

      # PYTHON from home/home.nix (GUI related or specific app backends)
      ytmusicapi # Python API for YouTube Music
      bullet # NOTE: not in nixpkgs?? (If for GUI)
      pillow # Friendly PIL fork (Python Imaging Library)
      colorthief # Python module for grabbing the color palette from an image
      pixcat # Display images on a kitty terminal with optional resizing (can be terminal profile too)
      python-mpv-jsonipc # For mpv control
      playsound # Simple audio playback
      gtts # Google Text-to-Speech
      ( ps.callPackage ../pkgs/python/pocket-tts {} ) # Lightweight text-to-speech (TTS) application designed to run efficiently on CPUs

      flask # Web framework, could be for local tools
      fastapi # Web framework for building APIs
      uvicorn # ASGI server for FastAPI
      python-multipart # Multipart parser for file uploads
      fastmcp # Fast, Pythonic way to build MCP servers and clients
      numpy # Often with matplotlib
      matplotlib # Plotting library
      cairosvg
      pybluez # Bluetooth
      bleak # Bluetooth Low Energy
      pyaudio # PortAudio bindings
      webrtcvad # Interface to the Google WebRTC Voice Activity Detector (VAD)
      (let
        silero_vad = ps.callPackage ../pkgs/python/silero-vad {};
      in ps.callPackage ../pkgs/python/local-wake { inherit silero_vad; }) # Local wake-word detector CLI (lwake)
      textual # TUI framework for Python inspired by modern web development
      textual-image # Render images in the terminal with Textual and rich
      ( pkgs.callPackage ../pkgs/python/textual-plotext.nix {})
      pandas # Powerful data structures for data analysis, time series, and statistics
      plotly # Python plotting library for collaborative, interactive, publication-quality graphs
      kaleido # Fast static image export for web-based visualization libraries with zero dependencies
      pynvml # Unofficial Python bindings for the NVIDIA Management Library
      #pkgs.python3Packages.yfinance
      yfinance
      vllm
      ollama # Ollama Python library
      ( pkgs.callPackage ../pkgs/python/bambulabs_api {})
      #( pkgs.callPackage ../pkgs/python/yt-fts {})
      ( ps.callPackage ../pkgs/python/deepface {} )

      #(inputs.ignis.packages.${pkgs.stdenv.hostPlatform.system}.ignis.override {
      #  extraPackages = [
      #    # Add extra packages if needed
      #  ];
      #})
    ]))
  ];
}
