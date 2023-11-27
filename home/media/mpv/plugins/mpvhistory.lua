-- Not my code: originally from https://redd.it/3t6s7k (author deleted; failed to ask for permission).
-- Only tested on Windows. Date is set to dd/mmm/yy and time to machine-wide format.
-- Save as "mpvhistory.lua" in your mpv scripts dir. Log will be saved to mpv default config directory.
-- Make sure to leave a comment if you make any improvements/changes to the script!

local settings = {
  umpv = false,
  history_file = '/home/zarred/sync/mpv/video_history',
  playlist_file = "/home/zarred/sync/mpv/mpv_playlist.m3u",
}


function save_history()
    local title, logfile, file;

    title = mp.get_property('media-title');
    title = (title == mp.get_property('filename') and '' or ('%s'):format(title));

	file = mp.get_property('path')
	if not string.match(file, '^(https?://[%w_.-]+/?[%w_./%-?&%%=]*)$') then
		file = mp.get_property('working-directory') .. "/" .. file
	end

    logfile = io.open(settings.history_file, 'a+');
    logfile:write(('[%s]   %s   %s\n'):format(os.date('%d/%m/%Y %X'), file, title));
    logfile:close();
end


function save_playlist(event, playlist_file)
  local length = mp.get_property_number('playlist-count', 0)
  if length == 0 or settings.umpv == false then return end

  if playlist_file == nil then
    playlist_file = settings.playlist_file
  end
  local file, err = io.open(playlist_file, "w")

  if not file then
    msg.error("Error in creating playlist file, check path/permissions. Error: "..(err or "unknown"))
  else
    local i=0
    while i < length do
      local pwd = mp.get_property("working-directory")
      local filename = mp.get_property('playlist/'..i..'/filename')
      local fullpath = filename
      if not filename:match("^%a%a+:%/%/") then
        fullpath = utils.join_path(pwd, filename)
      end
      local title = mp.get_property('playlist/'..i..'/title') or url_table[filename]
      if title then
        file:write("#EXTINF:,"..title.."\n")
      end
      file:write(fullpath, "\n")
      i=i+1
    end
    local saved_msg = "Playlist written to: "..savepath
    if settings.display_osd_feedback then mp.osd_message(saved_msg) end
    msg.info(saved_msg)
    file:close()
  end
end


mp.register_event('file-loaded', save_history)
mp.register_event('file-loaded', save_playlist)
mp.observe_property('playlist-count', nil, save_playlist)
