-- Clear demuxer buffers when switching playlist items to prevent memory bloat
-- Workaround for known mpv bugs #16658 and #15099
-- See: https://github.com/mpv-player/mpv/issues/16658

local function clear_buffers()
    -- Use mpv's built-in drop-buffers command to force buffer release
    -- This is experimental but specifically designed for this purpose
    mp.command("drop-buffers")
    mp.msg.info("Dropped buffers for new playlist item")
end

-- Clear buffers when switching to a new file in playlist
mp.register_event("start-file", clear_buffers)

mp.msg.info("Buffer clearing script loaded - will drop buffers on playlist changes")
