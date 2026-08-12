# MyExplorer 全项目代码审查报告

**日期**: 2026-08-12  
**范围**: 全项目 ~212 个 Dart 文件，重点关注当前 diff 修改的文件（24 个变更文件）及核心模块

---

## 一、严重 Bug（必须修复，影响功能或安全）

### #1. `lib/core/archive/archive_reader.dart:50` — 路径穿越防护失效（安全漏洞）

```dart
final normalized = p.normalize(path).replaceAll('\', '/');
```

**问题**: `'\'` 在 Dart 中是**单引号字符字面量**，不是反斜杠。实际执行的是把 `'` 替换为 `/`，反斜杠完全未处理。

**连带后果**：
- **行 57**: `return !normalized.startsWith(p.separator)` — Windows 上 `p.separator` 是 `\`，但 `normalized` 已用 `/` 标准化，相对路径不以 `\` 开头 → 被判定为"不安全"→ **所有相对路径被拒绝解压**
- 路径穿越攻击（`../`）可能绕过防护写出归档根目录外

**修复**:
```dart
final normalized = p.normalize(path).replaceAll('\\', '/');
// 行 57 改为直接 return false;
return false;
```

---

### #2. `lib/core/archive/archive_reader.dart:51` — 合法隐藏文件被拦截

```dart
if (normalized.startsWith('/') || normalized.startsWith('.')) return true;
```

**问题**: `startsWith('.')` 过于宽泛，`.git`、`.env`、`.DS_Store` 等合法隐藏目录/文件全部被拒绝。

**修复**: 改用精确的 `..` 检测（第 52-54 行已覆盖）：
```dart
if (normalized.startsWith('/')) return true;
```

---

### #3. `lib/features/operations/operation_store.dart:414-415` — 编译错误

```dart
'renameFrom': ?renameFromInner,
'renameTo': ?renameToName,
```

**问题**: `?` 前缀操作符在 map literal 中是非法 Dart 语法，**代码无法编译**。`enqueueArchiveEdit` 被 4 处调用（navigation_store.dart × 3、navigation_rename_ops.dart × 1）。

**修复**:
```dart
if (renameFromInner != null) 'renameFrom': renameFromInner,
if (renameToName != null) 'renameTo': renameToName,
```

---

### #4. `lib/app/myexplorer_shell/menus.dart:767-778` — 插件操作 fallthrough 导致级联执行

```dart
case 'copy':
  if (dst != null) _operationStore.enqueueCopy([src], dst);
case 'move':
  if (dst != null) _operationStore.enqueueMove([src], dst);
case 'delete': ...
case 'trash': ...
```

**问题**: `copy` 无 `break`，请求 copy 会**顺序执行 copy + move + delete + trash**，造成数据破坏。虽然 `if (dst != null)` 有一定防护，但若 dst 存在则所有操作都会执行。

**修复**: 每个 case 末尾加 `break;`，或重构为独立方法调用。

---

### #5. `lib/core/keyboard/keyboard_shortcuts.dart:824-839` — switch 缺少 break 导致快捷键绑定错误

```dart
switch (part) {
  case 'ctrl':
    ctrl = true;
  case 'shift':   // ← 无 break！
    shift = true;
  case 'alt':     // ← 无 break！
    alt = true;
  default:
    key = _parseKeyToken(part);
}
```

**问题**: 解析 `"ctrl+x"` 时，`ctrl = true` 后继续 fall-through 执行 `shift = true` 和 `alt = true`，生成的 KeyChord 变成 `Ctrl+Shift+Alt+X` 而非预期的 `Ctrl+X`。**所有带 modifier 的用户自定义快捷键均受影响**。

**修复**: 改用独立 if 语句或每 case 加 `break;`。

---

### #6. `lib/core/database/app_database.dart:927-929` — `_pruneFolderPrefs()` 可能过度删除

```dart
)..where((t) => t.updatedAt.isSmallerThanValue(cutoff.updatedAt))).go();
```

**问题**: 使用严格小于 `<` 删除 cutoff 行之前的记录。若多条记录共享同一 `updatedAt` 时间戳（批量写入常见），会一次性删除远超过限制的行数，可能清空整个 table。

**修复**: 使用 `<=` 但排除 cutoff 行本身，或改用 `orderBy.desc().limit(total - _maxFolderPrefs).delete()`。

---

### #7. `lib/core/database/app_database.dart:422` — 迁移 v33→v34 丢失 `added` 列

```sql
column_order = 'kind,size,date,created,permissions,owner'
```

**问题**: 当前 schema 默认值为 `'kind,size,date,created,added,permissions,owner'`（含 `added` 列）。迁移语句遗漏 `added`，导致升级到此版本的用户永久丢失该列配置。

**修复**: 补全 `added`：
```sql
column_order = 'kind,size,date,created,added,permissions,owner'
```

---

### #8. `lib/core/fs/myexplorer_core_loader.dart:522-525` — 搜索异常返回 done:true

```dart
} catch (e, st) {
  _warnNative('search poll', e, st);
  return const SearchPollResult(null, 0, true);  // done=true 误导调用方
}
```

**问题**: FFI 调用异常时返回 `done: true`，调用方（`recursive_search.dart`）停止轮询并显示空/陈旧结果，用户以为搜索完成但实际从未得到结果。

**修复**: 返回 `done: false` 并在日志中记录错误，让调用方重试或显示错误。

---

## 二、中等 Bug（影响正确性/稳定性）

### #9. `lib/core/settings/settings_store.dart:395-400` — dispose 丢失未保存设置

```dart
void dispose() {
  for (final d in _disposers) { d(); }
  _disposers.clear();
  _saveDebounce?.cancel();  // 取消但不再触发 _save
}
```

**问题**: 用户在 200ms 防抖窗口内修改了某个设置然后关闭应用，设置静默丢失。

**修复**: dispose 前先 flush 一次：
```dart
_saveDebounce?.cancel();
await _save();
```

---

### #10. `lib/features/files/file_grid.dart:422-425` — 首屏选中项不自动滚入视口

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) _reportMetrics(constraints, columns);
});
_revealSelectedTile();  // 此时 _lastColumns=0，直接 return
```

**问题**: `_revealSelectedTile` 在 post-frame 之前同步调用，`_lastColumns` 仍为初始值 0，方法直接 return，首次打开文件夹时已选中的 tile 不会滚入可见区域。

**修复**: 将 `_revealSelectedTile()` 也移入 post-frame 回调，放在 `_reportMetrics` 之后。

---

### #11. `lib/features/navigation/navigation_store.dart:456-460` — git 路径监听泄漏

```dart
_gitStatusDisposer = effect(() {
  final path = currentPath.value;
  if (!PlatformPaths.isNetworkPath(path)) gitStatus.watchPath(path);
});
```

**问题**: 每次 `currentPath` 变化都调用 `watchPath`，但从不调用取消监听的接口（`gitStatus` 没有 `unwatchPath`）。随着浏览历史增长，旧路径的监听持续积累。

**修复**: 在 effect 内部同时取消旧路径监听，或给 `GitStatusStore` 添加 `unwatchPath` 方法。

---

### #12. `lib/ui/theme/app_theme_registry.dart:160` — 同步 seeding 不创建目录

```dart
void _seedBuiltInThemesSync(String dirPath) {
  final dir = Directory(dirPath);
  try {
    if (!dir.existsSync()) return;  // 不创建目录，直接返回
```

**问题**: 异步版本（L136）有 `await dir.create(recursive: true)`，同步版本缺失。若首次运行时走同步路径且目录不存在，内置主题 ini 不会被导出。

**修复**: 加上 `await dir.create(recursive: true)` 或统一为异步实现。

---

### #13. `lib/core/fs/sftp_fs.dart:152-159` — rename 未验证 from/to 同属一个 session

```dart
final sessionId = _sessionFor(from);  // 只查 from 的 session
// to 未查 session，直接传给 sftpRename
```

**问题**: 若 `to` 解析到不同的 SFTP 服务器，rename 会尝试在错误服务器上操作，抛出模糊错误或静默失败。

**修复**: 验证 `to` 的 session 与 `from` 一致，不一致则抛出明确错误。

---

### #14. `lib/core/fs/duplicate_finder.dart:41-70` — exit port 未订阅，崩溃静默

```dart
final exitPort = ReceivePort();
// ...
final subscriptions = <StreamSubscription<dynamic>>[
  receivePort.listen(...),
  errorPort.listen(...),
];
// exitPort 存入但不订阅！
```

**问题**: Isolate 崩溃时 exit port 有消息但从不读取，调用方永远挂起等待结果，不会收到错误通知。

**修复**: 在 subscriptions 中加入 `exitPort.listen(...)` 并在 isolate 退出时 complete handle。

---

### #15. `lib/features/quick_look/info_panel.dart:21-29` — 日期格式非响应式

**问题**: `_formatStatDate` 直接读取 `SettingsStore.instance.dateFormat.value` 而非通过信号消费。用户更改日期格式后，已打开的 Info Panel 不会更新显示。

**修复**: 改用 `Watch` 或在信号变化时重新渲染。

---

## 三、性能问题

### #16. `lib/features/files/file_view.dart:448-474` — 列宽计算无缓存

**问题**: `_computeColumnWidths` 遍历所有文件计算每列最长文本，O(n×m) 复杂度。每次 build 都重算，对 10,000 文件的目录等于 70,000 次字符串比较。

**修复**: 结果 memoize 或在 visible files 子集上计算。

---

### #17. `lib/features/files/file_grid.dart:341-350` + `lib/features/files/file_view_rows.dart:407-412` — 拖拽未选中项自动改变选择

**问题**: `_provideDragItem` 在未选中时调用 `onSelect` 作为副作用，用户拖拽未选中文件时会意外改变选择状态。

**修复**: 仅在左键按下时选中，拖拽启动时不改变选择。

---

### #18. `lib/core/fs/checksum_service.dart:84` — 每次校验创建新 Isolate

**问题**: `Isolate.run()` 每次调用创建全新 isolate，批量校验大量文件时内存开销巨大。

**修复**: 使用 `compute()` 复用 worker 或维护 isolate 池。

---

## 四、代码质量问题

### #19. `lib/core/fs/safe_file_replace.dart:237-253` — toNativeUtf16 异常时内存泄漏

```dart
final replacement = replacementPath.toNativeUtf16();  // 成功
final destination = destinationPath.toNativeUtf16();  // 若此处抛异常...
try {
  ...
} finally {
  calloc.free(replacement);  // 不会执行
  calloc.free(destination);
}
```

**修复**: 两个转换包在同一个 try 块之外，或使用 `try-finally` 分别管理。

---

### #20. `lib/core/fs/fs_worker_pool.dart:202` — Worker 死亡后请求永久挂起

```dart
final result = await completer.future;  // 无超时
```

**问题**: Worker isolate 崩溃时 completer 永不完成，调用方永久等待。

**修复**: 加超时（如 30 秒）并监听 isolate exit。

---

### #21. `lib/core/archive/archive_writer.dart:78` — 计划缓存永 miss

```dart
static final Map<List<String>, _PlanCache> _planCache = {};
```

**问题**: Dart 中 List 作为 Map key 使用引用相等，每次调用传入新 List 对象，缓存永远 miss。

**修复**: 改用 `sources.join('\n')` 作为 key 或自定义 MapKey 类。

---

### #22. `lib/core/fs/sftp_fs.dart:163-169` — copyWithin 全量加载到内存

```dart
final stream = await openRead(from);
final builder = BytesBuilder(copy: false);
await for (final chunk in stream) {
  builder.add(chunk);
}
await writeBytes(to, builder.toBytes());
```

**问题**: 大文件会占用同等大小的堆内存，可改为流式 pipe。

---

### #23. CLAUDE.md 规则违反 — 代码注释

以下文件包含 `///` 文档注释，违反 "No code comments" 规则：
- `lib/core/fs/myexplorer_core_loader.dart`（多处）
- `lib/core/database/app_database.dart`（L126-129, L171-173）
- `lib/core/fs/checksum_service.dart`（L41-56）
- `lib/core/fs/duplicate_finder.dart`（L9-15, L17-22, L24-30）

---

### #24. `lib/features/navigation/search_bar_widget.dart:759,776` — 翻译标签重复

**问题**: Tab 和 Enter 键都显示 `t.search.complete`，Enter 应显示 `t.search.go` 或类似文案。

---

## 五、工作区清理建议

根目录有以下临时/遗留文件应删除：

| 文件 | 说明 |
|------|------|
| `cache_dirs.txt` | pub 缓存列表，200+ 行 |
| `fix_columns.py` | SQLite 列补丁脚本 |
| `fix_db.ps1` / `fix_db.py` / `fix_db2.py` | 数据库迁移补丁脚本 |
| `fix_db_part1.py` / `fix_db_part2.py` | 拆分版迁移补丁 |
| `fix_skip.py` | 跳过测试补丁 |
| `test.js` | Node.js 临时验证脚本 |
| `.inscode/` / `.reasonix/` / `.workbuddy/` | AI 助手缓存目录 |

---

## 六、优先级排序（建议修复顺序）

| 优先级 | ID | 文件 | 问题 |
|--------|----|------|------|
| **P0** | #3 | `operation_store.dart:414` | 编译错误 `?renameFromInner` |
| **P0** | #1 | `archive_reader.dart:50` | 路径穿越防护失效（安全） |
| **P0** | #2 | `archive_reader.dart:51` | 合法隐藏文件被拦截 |
| **P0** | #4 | `menus.dart:767` | 插件操作级联执行（数据破坏） |
| **P1** | #5 | `keyboard_shortcuts.dart:824` | 快捷键绑定全部错误 |
| **P1** | #6 | `app_database.dart:927` | 收藏夹偏好过度删除 |
| **P1** | #7 | `app_database.dart:422` | 迁移丢失 added 列 |
| **P1** | #8 | `myexplorer_core_loader.dart:522` | 搜索异常返回 done:true |
| **P2** | #9 | `settings_store.dart:395` | dispose 丢设置 |
| **P2** | #10 | `file_grid.dart:422` | 首屏不滚动 |
| **P2** | #11 | `navigation_store.dart:456` | git 监听泄漏 |
| **P2** | #12 | `app_theme_registry.dart:160` | 同步 seeding 不建目录 |
| **P2** | #13 | `sftp_fs.dart:152` | rename session 验证缺失 |
| **P2** | #14 | `duplicate_finder.dart:41` | exit port 未订阅 |
| **P3** | #16-#18 | 多个文件 | 性能优化 |
| **P3** | #19-#24 | 多个文件 | 代码质量 |
