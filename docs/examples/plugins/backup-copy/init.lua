myexplorer.register({
  id = "bak",
  menu = "context",
  title = "Create .bak copy",
  when = { types = { "file" }, min = 1, in_archive = false },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      myexplorer.exec("cp", { "-n", path, path .. ".bak" })
    end
    myexplorer.toast(ctx.count .. " file(s) copied to .bak")
    myexplorer.refresh()
  end,
})
