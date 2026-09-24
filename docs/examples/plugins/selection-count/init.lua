myexplorer.register({
  id = "count",
  menu = "context",
  title = "显示选中数量",
  when = { min = 1 },
  run = function(ctx)
    myexplorer.toast("已选中: " .. ctx.count .. " (" .. ctx.dir .. ")")
  end,
})
