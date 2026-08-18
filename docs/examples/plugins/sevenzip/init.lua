-- 7-Zip integration. Needs the `7z` binary on PATH (p7zip / 7-Zip); the
-- tar.gz entries also need `tar`. All compress entries share a "Compress with
-- 7-Zip" submenu: quick .zip / .tar.gz plus "Add to archive…", which opens a
-- modal for the name, format and compression level.

local GROUP = "使用 7-Zip 压缩"
local SELECTION = { min = 1, in_archive = false }

local function basename(path)
  return (path:gsub("(.*/)(.*)", "%2"))
end

local function strip_ext(name)
  return (name:gsub("%.[^.]+$", ""))
end

local function default_name(ctx)
  return strip_ext(basename(ctx.paths[1]))
end

local function run_7z(ctx, name, fmt, level)
  local archive = ctx.dir .. "/" .. name .. "." .. fmt
  local args = { "a", "-t" .. fmt, "-mx" .. level, archive }
  for _, path in ipairs(ctx.paths) do
    args[#args + 1] = path
  end
  myexplorer.run_task({
    title = "7-Zip 压缩: " .. name .. "." .. fmt,
    cmd = "7z",
    args = args,
    cwd = ctx.dir,
    timeout = 3600,
  })
end

local function run_targz(ctx, name)
  local args = { "-czf", name .. ".tar.gz" }
  for _, path in ipairs(ctx.paths) do
    args[#args + 1] = basename(path)
  end
  myexplorer.run_task({
    title = "tar 压缩: " .. name .. ".tar.gz",
    cmd = "tar",
    args = args,
    cwd = ctx.dir,
    timeout = 3600,
  })
end

myexplorer.register({
  id = "zip",
  group = GROUP,
  title = "压缩为 .zip",
  icon = "file-zip",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end
    run_7z(ctx, default_name(ctx), "zip", "5")
  end,
})

myexplorer.register({
  id = "targz",
  group = GROUP,
  title = "压缩为 .tar.gz",
  icon = "archive",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end
    run_targz(ctx, default_name(ctx))
  end,
})

-- Custom pass: first invoke opens the modal, the submit re-runs this action
-- with `ctx.form` populated.
myexplorer.register({
  id = "custom",
  group = GROUP,
  title = "添加到压缩包…",
  icon = "sliders",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end

    if not ctx.form then
      myexplorer.dialog({
        title = "添加到压缩包",
        fields = {
          { id = "name", type = "input", label = "压缩包名称",
            default = default_name(ctx) },
          { id = "format", type = "select", label = "格式",
            options = { "7z", "zip", "tar", "tar.gz" }, default = "7z" },
          { id = "level", type = "select", label = "压缩级别",
            options = {
              { value = "1", label = "最快" },
              { value = "5", label = "正常" },
              { value = "9", label = "极限" },
            }, default = "5" },
        },
      })
      return
    end

    local name = ctx.form.name
    if not name or name == "" then return end

    local fmt = ctx.form.format or "7z"
    if fmt == "tar.gz" then
      run_targz(ctx, name)
    else
      run_7z(ctx, name, fmt, ctx.form.level or "5")
    end
  end,
})

-- Extract a selected archive into a folder next to it.
myexplorer.register({
  id = "extract",
  title = "在此解压（7-Zip）",
  icon = "archive",
  when = { extensions = { "7z", "zip", "rar", "tar", "gz", "bz2", "xz" }, min = 1 },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      local dest = ctx.dir .. "/" .. strip_ext(basename(path))
      myexplorer.run_task({
        title = "解压 " .. basename(path),
        cmd = "7z",
        args = { "x", path, "-o" .. dest, "-y" },
        cwd = ctx.dir,
        timeout = 3600,
      })
    end
  end,
})
