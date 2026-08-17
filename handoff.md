# MyExplorer 项目交接文档

## 1. 项目目标
**MyExplorer v2.7.0**（pubspec name: `myexplorer`）— 对标 Total Commander 的 Windows 双窗格文件管理器（fork 自 Waydir，已全面更名）。

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

## 2. 当前进度（2026-08-17）

- ✅ **v2.7.0 版本号已更新**（pubspec `2.7.0+40`），本地构建通过
- ✅ **竖快捷栏 4 个复制快捷方式**：`copySelectedNames`（文件名）/`copySelectedParentPaths`（所在目录路径）/`copySelectedPaths`（完整路径含文件名）/`copySelectedDetails`（详细信息文本）；`NavigationStore` 新增方法 + `ClipboardController.copyText` + 顶层纯函数 `buildEntryDetailsText`（可单测）
- ✅ **慢速双击重命名**：列表行 `_ListRow` 与网格 `_GridTile` 的 `_handleTap` 增加 2x~3x 间隔分支 → 触发 `onMenuAction('rename')`；网格视图补齐 `onMenuAction` 传导链（FileGrid → _GridTile → pane_view）
- ✅ **横快捷栏增强**：`Wrap` 自动换行（minHeight 36 自适应，右下固定按钮不换行）；移除内置列表视图/搜索按钮，配置按钮改齿轮图标 `gearSix`
- ✅ **代码审查修复**（v2.7）：全部 `activePane.value!` 空值解引用加守卫（9 处）；`unawaited_futures` 扫描修复 20 处（await/unawaited）；sftp_task_executor 5 处静默 `catch(e){e.toString()}` 改 `log.warn`
- ✅ **大文件拆分**（v2.7）：`preferences_view.dart`（1235→910）+ 新 `settings_widgets.dart`（345 行共享组件，7 个 pane 改 import）；`file_view.dart`（1549→1159）+ 新 part `file_view_columns.dart`（391 行列头/列配置）
- ✅ 单元测试 **563 全过**（v2.6 的 553 + 10：buildEntryDetailsText/ClipboardController.copyText/file_sort 边界/慢双击）、integration 86 过 + 4 skip
- （v2.6 遗留完成项保留）横快捷栏编辑、menus/sidebar 拆分、AppDirs 只读降级、主题 GBK 容错、README hero 截图

---

## 3. 已完成修改（近期关键提交）

| Commit | 说明 |
|--------|------|
| （未提交，工作区） | **v2.7.0**：竖快捷栏 4 复制按钮、慢速双击重命名、横快捷栏换行/精简（齿轮图标）、代码审查修复（activePane/await/unawaited/sftp 日志）、preferences_view/file_view 拆分、file_sort 边界测试等；**待用户确认后提交推送** |
| `feat: v2.6.0 — shortcut bar editing, file splits, read-only fallback, GBK ini tolerance` | 横快捷栏编辑（update/右键菜单/编辑表单）、menus/sidebar 拆分、AppDirs 只读降级、主题 GBK 容错、gbk_codec UAF 修复、README hero 截图等 |
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
| `lib/core/platform/app_dirs.dart` | **便携目录解析 + 只读降级**：`selectBase`/`isWritableDir` 检测 exe 目录可写性，不可写回退 `%LOCALAPPDATA%\MyExplorer`；`debugExeDirOverride`/`debugReset` 测试 seam |
| `lib/core/platform/gbk_codec.dart` | GBK(code 936) 编解码（FFI）；**encodeGbkBytes 已修复 UAF**（`Uint8List.fromList` 拷贝） |
| `lib/app/myexplorer_shell/menus.dart` + `menus_plugin.dart` | 拆分的两个 part：菜单构建/分发 + 插件执行域（`_MyExplorerMenuMixin` / `_MyExplorerPluginMixin`） |
| `lib/features/navigation/sidebar.dart` + `sidebar_*.dart` | 拆分：sidebar（主 State）+ edit/footer/header/operations 四个 part |
| `lib/ui/dialogs/shortcut_bar_config_dialog.dart` | 快捷栏配置：支持 `editingId` 预填编辑、保存/取消、行内编辑 |
| `test/` | 544 单测 + 86 integration |

---

## 5. 不能动的边界（红线）

- **`pubspec name: myexplorer` 不能改**（已全面更名，import 路径 `package:myexplorer/`）
- **不写程序目录外**：任何数据目录都必须经 `AppDirs`；仅当 exe 目录只读（Program Files）时降级到 `%LOCALAPPDATA%\MyExplorer`（v2.6 新增白名单例外），禁止再引入 `path_provider` / 直写 %APPDATA%/%TEMP%
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
2. **中文键 ini 编码**：解析已支持 UTF-8 优先 + GBK 回退（v2.6）；若第三方存为其它编码（如 UTF-16）仍会解析失败被跳过并记日志。
3. **`shadowSubtle` 半透明**：输出为 8 位 ARGB（`33000000`），其余不透明输出 6 位 RGB；编辑时若用户只留 6 位会丢失阴影 alpha。
4. **便携式写入权限**：exe 目录只读（Program Files）时自动降级 `%LOCALAPPDATA%\MyExplorer`（v2.6）；降级后与"便携"定位略有偏差，启动日志会提示。仍不理想：`support()` 解析在首次调用即决定 base，之后缓存。
5. **Rust core 需单独构建**：integration 测试与发布依赖 `rust/myexplorer_core/target/release/myexplorer_core.dll`；改动 Rust 后需 `cargo build --release` 且同步 vendored。
6. **CI 环境 GBK 测试**：`tc_bar_parser` GBK 解码依赖代码页 936，英文 runner 上不可用时 skip（不要删 skip 防护）。
7. **`.inscode/` 工具目录**：不纳入版本控制（已加入 .gitignore）。
8. **识图技能 `claude-vision-skill` 的 API 不可用**：默认网关对所有模型返回 503（`model_not_found`），需要时须在脚本目录 `.env` 配有效 key。

---

## 8. 已经跑过的测试

| 测试项 | 结果 |
|--------|------|
| `flutter analyze` | ✅ No issues found |
| `flutter test --exclude-tags=integration` | ✅ 563 全过 |
| `flutter test --tags=integration` | ✅ 86 过 + 4 skip |
| `flutter build windows --release` | ✅ 成功（增量 ~20s-40s，首次 ~2-4min；v2.6/v2.7 实测产物正常，super_native_extensions 插件警告无害） |
| GitHub CI & Release | v2.5/v2.6 全绿；v2.7 待推送后验证 |

---

## 9. 下一步计划（可选方向）

1. **v2.7.0 提交推送**：当前改动全部在工作区未提交（含版本号 2.7.0+40、README/CHANGELOG/handoff），用户确认后按惯例提交并推送，让 CI & Release 出 v2.7 产物。
2. **补测试**：operations 的 isolate 深层、sftp_task_executor worker 路径覆盖偏少；压缩包内编辑路径可补更多边界。
3. **拆分收尾**：`lib/features/navigation/toolbar.dart`（1100+ 行路径栏/建议）、`file_system_workers.dart`（2478 行）、`navigation_store.dart`（1900 行）、`operation_store.dart`（1380 行）、`info_panel.dart`（1373 行）等仍偏大，可按域继续拆分。
4. **主题 ini 其它容错**：UTF-16 等编码仍会失败；可考虑 BOM 检测或编码选择提示。
5. **README 动图**：docs/gifs/ 已有 13 个演示 gif，可考虑挑重点 2-4 个插入 README 对应特性段。

**当前无遗留任务**，v2.7.0 功能与工程整理已完成，待提交推送。

---

## 10. 新窗口启动提示词

```
[Hermes UI Workspace]
workspace=D:\Documents\VS Code\MyExplorer-main
instruction=Treat this as the active workspace/root for file paths and shell commands.
[/Hermes UI Workspace]

读取 handoff.md 了解项目状态，然后继续下一步工作。

项目状态：
- MyExplorer v2.7.0（pubspec name: myexplorer，version 2.7.0+40）
- v2.7 新功能：竖快捷栏 4 个复制快捷方式（文件名/目录路径/完整路径/详细信息）、慢速双击重命名（2~3 倍间隔）、横快捷栏自动换行 + 精简（齿轮图标）、代码审查修复（activePane 空守卫/await/unawaited/sftp 日志）、preferences_view/file_view 大文件拆分
- v2.6 遗留：横快捷栏编辑、menus/sidebar 拆分、AppDirs 只读降级、主题 GBK 容错、README hero 截图
- 便携式布局：所有数据在程序目录内，不写 %APPDATA%/%TEMP%（只读目录例外降级）
- 单元测试 563 + integration 86 全绿，flutter analyze 通过；v2.7 本地 Release 构建成功，CI 待推送验证
- v2.7 改动全部在工作区未提交（NEVER push，需用户确认）

关键路径：
- Flutter/Dart：D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat（及 dart.bat）
- Rust cargo：C:\Users\shenl\.cargo\bin\cargo.exe
- 工作区 junction：D:\wd → D:\Documents\VS Code\MyExplorer-main
- 当前 branch：main
- 编译：flutter build windows --release → build\windows\x64\runner\Release\MyExplorer.exe
```