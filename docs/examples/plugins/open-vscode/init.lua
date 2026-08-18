-- A toolbar button that opens the current folder in VS Code. Needs the `code`
-- CLI on PATH (set a different command - e.g. `code-insiders`, `codium`, or a
-- flatpak wrapper - under Configure).
--
-- Windows note: the official VS Code installer puts `code.cmd` (a batch
-- shim) on PATH, and `myexplorer.exec` launches processes natively
-- (CreateProcess, no cmd.exe), which cannot start batch files. Configure the
-- command as `cmd /c code` when your VS Code install only provides the batch
-- shim.

local function editor_command(ctx)
  local cmd = (ctx.settings or {}).command
  if not cmd or cmd == "" then
    return "code"
  end
  return cmd
end

myexplorer.register({
  id = "open_vscode",
  title = "Open in VS Code",
  menu = "toolbar",
  icon = "icon.svg",
  settings = {
    { id = "command", type = "text", label = "Editor command", default = "code" },
  },
  run = function(ctx)
    if not ctx.dir or ctx.dir == "" then
      return
    end
    myexplorer.exec(editor_command(ctx), { ctx.dir })
    myexplorer.notify({
      title = "VS Code",
      message = "Opening " .. ctx.dir,
      level = "info",
    })
  end,
})

-- Bonus: also open a selected folder straight from its right-click menu. The
-- same bundled svg icon works in the context menu, just like the toolbar.
myexplorer.register({
  id = "open_vscode_selection",
  title = "Open in VS Code",
  icon = "icon.svg",
  when = { types = { "folder" }, min = 1, max = 1 },
  run = function(ctx)
    local target = ctx.paths[1]
    if not target or target == "" then
      return
    end
    myexplorer.exec(editor_command(ctx), { target })
  end,
})
