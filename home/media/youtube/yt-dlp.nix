{ ... }: {
  xdg.configFile."yt-dlp/config".text = ''
    -o ~/videos/youtube/%(title)s.%(ext)s
    -f bestvideo*+bestaudio/best
    -S 'vcodec:h264,res:1080,acodec:m4a'
    --restrict-filenames
    --no-overwrites
    --embed-thumbnail
    --embed-subs
    --embed-metadata
    --downloader ffmpeg # native, aria2c, avconv, axel, curl, ffmpeg, httpie, wget
    --downloader-args aria2c:'-c -x8 -s8 -k1M --continue=true'
    --extractor-args "youtube:player-client=tv"
    -N 16
  '';
}
