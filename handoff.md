# MyExplorer 项目交接文档

## 1. 项目目标
**MyExplorer v2.0**（pubspec name: `myexplorer`）— 对标 Total Commander 的双窗格文件管理器。

核心特性：
- 强制双窗格布局（恒双窗口，不恢复单窗口模式）
- 自定义横快捷栏（INI 配置文件，非 SQLite）
- 右键 NC 菜单（2s 长按触发，无加粗选中）
- 拖选修复（drag-select 交互）
- 2×2 四格布局支持
- Windows 原生窗口 Chrome 定制（自定义标题栏、横快捷栏）

---

## 2. 当前进度
- ✅ **首次启动空白问题已修复并推送**（commit `7439d63`）
- ✅ **横快捷栏 INI 持久化迁移完成并推送**（commit `6a65946`）
- ✅ **V2.0 所有特性已实现并测试通过**
- ✅ **工作区干净，无未提交变更**
- ✅ **已推送到 origin/main**（`e5245f5..7439d63`）
- ✅ **418/418 单元测试全部通过**
- ✅ **Flutter analyze 零告警**

---

## 3. 已完成修改（最新提交）

| Commit | 说明 |
|--------|------|
| `7439d63` | `fix: defer window show until first frame to prevent blank startup` — `lib/main.dart` 中用 `addPostFrameCallback` 延迟 `appWindow.show()`/`maximize()` |
| `6a65946` | `feat: migrate shortcut bar persistence from SQLite to INI file` — 新增 `toolbar_ini.dart`，重写 `shortcut_bar_store.dart` 改用 INI 文件持久化 |

---

## 4. 关键文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | 应用入口，窗口初始化 + 启动时序修复 |
| `lib/features/navigation/shortcut_bar_store.dart` | 横快捷栏状态管理，现读 INI 文件 |
| `lib/features/navigation/toolbar_ini.dart` | INI 配置解析/序列化（新文件，UTF-8 BOM） |
| `windows/runner/main.cpp` | 原生启动，`MYEXPLORER_WINDOW_HIDE_ON_STARTUP` 隐藏窗口 |
| `windows/runner/window/window_api.cpp` | 原生窗口控制（show/hide/maximize 等） |
| `lib/features/panes/pane_view.dart` | Pane 视图，含 TabStrip 布局（Column/Expanded 修复） |
| `lib/app/myexplorer_shell.dart` | 主 Shell，双窗格布局 + quickView 集成 |
| `lib/features/panes/shell_store.dart` | Pane 状态管理，`isDual = signal(true)` 强制双窗口 |

---

## 5. 不能动的边界（红线）

- **`pubspec name: myexplorer` 不能改**（向后兼容）
- **`sqlite3` 版本保持 3.1.7**
- **恒双窗口**（`shell_store.dart` 中 `isDual = signal(true)`，不恢复单窗口）
- **不恢复 Linux/macOS/单窗口支持**
- **git commit 前必须 `dart format`**（CI 有格式关卡）
- **AGENTS.md 规则：NEVER push**（需用户明确确认）
- **Flutter/Dart 不在 PATH**，必须用完整路径：
  ```
  D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat
  D:\wd\.cowork-temp\flutter-sdk\flutter\bin\dart.bat
  ```
- **工作区通过 junction 访问**：`D:\wd` → `D:\Documents\VS Code\MyExplorer-main`

---

## 6. 已否掉的方案

| 方案 | 原因 |
|------|------|
| `runApp()` 后立即调用 `appWindow.show()` | 导致首次启动空白（Flutter 首帧未渲染） |
| 恢复单窗口模式 | 破坏双窗格设计，用户明确要求恒双窗口 |
| SQLite 作为快捷栏持久化 | 迁移到 INI 文件，更易于手动编辑和版本控制 |
| 在 `appWindow.show()` 前等待 `WidgetsBinding` 就绪 | 不够精确，首帧仍可能未渲染 |

---

## 7. 当前风险点

1. **INI 写入权限**：`快捷栏.ini` 写入 exe 同目录。若安装到 `Program Files`，UAC 会阻止写入，`_save()` 会静默失败。
   - **建议**：后续可迁移到 `%APPDATA%\dev.myexplorer\MyExplorer\` 目录。

2. **`addPostFrameCallback` 时序**：若首帧渲染过慢（如大量异步初始化），窗口会延迟显示。目前可接受，但需监控。

3. **旧 SQLite 快捷栏方法**：`AppDatabase.getShortcutBarItems` 等可能已成为死代码，建议清理或确认无引用。

4. **无未提交风险**：当前工作区干净，所有修改已推送。

---

## 8. 已经跑过的测试

| 测试项 | 结果 |
|--------|------|
| `flutter analyze` | ✅ No issues found |
| `flutter test --exclude-tags=integration` | ✅ 418/418 All tests passed |
| `flutter build windows --release` | ✅ 编译成功 |
| 手动启动验证（PID 21416） | ✅ 窗口正常显示，标题 "shenl - MyExplorer"，Responding=True |
| `dart format .` | ✅ 357 files formatted (1 changed) |

---

## 9. 下一步计划

**可选方向**（按优先级）：

1. **清理死代码**：检查 `AppDatabase` 中的快捷栏相关方法是否仍有引用
2. **INI 路径优化**：将 `快捷栏.ini` 迁移到 `%APPDATA%\dev.myexplorer\MyExplorer\`
3. **V2.0 发布打包**：准备安装包/Release 归档
4. **TC Parity 文档更新**：补全剩余 P3/P4 项的验证状态
5. **补充快捷栏单元测试**：覆盖 INI 读写、排序、分隔符等场景

**当前无遗留任务**，V2.0 已完整交付。

---

## 10. 新窗口启动提示词

```
[Hermes UI Workspace]
workspace=D:\Documents\VS Code\MyExplorer-main
instruction=Treat this as the active workspace/root for file paths and shell commands.
[/Hermes UI Workspace]

读取 handoff.md 了解项目状态，然后继续下一步工作。

项目状态：
- 所有修改已提交并推送到 origin/main
- 工作区干净，无未提交变更
- Flutter analyze 零告警，418 测试全过
- 首次启动空白问题已修复并验证
- 横快捷栏已迁移到 INI 文件持久化

关键路径：
- Flutter/Dart：D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat
- 工作区 junction：D:\wd → D:\Documents\VS Code\MyExplorer-main
- 当前 branch：main（已推送）
- 不可推送（AGENTS.md 规则，需用户确认）
```
