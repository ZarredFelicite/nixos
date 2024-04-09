-- sponsorblock_minimal.lua
--
-- This script skips sponsored segments of YouTube videos
-- using data from https://github.com/ajayyy/SponsorBlock

local opt = require 'mp.options'
local utils = require 'mp.utils'

local ON = false
local ranges = nil

local options = {
	server = "https://sponsor.ajay.app/api/skipSegments",

	-- Categories to fetch and skip
	categories = '"sponsor"',

	-- Set this to "true" to use sha256HashPrefix instead of videoID
	hash = ""
}

opt.read_options(options)

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function skip_ads(name,pos)
	if pos then
		for _, i in pairs(ranges) do
			v = i.segment[2]
			if i.segment[1] <= pos and v > pos and ON then
				mp.osd_message(("[sponsorblock] skipping forward %ds"):format(math.floor(v-mp.get_property("time-pos"))))
        mp.set_property("speed", 3.5)
				return
      else
        if mp.get_property_number("speed") == 3.5 then
          mp.set_property("speed", speed)
        else
          speed = mp.get_property_number("speed")
        end
			end
		end
	end
end

function time_sort(a, b)
    if a.time == b.time then
        return string.match(a.title, "segment end")
    end
    return a.time < b.time
end

function create_chapter(chapter_title, chapter_time)
    local chapters = mp.get_property_native("chapter-list")
    local duration = mp.get_property_native("duration")
    table.insert(chapters, {title=chapter_title, time=(duration == nil or duration > chapter_time) and chapter_time or duration - .001})
    table.sort(chapters, time_sort)
    mp.set_property_native("chapter-list", chapters)
end

function file_loaded()
	local video_path = mp.get_property("path", "")
	local video_referer = string.match(mp.get_property("http-header-fields", ""), "Referer:([^,]+)") or ""

	local urls = {
		"ytdl://youtu%.be/([%w-_]+).*",
		"ytdl://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
		"https?://youtu%.be/([%w-_]+).*",
		"https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
		"/watch.*[?&]v=([%w-_]+).*",
		"/embed/([%w-_]+).*",
		"^ytdl://([%w-_]+)$",
		"-([%w-_]+)%."
	}
	local youtube_id = nil
	local purl = mp.get_property("metadata/by-key/PURL", "")
	for i,url in ipairs(urls) do
		youtube_id = youtube_id or string.match(video_path, url) or string.match(video_referer, url) or string.match(purl, url)
		if youtube_id then break end
	end

	if not youtube_id or string.len(youtube_id) < 11 then return end
	youtube_id = string.sub(youtube_id, 1, 11)

	local args = {"curl", "-L", "-s", "-G", "--data-urlencode", ("categories=[%s]"):format(options.categories)}
	local url = options.server
	if options.hash == "true" then
		local sha = mp.command_native{
			name = "subprocess",
			capture_stdout = true,
			args = {"sha256sum"},
			stdin_data = youtube_id
		}
		url = ("%s/%s"):format(url, string.sub(sha.stdout, 0, 4))
	else
		table.insert(args, "--data-urlencode")
		table.insert(args, "videoID=" .. youtube_id)
	end
	table.insert(args, url)

	local sponsors = mp.command_native{
		name = "subprocess",
		capture_stdout = true,
		playback_only = false,
		args = args
	}
	if sponsors.stdout then
		local json = utils.parse_json(sponsors.stdout)
		if type(json) == "table" then
			if options.hash == "true" then
				for _, i in pairs(json) do
					if i.videoID == youtube_id then
						ranges = i.segments
						break
					end
				end
			else
				ranges = json
			end

			if ranges then
				ON = true
        for _, segment in ipairs(ranges) do
          local start = math.floor(segment["segment"][1])
          local finish = math.floor(segment["segment"][2])
          local category_title = (segment["category"]:gsub("^%l", string.upper):gsub("_", " "))
          create_chapter(category_title .. " start", start)
          create_chapter("finish", finish)
        end
				mp.observe_property("time-pos", "native", skip_ads)
			end
		end
	end
end

function end_file()
	if not ON then return end
	mp.unobserve_property(skip_ads)
	ranges = nil
	ON = false
end

function toggle()
	if ON then
		mp.unobserve_property(skip_ads)
		mp.osd_message("[sponsorblock] off")
		ON = false
	else
		mp.observe_property("time-pos", "native", skip_ads)
		mp.osd_message("[sponsorblock] on")
		ON = true
	end
end

mp.register_event("file-loaded", file_loaded)
mp.register_event("end-file", end_file)
mp.register_script_message("toggle_sponsorblock", toggle)
