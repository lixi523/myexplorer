# MyExplorer 项目交接文档

## 1. 项目目标
**MyExplorer v2.5.0**（pubspec name: `myexplorer`）— 对标 Total Commander 的 Windows 双窗格文件管理器（fork 自 Waydir，已全面更名）。

核心特性：
- 强制双窗格布局（恒双窗口，不恢复单窗口模式）
- 自定义快捷栏（手写横快捷栏 INI + 中间 46px 竖快捷栏 17 按钮）
- 右键 NC 扩展选择模式（2 秒长按触发菜单，无加粗选中）
- 深色主题：底色 RGB(70,75,85)、文字 RGB(223,233,233)
- **便携式布局**：所有数据（数据库/日志/主题/插件/更新/缓存）在程序目录内，不写 %APPDATA%/%TEMP%
- **主题配色调色板由 `themes/*.ini` 文件驱动**（每主题一个 ini，键中文名 + RGB 色号）
- Windows 原生窗口 Chrome（bitsdojo_window 自定义标题栏、横快捷栏）
- Rust 原生核心（list/search/trash/enumerate/pdf/pty/sftp/plugin）+ FFI

---

## 2. 当前进度（2026-08-12）

- ✅ **v2.5.0 已发布**（提交推送，CI & Release 产出 exe + zip）
- ✅ **代码审查修复完成**：路径穿越防护（`archive_reader.dart`）、编译错误（`operation_store.dart`）、插件操作级联（`menus.dart`）、快捷键绑定错误（`keyboard_shortcuts.dart`）、数据库过度删除（`app_database.dart`）、搜索异常静默失败（`myexplorer_core_loader.dart`）、git 监听泄漏（`navigation_store.dart`）、dispose 丢失设置、首屏滚动、同步主题 seeding 不建目录、SFTP rename session 验证、exit port 订阅、safe_file_replace 内存泄漏、archive 计划缓存永 miss、搜索标签重复等 16 项
- ✅ **便携式布局完成**：应用不再在程序目录外创建任何目录/文件
- ✅ **path_provider 依赖已移除**
- ✅ **文件排序对齐 Windows**：改用 StrCmpLogicalW（Vista+）语义，点号/数字/前导零规则与资源管理器一致
- ✅ **浅色模式文字色调整**：双窗口文件列表文字为 RGB(60,65,75)；文件夹名深/浅色由 `themes/*.ini` 的 `深色文件夹文字色`/`浅色文件夹文字色` 配置（默认 深色 RGB(233,233,233) / 浅色 RGB(60,65,75)）
- ✅ **主题系统全面改为 ini**：移除 JSON，`themes/*.ini` 每主题一个文件，内置主题首次启动自动导出；`[palette]`/`[terminal]` 键名简体中文、不透明色 6 位 RGB、透明色 8 位 ARGB
- ✅ 大量健壮性修复（快捷栏保存串行化、worker 目标校验、git 缓存等）
- ✅ 单元测试 509 全过、integration 86 过 + 4 skip、CI 全绿

---

## 3. 已完成修改（近期关键提交）

| Commit | 说明 |
|--------|------|
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
| `test/` | 509 单测 + 86 integration |

---

## 5. 不能动的边界（红线）

- **`pubspec name: myexplorer` 不能改**（已全面更名，import 路径 `package:myexplorer/`）
- **不写程序目录外**：任何数据目录都必须经 `AppDirs`（exe 目录下），禁止再引入 `path_provider` / 直写 %APPDATA%/%TEMP%
- **恒双窗口**（`shell_store.dart` `isDual = signal(true)`）
- **不恢复 Linux/macOS/单窗口支持**
- **插件 Lua API 为 `myexplorer.register` 等**（勿改回 waydir）
- **NEVER push**（AGENTS.md 规则，需用户明确确认）
- **git commit 前必须 `dart format`**（CI 有格式关卡）
- **Flutter/Dart 不在 PATH**，用完整路径：
  ```
  D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat
  D:\wd\.cowork-temp\flutter-sdk\flutter\bin\dart.bat
  ```
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

1. **首次启动自动导出内置 ini**：若 `themes/` 目录已非空（如用户只留一个自定义 ini），`load()` 会跳过导出内置 ini，导致 dark 等内置主题退回 const 兜底配色。默认/兜底用 const dark。
2. **中文键 ini 编码**：`File.writeAsString` 默认 UTF-8，中文键名与值均存 UTF-8；解析用 `readAsString()`（UTF-8）。若第三方用记事本另存为 ANSI/GBK 会解析失败（`_parseIni` 按 `key=value` 硬解析，非法主题会被跳过并记日志）。
3. **`shadowSubtle` 半透明**：输出为 8 位 ARGB（`33000000`），其余不透明输出 6 位 RGB；编辑时若用户只留 6 位会丢失阴影 alpha。
4. **便携式写入权限**：装到 `Program Files` 等只读目录时写 exe 目录（数据库/日志/主题 ini）会失败。自用/便携可接受。
5. **Rust core 需单独构建**：integration 测试与发布依赖 `rust/myexplorer_core/target/release/myexplorer_core.dll`；改动 Rust 后需 `cargo build --release` 且同步 vendored。
6. **CI 环境 GBK 测试**：`tc_bar_parser` GBK 解码依赖代码页 936，英文 runner 上不可用时 skip（不要删 skip 防护）。
7. **`.inscode/` 工具目录**：不纳入版本控制。
8. **识图技能 `claude-vision-skill` 的 API 不可用**：默认网关对所有模型返回 503（`model_not_found`），需要时须在脚本目录 `.env` 配有效 key。

---

## 8. 已经跑过的测试

| 测试项 | 结果 |
|--------|------|
| `flutter analyze` | ✅ No issues found |
| `flutter test --exclude-tags=integration` | ✅ 509 全过 |
| `flutter test --tags=integration` | ✅ 86 过 + 4 skip |
| `flutter build windows --release` | ✅ 成功（增量 ~17s，首次 ~2-4min） |
| GitHub CI & Release | ✅ 全绿（Analyze/Unit/Integration/Build/Publish） |

---

## 9. 下一步计划（可选方向）

1. **拆分剩余大文件**：`lib/app/myexplorer_shell/menus.dart`（1645 行）、`lib/features/navigation/sidebar.dart`（1905 行）可继续按域拆分。
2. **补测试**：operations 的 isolate 深层、sftp_task_executor、压缩包内编辑路径覆盖偏少；主题 ini 与归档列表排序可补更多边界。
3. **便携式可写性**：考虑 Program Files 安装时的降级策略或错误提示（当前静默失败）。
4. **主题 ini 容错**：编辑器把中文 ini 存为 GBK 时的容错（自动检测编码或提示）。
5. **README 重传截图**：可用最新 exe 截图替换。

**当前无遗留任务**，v2.5.0 代码审查修复全部完成。

---

## 10. 新窗口启动提示词

```
[Hermes UI Workspace]
workspace=D:\Documents\VS Code\MyExplorer-main
instruction=Treat this as the active workspace/root for file paths and shell commands.
[/Hermes UI Workspace]

读取 handoff.md 了解项目状态，然后继续下一步工作。

项目状态：
- MyExplorer v2.5.0（pubspec name: myexplorer）
- v2.5 代码审查修复：16 项 bug 修复（路径穿越防护、编译错误、插件操作级联、快捷键绑定、DB 过度删除、搜索异常静默失败、git 监听泄漏等）
- 便携式布局：所有数据在程序目录内，不写 %APPDATA%/%TEMP%
- 文件排序对齐 Windows（StrCmpLogicalW：点号断点/数字比较/前导零多的排前）
- 浅色模式文件列表文字 RGB(60,65,75)；文件夹名深/浅色从 ini 读取（`深色文件夹文字色`/`浅色文件夹文字色`，默认 深色 E9E9E9 / 浅色 3C414B）
- 主题系统全面改为 ini：themes/*.ini 每主题一个，[palette]/[terminal] 键名简体中文 + RGB 色号；首次启动自动导出内置主题；已移除 JSON；解析兼容旧英文键
- 单元测试 509 + integration 86 全绿，flutter analyze 通过，CI & Release 正常
- 已推送到 github.com/lixi523/myexplorer（NEVER push，需用户确认）

关键路径：
- Flutter/Dart：D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat（及 dart.bat）
- Rust cargo：C:\Users\shenl\.cargo\bin\cargo.exe
- 工作区 junction：D:\wd → D:\Documents\VS Code\MyExplorer-main
- 当前 branch：main
- 编译：flutter build windows --release → build\windows\x64\runner\Release\MyExplorer.exe
```