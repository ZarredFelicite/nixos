{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    # PYTHON Tools from home/cli-apps.nix
    uv # Extremely fast Python package installer and resolver, written in Rust
    ruff # Extremely fast Python linter
    (python3.withPackages(ps: with ps; [
      # CLI related or general purpose from cli-apps.nix
      pip # PyPA recommended tool for installing Python packages
      jwt # JSON Web Token library for Python 3
      yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
      rich # Render rich text, tables, progress bars, syntax highlighting, markdown and more to the terminal
      psutil # Process and system utilization information interface
      mutagen # Python module for handling audio metadata (often CLI)
      beautifulsoup4 # Useful for CLI scripting
      html2text # Convert HTML to plain text
      markitdown # Python tool for converting files and office documents to Markdown
      libtmux # for tmux scripting
      cloudscraper # for web scraping
      jupyter-core # jupyter support (CLI aspects)
      nbconvert # notebook conversion (CLI aspects)
      dbus-next # dbus lib for python (can be CLI related)
      requests-futures # async requests
      openai # For CLI AI tools
      transformers # Often used by CLI AI tools
      onnxruntime # Often used by CLI AI tools
      tensorboard # Can be CLI for viewing logs
      pyrss2gen # rss generation
      feedgen # newer rss generator
      networkx # graph lib (can be CLI related)
      pygraphviz # graphviz python (can be CLI related)
      pdf2image # pdf utility (CLI usage)
      reportlab # pdf generation (CLI usage)
      fontforge # font editor (CLI/scriptable)
      ( pkgs.callPackage ../pkgs/python/reader {}) # feed reader (CLI)
      ( pkgs.callPackage ../pkgs/python/ibind {}) # Interactive Brokers (CLI/API)

      # PYTHON from home/home.nix (GUI related or specific app backends)
      ytmusicapi # Python API for YouTube Music
      bullet # NOTE: not in nixpkgs?? (If for GUI)
      pillow # Friendly PIL fork (Python Imaging Library)
      colorthief # Python module for grabbing the color palette from an image
      pixcat # Display images on a kitty terminal with optional resizing (can be terminal profile too)
      python-mpv-jsonipc # For mpv control
      playsound # Simple audio playback
      gtts # Google Text-to-Speech
      flask # Web framework, could be for local tools
      numpy # Often with matplotlib
      matplotlib # Plotting library
      pybluez # Bluetooth
      yfinance
      bleak # Bluetooth Low Energy
      pyaudio # PortAudio bindings

      # Ensure all custom python packages from ../pkgs/python are included if not already listed
      # ( pkgs.callPackage ../pkgs/python/yt-dlp {}) # Already covered by yt-dlp
      # ( pkgs.python3Packages.callPackage ../pkgs/python/yfinance {}) # Will be in finance.nix
      # TODO: broken vllm
      # TODO: broken ( pkgs.callPackage ../pkgs/python/bambulabs_api {})
      # TODO dep chromadb broken ( pkgs.callPackage ../pkgs/python/yt-fts {})
      # Fails paho-mqtt version conflict ( pkgs.callPackage ../pkgs/python/bambu-connect {})
    ]))
  ];
}
