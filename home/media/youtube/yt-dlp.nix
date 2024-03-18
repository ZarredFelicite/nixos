{ ... }: {
  xdg.configFile."yt-dlp/config".text = ''
    -o ~/videos/youtube/%(title)s.%(ext)s
    -f bestvideo*+bestaudio/best
    --restrict-filenames
    --no-overwrites
    --embed-thumbnail
    --embed-subs
    --embed-metadata
    --downloader aria2c
    --downloader-args aria2c:'-c -x8 -s8 -k1M --continue=true'
  '';
}
