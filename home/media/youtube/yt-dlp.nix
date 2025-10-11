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
    #--downloader ffmpeg # native, aria2c, avconv, axel, curl, ffmpeg, httpie, wget
    --downloader-args aria2c:'-c -x8 -s8 -k1M --continue=true'
    --downloader-arg "ffmpeg_i1:-extension_picky 0"
    --downloader-arg "ffmpeg_i2:-extension_picky 0"
    --extractor-args "youtube:player-client=tv"
    #--cookies-from-browser firefox
    -N 16
  '';
}
