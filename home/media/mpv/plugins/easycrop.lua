local msg = require('mp.msg')
local assdraw = require('mp.assdraw')

local script_name = "easycrop"

-- Number of crop points currently chosen (0 to 2)
local points = {}
-- True if in cropping selection mode
local cropping = false
-- Original value of osc property
local osc_prop = false

-- Helper that converts two points to top-left and bottom-right
local swizzle_points = function (p1, p2)
    if p1.x > p2.x then p1.x, p2.x = p2.x, p1.x end
    if p1.y > p2.y then p1.y, p2.y = p2.y, p1.y end
end

local clamp = function (val, min, max)
    assert(min <= max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local video_space_from_screen_space = function (ssp)
    -- Video native dimensions and screen size
    local vid_w = mp.get_property("width")
    local vid_h = mp.get_property("height")
    local osd_w = mp.get_property("osd-width")
    local osd_h = mp.get_property("osd-height")

    -- Factor by which the video is scaled to fit the screen
    local scale = math.min(osd_w/vid_w, osd_h/vid_h)

    -- Size video takes up in screen
    local vid_sw, vid_sh = scale*vid_w, scale*vid_h

    -- Video offset within screen
    local off_x = math.floor((osd_w - vid_sw)/2)
    local off_y = math.floor((osd_h - vid_sh)/2)

    local vsp = {}

    -- Move the point to within the video
    vsp.x = clamp(ssp.x, off_x, off_x + vid_sw)
    vsp.y = clamp(ssp.y, off_y, off_y + vid_sh)

    -- Convert screen-space to video-space
    vsp.x = math.floor((vsp.x - off_x) / scale)
    vsp.y = math.floor((vsp.y - off_y) / scale)

    return vsp
end

local screen_space_from_video_space = function (vsp)
    -- Video native dimensions and screen size
    local vid_w = mp.get_property("width")
    local vid_h = mp.get_property("height")
    local osd_w = mp.get_property("osd-width")
    local osd_h = mp.get_property("osd-height")

    -- Factor by which the video is scaled to fit the screen
    local scale = math.min(osd_w/vid_w, osd_h/vid_h)

    -- Size video takes up in screen
    local vid_sw, vid_sh = scale*vid_w, scale*vid_h

    -- Video offset within screen
    local off_x = math.floor((osd_w - vid_sw)/2)
    local off_y = math.floor((osd_h - vid_sh)/2)

    local ssp = {}
    ssp.x = vsp.x * scale + off_x
    ssp.y = vsp.y * scale + off_y
    return ssp
end

-- Wrapper that converts RRGGBB / RRGGBBAA to ASS format
local ass_set_color = function (idx, color)
    assert(color:len() == 8 or color:len() == 6)
    local ass = ""

    -- Set alpha value (if present)
    if color:len() == 8 then
        local alpha = 0xff - tonumber(color:sub(7, 8), 16)
        ass = ass .. string.format("\\%da&H%X&", idx, alpha)
    end

    -- Swizzle RGB to BGR and build ASS string
    color = color:sub(5, 6) .. color:sub(3, 4) .. color:sub(1, 2)
    return "{" .. ass .. string.format("\\%dc&H%s&", idx, color) .. "}"
end

local draw_rect = function (p1, p2)
    local osd_w, osd_h = mp.get_property("osd-width"), mp.get_property("osd-height")

    ass = assdraw.ass_new()

    -- Draw overlay over surrounding unselected region

    ass:draw_start()
    ass:pos(0, 0)

    ass:append(ass_set_color(1, "000000aa"))
    ass:append(ass_set_color(3, "00000000"))

    local l = math.min(p1.x, p2.x)
    local r = math.max(p1.x, p2.x)
    local u = math.min(p1.y, p2.y)
    local d = math.max(p1.y, p2.y)

    ass:rect_cw(0, 0, l, osd_h)
    ass:rect_cw(r, 0, osd_w, osd_h)
    ass:rect_cw(l, 0, r, u)
    ass:rect_cw(l, d, r, osd_h)

    ass:draw_stop()

    -- Draw border around selected region

    ass:new_event()
    ass:draw_start()
    ass:pos(0, 0)

    ass:append(ass_set_color(1, "00000000"))
    ass:append(ass_set_color(3, "000000ff"))
    ass:append("{\\bord2}")

    ass:rect_cw(p1.x, p1.y, p2.x, p2.y)

    ass:draw_stop()

    mp.set_osd_ass(osd_w, osd_h, ass.text)
end

local draw_fill = function ()
    local osd_w, osd_h = mp.get_property("osd-width"), mp.get_property("osd-height")

    ass = assdraw.ass_new()
    ass:draw_start()
    ass:pos(0, 0)

    ass:append(ass_set_color(1, "000000aa"))
    ass:append(ass_set_color(3, "00000000"))
    ass:rect_cw(0, 0, osd_w, osd_h)

    ass:draw_stop()
    mp.set_osd_ass(osd_w, osd_h, ass.text)
end

local draw_clear = function ()
    local osd_w, osd_h = mp.get_property("osd-width"), mp.get_property("osd-height")
    mp.set_osd_ass(osd_w, osd_h, "")
end

local draw_cropper = function ()
    if #points == 1 then
        local p1 = screen_space_from_video_space(points[1])
        local p2 = {}
        p2.x, p2.y = mp.get_mouse_pos()
        draw_rect(p1, p2)
    end
end

local uncrop = function ()
    mp.command("no-osd vf del @" .. script_name .. ":crop")
end

local crop = function(p1, p2)
    swizzle_points(p1, p2)

    local w = p2.x - p1.x
    local h = p2.y - p1.y
    local ok, err = mp.command(string.format(
        "no-osd vf add @%s:crop=%s:%s:%s:%s", script_name, w, h, p1.x, p1.y))

    if not ok then
        mp.osd_message("Cropping failed")
        points = {}
    end
end

local easycrop_stop = function ()
    mp.set_property("osc", osc_prop)
    cropping = false
    mp.remove_key_binding("easycrop_mouse_btn0")
    draw_clear()
end

local mouse_btn0_cb = function ()
    if not cropping then
        return
    end

    local mx, my = mp.get_mouse_pos()
    table.insert(points, video_space_from_screen_space({ x = mx, y = my }))

    if #points == 2 then
        crop(points[1], points[2])
        easycrop_stop()
    end
end

local easycrop_start = function ()
    -- Cropping requires swdec or hwdec with copy-back
    local hwdec = mp.get_property("hwdec-current")
    if hwdec == nil then
        return mp.msg.error("Cannot determine current hardware decoder mode")
    end
    -- Check whitelist of ok values
    local valid_hwdec = {
       ["no"] = true, -- software decoding
       -- Taken from mpv manual
       ["videotoolbox-co"] = true,
       ["vaapi-copy"] = true,
       ["dxva2-copy"] = true,
       ["d3d11va-copy"] = true,
       ["mediacodec"] = true
    }
    if not valid_hwdec[hwdec] then
        return mp.osd_message("Cropping requires swdec or hwdec with copy-back (see mpv manual)")
    end

    -- Just clear the current crop and return, if there is one
    if #points ~= 0 then
        uncrop()
        points = {}
        return
    end

    -- Hide OSC
    osc_prop = mp.get_property("osc")
    mp.set_property("osc", "no")

    cropping = true
    mp.add_forced_key_binding("mouse_btn0", "easycrop_mouse_btn0", mouse_btn0_cb)
    draw_fill()
end

-- Encoding format selection
local format_menu_active = false
local encoding_formats = {
    {name = "H.264 (Fast, Compatible)", codec = "h264", hw_vaapi = "h264_vaapi", hw_nvenc = "h264_nvenc", sw = "libx264"},
    {name = "H.265/HEVC (Better Compression)", codec = "hevc", hw_vaapi = "hevc_vaapi", hw_nvenc = "hevc_nvenc", sw = "libx265"},
    {name = "AV1 (Best Compression, Slower)", codec = "av1", hw_vaapi = "av1_vaapi", hw_nvenc = "av1_nvenc", sw = "libsvtav1"},
    {name = "VP9 (Good for Web)", codec = "vp9", hw_vaapi = "vp9_vaapi", hw_nvenc = nil, sw = "libvpx-vp9"},
}

-- Forward declaration
local save_cropped_video_with_format

local show_format_menu = function()
    local menu_text = "Select output format:\n\n"
    for i, fmt in ipairs(encoding_formats) do
        menu_text = menu_text .. string.format("%d) %s\n", i, fmt.name)
    end
    menu_text = menu_text .. "\nESC) Cancel"
    
    mp.osd_message(menu_text, 30)
    format_menu_active = true
    
    -- Bind number keys for selection
    for i = 1, #encoding_formats do
        mp.add_forced_key_binding(tostring(i), "format_select_" .. i, function()
            format_menu_active = false
            -- Remove all bindings
            for j = 1, #encoding_formats do
                mp.remove_key_binding("format_select_" .. j)
            end
            mp.remove_key_binding("format_cancel")
            mp.osd_message("")
            save_cropped_video_with_format(encoding_formats[i])
        end)
    end
    
    -- Bind ESC to cancel
    mp.add_forced_key_binding("ESC", "format_cancel", function()
        format_menu_active = false
        for j = 1, #encoding_formats do
            mp.remove_key_binding("format_select_" .. j)
        end
        mp.remove_key_binding("format_cancel")
        mp.osd_message("Cancelled")
    end)
end

save_cropped_video_with_format = function (format)
    -- Check if we have a crop active
    if #points ~= 2 then
        mp.osd_message("No crop active - please crop first with 'c'")
        return
    end
    
    local p1, p2 = points[1], points[2]
    swizzle_points(p1, p2)
    
    local w = p2.x - p1.x
    local h = p2.y - p1.y
    local x = p1.x
    local y = p1.y
    
    -- Get current file path
    local path = mp.get_property("path")
    if not path then
        mp.osd_message("No file loaded")
        return
    end
    
    -- Generate output filename with codec extension
    local ext_map = {h264 = "mp4", hevc = "mp4", av1 = "mp4", vp9 = "webm"}
    local ext = ext_map[format.codec] or "mp4"
    local output = path:gsub("(%.[^.]+)$", "_cropped_" .. format.codec .. "." .. ext)
    
    mp.osd_message("Saving cropped video with " .. format.name .. "...\nOutput: " .. output)
    
    -- Build encoding methods based on selected format
    local methods = {}
    
    -- Method 1: Hardware encoding (VAAPI) - properly initialized
    if format.hw_vaapi then
        table.insert(methods, {
            name = "hardware encoding (VAAPI)",
            cmd = string.format(
                'ffmpeg -y -init_hw_device vaapi=va:/dev/dri/renderD128 -hwaccel vaapi -hwaccel_output_format vaapi -i "%s" -filter_hw_device va -vf "format=nv12|vaapi,hwupload,crop=%d:%d:%d:%d" -c:v %s -qp 18 -vf fps=60 -c:a copy "%s" 2>&1',
                path, w, h, x, y, format.hw_vaapi, output
            )
        })
    end
    
    -- Method 2: Hardware encoding (NVENC)
    if format.hw_nvenc then
        table.insert(methods, {
            name = "hardware encoding (NVENC)",
            cmd = string.format(
                'ffmpeg -y -hwaccel cuda -i "%s" -vf "crop=%d:%d:%d:%d,mpdecimate,fps=60" -c:v %s -preset p4 -cq 23 -g 240 -c:a copy "%s" 2>&1',
                path, w, h, x, y, format.hw_nvenc, output
            )
        })
    end
    
    -- Method 3: Software encoding with proper settings
    local sw_opts = ""
    local vf_extra = ""
    
    if format.codec == "av1" then
        -- SVT-AV1: CRF 35 for good quality, preset 6 for speed/quality balance
        -- mpdecimate removes duplicate frames before fps limiting
        sw_opts = "-preset 6 -crf 35 -g 240 -svtav1-params tune=0:film-grain=8"
        vf_extra = "mpdecimate,fps=60"
    elseif format.codec == "hevc" then
        sw_opts = "-preset medium -crf 23 -g 240"
        vf_extra = "mpdecimate,fps=60"
    elseif format.codec == "vp9" then
        sw_opts = "-b:v 0 -crf 31 -g 240 -cpu-used 2"
        vf_extra = "mpdecimate,fps=60"
    else
        -- H.264
        sw_opts = "-preset medium -crf 23 -g 240"
        vf_extra = "mpdecimate,fps=60"
    end
    
    table.insert(methods, {
        name = "software encoding (" .. format.sw .. ")",
        cmd = string.format(
            'ffmpeg -y -i "%s" -vf "crop=%d:%d:%d:%d,%s" -c:v %s %s -c:a copy "%s" 2>&1',
            path, w, h, x, y, vf_extra, format.sw, sw_opts, output
        )
    })
    
    local success = false
    for i, method in ipairs(methods) do
        msg.info("Trying " .. method.name .. ": " .. method.cmd)
        local handle = io.popen(method.cmd)
        local result = handle:read("*a")
        local ok = handle:close()
        
        if ok then
            mp.osd_message("Cropped video saved successfully!\nCodec: " .. format.name .. "\nMethod: " .. method.name .. "\n" .. output, 5)
            msg.info("Success with " .. method.name)
            success = true
            break
        else
            msg.warn("Failed with " .. method.name .. ": " .. result)
            if i < #methods then
                msg.info("Trying next method...")
            end
        end
    end
    
    if not success then
        mp.osd_message("Failed to save cropped video with all methods", 3)
    end
end

local save_cropped_video = function ()
    show_format_menu()
end

local easycrop_activate = function ()
    if cropping then
        easycrop_stop()
    else
        easycrop_start()
    end
end

mp.add_key_binding("mouse_move", draw_cropper)
mp.observe_property("osd-width", "native", draw_cropper)
mp.observe_property("osd-height", "native", draw_cropper)

mp.add_key_binding("c", "easy_crop", easycrop_activate)
mp.add_key_binding("ctrl+c", "save_cropped_video", save_cropped_video)
