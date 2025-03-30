local utils = require "mp.utils"

local cover_filenames = { "cover.png", "cover.jpg", "cover.jpeg",
  "folder.jpg", "folder.png", "folder.jpeg",
  "AlbumArtwork.png", "AlbumArtwork.jpg", "AlbumArtwork.jpeg" }

function notify(summary, body, options)
  local option_args = {}
  for key, value in pairs(options or {}) do
    table.insert(option_args, string.format("--%s=%s", key, value))
  end
  return mp.command_native({
    "run", "notify-send", "-e",
    summary, body,
    unpack(option_args)
  })
end

function escape_pango_markup(str)
  return string.gsub(str, "([\"'<>&])", function(char)
    return string.format("&#%d;", string.byte(char))
  end)
end

function notify_media(title, origin, thumbnail)
  return notify(escape_pango_markup(title), origin, {
    urgency = "low",
    ["app-name"] = "mpv",
    hint = "string:desktop-entry:mpv",
    icon = thumbnail or "mpv",
  })
end

function file_exists(path)
  local info, _ = utils.file_info(path)
  return info ~= nil
end

function find_cover(dir)
  -- make dir an absolute path
  if dir[1] ~= "/" then
    dir = utils.join_path(utils.getcwd(), dir)
  end

  for _, file in ipairs(cover_filenames) do
    local path = utils.join_path(dir, file)
    if file_exists(path) then
      return path
    end
  end

  return nil
end

function first_upper(str)
  return (string.gsub(string.gsub(str, "^%l", string.upper), "_%l", string.upper))
end

function notify_current_media(_, metadata)
  if metadata then
    function tag(name)
      return metadata[string.upper(name)] or metadata[first_upper(name)] or metadata[name]
    end

    local title = tag("title") or tag("icy-title") or nil

    -- for key, value in pairs(metadata) do
    --   print("==")
    --   print(key)
    --   print(value)
    --   print("==")
    -- end

    if not title then
      return nil
    end

    local origin = tag("artist_credit") or tag("artist") or tag("icy-name") or ""

    local album = tag("album")
    if album then
      origin = string.format("%s — %s", origin, album)
    end

    local year = tag("original_year") or tag("year")
    if year then
      origin = string.format("%s (%s)", origin, year)
    end
    return notify_media(title, origin, nil)
  end
  return nil
end

mp.observe_property("metadata", "native", notify_current_media)
