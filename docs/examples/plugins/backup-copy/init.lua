myexplorer.register({
  id = "bak",
  menu = "context",
  title = "创建 .bak 副本",
  when = { types = { "file" }, min = 1, in_archive = false },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      myexplorer.exec("cp", { "-n", path, path .. ".bak" })
    end
    myexplorer.toast("已将 " .. ctx.count .. " 个文件复制为 .bak")
    myexplorer.refresh()
  end,
})
