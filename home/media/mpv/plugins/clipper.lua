local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"

local output_dir = (os.getenv("HOME") or "") .. "/videos/clips"
local menu_type = "clipper-filename"

local clip_start = nil
local clip_end = nil
local clip_path = nil
local exporting = false
local awaiting_filename = false

local function format_time(seconds)
    local milliseconds = math.floor((seconds % 1) * 1000 + 0.5)
    local whole_seconds = math.floor(seconds)
    local hours = math.floor(whole_seconds / 3600)
    local minutes = math.floor((whole_seconds % 3600) / 60)
    local secs = whole_seconds % 60
    return string.format("%02d-%02d-%02d.%03d", hours, minutes, secs, milliseconds)
end

local function reset_clip(show_message)
    clip_start = nil
    clip_end = nil
    clip_path = nil
    awaiting_filename = false
    if show_message then
        mp.osd_message("Clip markers cleared")
    end
end

local function get_local_path()
    local path = mp.get_property("path")
    if not path or path == "" then
        return nil, "No video is loaded"
    end
    if path:match("^[%a][%w+.-]*://") or path:match("^ytdl://") then
        return nil, "Clipping currently supports local files only"
    end
    if path:sub(1, 1) ~= "/" then
        path = utils.join_path(mp.get_property("working-directory") or utils.getcwd(), path)
    end
    return path
end

local function source_extension(path)
    local _, filename = utils.split_path(path)
    return filename:match("(%.[^%.]+)$") or ".mkv"
end

local function validate_filename(filename, input_path)
    filename = filename:match("^%s*(.-)%s*$")
    if filename == "" then
        return nil, "Enter a filename"
    end
    if filename == "." or filename == ".." or filename:find("[/\\]") then
        return nil, "Use a filename, not a path"
    end
    if filename:sub(1, 1) == "-" or filename:find("%c") then
        return nil, "Filename contains unsupported characters"
    end
    if not filename:match("%.[^%.]+$") then
        filename = filename .. source_extension(input_path)
    end
    return filename
end

local function export_clip(filename)
    local input_path, path_error = get_local_path()
    if not input_path then
        mp.osd_message(path_error)
        return
    end

    if input_path ~= clip_path then
        mp.osd_message("The loaded video changed; set new clip markers")
        reset_clip(false)
        return
    end

    local valid_filename, filename_error = validate_filename(filename, input_path)
    if not valid_filename then
        mp.osd_message(filename_error)
        return
    end

    local mkdir_result = mp.command_native({
        name = "subprocess",
        args = {"mkdir", "-p", output_dir},
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    })
    if not mkdir_result or mkdir_result.status ~= 0 then
        mp.osd_message("Could not create " .. output_dir)
        msg.error(mkdir_result and mkdir_result.stderr or "mkdir failed")
        return
    end

    local output_path = utils.join_path(output_dir, valid_filename)
    local args = {
        "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-n",
        "-ss", string.format("%.3f", clip_start),
        "-t", string.format("%.3f", clip_end - clip_start),
        "-i", input_path,
        "-map", "0:v?", "-map", "0:a?", "-map", "0:s?",
        "-c", "copy", "-avoid_negative_ts", "make_zero",
        output_path,
    }

    local exported_path = clip_path
    local exported_start = clip_start
    local exported_end = clip_end

    exporting = true
    awaiting_filename = false
    mp.commandv("script-message-to", "uosc", "close-menu", menu_type)
    mp.osd_message("Exporting clip…")

    mp.command_native_async({
        name = "subprocess",
        args = args,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result, error_message)
        exporting = false
        if success and result and result.status == 0 then
            if clip_path == exported_path and clip_start == exported_start and clip_end == exported_end then
                reset_clip(false)
            end
            mp.osd_message("Clip saved: " .. output_path, 4)
            msg.info("Clip saved: " .. output_path)
            return
        end

        local details = error_message or (result and result.stderr) or "unknown ffmpeg error"
        local markers_retained = clip_path == exported_path
            and clip_start == exported_start
            and clip_end == exported_end
        mp.osd_message(markers_retained and "Clip export failed; markers retained" or "Clip export failed", 4)
        msg.error("Clip export failed: " .. details)
    end)
end

local function suggested_filename(input_path)
    local _, filename = utils.split_path(input_path)
    local stem, extension = filename:match("^(.*)(%.[^%.]+)$")
    if not stem then
        stem, extension = filename, ".mkv"
    end
    return string.format(
        "%s_clip_%s-%s%s",
        stem,
        format_time(clip_start),
        format_time(clip_end),
        extension
    )
end

local function open_filename_prompt()
    local input_path, path_error = get_local_path()
    if not input_path then
        mp.osd_message(path_error)
        return
    end

    awaiting_filename = true
    local menu = {
        type = menu_type,
        title = "Save clip as",
        footnote = "Enter to export · Esc to cancel",
        search_style = "palette",
        search_debounce = "submit",
        search_suggestion = suggested_filename(input_path),
        on_search = "callback",
        callback = {"clipper", "filename-event"},
        items = {
            {title = "Type a filename", value = "", selectable = false, muted = true},
        },
    }
    mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(menu))
end

local function mark_or_export()
    if exporting then
        mp.osd_message("A clip is already exporting")
        return
    end

    if clip_start and clip_end then
        open_filename_prompt()
        return
    end

    local input_path, path_error = get_local_path()
    if not input_path then
        mp.osd_message(path_error)
        return
    end

    local position = mp.get_property_number("time-pos")
    if not position then
        mp.osd_message("Current playback position is unavailable")
        return
    end

    if not clip_start then
        clip_start = position
        clip_path = input_path
        mp.osd_message("Clip start: " .. format_time(clip_start))
        return
    end

    if input_path ~= clip_path then
        reset_clip(false)
        mp.osd_message("The loaded video changed; start marker cleared")
        return
    end

    if position <= clip_start then
        mp.osd_message("Clip end must be after the start")
        return
    end

    clip_end = position
    open_filename_prompt()
end

mp.register_script_message("filename-event", function(json)
    local event = utils.parse_json(json)
    if not event then
        return
    end
    if event.type == "search" then
        export_clip(event.query or "")
    elseif event.type == "close" and awaiting_filename then
        awaiting_filename = false
        clip_end = nil
        mp.osd_message("Filename canceled; start marker retained")
    end
end)

mp.register_event("file-loaded", function()
    if clip_start then
        reset_clip(false)
    end
end)

mp.add_key_binding(nil, "mark-or-export", mark_or_export)
mp.add_key_binding(nil, "reset", function()
    if exporting then
        mp.osd_message("Cannot clear markers while exporting")
        return
    end
    reset_clip(true)
end)
