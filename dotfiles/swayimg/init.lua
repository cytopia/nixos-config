-- Swayimg 5.x configuration (Lua).
--
-- Swayimg >= 5.0 no longer reads the INI style "config" file. The only file it
-- loads is $XDG_CONFIG_HOME/swayimg/init.lua. Reference for this file:
--   https://github.com/artemsen/swayimg/blob/v5.6/CONFIG.md
--   https://github.com/artemsen/swayimg/blob/v5.6/extra/example.lua
--
-- The interpreter is LuaJIT (Lua 5.1 syntax), so no "//" or "goto".
--
-- Key names: xkb keysym names, case-insensitive ("space", "Return", "F1",
-- "bracketleft", "equal", "minus"). Modifiers: Ctrl, Alt, Shift, joined with
-- "+" or "-". Because "-" is a separator, the minus key must be written as
-- "minus". Letters are matched lower-case, so "Shift+g" is Shift and g.
--
-- Bindings defined here override the compiled-in defaults with the same key.
-- Defaults that are not overridden stay active (see `swayimg -h` man page,
-- section KEYS).

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.mode = "viewer"          -- mode at startup (viewer/slideshow/gallery)
swayimg.overlay = false          -- do not mimic the focused terminal window
swayimg.decoration = false       -- no title bar / borders
swayimg.antialiasing = true
swayimg.exif_orientation = true

--------------------------------------------------------------------------------
-- Image list
--------------------------------------------------------------------------------
swayimg.imagelist.order = "alpha"
swayimg.imagelist.reverse = false
swayimg.imagelist.recursive = false
swayimg.imagelist.adjacent = true   -- open one file, browse the whole directory
swayimg.imagelist.fsmon = true

--------------------------------------------------------------------------------
-- Text overlay (colors are ARGB: 0xAARRGGBB)
--------------------------------------------------------------------------------
swayimg.text.visible = true
swayimg.text.font = "monospace"
swayimg.text.size = 14
swayimg.text.padding = 10
swayimg.text.color = 0xffcccccc
swayimg.text.background = 0x80000000
swayimg.text.shadow = 0x00000000    -- alpha 0 disables the shadow
swayimg.text.timeout = 5            -- hide the whole layer after N seconds
swayimg.text.status_timeout = 3     -- hide status messages after N seconds

--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.default_scale = "optimal"
swayimg.viewer.default_position = "center"
swayimg.viewer.autocenter = true
swayimg.viewer.loop = true
swayimg.viewer.history = 2
swayimg.viewer.preload = 2
swayimg.viewer.set_window_background(0xee000000)
swayimg.viewer.text = {
  topleft = {
    "File:\t{name}",
    "Format:\t{format}",
    "File size:\t{sizehr}",
    "Image size:\t{frame.width}x{frame.height}",
    "EXIF date:\t{meta.Exif.Photo.DateTimeOriginal}",
    "EXIF camera:\t{meta.Exif.Image.Model}",
    "EXIF lens:\t{meta.Exif.Photo.LensModel}",
  },
  topright = {
    "{list.index} of {list.total}",
  },
  bottomleft = {
    "Scale:\t{scale}",
    "Frame:\t{frame.index} of {frame.total}",
  },
}

--------------------------------------------------------------------------------
-- Slideshow mode
--------------------------------------------------------------------------------
swayimg.slideshow.timeout = 5
swayimg.slideshow.default_scale = "fit"
swayimg.slideshow.text = { topleft = { "{name}" } }
swayimg.slideshow.set_window_background(0xee000000)

--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.thumb_size = 200
swayimg.gallery.aspect = "fill"
swayimg.gallery.selected_scale = 1.15
swayimg.gallery.padding_size = 5
swayimg.gallery.border_size = 5
swayimg.gallery.border_color = 0xffaaaaaa
swayimg.gallery.selected_color = 0xff404040
swayimg.gallery.unselected_color = 0xff202020
swayimg.gallery.window_color = 0xee000000
swayimg.gallery.cache = 100
swayimg.gallery.preload = false
swayimg.gallery.pstore = false
swayimg.gallery.text = {
  topright = { "{list.index} of {list.total}" },
  bottomright = { "{name}" },
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function basename(path)
  return path:match("([^/]+)$") or path
end

local function status(msg)
  swayimg.text.status = msg
end

-- Delete the current file from disk and drop it from the image list.
local function delete_file(mode)
  local img = mode.get_image()
  if not img then
    return
  end
  local ok, err = os.remove(img.path)
  if ok then
    swayimg.imagelist.remove(img.path)
    status("Deleted " .. basename(img.path))
  else
    status("Delete failed: " .. tostring(err))
  end
end

-- Drop the current file from the image list only (file stays on disk).
local function skip_file(mode)
  local img = mode.get_image()
  if img then
    swayimg.imagelist.remove(img.path)
  end
end

-- Move the image by a fraction of the window size (dx, dy in tenths).
local function pan(mode, dx, dy)
  local wnd = swayimg.get_window_size()
  local pos = mode.get_position()
  local x = pos.x + math.floor(wnd.width * dx / 10)
  local y = pos.y + math.floor(wnd.height * dy / 10)
  mode.set_abs_position(x, y)
end

local function zoom(mode, factor)
  mode.scale = mode.scale * factor
end

local viewer_help = table.concat({
  "n/Space/PgDn next   p/PgUp prev   g/Home first   G/End last",
  "d/D next/prev dir   R random      o/O next/prev frame   Ctrl+Space animation",
  "h/j/k/l or arrows pan   +/- zoom   w/W fit width/height   z/Z fit/fill",
  "0 real size   Backspace reset   [ ] < > rotate   m/M flip   a antialias",
  "Return gallery   s slideshow   f fullscreen   i/t info   r reload",
  "c skip   Delete remove from list   Shift+Delete delete file   q/Esc quit",
}, "\n")

local gallery_help = table.concat({
  "h/j/k/l or arrows select   PgUp/PgDn page   g/Home first   G/End last",
  "+/- thumbnail size   Return open   s slideshow   f fullscreen   i/t info",
  "c skip   Delete remove from list   Shift+Delete delete file   q/Esc quit",
}, "\n")

--------------------------------------------------------------------------------
-- Viewer and slideshow key bindings (same layout for both modes)
--------------------------------------------------------------------------------
local function bind_viewer_keys(mode, is_slideshow)
  -- quit
  mode.on_key({ "q", "Escape" }, function() swayimg.exit() end)
  mode.on_key("F1", function() status(viewer_help) end)

  -- mode switching
  mode.on_key("Return", function() swayimg.mode = "gallery" end)
  mode.on_key("s", function()
    swayimg.mode = is_slideshow and "viewer" or "slideshow"
  end)
  mode.on_key("f", function() swayimg.fullscreen = not swayimg.fullscreen end)
  mode.on_key({ "i", "t" }, function()
    swayimg.text.visible = not swayimg.text.visible
  end)
  mode.on_key("a", function() swayimg.antialiasing = not swayimg.antialiasing end)
  mode.on_key("r", function() mode.reload() end)

  -- navigation (nsxiv style n/p plus the classic swayimg keys)
  mode.on_key({ "n", "space", "Next" }, function() mode.open("next") end)
  mode.on_key({ "p", "Prior" }, function() mode.open("prev") end)
  mode.on_key({ "g", "Home" }, function() mode.open("first") end)
  mode.on_key({ "Shift+g", "End" }, function() mode.open("last") end)
  mode.on_key("d", function() mode.open("next_dir") end)
  mode.on_key("Shift+d", function() mode.open("prev_dir") end)
  mode.on_key("Shift+r", function() mode.open("random") end)

  -- multi-frame images (GIF, WebP, APNG)
  mode.on_key("o", function() mode.frame = mode.frame + 1 end)
  mode.on_key("Shift+o", function()
    if mode.frame > 0 then
      mode.frame = mode.frame - 1
    end
  end)
  mode.on_key("Ctrl+space", function() mode.animation = not mode.animation end)

  -- pan (vim keys and arrows), 10% of the window per step
  mode.on_key({ "h", "Left" }, function() pan(mode, 1, 0) end)
  mode.on_key({ "l", "Right" }, function() pan(mode, -1, 0) end)
  mode.on_key({ "k", "Up" }, function() pan(mode, 0, 1) end)
  mode.on_key({ "j", "Down" }, function() pan(mode, 0, -1) end)

  -- zoom
  mode.on_key({ "equal", "plus", "Shift+plus", "KP_Add" }, function()
    zoom(mode, 1.1)
  end)
  mode.on_key({ "minus", "KP_Subtract" }, function() zoom(mode, 1 / 1.1) end)
  mode.on_key("w", function() mode.set_fix_scale("width") end)
  mode.on_key("Shift+w", function() mode.set_fix_scale("height") end)
  mode.on_key("z", function() mode.set_fix_scale("fit") end)
  mode.on_key("Shift+z", function() mode.set_fix_scale("fill") end)
  mode.on_key("0", function() mode.set_fix_scale("real") end)
  mode.on_key("BackSpace", function() mode.reset() end)

  -- rotate / flip
  mode.on_key({ "bracketright", "greater", "Shift+greater" }, function()
    mode.rotate(90)
  end)
  mode.on_key({ "bracketleft", "less", "Shift+less" }, function()
    mode.rotate(270)
  end)
  mode.on_key("m", function() mode.flip_vertical() end)
  mode.on_key("Shift+m", function() mode.flip_horizontal() end)

  -- marks and file list
  mode.on_key("Insert", function() mode.mark_image() end)
  mode.on_key({ "c", "Delete" }, function() skip_file(mode) end)
  mode.on_key("Shift+Delete", function() delete_file(mode) end)

  -- mouse extras (the defaults keep scroll = pan, Ctrl+scroll = zoom,
  -- left button = drag, right button = drag-and-drop to other apps)
  mode.on_mouse("Shift+ScrollUp", function() mode.open("prev") end)
  mode.on_mouse("Shift+ScrollDown", function() mode.open("next") end)
  mode.on_mouse("MouseSide", function() mode.open("prev") end)
  mode.on_mouse("MouseExtra", function() mode.open("next") end)
  mode.on_mouse("Alt+ScrollUp", function()
    if mode.frame > 0 then
      mode.frame = mode.frame - 1
    end
  end)
  mode.on_mouse("Alt+ScrollDown", function() mode.frame = mode.frame + 1 end)
end

bind_viewer_keys(swayimg.viewer, false)
bind_viewer_keys(swayimg.slideshow, true)

--------------------------------------------------------------------------------
-- Gallery key bindings
--------------------------------------------------------------------------------
local gallery = swayimg.gallery

gallery.on_key({ "q", "Escape" }, function() swayimg.exit() end)
gallery.on_key("F1", function() status(gallery_help) end)

gallery.on_key("Return", function() swayimg.mode = "viewer" end)
gallery.on_key("s", function() swayimg.mode = "slideshow" end)
gallery.on_key("f", function() swayimg.fullscreen = not swayimg.fullscreen end)
gallery.on_key({ "i", "t" }, function()
  swayimg.text.visible = not swayimg.text.visible
end)
gallery.on_key("a", function() swayimg.antialiasing = not swayimg.antialiasing end)
gallery.on_key("r", function() gallery.reload() end)

gallery.on_key({ "h", "Left" }, function() gallery.select("left") end)
gallery.on_key({ "l", "Right" }, function() gallery.select("right") end)
gallery.on_key({ "k", "Up" }, function() gallery.select("up") end)
gallery.on_key({ "j", "Down" }, function() gallery.select("down") end)
gallery.on_key("Prior", function() gallery.select("pgup") end)
gallery.on_key("Next", function() gallery.select("pgdown") end)
gallery.on_key({ "g", "Home" }, function() gallery.select("first") end)
gallery.on_key({ "Shift+g", "End" }, function() gallery.select("last") end)

gallery.on_key({ "equal", "plus", "Shift+plus", "KP_Add" }, function()
  gallery.thumb_size = gallery.thumb_size + 20
end)
gallery.on_key({ "minus", "KP_Subtract" }, function()
  gallery.thumb_size = gallery.thumb_size - 20
end)

gallery.on_key("Insert", function() gallery.mark_image() end)
gallery.on_key({ "c", "Delete" }, function() skip_file(gallery) end)
gallery.on_key("Shift+Delete", function() delete_file(gallery) end)

--------------------------------------------------------------------------------
-- External commands (examples, disabled). Uncomment what you need.
--------------------------------------------------------------------------------
-- Copy the path of the current image to the Wayland clipboard.
-- swayimg.viewer.on_key("y", function()
--   local img = swayimg.viewer.get_image()
--   if img then
--     os.execute("printf '%s' '" .. img.path .. "' | wl-copy")
--     status("Copied path")
--   end
-- end)

-- Open the current image in GIMP without blocking the viewer.
-- swayimg.viewer.on_key("Ctrl+e", function()
--   local img = swayimg.viewer.get_image()
--   if img then
--     os.execute("gimp '" .. img.path .. "' >/dev/null 2>&1 &")
--   end
-- end)
