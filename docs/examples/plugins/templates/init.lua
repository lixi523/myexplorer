-- A fuller tour of the v2 API: the same "create from template" action is
-- surfaced four ways - a toolbar button (menu = "toolbar"), the background
-- right-click menu, the top Plugins menubar, and a shortcut - plus a second
-- menubar entry that edits this plugin's own settings via set_setting.
--
-- It reads a `select` dialog field, persists an author in settings, and writes
-- the chosen boilerplate with `fs`.

local TEMPLATES = {
  { id = "markdown", label = "Markdown 文档", ext = "md" },
  { id = "text", label = "纯文本", ext = "txt" },
  { id = "shell", label = "Shell 脚本", ext = "sh" },
  { id = "python", label = "Python 脚本", ext = "py" },
  { id = "html", label = "HTML 页面", ext = "html" },
  { id = "json", label = "JSON 文件", ext = "json" },
}

local SHELL = [[#!/usr/bin/env bash
set -euo pipefail

]]

local PYTHON = [[#!/usr/bin/env python3
"""%s."""


def main() -> None:
    pass


if __name__ == "__main__":
    main()
]]

local HTML = [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>%s</title>
</head>
<body>
</body>
</html>
]]

local function template_options()
  local opts = {}
  for _, tpl in ipairs(TEMPLATES) do
    opts[#opts + 1] = { value = tpl.id, label = tpl.label }
  end
  return opts
end

local function ext_for(id)
  for _, tpl in ipairs(TEMPLATES) do
    if tpl.id == id then
      return tpl.ext
    end
  end
  return "txt"
end

local function body(id, name, author)
  if id == "markdown" then
    local s = "# " .. name .. "\n"
    if author ~= "" then
      s = s .. "\n_by " .. author .. "_\n"
    end
    return s
  elseif id == "shell" then
    return SHELL
  elseif id == "python" then
    return string.format(PYTHON, name)
  elseif id == "html" then
    return string.format(HTML, name)
  elseif id == "json" then
    return "{\n}\n"
  end
  return ""
end

-- First pass opens the dialog; the submit re-runs the emitting action with
-- ctx.form populated, so every surface shares this one function.
local function create_from_template(ctx)
  local settings = ctx.settings or {}
  if not ctx.form then
    myexplorer.dialog({
      title = "从模板新建",
      fields = {
        { id = "name", type = "input", label = "文件名", default = "untitled" },
        {
          id = "template",
          type = "select",
          label = "模板",
          options = template_options(),
          default = settings.default or "markdown",
        },
      },
    })
    return
  end

  local name = ctx.form.name
  if not name or name == "" then
    return
  end
  local id = ctx.form.template or "markdown"
  local ext = ext_for(id)
  local path = ctx.dir .. "/" .. name .. "." .. ext
  myexplorer.write_text(path, body(id, name, settings.author or ""))
  myexplorer.notify({
    title = "从模板新建",
    message = "已创建 " .. name .. "." .. ext,
    level = "success",
  })
  myexplorer.refresh()
end

-- Primary entry: background menu + shortcut, and owns the settings schema.
myexplorer.register({
  id = "new_from_template",
  title = "从模板新建…",
  where = { "background" },
  icon = "note",
  shortcut = "ctrl+alt+n",
  settings = {
    { id = "author", type = "text", label = "作者（写入模板）", default = "" },
    {
      id = "default",
      type = "select",
      label = "默认模板",
      options = template_options(),
      default = "markdown",
    },
  },
  run = create_from_template,
})

-- Toolbar button, next to New Folder. Uses the bundled icon.
myexplorer.register({
  id = "new_from_template_toolbar",
  title = "从模板新建…",
  menu = "toolbar",
  icon = "icon.svg",
  run = create_from_template,
})

-- Top Plugins menubar. `icon` accepts a bundled image (svg/png) just like the
-- toolbar, or a named builtin glyph (see set_author below).
myexplorer.register({
  id = "new_from_template_menubar",
  title = "从模板新建…",
  menu = "menubar",
  icon = "icon.svg",
  run = create_from_template,
})

-- A second menubar entry that edits this plugin's own setting.
myexplorer.register({
  id = "set_author",
  title = "设置模板作者…",
  menu = "menubar",
  icon = "pencil",
  run = function(ctx)
    if not ctx.form then
      myexplorer.dialog({
        title = "模板作者",
        fields = {
          {
            id = "author",
            type = "input",
            label = "作者名称",
            default = (ctx.settings or {}).author or "",
          },
        },
      })
      return
    end
    myexplorer.set_setting("author", ctx.form.author or "")
    myexplorer.notify({
      title = "从模板新建",
      message = "作者已保存",
      level = "success",
    })
  end,
})
