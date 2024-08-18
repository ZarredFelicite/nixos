{ ... }: {
  xdg.configFile."yt-dlp/config".text = ''
    -o ~/videos/youtube/%(title)s.%(ext)s
    -f bestvideo*+bestaudio/best
    -S 'res:1080,vcodec:av1'
    --restrict-filenames
    --no-overwrites
    --embed-thumbnail
    --embed-subs
    --embed-metadata
    --downloader ffmpeg # native, aria2c, avconv, axel, curl, ffmpeg, httpie, wget
    --downloader-args aria2c:'-c -x8 -s8 -k1M --continue=true'
  '';
}
