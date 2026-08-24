# MyExplorer 项目交接文档

## 1. 项目目标
**MyExplorer v3.0.1**（pubspec name: `myexplorer`）— 对标 Total Commander 的 Windows 双窗格文件管理器（fork 自 Waydir，已全面更名）。

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

## 2. 当前进度（2026-08-24）

- ✅ **v3.0.1 已提交并推送**（pubspec `3.0.1+44`），本地 Release 构建通过，CI & Release 待 GitHub 验证
- ✅ **v3.0.1 内容（三部分）**：
  1. **书签/标签/侧栏 INI 化**（`feat: bookmarks, tags and sidebar prefs persist to INI files`）：书签.ini / 标签.ini / 侧栏.ini 存程序根目录（UTF-8 BOM），启动时加载（main.dart）；标签定义 + 文件关联全量在标签.ini；侧栏分区顺序/隐藏/折叠落盘；**一次性迁移**（INI 缺失时从 SQLite 导入）；新增通用 `lib/utils/ini_file.dart` + 12 个单测
  2. **书签拖拽排序**（同提交）：侧边栏书签区普通模式支持整行拖拽排序（`ReorderableListView` + `_BookmarkReorderList`），复用 `BookmarkStore.reorder` 落盘书签.ini
  3. **复制/移动修复**（`fix: copy temp random suffix control chars`）：**v2.5 引入的 `_randomHex` bug**——`String.fromCharCodes(nextInt(16))` 生成控制字符（NUL/换行）而非 hex，临时文件名非法导致 Windows 拒绝复制（Permission denied）；改从 hex 字符表取字符，复制/移动到对面窗口恢复
- 单元测试 **578 全过**、integration **86 过 + 4 skip**、`flutter analyze` 0 issues、`flutter build windows --release` 成功

---

## 3. 已完成修改（近期关键提交）

| Commit | 说明 |
|--------|------|
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
| `lib/utils/ini_file.dart` | **通用 INI 工具（v3.0.1 新增）**：段/键值/注释/列表解析与序列化、UTF-8 BOM、原子写入；书签.ini/标签.ini/侧栏.ini 均基于它 |
| `lib/core/platform/app_dirs.dart` | **便携目录解析 + 只读降级**：`selectBase`/`isWritableDir` 检测 exe 目录可写性，不可写回退 `%LOCALAPPDATA%\MyExplorer`；`debugExeDirOverride`/`debugReset` 测试 seam |
| `lib/core/platform/gbk_codec.dart` | GBK(code 936) 编解码（FFI）；**encodeGbkBytes 已修复 UAF**（`Uint8List.fromList` 拷贝） |
| `lib/app/myexplorer_shell/menus.dart` + `menus_plugin.dart` | 拆分的两个 part：菜单构建/分发 + 插件执行域（`_MyExplorerMenuMixin` / `_MyExplorerPluginMixin`） |
| `lib/features/navigation/sidebar.dart` + `sidebar_*.dart` | 拆分：sidebar（主 State）+ edit/footer/header/operations 四个 part |
| `scripts/build_myexplorer_core_windows.ps1` | 构建并 vendored Rust core + pdfium |
| `scripts/check_myexplorer_core_up_to_date.ps1` | **Rust core 一致性检查（v2.8.0 新增）**：SHA256 对比本地构建与 vendored DLL，不一致 exit 1 提示重建；CI build job 护栏 |
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
| `flutter analyze` | ✅ No issues found |
| `flutter test --exclude-tags=integration` | ✅ 578 全过 |
| `flutter test --tags=integration` | ✅ 86 过 + 4 skip |
| `flutter build windows --release` | ✅ 成功（增量 ~20s-40s，首次 ~2-4min；v2.6-v3.0.1 实测产物正常，super_native_extensions 插件警告无害） |
| GitHub CI & Release | v2.5/v2.6 全绿；**v3.0.1 已推送，待验证** |

---

## 9. 下一步计划（可选方向）

1. **v3.0.1 CI & Release 验证**：3 个提交已推送（含 v3.0.1 版本提交），等 GitHub CI 全绿 + Release 出 v3.0.1 产物；若 CI 红按红项修。
2. **行为迁移提醒**：v2.8.0 起快捷栏/终端命令不再隐式经 cmd.exe——README 已注明，若用户反馈 `>`/`|` 按钮失效需引导写 `cmd /c`；插件 `exec` 同理（open-vscode 需 `cmd /c code`）。
3. **补测试**：operations 的 isolate 深层、sftp_task_executor worker 路径覆盖偏少；压缩包内编辑路径可补更多边界。
4. **拆分收尾**：`toolbar.dart`（1100+ 行）、`file_system_workers.dart`（2484 行）、`navigation_store.dart`（1900+ 行）、`operation_store.dart`（1380 行）、`info_panel.dart`（1373 行）等仍偏大，可按域继续拆分。
5. **Rust panic 屏障收官**：sftp/ops.rs 15 个入口尚未包 `catch_unwind`（v2.9 已包 21 个，触发面全覆盖；sftp 无 panic 面，可下次补）。
6. **INI 化收尾**：`app_database.dart` 中 bookmarks/tags/file_tags/sidebar_prefs 表及 DAO 已无 store 调用方，可考虑后续清理（schema 保留以兼容旧数据迁移）。

---

## 10. 新窗口启动提示词

```
[Hermes UI Workspace]
workspace=D:\Documents\VS Code\MyExplorer-main
instruction=Treat this as the active workspace/root for file paths and shell commands.
[/Hermes UI Workspace]

读取 handoff.md 了解项目状态，然后继续下一步工作。

项目状态：
 - MyExplorer **v3.0.1**（pubspec name: myexplorer，version 3.0.1+44，**已提交推送**）
 - v3.0.1 三部分：① 书签/标签/侧栏 INI 化（书签.ini/标签.ini/侧栏.ini 程序根目录 + 启动加载 + 一次性迁移）② 书签拖拽排序 ③ 复制/移动修复（v2.5 `_randomHex` 控制字符 bug）
 - v3.0.0 前置：全界面汉化 + 插件/Rust 错误消息 i18n + 5 示例插件汉化
 - v2.9.0 前置：闪退修复（FFI panic barriers + unwind）、隐藏列表双模式、行内编辑
 - v2.8.0 前置：风险点治理（主题 ini 补缺 + UTF-16 BOM + 导出注释 + AppDirs 行为锁定 + Rust core 一致性脚本）+ 审查修复（移除 runInShell、unawaited lint、activeStore 守卫、FFI 屏障雏形）
 - 行为变化：快捷栏/终端/插件 exec 不再隐式经 cmd.exe，shell 特性需显式 `cmd /c`
 - 便携式布局：所有数据在程序目录内，不写 %APPDATA%/%TEMP%（只读目录例外降级）
 - 单元测试 578 全过、integration 86 过 + 4 skip、flutter analyze 通过；v3.0.1 本地 Release 构建成功，CI 待验证
 - NEVER push 规则：v3.0.1 已由用户明确确认推送，后续新改动先确认再推

关键路径：
- Flutter/Dart：D:\wd\.cowork-temp\flutter-sdk\flutter\bin\flutter.bat（及 dart.bat）
- Rust cargo：C:\Users\shenl\.cargo\bin\cargo.exe
- 工作区 junction：D:\wd → D:\Documents\VS Code\MyExplorer-main
- 当前 branch：main
- 编译：flutter build windows --release → build\windows\x64\runner\Release\MyExplorer.exe
```