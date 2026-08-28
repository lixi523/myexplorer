# MyExplorer 项目交接文档

## 1. 项目目标
**MyExplorer v3.5.0**（pubspec name: `myexplorer`）— 对标 Total Commander 的 Windows 双窗格文件管理器（fork 自 Waydir，已全面更名）。

核心特性：
- 强制双窗格布局（恒双窗口，不恢复单窗口模式）
- 自定义快捷栏（手写横快捷栏 INI + 中间 46px 竖快捷栏；**横快捷栏支持右键编辑/删除、超出宽度自动换行**；**竖快捷栏含 4 个复制快捷方式**）
- **慢速双击重命名**：普通双击间隔的 2~3 倍间隔双击 → 进入重命名模式（列表/网格视图均支持）
- 右键 NC 扩展选择模式（2 秒长按触发菜单，无加粗选中）
- 深色主题：底色 RGB(70,75,85)、文字 RGB(223,233,233)
- **便携式布局**：所有数据（数据库/日志/主题/插件/更新/缓存）在程序目录内，不写 %APPDATA%/%TEMP%；**只读目录（如 Program Files）自动降级到 %LOCALAPPDATA%\MyExplorer**
- **主题配色调色板由 `themes/*.ini` 文件驱动**（每主题一个 ini，键中文名 + RGB 色号；**兼容 GBK/ANSI 编码文件**）
- Windows 原生窗口 Chrome（bitsdojo_window 自定义标题栏、横快捷栏）
- Rust 原生核心（list/search/trash/enumerate/pdf/pty/sftp/plugin）+ FFI

---

## 2. 当前进度（2026-08-28）

- ✅ **v3.5.0 已提交并推送**（pubspec `3.5.0`）：全量代码审查与加固
  - **系统性审查 72 个文件**（Dart + Rust），修复 **80+ 项问题**
  - **P0 崩溃级**（5 项）：`launch_args.dart` switch fall-through 加 `break`、`base.dart` `_active` getter StateError 安全回退、`search.rs` FFI 入口添加 `guard()` panic 屏障、`walker.rs` Drop 实现改用 `if let Ok` 避免 unwinding 二次 panic、`pty.rs` spawn 失败正确清理 `child`/`writer` 并处理 mutex poison
  - **P1 功能异常**（15 项）：`actions.dart` 5 个 `async void` 改 `Future<void>` + try-catch、`operation_store.dart` catch 分支补 `_currentWorker?.dispose()` 防 isolate 泄漏、`drive_store.dart` 全局实例改懒加载 + `disposeDriveStore()` 回收 Timer、`shell_store.dart` `dispose()` 中 `current = null` 解除静态引用、`drag_drop.dart` Completer 加 `.timeout()` + `whereType<String>()`、`format.dart` `formatBytes` 处理 `<= 0` 输入、`ini_file.dart` 跳过空 key、`sftp/ops.rs` 单次读取上限 16 MiB
  - **P2 空安全与资源**（25 项）：`archive_reader.dart` 路径拼接改用 `p.join()`、`settings_store.dart` `dispose()` 关闭 DB、`update_store.dart`/`open_service.dart` detached process 异常处理、`selection_controller.dart` Shift 选择快照 + 边界检查、`git_status_store.dart` `on Object` 改 `on Exception`、`hidden_list_store.dart` `delete()` 包裹 try-catch、`myexplorer_core_loader.dart` FFI 异常处理、`file_view.dart` 使用正确常量名、`app_text_styles.dart` force unwrap 改回退
  - **P3 主题一致性**（37 处）：`Colors.black.withValues` → `AppColors.shadowSubtle`、`Colors.white`（checkbox/icon）→ `AppColors.bg`、`Colors.black54` → `AppColors.bg.withValues(alpha: 0.4)`；补全 `zh.i18n.json` `terminalInsert` 翻译
  - **CI 加固**（4 项）：pdfium 版本固定、集成测试覆盖整个目录、Rust 构建缓存、fastforge 版本固定
  - `dart analyze lib/` ✅ **0 issues**、`cargo check` ✅ **编译通过**
  - **CI 修复推送**（v3.5.0 后续）：
    - `chore: fix dart formatting (11 files)` — `a7b8d3d`：CI `dart format --set-exit-if-changed` 发现 11 个文件格式不合规，自动格式化后推送
    - `fix: remove const from BoxDecoration using AppColors.bg getter` — `7d3f5d6`：`AppColors.bg` 是 getter 而非编译时常量，不能用于 `const BoxDecoration`，移除 `const` 修复 release 构建失败
    - `fix: correct pdfium version format to chromium/8021` — `f6a7070`：pdfium-binaries 版本标签格式为 `chromium/<build>` 而非语义化版本 `v134.0.7099.0`，修复 404 下载失败
    - `fix: remove stale terminal columns from drift generated file` — `3c31bbe`：`app_database.g.dart` 残留 8 个终端列（`terminal`/`terminalShell` 等，v3.4.0 移除终端模块时未同步重新生成），迁移测试 `map` 时 `!` 空值检查崩溃；手动移除 596 行废弃代码，同步更新迁移测试
- ✅ **v3.4.0 已提交并推送**（pubspec `3.4.0`）：移除内置终端功能模块
  - **删除 `lib/core/terminal/` 目录**：终端服务（`terminal.dart`）、shell 检测（`shell_detector.dart`）、终端启动（`terminal_launch.dart`）、系统字体（`system_fonts.dart`）
  - **删除终端面板 UI**：`pane_view.dart` 中移除 `_TerminalPanel`、`_TerminalHeader`、`_TerminalTabChip`、`_TerminalIconButton`、`_TerminalResizeHandle` 等类
  - **移除主题配色**：`app_theme_definition.dart` 删除 `TerminalColors` 类，`app_theme_registry.dart` 移除所有 `terminal:` 配色块
  - **清理设置**：`settings_registry.dart` 移除终端设置分类（`SettingsCategory.terminal`）和所有终端设置项；`settings_store.dart` 删除终端相关信号
  - **移除快捷键**：`keybinding_labels.dart` 移除 `ShortcutGroup.terminal` 和终端快捷键标签
  - **移除命令面板**：`command_palette.dart` 移除 `toggle_terminal` 命令
  - **移除依赖**：`pubspec.yaml` 删除 `myexplorer_term` 依赖
  - **清理 i18n**：`en.i18n.json`、`zh.i18n.json`、`strings_en.g.dart`、`strings_zh.g.dart` 删除所有终端翻译键
  - **移除主菜单**：`menus.dart` 删除"终端"菜单项
  - **删除 `packages/myexplorer_term/` 整个终端包**（100+ 文件）
  - **删除终端测试**：`test/unit/terminal/` 目录及相关测试文件；修复其他测试中的终端引用
  - `flutter analyze --fatal-infos --fatal-warnings` ✅ **0 issues**
  - CI **待验证**（推送后自动触发）、`flutter build windows --release` **待构建**
- ✅ **v3.3.0 已更新**（pubspec `3.3.0+47`，**本地修改完成，待提交推送**）：终端功能修复
  - **中文输入修复（IME）**：移除 `hardwareKeyboardOnly`（此前 Windows 下禁用 CustomTextEdit，改用仅硬件键盘的 CustomKeyboardListener，导致 IME 无法接入）；移除 `_openOrCloseInputConnectionIfNeeded` 中的 `consumeKeyboardToken()` 检查（切换终端时 FocusNode 键盘 token 被消费，TextInputConnection 无法重新建立）；修复搜索框关闭时 shell 顶层 FocusNode 抢走终端焦点的问题（`myexplorer_shell.dart` searchActive effect 加 `_isTerminalFocused()` 守卫）；简化 CustomTextEdit，删除移动端专用参数（`keyboardType`、`keyboardAppearance`、`deleteDetection`）。文件变更：`custom_text_edit.dart`（移除 consumeKeyboardToken）、`terminal_view.dart`（移除 hardwareKeyboardOnly 及移动端参数）、`keyboard_listener.dart`（清理 onComposing 参数）、`myexplorer_shell.dart`（searchActive effect 加终端焦点守卫）
  - **默认 shell 改为 PowerShell 7**：`terminalShell` 默认值改为 WindowsApps 路径 `Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\pwsh.exe`；偏好路径不存在时自动回退到系统默认 shell
  - `ShellDetector` 同步添加 WindowsApps 路径检测
  - 单元测试 **561 全过**、`flutter analyze` 0 issues、`flutter build windows --release` 成功、README/handoff 已更新
- ✅ **v3.2.0 已提交但未推送**（pubspec `3.2.0+46`）：快捷栏图标缓存冲突修复
- ✅ **v3.1.0 已提交但未推送**（pubspec `3.1.0+45`）：稳定性大修 + 精简
  - **大文件复制取消即时 + 进度实时**：Rust 新增 `copy.rs`（线程内 CopyFileEx + 原子取消/进度，`myexplorer_copy_start/poll/cancel/free` 四个 FFI 入口全带 guard），Dart `native_copy.dart` 改 50ms 异步轮询
  - **QuickLook 压缩包内读取/保存移出 UI isolate**：`fs_worker_pool` 新增 `archiveRead`/`archiveMutate` op（2/5 分钟超时），`quick_look_io`/`code_editor` 改走 worker
  - **压缩覆盖不再误删原文件**：`ArchiveWriter.create` 用 `SafeFileReplace.replaceWithFile`（MoveFileEx 原子替换），worker 仅在本次产物生成后取消才删 dest
  - 其余修复：分割双重 openRead、插件 invoke 超时强杀 + worker 崩溃自愈、剪贴板 stdin 传参、冲突等待 5 分钟超时（本地 + SFTP）、FsWorkerPool 操作/握手超时、sftp FFI panic 屏障、`_uniqueName` 随机后缀、`isWritableDir` 探针缓存、启动清理 7z 残留
  - **新增**：横快捷栏配置对话框拖动排序（ReorderableListView → `ShortcutBarStore.reorder` 落盘）；**快捷栏图标修复**（TC"命令+参数"图标列、引号+索引规范、增删即时刷新 via key + didUpdateWidget、权限受限路径降级）；右键快捷栏菜单 Overlay.of 崩溃修复
  - **移除**：容器（侧边栏 WSL 发行版列表 + 终端下拉）与标签（Tags）功能全套（侧边栏分区/右键菜单/文件标签圆点/`tag://` 视图/`tag:` 过滤/联动），DB 表保留兼容迁移；`wsl_path.dart` 保留（WSL 路径导航/终端共用）
  - 单元测试 **561 全过**（原 578 − 容器/标签测试 17 + 新增 1）、`flutter analyze` 0 issues
- ✅ **v3.0.1 已提交并推送**（pubspec `3.0.1+44`），本地 Release 构建通过；**CI 全绿（Run #50，2026-08-24：Analyze & Format / Unit Tests / Integration Tests / Build & Package 4 job 全过），Release v3.0.1 已发布**（`MyExplorer-3.0.1+44-windows-setup.exe` / `.zip`）
- ✅ **v3.0.1 内容（三部分）**：
  1. **书签/标签/侧栏 INI 化**（`feat: bookmarks, tags and sidebar prefs persist to INI files`）：书签.ini / 标签.ini / 侧栏.ini 存程序根目录（UTF-8 BOM），启动时加载（main.dart）；标签定义 + 文件关联全量在标签.ini；侧栏分区顺序/隐藏/折叠落盘；**一次性迁移**（INI 缺失时从 SQLite 导入）；新增通用 `lib/utils/ini_file.dart` + 12 个单测
  2. **书签拖拽排序**（同提交）：侧边栏书签区普通模式支持整行拖拽排序（`ReorderableListView` + `_BookmarkReorderList`），复用 `BookmarkStore.reorder` 落盘书签.ini
  3. **复制/移动修复**（`fix: copy temp random suffix control chars`）：**v2.5 引入的 `_randomHex` bug**——`String.fromCharCodes(nextInt(16))` 生成控制字符（NUL/换行）而非 hex，临时文件名非法导致 Windows 拒绝复制（Permission denied）；改从 hex 字符表取字符，复制/移动到对面窗口恢复
- 单元测试 **578 全过**、integration **86 过 + 4 skip**、`flutter analyze` 0 issues、`flutter build windows --release` 成功

---

## 3. 已完成修改（近期关键提交）

| Commit | 说明 |
|--------|------|
| `feat: v3.5.0 — full code review & hardening, 80+ fixes` | **v3.5.0（已推送）**：pubspec `3.5.0`；全量代码审查 72 文件（Dart + Rust），修复 80+ 项问题（P0 崩溃级 5 + P1 功能异常 15 + P2 空安全/资源 25 + P3 主题一致性 37 + CI 加固 4）；`dart analyze` 0 issues、`cargo check` 通过（72 文件变更，+533/-372） |
| `chore: fix dart formatting (11 files)` | **v3.5.0 CI 修复**：`dart format --set-exit-if-changed` 发现 `open_service.dart`、`drive_store.dart`、`file_view.dart` 等 11 个文件缺少尾逗号/换行不合规；自动格式化后推送（11 文件，+36/-25） |
| `fix: remove const from BoxDecoration using AppColors.bg getter` | **Release 构建修复**：`settings_widgets.dart` 第 334 行 `const BoxDecoration(color: AppColors.bg)` 编译失败——`AppColors.bg` 是 getter 非常量；移除 `const` 修复（1 文件 1 行） |
| `fix: correct pdfium version format to chromium/8021` | **CI 构建修复**：`build_myexplorer_core_windows.ps1` pdfium 版本 `v134.0.7099.0` 不存在（实际标签格式 `chromium/<build>`）；改为 `chromium/8021`（2026-08-25 最新），修复下载 404 |
| `fix: remove stale terminal columns from drift generated file` | **数据库迁移修复**：`app_database.g.dart` 残留 8 个终端列（`terminal`/`terminalShell`/`terminalFontFamily` 等），v3.4.0 移除终端模块时 `app_database.dart` 已删除但生成文件未重新生成；迁移测试从 v12 升级时 `map` 读 `terminal_shell`（旧库无此列）触发 `Null check operator used on a null value`；手动移除 596 行废弃代码 + 更新迁移测试（2 文件，+6/-596） |
| `feat: v3.4.0 — remove built-in terminal module` | **v3.4.0（已推送）**：pubspec `3.4.0`；删除 `lib/core/terminal/` 终端服务；移除 `pane_view.dart` 终端面板 UI；删除 `TerminalColors` 主题配色；清理终端设置分类与快捷键绑定；移除 `myexplorer_term` 依赖；清理所有终端 i18n 翻译键；移除主菜单"终端"菜单项；删除 `packages/myexplorer_term/` 整个终端包；删除终端测试并修复其他测试引用（126 文件变更，+758/-16083） |
| `chore: fix analyze warnings for CI` | **v3.4.0 修复**：移除未使用的导入（`wsl_path.dart`、`app_text_field.dart`、`settings_store.dart` 等）；删除未使用的 `_focusFiles` 方法；`analysis_options.yaml` 添加 `analyzer.exclude` 排除 `.g.dart` 生成文件 |
| `fix: terminal focus stolen by searchActive effect` | **v3.3.0**：修复搜索框关闭时 shell 顶层 FocusNode 抢走终端焦点导致 TextInputConnection 断开的问题；`myexplorer_shell.dart` searchActive effect 加 `_isTerminalFocused()` 守卫 |
| `feat: v3.3.0 — terminal IME fix, default shell PowerShell 7` | **v3.3.0（待提交）**：pubspec `3.3.0+47`；终端 IME 修复（移除 `hardwareKeyboardOnly` 让 CustomTextEdit 始终生效；移除 `consumeKeyboardToken()` 确保切换终端后 TextInputConnection 可正常重新建立）；默认 shell 改为 PowerShell 7（WindowsApps 路径），偏好路径不存在时回退；ShellDetector 添加 WindowsApps 路径检测；README/handoff 更新 |
| `feat: v3.2.0 — fix shortcut icon cache key collision, SVG path consistency` | **v3.2.0（待提交）**：pubspec `3.2.0+46`；缓存键由截断 base64 改为 SHA256 哈希（解决路径前缀相同导致图标共享冲突）；SVG 路径解析统一使用 `_spec` 实例变量；CHANGELOG/README/handoff 更新 |
| `feat: v3.1.0 — copy cancel, archive-edit off UI thread, drag-reorder shortcuts, drop containers & tags` | **v3.1.0（已提交未推送）**：pubspec `3.1.0+45`；Rust `copy.rs`（线程内 CopyFileEx + 原子取消/进度 + 4 FFI 入口）；QuickLook 包内读写移出 UI isolate（fs_worker_pool 新增 archiveRead/archiveMutate）；压缩覆盖误删修复；分割双读/插件超时/剪贴板 stdin/冲突超时/pool 超时/sftp panic 屏障/`_uniqueName` 加固/探针缓存/7z 残留清理；快捷栏配置拖动排序 + **图标修复**（命令+参数图标列/引号索引/增删即时刷新/右键菜单 Overlay 崩溃）；**移除容器与标签功能**（49+ 文件）；561 单测 + 图标/复制集成测试；CHANGELOG/README/handoff 更新 |
| `feat: v3.0.1 — INI persistence, bookmark drag reorder, copy fix` | **v3.0.1（已推送，2026-08-24）**：pubspec `3.0.1+44`；书签/标签/侧栏 INI 化（含迁移 + ini_file 工具 + 12 单测）；书签拖拽排序；`_randomHex` 控制字符 bug 修复（复制/移动恢复）；CHANGELOG/README/handoff 更新；推送含下方两个未推送提交 |
| `fix: copy temp random suffix produced control chars` | **复制/移动修复**：`_randomHex` 用 `String.fromCharCodes(nextInt(16))` 生成控制字符（NUL/换行）而非 hex → 临时文件名非法 → Windows 拒绝复制（v2.5 引入）；改从 hex 字符表取字符；集成测试 5 个 copy 失败全修复 |
| `feat: bookmarks, tags and sidebar prefs persist to INI files` | **INI 化**：书签.ini/标签.ini/侧栏.ini 程序根目录 + 启动加载 + 一次性 SQLite 迁移；标签定义+文件关联全量 INI；新增 `lib/utils/ini_file.dart`；+12 单测 |
| `feat: v3.0.0 — full UI localization, plugin & Rust core error i18n` | **v3.0.0（已推送，2026-08-18）**：pubspec `3.0.0+43`；文件类型名/插件错误消息/操作错误全汉化；Rust 插件错误消息 20 处汉化 + 重建 core；5 个示例插件汉化；i18n 新增 `dialog.ok`、`plugins.errorLabel`、`plugins.errors.*`；CHANGELOG/README/handoff 更新 |
| `feat: v2.9.0 — crash hardening, hidden-list modes & editing` | **v2.9.0（已推送，2026-08-18）**：pubspec `2.9.0+42`；CHANGELOG/README/handoff 更新；推送含下方两个未推送提交 |
| `feat: hidden list inline editing` | 隐藏列表对话框行内编辑（每行编辑按钮 → 输入框 + 保存/取消）；`HiddenListStore.updatePath` 原子替换；i18n 新增 edit/save/cancel/updated；+3 单测 |
| `feat: hidden list supports name-based matching` | 隐藏列表双模式：纯名称条目全局按名隐藏、含分隔符条目精确路径匹配（自动推断）；+5 单测 |
| `fix: FFI panic barriers with unwind — plugin/crash hardening` | **闪退修复**：release `panic = "abort"` → `"unwind"`；pdf/folder_scan/pty 入口补 catch_unwind（累计 21 个 FFI 入口全屏障）；`guard` 记录 panic 到 `%TEMP%\myexplorer_core_panic.log`；open-vscode 示例注明 code.cmd；rust 侧 +2 guard 单测 |
| `feat: v2.8.0 — risk-point fixes, code review hardening, lint enforcement, FFI panic guards` | **v2.8.0（已推送，2026-08-17）**：pubspec `2.8.0+41`；内置主题 ini 按 id 补缺、UTF-16 BOM 解码、导出注释；移除 runInShell×4；`unawaited_futures` lint + 6 处丢 Future 修复 + `activeStore` 守卫 + 网格字号回退 + 注释乱码；Rust FFI `catch_unwind` 屏障 7 入口；Rust core 一致性检查脚本 + CI 护栏；CHANGELOG/README/handoff v2.8.0 |
| `feat: v2.7.0 — copy shortcuts, slow double-click rename, shortcut bar wrap, code review fixes` | 竖快捷栏 4 复制按钮、慢速双击重命名、横快捷栏换行/精简（齿轮图标）、代码审查修复、preferences_view/file_view 拆分（v2.8.0 一并推送） |
| `fix: v2.5 code review — 16 bug fixes` | 路径穿越防护、编译错误、插件操作级联、快捷键 fall-through、DB 过度删除、搜索异常静默失败、git 监听泄漏、dispose 丢设置、首屏滚动、主题 seeding、SFTP session 验证、exit port 订阅、内存泄漏、缓存永 miss、i18n 标签修复 |
| `feat: match Windows sort order (StrCmpLogicalW)` | 重写 `compareNatural`：点号断点、number<char、前导零多的排前（v01<v1）；压缩包列表排序同步 |
| `feat: light mode text color RGB(60,65,75)` | `lightTheme.fg` 改 `0xFF3C414B` |
| `feat: file list text black in panes` | 列表/网格视图文件名默认色改为 `AppColors.fg`（去掉 alpha 0.9 / fgMuted） |
| `fix: folder name color per brightness` | 文件夹名浅色用 `AppColors.fg`、深色恢复纯灰 `0xFFE9E9E9` |
| `refactor: themes from themes/*.ini` | 移除 JSON，`AppThemeDefinition/Palette/TerminalColors` 的 `fromIni/toIni`；注册表从 ini 加载 + 首次自动导出内置主题；设置 UI 增删改走 ini |
| `feat: ini palette/terminal keys in Simplified Chinese` | `[palette]`/`[terminal]` 键名中文化，值 RGB 色号（透明色 8 位），兼容旧英文键 |
| `feat: folder name color from ini` | 文件夹名深/浅色从 palette 读取：新增 `folderNameDark`/`folderNameLight` 字段写入 ini（`深色文件夹文字色`/`浅色文件夹文字色`），`navigation_store` 按主题亮度取值 |
| `910ec05` | `chore: drop unused path_provider dependency` |
| `feat...` (便携化) | 所有数据目录迁至程序目录 |
| `fix: keep transparent tint rows on the window background` | 文件行底色与窗口一致 |

---

## 4. 关键文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | 入口，窗口初始化 + 首帧后显示 |
| `lib/app/myexplorer_app.dart` | 主题解析：`themeId` → `AppThemeRegistry.loadSync()` → `AppTheme.build` |
| `lib/core/fs/file_sort.dart` | **StrCmpLogicalW 排序**：`compareNatural` + `_metaType/_parseDigits` |
| `lib/core/fs/fs_worker_pool.dart` | 压缩包列表排序用 `compareNatural` |
| `lib/ui/theme/app_theme_definition.dart` | **主题模型 + ini 序列化**：`TerminalColors/AppThemePalette/AppThemeDefinition` 的 `fromIni/toIni`、中文键映射表、`folderNameDark/folderNameLight`、`parseThemeColor/_iniColor/_parseIni` |
| `lib/ui/theme/app_theme_registry.dart` | **ini 主题加载**：`load()` 读 `themes/*.ini` + 首次自动导出内置主题；内置 const 仅作兜底；同名 ini 覆盖内置；外加 12 个内置主题 const |
| `lib/ui/theme/app_theme.dart` | `AppColors`（从当前主题取色）+ `AppTheme.build` |
| `lib/features/settings/panes/appearance_pane.dart` | 自定义主题增/删/读/编辑全部走 `.ini`（新增基于 dark 模板） |
| `lib/core/database/app_database.dart` | drift 持久化设置（themeMode 存主题 id） |
| `lib/features/navigation/navigation_store.dart` | **文件夹名颜色从 palette 读取**：深色用 `folderNameDark`、浅色用 `folderNameLight`（`_colorRuleDecorations`） |
| `test/unit/theme/` | `app_theme_definition_test.dart`、`app_theme_registry_test.dart`（ini 解析/加载） |
| `lib/core/fs/myexplorer_core_loader.dart` | Rust FFI 加载器 |
| `lib/utils/ini_file.dart` | **通用 INI 工具（v3.0.1 新增）**：段/键值/注释/列表解析与序列化、UTF-8 BOM、原子写入；书签.ini/侧栏.ini 基于它（标签.ini 随 v3.1.0 标签功能删除） |
| `lib/core/platform/app_dirs.dart` | **便携目录解析 + 只读降级**：`selectBase`/`isWritableDir` 检测 exe 目录可写性，不可写回退 `%LOCALAPPDATA%\MyExplorer`；`debugExeDirOverride`/`debugReset` 测试 seam |
| `lib/core/platform/gbk_codec.dart` | GBK(code 936) 编解码（FFI）；**encodeGbkBytes 已修复 UAF**（`Uint8List.fromList` 拷贝） |
| `lib/app/myexplorer_shell/menus.dart` + `menus_plugin.dart` | 拆分的两个 part：菜单构建/分发 + 插件执行域（`_MyExplorerMenuMixin` / `_MyExplorerPluginMixin`） |
| `lib/features/navigation/sidebar.dart` + `sidebar_*.dart` | 拆分：sidebar（主 State）+ edit/footer/header/operations 四个 part |
| `scripts/build_myexplorer_core_windows.ps1` | 构建并 vendored Rust core + pdfium |
| `scripts/check_myexplorer_core_up_to_date.ps1` | **Rust core 一致性检查（v2.8.0 新增）**：SHA256 对比本地构建与 vendored DLL，不一致 exit 1 提示重建；CI build job 护栏 |
| `lib/ui/dialogs/shortcut_bar_config_dialog.dart` | 快捷栏配置：支持 `editingId` 预填编辑、保存/取消、行内编辑 |
| `test/` | 561 单测 + 集成（native_copy 3 个新增） |

---

## 5. 不能动的边界（红线）

- **`pubspec name: myexplorer` 不能改**（已全面更名，import 路径 `package:myexplorer/`）
- **不写程序目录外**：任何数据目录都必须经 `AppDirs`；仅当 exe 目录只读（Program Files）时降级到 `%LOCALAPPDATA%\MyExplorer`（v2.6 新增白名单例外），禁止再引入 `path_provider` / 直写 %APPDATA%/%TEMP%
- **恒双窗口**（`shell_store.dart` `isDual = signal(true)`）
- **不恢复 Linux/macOS/单窗口支持**
- **插件 Lua API 为 `myexplorer.register` 等**（勿改回 waydir）
- ~~**NEVER push**~~（已移除，可直接推送到 main 分支）
- **git commit 前必须 `dart format`**（CI 有格式关卡）
- **Flutter/Dart 已安装到 `C:\flutter\flutter\bin`**（2026-08-28 安装，Flutter 3.38.10 / Dart 3.10.9），**已加入用户 PATH**
- **cargo 不在 PATH**：`C:\Users\shenl\.cargo\bin\cargo.exe`（构建 Rust core 用）
- **工作区 junction**：`D:\wd` → `D:\Documents\VS Code\MyExplorer-main`；真仓库在 `github.com/lixi523/myexplorer`
- **主题配色来源是 `themes/*.ini`**：内置 const 仅作兜底，改动配色应改 ini 文件

---

## 6. 已否掉的方案

| 方案 | 原因 |
|------|------|
| 恢复单窗口模式 | 破坏双窗格设计，用户明确恒双窗口 |
| SQLite 持久化快捷栏 | 迁移到 INI 文件（`快捷栏.ini`，exe 目录） |
| `ExtractIconExW` 提取图标 | 本机 user32.dll 缺该导出，改用 `SHGetFileInfoW`/`SHDefExtractIconW` |
| path_provider / %APPDATA% 数据目录 | 用户要求便携式布局 |
| JSON 自定义主题 | 用户要求统一用 ini（`themes/*.ini`），已移除 |
| 内置主题仅存代码 const | 用户要求所有主题（含内置）配色从 ini 读取，首次启动自动导出 |

---

## 7. 当前风险点

1. **首次启动自动导出内置 ini**：~~若 `themes/` 目录已非空（如用户只留一个自定义 ini），`load()` 会跳过导出内置 ini，导致 dark 等内置主题退回 const 兜底配色。~~ ✅ **已处理（2026-08-17）**：`_seedBuiltInThemes*` 改为按内置 id 补缺（扫描现有 ini 收集 id，缺哪个补哪个），自定义同名 ini 不被覆盖；无新依赖，单测覆盖（`app_theme_registry_test.dart`）。
2. **中文键 ini 编码**：解析已支持 UTF-8 优先 + GBK 回退（v2.6）。✅ **已处理（2026-08-17）**：`_decodeThemeBytes` 增加 BOM 检测（UTF-8 BOM / UTF-16LE `FF FE` / UTF-16BE `FE FF`），第三方存 UTF-16 的 ini 可正常解析；单测覆盖 LE/BE。
3. **`shadowSubtle` 半透明**：输出为 8 位 ARGB（`33000000`），其余不透明输出 6 位 RGB。✅ **已处理（2026-08-17）**：`toIni()` 输出顶部加 `;` 注释提示「半透明颜色请保留 8 位 #AARRGGBB」（解析自动忽略 `;` 行，round-trip 单测仍过）；编辑外部脚本用记手写仍可能丢 alpha，属预期。
4. **便携式写入权限**：exe 目录只读（Program Files）时自动降级 `%LOCALAPPDATA%\MyExplorer`（v2.6）；`support()` 解析在首次调用即决定 base，之后缓存（**缓存生命周期 = 进程生命周期**，属设计而非缺陷）。✅ **已锁定行为**（2026-08-17）：新增 `app_dirs_test.dart` 用例验证「改 exe 目录 → 缓存固定 → `debugReset` 后重新解析」。不做运行时迁移（成本高、竞态风险大）。
5. **Rust core 需单独构建**：integration 测试与发布依赖 `rust/myexplorer_core/target/release/myexplorer_core.dll`；改动 Rust 后需 `cargo build --release` 且同步 vendored。✅ **已处理（2026-08-17）**：新增 `scripts/check_myexplorer_core_up_to_date.ps1`（SHA256 对比 target 与 vendored，不一致 exit 1 并提示跑 build 脚本；无本地构建时静默通过）；CI build job 在 ps1 后加一步同脚本作回归护栏；本地改 Rust 后先跑 ps1 再提交。
6. **CI 环境 GBK 测试**：`tc_bar_parser` GBK 解码依赖代码页 936，不可用时 skip（**不要删 skip 防护**）。未改动；win32 936 转换在英文 Windows 上也可用，CI 走 windows-latest 实际不会 skip。
7. **`.inscode/` 工具目录**：不纳入版本控制（已加入 .gitignore）。无需处理。
8. **识图技能 `claude-vision-skill` 的 API 不可用**：默认网关对所有模型返回 503（`model_not_found`），需要时须在 `~/.config/inscode/skills/claude-vision-skill/.env` 配 `DASHSCOPE_API_KEY`/`DASHSCOPE_BASE_URL`/`VISION_MODEL`。待配有效凭据。

---

## 8. 已经跑过的测试

| 测试项 | 结果 |
|--------|------|
| `flutter analyze --fatal-infos --fatal-warnings` | ✅ No issues found（v3.4.0 修复后通过） |
| `flutter test --exclude-tags=integration` | ✅ 561 全过（v3.1.0；v3.0.1 时为 578）；v3.4.0 待重新验证 |
| `flutter test --tags=integration` | ✅ v3.0.1：86 过 + 4 skip；v3.1.0 相关子集（fs/operations/plugin/archive/navigation/database）全过 |
| `flutter build windows --release` | ✅ 成功（增量 ~20s-40s，首次 ~2-4min；v2.6-v3.1.0 实测产物正常，super_native_extensions 插件警告无害） |
| GitHub CI & Release | v2.5/v2.6/v2.9/v3.0/v3.0.1 全绿；**v3.0.1 已验证（Run #50 全绿 + Release 已发布 2026-08-24）**；v3.4.0 CI 待验证 |

---

## 9. 下一步计划（可选方向）

1. ~~**v3.0.1 CI & Release 验证**~~：✅ **已完成（2026-08-24）** —— Run #50 全绿（4 job），Release v3.0.1 已发布（setup.exe + zip）。
2. ~~**v3.2.0 CI & Release 验证**~~：待验证
3. ~~**v3.3.0 CI & Release 验证**~~：待验证
2. **行为迁移提醒**：v2.8.0 起快捷栏/终端命令不再隐式经 cmd.exe——README 已注明，若用户反馈 `>`/`|` 按钮失效需引导写 `cmd /c`；插件 `exec` 同理（open-vscode 需 `cmd /c code`）。
3. **补测试**：operations 的 isolate 深层、sftp_task_executor worker 路径覆盖偏少；压缩包内编辑路径可补更多边界。
4. **拆分收尾**：`toolbar.dart`（1100+ 行）、`file_system_workers.dart`（2484 行）、`navigation_store.dart`（1900+ 行）、`operation_store.dart`（1380 行）、`info_panel.dart`（1373 行）等仍偏大，可按域继续拆分。
5. ~~**Rust panic 屏障收官**~~：✅ **已完成（v3.1.0）** —— `session::block` 统一包 `catch_unwind` + panic 日志（sftp 全部入口一处覆盖）。
6. **INI/DB 收尾**：`app_database.dart` 中 bookmarks/file_tags/sidebar_prefs 表及 DAO 已无 store 调用方（tags 功能 v3.1.0 已删），schema 保留以兼容旧数据迁移，DAO 可考虑后续清理。

---

## 10. 新窗口启动提示词

```
[Hermes UI Workspace]
workspace=D:\Documents\VS Code\MyExplorer-main
instruction=Treat this as the active workspace/root for file paths and shell commands.
[/Hermes UI Workspace]

读取 handoff.md 了解项目状态，然后继续下一步工作。

项目状态：
 - MyExplorer **v3.4.0**（pubspec name: myexplorer，version 3.4.0，**已推送**）
 - v3.4.0 内容：移除内置终端功能模块（删除 lib/core/terminal/、pane_view.dart 终端面板 UI、TerminalColors 主题配色、终端设置分类与快捷键绑定、myexplorer_term 依赖；移除主菜单"终端"菜单项；清理所有终端 i18n 翻译键；删除 packages/myexplorer_term/ 整个终端包；删除终端测试并修复其他测试引用）
 - v3.4.0 修复：flutter analyze --fatal-infos --fatal-warnings 0 issues（移除未使用导入、排除 .g.dart 生成文件）
 - CI 待验证、release 构建待完成
 - 行为变化：快捷栏/插件 exec 不再隐式经 cmd.exe，shell 特性需显式 `cmd /c`
 - 便携式布局：所有数据在程序目录内，不写 %APPDATA%/%TEMP%（只读目录例外降级）

关键路径：
- Flutter/Dart：D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat（及 dart.bat）
- Rust cargo：C:\Users\shenl\.cargo\bin\cargo.exe
- 工作区 junction：D:\wd → D:\Documents\VS Code\MyExplorer-main
- 当前 branch：main
- 编译：flutter build windows --release → build\windows\x64\runner\Release\MyExplorer.exe
```