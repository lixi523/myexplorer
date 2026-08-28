# MyExplorer

A lightweight, self-use Windows file manager similar to Total Commander, forked from [Waydir](https://github.com/Waydir/Waydir).

一个自用的、类似 Total Commander 的 Windows 文件管理器，源自 [Waydir](https://github.com/Waydir/Waydir)。

![Platform](https://img.shields.io/badge/platform-Windows-blue) ![License](https://img.shields.io/badge/license-MIT-green)

<p align="center">
  <img src="docs/screenshots/hero.png" alt="MyExplorer" width="860">
</p>

> **V3.5.0**（已发布，2026-08-28）：全量代码审查与加固 —— 系统性审查 72 个文件（Dart + Rust），修复 80+ 项问题：**P0 崩溃级**（switch fall-through、StateError、Rust panic barrier、Drop unwinding、PTY spawn 失败资源泄漏）、**P1 功能异常**（async void 改 Future、isolate/Timer 泄漏、Completer 超时、负字节格式化、ini 空 key、SFTP 读内存上限）、**P2 空安全与资源**（DB 连接未关闭、FFI 异常吞掉、Shift 选择越界、`on Object` 捕获致命错误、路径硬编码 `/`、force unwrap 回退）、**P3 主题一致性**（37 处 `Colors.black.withValues` 统一为 `AppColors.shadowSubtle`/`bg`、补全 `terminalInsert` 中文翻译）；CI 加固（pdfium 版本固定、集成测试覆盖整个目录、Rust 构建缓存）。发布后追加 3 项修复：移除测试文件中残留的终端引用、修复 native copy 取消测试在快 SSD 上的竞态问题、移除 CI 中不存在的 fastforge 3.2.0 版本号。

> **V3.3.0**: 终端功能修复 —— 修复 Windows 终端无法输入中文（移除 `hardwareKeyboardOnly`，改用 `CustomTextEdit` 建立 TextInputConnection 支持 IME）；终端默认 shell 改为 PowerShell 7（WindowsApps 路径 `Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\pwsh.exe`），偏好路径不存在时自动回退到系统默认 shell。
>
> **V3.1.0**: 稳定性大修 + 精简 —— **大文件复制取消即时生效、进度实时**（Rust 线程内跑 CopyFileEx，原子取消/进度 + Dart 异步轮询）；**QuickLook 压缩包内读取/保存移出 UI 线程**（7z 不再卡界面）；修复**压缩覆盖已存在目标会误删原文件**、分割任务双重读取、插件动作永久挂起、插件 worker 崩溃无恢复、SFTP 传输冲突死等、剪贴板命令长度限制等 14 项问题；启动自动清理残留 7z 临时目录；横快捷栏配置对话框支持**拖动排序**；**快捷栏图标修复**（支持 TC 式"命令+参数"图标列、引号+索引规范，增删/编辑快捷方式后图标与列表**即时刷新**不再需重启）；**移除容器（WSL 发行版列表）与标签（Tags）功能**（侧边栏分区、右键标签菜单、文件标签圆点、`tag://` 视图、`tag:` 搜索过滤全部移除，DB 表保留兼容迁移）。
>
> **V3.0.1**: 修复复制/移动失败 —— v2.5 引入的 `_randomHex` bug 把 0-15 直接转成控制字符（NUL/换行等）而非 hex 字符，导致复制临时文件名含非法字符、Windows 拒绝创建，"复制到对面窗口/移动到对面窗口"及所有复制操作失败；现已改为生成标准 hex 字符，复制功能恢复正常。
>
> **V3.0**: 中文界面全面汉化 —— 文件列表类型列与网格视图文件名描述、插件表单对话框按钮、插件加载/运行错误消息全部汉化；5 个示例插件（备份副本、在 VS Code 中打开、选中计数、7-Zip、从模板新建）菜单标题与用户提示汉化完成；Rust 原生核心插件错误消息（超时/未找到操作/命令执行失败等）汉化；新增 i18n 键 `dialog.ok`、`plugins.errorLabel`、`plugins.errors.*`；操作错误"missing destination"汉化。
>
> **V2.9**: 稳定性与隐藏列表 —— 修复插件操作（如 "Open in VS Code" 按钮）导致的闪退：Rust 发布配置改为 unwind、全部 21 个 FFI 入口加 `catch_unwind` panic 屏障，panic 信息记入 `%TEMP%\myexplorer_core_panic.log`，插件异常降级为错误提示而非杀进程；**隐藏列表支持"纯名称"与"完整路径"双模式匹配**（按条目是否含路径分隔符自动区分，如 `desktop.ini` 全局隐藏同名文件），隐藏列表对话框新增**行内编辑**（添加/编辑/删除完整闭环）。
>
> **V2.8**: 安全与工程加固 —— 快捷栏/终端命令不再隐式经 cmd.exe（`&` 等元字符按字面处理，对齐 TC 原生 CreateProcess 行为，shell 特性需显式 `cmd /c`）；Rust FFI 核心入口加 panic 屏障（`catch_unwind`）；**内置主题 ini 按 id 补缺导出**（不再因存在自定义 ini 而跳过）与 UTF-8/UTF-16 BOM 编码容错；启用 `unawaited_futures` lint 并修复 6 处真实丢 Future；新增 Rust core 与 vendored DLL 一致性检查脚本并接入 CI；全项目代码审查修复（activeStore 空值守卫、网格字号回退、注释乱码等）。
>
> **V2.7**: 快捷栏与交互打磨 —— 竖快捷栏新增 4 个复制快捷方式（文件名/所在目录路径/完整路径/详细信息）；**慢速双击**（普通双击间隔的 2~3 倍）进入重命名；横快捷栏超出宽度自动换行；横快捷栏精简（移除内置列表视图/搜索按钮，配置按钮改齿轮图标）；代码审查修复（空值解引用、未处理 Future、SFTP 静默异常日志等）；`preferences_view`/`file_view` 大文件拆分。
>
> **V2.6**: 快捷栏编辑与工程整理 —— 横快捷栏支持**右键编辑/删除**快捷方式，配置对话框可直接修改已有按钮（预填表单 + 保存/取消）；代码审查相关：GBK 编码主题 ini 自动容错、Program Files 只读目录降级、`menus.dart`/`sidebar.dart` 按域拆分、新增 operations/sftp/AppDirs 单测等。
>
> **V2.5**: 代码审查修复 —— 路径穿越防护（archive_reader）、编译错误（operation_store）、插件操作级联（menus.dart）、快捷键绑定错误（keyboard_shortcuts）、数据库过度删除、搜索异常静默失败、git 监听泄漏等 16 项 bug 修复。
>
> **V2.4**: 便携式布局 —— 数据库、日志、主题、插件、更新与缓存全部保存在程序目录内，不写入 `%APPDATA%`/`%TEMP%`；标签行与浅色模式文字精细调整。
>
> **V2.3**: 稳定性与性能 —— 快捷栏保存串行化（快速操作不再丢配置）、文件操作目标校验、Git 状态缓存与更宽容的超时。
>
> **V2.2**: 主题与可用性打磨 —— 深色模式底色 RGB(70,75,85)、文字 RGB(223,233,233)；快捷栏按钮自动从目标 exe 提取图标（支持 `路径,索引`）；标签文件行不再整行着色（保留 badge 圆点）。
>
> **V2.1**: 品牌统一为 **MyExplorer**（全项目由 waydir 更名，含原生核心、插件 API、发布产物）；文件着色改为文件名着色，新增右键 NC 扩展选择模式。
>
> **V2.0**: Total Commander 对标升级完成 —— 双窗格 + 中间竖快捷栏、Ctrl+Q 快速查看、操作队列、校验清单、分割合并、重复文件查找、文件着色、7z 支持、压缩包内编辑等。

---

## 特性一览

### 界面与导航
- **恒双窗格**布局（不可切回单窗格），中间 46px 竖型快捷栏（新建/查看/复制到对面/移动到对面/删除/复制文件名/复制路径/复制完整路径/复制详细信息/三视图切换/选择组/反选/搜索/同步/批量重命名/隐藏切换/属性）
- 每窗格多标签、列表/树形/网格三视图、侧边栏（书签/驱动器/树）
- **慢速双击**（普通双击间隔的 2~3 倍）直接进入重命名模式；列表与网格视图均支持
- **Ctrl+Q 快速查看面板**：对侧窗格底部常驻预览，随光标实时刷新（图片/PDF/Markdown/代码/属性）
- Quick Look 弹窗（空格）支持代码高亮、图片、Markdown、PDF 预览与**压缩包内文件编辑**

### TC 兼容
- **快捷栏**：导入 Total Commander `.bar` 按钮栏（GBK/UTF-8）、exe/dll 图标提取、`CD` 跳转、`cm_` 内置命令；按钮支持**右键编辑/删除**，配置对话框可添加、编辑、移除、排序
- **参数宏**：`%P` `%N` `%T` `%M` `%L` `%S`（及小写原始值变体）在按钮运行时展开，完全对齐 TC 语义
- **右键 NC 模式（扩展选择）**：右键单击文件 = 追加多选（高亮但不加粗）；按住右键拖动 = 轨迹经过全部选中（含边缘自动滚动、快速拖动区间补全不丢行）；**长按右键 >2 秒** = 弹出上下文菜单（文件上弹文件菜单，空白处弹背景菜单）；快速右键单击空白不弹菜单
- 操作队列支持**暂停/恢复/取消**；冲突自动策略（覆盖较旧/跳过同大小）

### 界面与交互
- 选中文件**不加粗**（仅高亮底色）；**文件着色**：文件名按扩展名规则显示颜色（默认：可执行红/图片紫/压缩包棕/文档蓝/媒体绿/文本青，可自定义），文件夹名浅灰，行底色不变
- 上下文菜单：鼠标移出菜单区域或点击外部（左键/右键）自动关闭，Esc 亦可

### 文件操作
- 复制/移动/删除/重命名、后台任务面板、冲突对话框
- **分割/合并**：`.001`/`.002` 分卷 + `.crc` MD5 清单，预设（软盘/100MB/CD/DVD）+ 自定义
- **校验清单**：生成/验证 `.md5`/`.sha256`（GNU coreutils 格式，批量并发校验）
- **重复文件查找**：大小→哈希两级扫描，分组勾选保留一份，回收站/删除
- **批量重命名**：模板 + 查找替换（正则），`[C]` 计数器、`[N1-3]` 切片、`[P]` 上级目录名
- **文件着色**：扩展名→颜色规则，**文件名文字着色**（默认内置配色，可自定义）

### 归档与远程
- zip/tar/tar.gz/tar.bz2/tar.xz 浏览、解压、压缩
- **7z 浏览与解压**（自动定位系统 7-Zip：exe 旁、PATH、Program Files、scoop/chocolatey）
- **压缩包内编辑**：Quick Look 直接打开并保存包内文本文件（zip/tar）
- SFTP 完整读写、SMB 共享发现、WSL 路径、内嵌 PTY 终端

### 其他
- 简体中文 / English 双语（自动检测）、可自定义快捷键、多主题
- 隐藏列表（`隐藏文件.ini`）、命令面板、文件夹大小扫描、自动更新（GitHub Release）
- 唯一实例、默认最大化启动、Rust 原生核心加速

---

## 环境要求

- Windows 10/11（64 位）
- 可选：安装 7-Zip 以启用 7z 浏览/解压（未安装时 7z 功能自动隐藏）

## 构建

```bash
flutter pub get
flutter build windows --release
```

CI（GitHub Actions）会自动完成 测试 → 构建 → 打包 → 发布 Release（产物 `MyExplorer-<version>-windows-setup.exe` / `.zip`）。

## 许可

MIT（继承自 Waydir）。
