///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh app = _Translations$app$zh._(_root);
	@override late final _Translations$terminal$zh terminal = _Translations$terminal$zh._(_root);
	@override late final _Translations$menu$zh menu = _Translations$menu$zh._(_root);
	@override late final _Translations$multiRename$zh multiRename = _Translations$multiRename$zh._(_root);
	@override late final _Translations$compress$zh compress = _Translations$compress$zh._(_root);
	@override late final _Translations$checksum$zh checksum = _Translations$checksum$zh._(_root);
	@override late final _Translations$compare$zh compare = _Translations$compare$zh._(_root);
	@override late final _Translations$properties$zh properties = _Translations$properties$zh._(_root);
	@override late final _Translations$preferences$zh preferences = _Translations$preferences$zh._(_root);
	@override late final _Translations$update$zh update = _Translations$update$zh._(_root);
	@override late final _Translations$appMenu$zh appMenu = _Translations$appMenu$zh._(_root);
	@override late final _Translations$changelog$zh changelog = _Translations$changelog$zh._(_root);
	@override late final _Translations$help$zh help = _Translations$help$zh._(_root);
	@override late final _Translations$tags$zh tags = _Translations$tags$zh._(_root);
	@override late final _Translations$keybindings$zh keybindings = _Translations$keybindings$zh._(_root);
	@override late final _Translations$commandPalette$zh commandPalette = _Translations$commandPalette$zh._(_root);
	@override late final _Translations$quickLook$zh quickLook = _Translations$quickLook$zh._(_root);
	@override late final _Translations$toast$zh toast = _Translations$toast$zh._(_root);
	@override late final _Translations$terminalInsert$zh terminalInsert = _Translations$terminalInsert$zh._(_root);
	@override late final _Translations$selectionFile$zh selectionFile = _Translations$selectionFile$zh._(_root);
	@override late final _Translations$dragHint$zh dragHint = _Translations$dragHint$zh._(_root);
	@override late final _Translations$fileView$zh fileView = _Translations$fileView$zh._(_root);
	@override late final _Translations$sidebar$zh sidebar = _Translations$sidebar$zh._(_root);
	@override late final _Translations$folderAccess$zh folderAccess = _Translations$folderAccess$zh._(_root);
	@override late final _Translations$toolbar$zh toolbar = _Translations$toolbar$zh._(_root);
	@override late final _Translations$notifications$zh notifications = _Translations$notifications$zh._(_root);
	@override late final _Translations$search$zh search = _Translations$search$zh._(_root);
	@override late final _Translations$statusBar$zh statusBar = _Translations$statusBar$zh._(_root);
	@override late final _Translations$dialog$zh dialog = _Translations$dialog$zh._(_root);
	@override late final _Translations$password$zh password = _Translations$password$zh._(_root);
	@override late final _Translations$selectPattern$zh selectPattern = _Translations$selectPattern$zh._(_root);
	@override late final _Translations$split$zh split = _Translations$split$zh._(_root);
	@override late final _Translations$operations$zh operations = _Translations$operations$zh._(_root);
	@override late final _Translations$errors$zh errors = _Translations$errors$zh._(_root);
	@override late final _Translations$tasks$zh tasks = _Translations$tasks$zh._(_root);
	@override late final _Translations$git$zh git = _Translations$git$zh._(_root);
	@override late final _Translations$openWith$zh openWith = _Translations$openWith$zh._(_root);
	@override late final _Translations$hiddenList$zh hiddenList = _Translations$hiddenList$zh._(_root);
}

// Path: app
class _Translations$app$zh extends Translations$app$en {
	_Translations$app$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'MyExplorer';
	@override String get tagline => '随心浏览你的文件。';
	@override String get description => '一款基于 Flutter 构建的快速、键盘优先的桌面文件管理器。';
}

// Path: terminal
class _Translations$terminal$zh extends Translations$terminal$en {
	_Translations$terminal$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '终端';
}

// Path: menu
class _Translations$menu$zh extends Translations$menu$en {
	_Translations$menu$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get view => '视图';
	@override String get open => '打开';
	@override String openItems({required Object count}) => '打开 ${count} 个项目';
	@override String get copy => '复制';
	@override String get cut => '剪切';
	@override String get paste => '粘贴';
	@override String get duplicate => '复制到此处（副本）';
	@override String get copyPath => '复制路径';
	@override String get delete => '删除';
	@override String deleteItems({required Object count}) => '删除 ${count} 个项目';
	@override String get moveToTrash => '移入回收站';
	@override String moveToTrashItems({required Object count}) => '将 ${count} 个项目移入回收站';
	@override String get deletePermanently => '永久删除';
	@override String deletePermanentlyItems({required Object count}) => '永久删除 ${count} 个项目';
	@override String get restore => '还原';
	@override String restoreItems({required Object count}) => '还原 ${count} 个项目';
	@override String get showHidden => '显示隐藏文件';
	@override String get hideSelected => '加入隐藏列表';
	@override String get hiddenList => '隐藏列表…';
	@override String get selectAll => '全选';
	@override String get selectByPattern => '按模式选择…';
	@override String get deselectAll => '取消全选';
	@override String get invertSelection => '反向选择';
	@override String get saveSelection => '保存选择到文件…';
	@override String get loadSelection => '从文件加载选择…';
	@override String get openInTerminal => '在终端中打开';
	@override String get rename => '重命名';
	@override String get openLocation => '打开位置';
	@override String get openInNewTab => '在新标签页中打开';
	@override String get removeBookmark => '移除书签';
	@override String get addBookmark => '添加到书签';
	@override String get eject => '弹出';
	@override String get disconnect => '断开连接';
	@override String get dualPaneMode => '双栏模式';
	@override String get toggleTerminal => '切换终端';
	@override String get newTerminalTab => '新建终端标签页';
	@override String get closeTerminalTab => '关闭终端标签页';
	@override String get properties => '属性';
	@override String get openWith => '打开方式';
	@override String openWithApp({required Object app}) => '使用 ${app} 打开';
	@override String get openWithChoose => '其他应用…';
	@override String get extract => '解压';
	@override String get extractHere => '解压到此处';
	@override String extractToFolder({required Object name}) => '解压到 ${name}/';
	@override String get extractEach => '逐个解压到独立文件夹';
	@override String get compress => '压缩';
	@override String compressTo({required Object name}) => '压缩到 ${name}';
	@override String get compressOptions => '添加到压缩包…';
	@override String get multiRename => '批量重命名…';
	@override String get verifyChecksum => '校验校验和…';
	@override String get verifyChecksumManifest => '验证校验文件…';
	@override String get createChecksumManifest => '生成校验文件…';
	@override String get splitFile => '分割文件…';
	@override String get combineParts => '合并分卷…';
	@override String get sortBy => '排序方式';
	@override String get sortAscending => '升序';
	@override String get sortDescending => '降序';
	@override String get copyToOtherPane => '复制到对面窗口';
	@override String get moveToOtherPane => '移动到对面窗口';
	@override String get selectGroup => '选一组';
	@override String get deselectGroup => '不选一组';
}

// Path: multiRename
class _Translations$multiRename$zh extends Translations$multiRename$en {
	_Translations$multiRename$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '批量重命名';
	@override String subtitle({required Object count}) => '已选择 ${count} 个项目';
	@override String get modeTemplate => '模板';
	@override String get modeFindReplace => '查找与替换';
	@override String get namePattern => '名称模式';
	@override String get tokens => '令牌';
	@override String get tokenFilename => '不含扩展名的原始名称';
	@override String get tokenExt => '原始扩展名（含点）';
	@override String get tokenN => '序号（从 1 开始）';
	@override String get tokenIndex => '序号索引（从 0 开始）';
	@override String get tokenDate => '今天的日期（YYYY-MM-DD）';
	@override String get find => '查找';
	@override String get replaceWith => '替换为';
	@override String get useRegex => '正则表达式';
	@override String get caseSensitive => '区分大小写';
	@override String get preview => '预览';
	@override String get columnBefore => '之前';
	@override String get columnAfter => '之后';
	@override String get showOnlyChanged => '仅显示更改项';
	@override String changedOfTotal({required Object changed, required Object total}) => '${changed} / ${total} 将被更改';
	@override String errorCount({required Object count}) => '${count} 个冲突';
	@override String get noChanges => '没有文件会被重命名';
	@override String get cancel => '取消';
	@override String get rename => '重命名';
	@override String renameCount({required Object count}) => '重命名 ${count} 个文件';
	@override String get errorInvalid => '无效名称';
	@override String get errorDuplicate => '重名';
}

// Path: compress
class _Translations$compress$zh extends Translations$compress$en {
	_Translations$compress$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '添加到压缩包';
	@override String get archiveName => '压缩包名称';
	@override String get format => '格式';
	@override String get level => '压缩级别';
	@override String get destination => '目标位置';
	@override String get levelStore => '仅存储（不压缩）';
	@override String get levelNormal => '标准';
	@override String get levelMaximum => '最大';
	@override String get create => '创建';
	@override String get cancel => '取消';
}

// Path: checksum
class _Translations$checksum$zh extends Translations$checksum$en {
	_Translations$checksum$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '校验校验和';
	@override String get md5 => 'MD5';
	@override String get sha256 => 'SHA-256';
	@override String get expected => '期望的校验和';
	@override String expectedHint({required Object algorithm}) => '${algorithm} 摘要';
	@override String get verify => '校验';
	@override String get calculating => '正在计算…';
	@override String get match => '校验和匹配';
	@override String get mismatch => '校验和不匹配';
	@override String get copy => '复制';
	@override String get copied => '已复制';
	@override String invalidExpected({required Object algorithm, required Object length}) => '${algorithm} 校验和必须为 ${length} 位十六进制字符';
	@override String get readError => '无法读取文件';
	@override String get createManifest => '生成校验文件';
	@override String createManifestFiles({required Object count}) => '将为 ${count} 个文件生成校验文件';
	@override String get create => '生成';
	@override String get verifyManifest => '验证校验文件';
	@override String verifySummary({required Object ok, required Object total}) => '${ok} 个文件验证通过，共 ${total} 个';
	@override String get manifestEmpty => '校验文件中没有有效条目';
}

// Path: compare
class _Translations$compare$zh extends Translations$compare$en {
	_Translations$compare$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get toolbarTooltip => '比较文件夹';
	@override String get unique => '仅在此处';
	@override String get newer => '较新';
	@override String get older => '较旧';
	@override String get differ => '不同';
	@override String get identical => '相同';
	@override String get syncRight => '同步 →';
	@override String get syncLeft => '← 同步';
	@override String get recursive => '递归';
	@override String get done => '完成';
	@override String get running => '正在比较…';
	@override String counts({required Object identical, required Object differ, required Object uniqueLeft, required Object uniqueRight}) => '${identical} 个相同 · ${differ} 个不同 · ${uniqueLeft} 个仅在左侧 · ${uniqueRight} 个仅在右侧';
}

// Path: properties
class _Translations$properties$zh extends Translations$properties$en {
	_Translations$properties$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '属性';
	@override String get name => '名称';
	@override String get type => '类型';
	@override String get location => '位置';
	@override String get size => '大小';
	@override String get modified => '修改时间';
	@override String get accessed => '访问时间';
	@override String get changed => '更改时间';
	@override String get permissions => '权限';
	@override String get contains => '包含';
	@override String get typeFolder => '文件夹';
	@override String get typeFile => '文件';
	@override String sizeDetail({required Object formatted, required Object count}) => '${formatted}（${count} 字节）';
	@override String containsItems({required Object count}) => '${count} 个项目';
	@override String get calculating => '正在计算…';
	@override String get close => '关闭';
}

// Path: preferences
class _Translations$preferences$zh extends Translations$preferences$en {
	_Translations$preferences$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get menuLabel => '设置…';
	@override String get close => '关闭';
	@override String get searchPlaceholder => '搜索设置…';
	@override String get searchNoResults => '未找到设置';
	@override String get comingSoon => '即将推出';
	@override late final _Translations$preferences$categories$zh categories = _Translations$preferences$categories$zh._(_root);
	@override late final _Translations$preferences$plugins$zh plugins = _Translations$preferences$plugins$zh._(_root);
	@override late final _Translations$preferences$general$zh general = _Translations$preferences$general$zh._(_root);
	@override late final _Translations$preferences$terminal$zh terminal = _Translations$preferences$terminal$zh._(_root);
	@override late final _Translations$preferences$quickLook$zh quickLook = _Translations$preferences$quickLook$zh._(_root);
	@override late final _Translations$preferences$appearance$zh appearance = _Translations$preferences$appearance$zh._(_root);
	@override late final _Translations$preferences$bookmarks$zh bookmarks = _Translations$preferences$bookmarks$zh._(_root);
	@override late final _Translations$preferences$shortcutBar$zh shortcutBar = _Translations$preferences$shortcutBar$zh._(_root);
	@override late final _Translations$preferences$diagnostics$zh diagnostics = _Translations$preferences$diagnostics$zh._(_root);
	@override late final _Translations$preferences$about$zh about = _Translations$preferences$about$zh._(_root);
}

// Path: update
class _Translations$update$zh extends Translations$update$en {
	_Translations$update$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '更新';
	@override String get available => '有可用更新';
	@override String get downloading => '正在下载更新';
	@override String get ready => '准备安装';
	@override String get launching => '正在启动安装程序...';
	@override String get error => '更新错误';
	@override String get checking => '正在检查更新...';
	@override String get unknownError => '未知错误';
	@override String upToDate({required Object version}) => '你已是最新版本（v${version}）。';
	@override String get noRelease => '没有发布信息。';
	@override String get noMatch => '此平台没有匹配的下载。';
	@override String get noNotes => '未提供发布说明。';
	@override String versionLabel({required Object version}) => 'v${version}';
	@override String titleWithVersion({required Object title, required Object version}) => '${title} - v${version}';
	@override String tooltipAvailable({required Object version}) => '有可用更新 - v${version}';
	@override String get tooltipUpToDate => '已是最新';
	@override String get checkForUpdates => '检查更新';
	@override String get releasePage => '发布页面';
	@override String get downloaded => '已下载';
	@override String get btnDownload => '下载';
	@override String get btnGetUpdate => '获取更新';
	@override String get appImageManual => 'AppImage 不会自我更新。请下载新版本并替换此文件。';
	@override String get btnDownloading => '正在下载...';
	@override String get btnCheckNow => '立即检查';
	@override String get btnRetry => '重试';
	@override String get btnInstall => '安装';
	@override String get btnUpdate => '更新';
	@override String get btnOpenDmg => '打开 DMG';
	@override String get statusCheckingInline => '检查中...';
	@override String get statusUpToDateInline => '已是最新';
	@override String get formatInstaller => '安装程序';
	@override String get formatPortable => '便携版';
	@override String get formatUnknown => '未知';
	@override String downloadFailed({required Object statusCode}) => '下载失败：HTTP ${statusCode}';
	@override String githubApiError({required Object statusCode, required Object reason}) => 'GitHub API ${statusCode}：${reason}';
	@override String missingChecksum({required Object asset}) => '更新资源 ${asset} 未提供有效的 SHA-256 校验和。';
	@override String checksumMismatch({required Object asset}) => '更新资源 ${asset} 未通过 SHA-256 校验。';
	@override String get bundleNotWritable => '无法写入程序目录。请手动安装新版本。';
	@override String installerLaunchFailed({required Object error}) => '启动安装程序失败：${error}';
}

// Path: appMenu
class _Translations$appMenu$zh extends Translations$appMenu$en {
	_Translations$appMenu$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get help => '帮助';
	@override String get managePlugins => '管理插件';
	@override String get changelog => '更新日志';
	@override String get repository => '仓库';
	@override String get createIssue => '报告问题';
	@override String get starOnGithub => '在 GitHub 上点赞';
	@override String get quit => '退出';
}

// Path: changelog
class _Translations$changelog$zh extends Translations$changelog$en {
	_Translations$changelog$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '更新日志';
	@override String get loadError => '无法加载更新日志。';
}

// Path: help
class _Translations$help$zh extends Translations$help$en {
	_Translations$help$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '应用内教程';
	@override String get menuLabel => '应用内教程';
	@override late final _Translations$help$groups$zh groups = _Translations$help$groups$zh._(_root);
}

// Path: tags
class _Translations$tags$zh extends Translations$tags$en {
	_Translations$tags$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get menuLabel => '标签';
	@override String get newTag => '新建标签';
	@override String get newTagDots => '新建标签…';
	@override String get editTag => '编辑标签';
	@override String get deleteTag => '删除标签';
	@override String get clear => '清除标签';
	@override String get save => '保存';
}

// Path: keybindings
class _Translations$keybindings$zh extends Translations$keybindings$en {
	_Translations$keybindings$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '键盘快捷键';
	@override String get menuLabel => '快捷键';
	@override late final _Translations$keybindings$categories$zh categories = _Translations$keybindings$categories$zh._(_root);
	@override String get or => '或';
	@override String get fixed => '固定快捷键';
	@override String get change => '更改快捷键';
	@override String get reset => '重置快捷键';
	@override String get pressShortcut => '按下快捷键';
	@override String get escapeToCancel => 'Esc 取消';
	@override String conflict({required Object action}) => '已被 ${action} 使用';
	@override String get dualHint => '双栏';
	@override String get openItem => '打开';
	@override String get goUp => '返回上级';
	@override String get goBack => '后退';
	@override String get goForward => '前进';
	@override String get refresh => '刷新';
	@override String get focusPath => '聚焦路径栏';
	@override String get quickLook => '打开快速预览';
	@override String get quickLookClose => '关闭快速预览';
	@override String get quickLookPrevFile => '上一个文件';
	@override String get quickLookNextFile => '下一个文件';
	@override String get quickLookPrevFileEdit => '编辑时上一个文件';
	@override String get quickLookNextFileEdit => '编辑时下一个文件';
	@override String get quickLookSave => '保存更改';
	@override String get quickViewPanel => '切换快速查看面板';
	@override String get cursorUp => '上移';
	@override String get cursorDown => '下移';
	@override String get pageUp => '上翻一页';
	@override String get pageDown => '下翻一页';
	@override String get home => '跳到开头';
	@override String get end => '跳到结尾';
	@override String get newTab => '新建标签页';
	@override String get closeTab => '关闭标签页';
	@override String get nextTab => '下一个标签页';
	@override String get prevTab => '上一个标签页';
	@override String get switchTab => '切换到标签页';
	@override String get jumpBookmark => '跳转到书签';
	@override String get toggleDual => '切换双栏模式';
	@override String get switchPane => '切换活动面板';
	@override String get compare => '比较文件夹';
	@override String get compareSyncRight => '从左到右同步';
	@override String get compareSyncLeft => '从右到左同步';
	@override String get compareExit => '退出比较模式';
	@override String get focusTerminal => '打开 / 聚焦终端';
	@override String get toggleTerminal => '切换终端';
	@override String get newTerminalTab => '新建终端标签页';
	@override String get closeTerminalTab => '关闭终端标签页';
	@override String get insertRelativePaths => '在终端中插入相对路径';
	@override String get insertAbsolutePaths => '在终端中插入绝对路径';
	@override String get terminalFontIncrease => '增大终端字体';
	@override String get terminalFontDecrease => '减小终端字体';
	@override String get terminalFontReset => '重置终端字体';
	@override String get fileListZoomIn => '放大文件列表';
	@override String get fileListZoomOut => '缩小文件列表';
	@override String get fileListZoomReset => '重置文件列表缩放';
	@override String get toggleSidebar => '切换侧边栏';
	@override String get toggleView => '切换列表/树/网格视图';
	@override String get copy => '复制';
	@override String get cut => '剪切';
	@override String get paste => '粘贴';
	@override String get duplicate => '复制到此处（副本）';
	@override String get delete => '删除';
	@override String get deletePermanent => '永久删除';
	@override String get rename => '重命名';
	@override String get newFolder => '新建文件夹';
	@override String get dualCopy => '复制到另一面板';
	@override String get dualMove => '移动到另一面板';
	@override String get selectAll => '全选';
	@override String get selectPattern => '按模式选择';
	@override String get deselectAll => '取消全选';
	@override String get invertSelection => '反向选择';
	@override String get toggleSelect => '切换选择';
	@override String get saveSelection => '保存选择到文件';
	@override String get loadSelection => '从文件加载选择';
	@override String get computeFolderSize => '计算文件夹大小';
	@override String get search => '搜索';
	@override String get recursiveSearch => '递归搜索';
	@override String get closeSearch => '关闭搜索';
	@override String get commandPalette => '命令面板';
	@override String get preferences => '设置';
}

// Path: commandPalette
class _Translations$commandPalette$zh extends Translations$commandPalette$en {
	_Translations$commandPalette$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '命令面板';
	@override String get placeholder => '输入命令或设置…';
	@override String get empty => '没有匹配的命令';
	@override String get unavailable => '当前不可用';
	@override String get categoryBookmark => '书签';
	@override String get categoryRecent => '最近';
	@override String get categoryDrive => '驱动器';
	@override String get categoryFile => '文件';
	@override String get categoryFolder => '文件夹';
	@override String get categoryPlugin => '插件';
	@override String get openPreferences => '打开设置';
	@override String get preferencesSubtitle => '打开完整的设置对话框';
	@override String get enabled => '已启用';
	@override String get disabled => '已禁用';
	@override String searchingDeep({required Object count}) => '正在搜索子文件夹… 找到 ${count} 个';
	@override String ready({required Object count}) => '${count} 个结果';
}

// Path: quickLook
class _Translations$quickLook$zh extends Translations$quickLook$en {
	_Translations$quickLook$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快速预览';
	@override String get noSelection => '未选择文件';
	@override String get folder => '文件夹';
	@override String get noPreview => '无可用预览';
	@override String get binaryFile => '二进制文件 - 无法预览';
	@override String get tooLarge => '文件太大，无法预览';
	@override String get readError => '无法读取文件';
	@override String get save => '保存';
	@override String get saved => '已保存';
	@override String get unsaved => '未保存';
	@override String get saveError => '无法保存文件';
	@override String get largeFileReadOnly => '大文件 - 为速度以只读方式打开';
	@override String get editAnyway => '仍要编辑';
	@override String get unsavedTitle => '未保存的更改';
	@override String get unsavedMessage => '你有未保存的更改。关闭前保存吗？';
	@override String get discard => '放弃';
	@override String get cancel => '取消';
	@override String get vimNormal => '普通';
	@override String get vimInsert => '插入';
	@override String get vimVisual => '可视';
	@override String get accessed => '访问时间';
	@override String get changed => '更改时间';
	@override String get permissions => '权限';
	@override String get contains => '包含';
	@override String get calculating => '正在计算…';
	@override String items({required Object count}) => '${count} 个项目';
	@override String pdfPages({required Object count}) => '${count} 页';
	@override String get sectionDetails => '详细信息';
	@override String get info => '信息';
	@override String get name => '名称';
	@override String get type => '类型';
	@override String get size => '大小';
	@override String get path => '路径';
	@override String get location => '位置';
	@override String get modified => '修改时间';
	@override String get created => '创建时间';
	@override String get typeFolder => '文件夹';
	@override String get typeFile => '文件';
	@override String get dimensions => '尺寸';
	@override String get camera => '相机';
	@override String get lens => '镜头';
	@override String get exposure => '曝光';
	@override String get aperture => '光圈';
	@override String get iso => 'ISO';
	@override String get focalLength => '焦距';
	@override String get dateTaken => '拍摄日期';
	@override String linePosition({required Object line, required Object count}) => '第 ${line} / ${count} 行';
	@override String get lines => '行数';
	@override String get characters => '字符数';
	@override String get sectionGeneral => '常规';
	@override String get sectionStatistics => '统计';
	@override String get sizeBreakdown => '大小分布';
	@override String get typeBreakdown => '类型分布';
	@override String get noExtension => '无扩展名';
	@override String get sectionImage => '图片';
	@override String get sectionText => '文本';
	@override String get hintSwitchFile => '切换文件';
	@override String get hintClose => '关闭';
	@override String get viewSource => '查看源码';
	@override String get viewRendered => '查看渲染效果';
	@override String get saveBeforePreview => '保存更改以预览';
}

// Path: toast
class _Translations$toast$zh extends Translations$toast$en {
	_Translations$toast$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String copiedItems({required Object count}) => '已复制 ${count} 个项目';
	@override String duplicatedItems({required Object count}) => '已复制 ${count} 个项目（副本）';
	@override String cutItems({required Object count}) => '已剪切 ${count} 个项目';
	@override String selectionSaved({required Object count, required Object path}) => '已将 ${count} 个名称保存到 ${path}';
	@override String selectionLoaded({required Object count}) => '已选择 ${count} 个可见项目';
	@override String get selectionLoadEmpty => '没有可见项目匹配';
	@override String get terminalUnavailable => '终端不可用：原生核心未加载';
	@override String get terminalNotVisible => '终端未打开';
	@override String selectionFileError({required Object message}) => '选择文件错误：${message}';
	@override String taskErrors({required Object label, required Object count}) => '${label} - ${count} 个错误';
	@override String renameAlreadyExists({required Object name}) => '名为“${name}”的项目已存在';
	@override String get renameInvalidName => '无效名称';
	@override String renameError({required Object message}) => '无法重命名：${message}';
	@override String multiRenameSuccess({required Object count}) => '已重命名 ${count} 个文件';
	@override String multiRenamePartial({required Object succeeded, required Object total, required Object details}) => '已重命名 ${succeeded} / ${total}（${details}）';
	@override String multiRenameCollisions({required Object count}) => '${count} 个已存在';
	@override String multiRenameInvalid({required Object count}) => '${count} 个无效名称';
	@override String multiRenameOtherErrors({required Object count}) => '${count} 个错误';
	@override String get multiRenameTrashBlocked => '回收站中无法使用批量重命名';
}

// Path: terminalInsert
class _Translations$terminalInsert$zh extends Translations$terminalInsert$en {
	_Translations$terminalInsert$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object count}) => '插入 ${count} 个选中项目';
	@override String get separator => '分隔符';
	@override String get customHint => '分隔符';
	@override String get preview => '预览';
	@override String get insert => '插入';
}

// Path: selectionFile
class _Translations$selectionFile$zh extends Translations$selectionFile$en {
	_Translations$selectionFile$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get saveTitle => '保存选择';
	@override String get loadTitle => '加载选择';
	@override String get pathLabel => '文本文件';
	@override String get pathHint => 'selection.txt';
	@override String get save => '保存';
	@override String get load => '加载';
}

// Path: dragHint
class _Translations$dragHint$zh extends Translations$dragHint$en {
	_Translations$dragHint$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String copyTo({required Object name}) => '复制到“${name}”';
	@override String moveTo({required Object name}) => '移动到“${name}”';
	@override String get tabToSwitch => '（按住 Alt 拖动以移动）';
}

// Path: fileView
class _Translations$fileView$zh extends Translations$fileView$en {
	_Translations$fileView$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String movingItems({required Object count}) => '正在移动 ${count} 个项目';
	@override String get empty => '文件夹为空';
	@override late final _Translations$fileView$date$zh date = _Translations$fileView$date$zh._(_root);
	@override late final _Translations$fileView$columns$zh columns = _Translations$fileView$columns$zh._(_root);
}

// Path: sidebar
class _Translations$sidebar$zh extends Translations$sidebar$en {
	_Translations$sidebar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get places => '位置';
	@override String get devices => '设备';
	@override String get home => '主页';
	@override String get desktop => '桌面';
	@override String get documents => '文档';
	@override String get downloads => '下载';
	@override String get pictures => '图片';
	@override String get music => '音乐';
	@override String get videos => '视频';
	@override String get trash => '回收站';
	@override String get root => '根目录';
	@override String get network => '网络';
	@override String get containers => '容器';
	@override String get containerRunning => '运行中';
	@override String get bookmarks => '书签';
	@override String get tags => '标签';
	@override String get noTags => '标记文件后它们会显示在这里';
	@override String get dropBookmark => '拖放文件夹以添加书签';
	@override String get editLayout => '编辑侧边栏';
	@override String get editDone => '完成';
	@override String get hide => '隐藏';
	@override String get show => '显示';
	@override String get connectToServer => '连接到服务器';
	@override late final _Translations$sidebar$connectDialog$zh connectDialog = _Translations$sidebar$connectDialog$zh._(_root);
	@override late final _Translations$sidebar$driveSpace$zh driveSpace = _Translations$sidebar$driveSpace$zh._(_root);
	@override late final _Translations$sidebar$drives$zh drives = _Translations$sidebar$drives$zh._(_root);
	@override String get collapse => '折叠侧边栏';
	@override String get expand => '展开侧边栏';
	@override String get collapseSection => '折叠分区';
	@override String get expandSection => '展开分区';
}

// Path: folderAccess
class _Translations$folderAccess$zh extends Translations$folderAccess$en {
	_Translations$folderAccess$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get deniedTitle => '无法访问此文件夹';
	@override String get deniedBody => '系统阻止了对此文件夹的访问。请重试或检查文件夹权限。';
	@override String get retry => '重试';
	@override String get errorTitle => '无法打开此文件夹';
}

// Path: toolbar
class _Translations$toolbar$zh extends Translations$toolbar$en {
	_Translations$toolbar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get back => '后退';
	@override String get forward => '前进';
	@override String get up => '上级';
	@override String get refresh => '刷新';
	@override String get viewOptions => '视图选项';
	@override String get newFolder => '新建文件夹';
	@override String get operations => '操作';
	@override String get notifications => '通知';
	@override String get search => '搜索';
	@override String get multiRename => '批量重命名…';
	@override String get selectByPattern => '按模式选择…';
	@override String get showHidden => '显示隐藏文件';
	@override String get copyPath => '复制路径';
	@override String get saveSelection => '保存选择…';
	@override String get loadSelection => '加载选择…';
	@override String get listView => '列表视图';
	@override String get treeView => '树形视图';
	@override String get gridView => '网格视图';
	@override String get more => '更多';
	@override String get newFile => '新建文件';
	@override String get sync => '同步';
}

// Path: notifications
class _Translations$notifications$zh extends Translations$notifications$en {
	_Translations$notifications$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '通知';
	@override String get empty => '暂无通知';
	@override String get clear => '清除';
}

// Path: search
class _Translations$search$zh extends Translations$search$en {
	_Translations$search$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get placeholder => '筛选…';
	@override String get filterPlaceholder => 'kind:image size:>10mb modified:week';
	@override String get subfolders => '子文件夹';
	@override String get subfoldersShortcut => '子文件夹（Ctrl+Shift+F）';
	@override String get content => '内容';
	@override String get contentSearch => '在文件内容中搜索';
	@override String get contentSftpUnsupported => 'SFTP 上不支持内容搜索';
	@override String get close => '关闭搜索';
	@override String results({required Object count}) => '${count} 个结果';
	@override String found({required Object count}) => '找到 ${count} 个';
	@override String scanning({required Object dirs}) => '已扫描 ${dirs} 个目录';
	@override String truncated({required Object limit}) => '（前 ${limit} 个）';
	@override String get noMatches => '没有匹配';
	@override String get starting => '正在开始…';
	@override String get clear => '清除搜索';
	@override String get modeSubstring => '子串';
	@override String get modeGlob => '通配符';
	@override String get modeRegex => '正则';
	@override String get modeFilter => '筛选构建器';
	@override String get invalidGlob => '无效的通配符模式';
	@override String get invalidRegex => '无效的正则表达式';
	@override late final _Translations$search$filterErrors$zh filterErrors = _Translations$search$filterErrors$zh._(_root);
	@override late final _Translations$search$filterDetails$zh filterDetails = _Translations$search$filterDetails$zh._(_root);
	@override String get complete => '完成';
	@override String get go => '前往';
}

// Path: statusBar
class _Translations$statusBar$zh extends Translations$statusBar$en {
	_Translations$statusBar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String items({required Object count}) => '${count} 个项目';
	@override String folders({required Object count}) => '${count} 个文件夹';
	@override String files({required Object count}) => '${count} 个文件';
	@override String selected({required Object count}) => '已选 ${count} 个';
	@override String get zoomOut => '缩小';
	@override String get zoomIn => '放大';
	@override String get zoomReset => '重置缩放';
}

// Path: dialog
class _Translations$dialog$zh extends Translations$dialog$en {
	_Translations$dialog$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get create => '创建';
	@override String get cancel => '取消';
	@override String get folderNameHint => '文件夹名称';
	@override String get close => '关闭';
	@override String get delete => '删除';
	@override String get moveToTrash => '移入回收站';
	@override String get confirmDeleteTitle => '永久删除？';
	@override String confirmDeleteSingle({required Object name}) => '删除“${name}”？此操作无法撤销。';
	@override String confirmDeleteMultiple({required Object count}) => '删除 ${count} 个项目？此操作无法撤销。';
	@override String get confirmTrashTitle => '移入回收站？';
	@override String confirmTrashSingle({required Object name}) => '将“${name}”移入回收站？';
	@override String confirmTrashMultiple({required Object count}) => '将 ${count} 个项目移入回收站？';
	@override String get copy => '复制';
	@override String get move => '移动';
	@override String get confirmCopyTitle => '复制项目？';
	@override String confirmCopySingle({required Object name}) => '将“${name}”复制到这里？';
	@override String confirmCopyMultiple({required Object count}) => '将 ${count} 个项目复制到这里？';
	@override String get confirmMoveTitle => '移动项目？';
	@override String confirmMoveSingle({required Object name}) => '将“${name}”移动到这里？';
	@override String confirmMoveMultiple({required Object count}) => '将 ${count} 个项目移动到这里？';
}

// Path: password
class _Translations$password$zh extends Translations$password$en {
	_Translations$password$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get authenticationRequired => '需要身份验证';
	@override String get dismiss => '取消';
	@override String get mountPrompt => '输入密码以挂载此驱动器。';
	@override String get smbPrompt => '输入此网络共享的凭据。';
	@override String get sftpPrompt => 'SSH/SFTP 身份验证';
	@override String get username => '用户名';
	@override String get password => '密码';
	@override String get privateKey => '私钥';
	@override String get privateKeyPath => '私钥路径';
	@override String get passphraseOptional => '口令（可选）';
	@override String get unlock => '解锁';
}

// Path: selectPattern
class _Translations$selectPattern$zh extends Translations$selectPattern$en {
	_Translations$selectPattern$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '按模式选择';
	@override String get hint => '*.jpg, *.png';
	@override String get help => '通配符：*（任意）、?（单个字符）。用逗号分隔多个模式。';
	@override String get select => '选择';
}

// Path: split
class _Translations$split$zh extends Translations$split$en {
	_Translations$split$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '分割文件';
	@override String filesCount({required Object count}) => '分割 ${count} 个文件';
	@override String get partSize => '分卷大小';
	@override String get custom => '自定义…';
	@override String get customHint => '大小（字节）';
	@override String get split => '分割';
}

// Path: operations
class _Translations$operations$zh extends Translations$operations$en {
	_Translations$operations$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '操作';
	@override String get clear => '清除';
	@override String get noActive => '没有正在进行的操作';
	@override String get pause => '暂停';
	@override String get resume => '继续';
	@override String get resolveConflicts => '解决冲突';
	@override String errorsCount({required Object count}) => '${count} 个错误';
	@override String get compressing => '正在压缩…';
	@override String get compressingGzip => '正在压缩（gzip）…';
	@override String get compressingBzip2 => '正在压缩（bzip2）…';
	@override String get compressingXz => '正在压缩（xz）…';
	@override String get justNow => '刚刚';
	@override String secondsAgo({required Object count}) => '${count} 秒前';
	@override String minutesAgo({required Object count}) => '${count} 分钟前';
	@override String hoursAgo({required Object count}) => '${count} 小时前';
	@override String eta({required Object time}) => '预计 ${time}';
	@override String get conflictsDetected => '检测到冲突';
	@override String filesExist({required Object count}) => '目标位置已有 ${count} 个文件。';
	@override String get overwriteAll => '全部覆盖';
	@override String get skipAll => '全部跳过';
	@override String get review => '查看';
	@override String fileConflict({required Object index, required Object total}) => '文件冲突（${index}/${total}）';
	@override String get replace => '替换';
	@override String get keepBoth => '两者都保留';
	@override String get skip => '跳过';
	@override String errors({required Object count}) => '错误（${count}）';
	@override String filesCount({required Object processed, required Object count}) => '${processed} / ${count} 个文件';
	@override String get fileExists => '已存在同名文件：';
	@override String source({required Object size, required Object date}) => '来源：${size} · ${date}';
	@override String target({required Object size, required Object date}) => '目标：${size} · ${date}';
	@override String get newer => '  ← 较新';
	@override String applyToAll({required Object count}) => '应用于所有剩余冲突（${count}）';
}

// Path: errors
class _Translations$errors$zh extends Translations$errors$en {
	_Translations$errors$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get permissionDenied => '权限被拒绝';
	@override String get authenticationRequired => '需要身份验证';
	@override String get noSpace => '设备上没有剩余空间';
	@override String get readOnly => '只读文件系统';
	@override String get notFound => '文件不存在';
	@override String get sourceNotFound => '源不存在';
	@override String get pathNotFound => '路径不存在';
	@override String get invalidPartSize => '无效的分卷大小';
	@override String get missingSmbHost => 'smb:// URI 中缺少主机';
	@override String get missingSftpHost => 'sftp:// URI 中缺少主机';
	@override String get invalidSmbUri => '无效的 smb:// URI';
	@override String get smbPortsNotSupportedOnWindows => 'Windows 上不支持 SMB 端口';
	@override String get smbShareNotMounted => 'SMB 共享未挂载';
	@override String netUnavailable({required Object message}) => 'net 不可用：${message}';
	@override String netViewFailed({required Object code}) => 'net view 失败（${code}）';
	@override String failedToCreatePath({required Object path, required Object error}) => '创建 ${path} 失败：${error}';
	@override String get notEmpty => '目录非空';
	@override String get crossDevice => '无法跨设备移动';
	@override String get targetExists => '目标已存在';
	@override String get sftpNotSupported => '不支持 SFTP';
	@override String get sftpConnectFailed => 'SFTP 连接失败';
	@override String sftpError({required Object error}) => 'SFTP：${error}';
	@override String get sftpNoActiveSession => '没有活动的 SFTP 会话';
	@override String sftpNoActiveSessionFor({required Object path}) => '${path} 没有活动的 SFTP 会话';
	@override String get sftpListingFailed => 'SFTP 列表失败';
	@override String get sftpReadFailed => 'SFTP 读取失败';
	@override String get sftpWriteFailed => 'SFTP 写入失败';
	@override String get sftpMkdirFailed => 'SFTP 创建目录失败';
	@override String get sftpRemoveFailed => 'SFTP 删除失败';
	@override String get sftpRenameFailed => 'SFTP 重命名失败';
	@override String get sftpOpenReaderFailed => 'SFTP 打开读取器失败';
	@override String get sftpOpenWriterFailed => 'SFTP 打开写入器失败';
	@override String get sftpCloseFailed => 'SFTP 关闭失败';
	@override String get directoryNotReadable => '目录不可读';
	@override String get transferIntoSelf => '不能将文件夹复制或移动到自身内部。';
	@override String get workerExitedUnexpectedly => '工作进程意外退出';
	@override String get appearedDuring => '操作期间目标位置出现了文件';
	@override String get archiveError => '无法读取压缩包';
	@override String archiveCreateFailed({required Object error}) => '无法创建压缩包：${error}';
	@override String archiveReadFailed({required Object error}) => '压缩包错误：${error}';
	@override String archiveEntryNotFound({required Object path}) => '压缩包条目不存在：${path}';
	@override String get unsupportedArchiveFormat => '不支持的压缩包格式';
	@override String nativeCoreNotFound({required Object paths}) => '未找到原生 waydir_core；已搜索：${paths}';
	@override String moveFileExFailed({required Object error}) => 'MoveFileEx 失败，Windows 错误 ${error}';
	@override String get nativeTrashListFailed => '原生回收站列表失败';
	@override String nativeTrashListFailedWithMessage({required Object message}) => '原生回收站列表失败：${message}';
	@override String get smbNotSupportedOnPlatform => '此平台尚不支持网络共享（smb://）。';
}

// Path: tasks
class _Translations$tasks$zh extends Translations$tasks$en {
	_Translations$tasks$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String copyingSingle({required Object name}) => '正在复制 ${name}';
	@override String copyingMultiple({required Object count}) => '正在复制 ${count} 个项目';
	@override String movingSingle({required Object name}) => '正在移动 ${name}';
	@override String movingMultiple({required Object count}) => '正在移动 ${count} 个项目';
	@override String deletingSingle({required Object name}) => '正在删除 ${name}';
	@override String deletingMultiple({required Object count}) => '正在删除 ${count} 个项目';
	@override String trashingSingle({required Object name}) => '正在将 ${name} 移入回收站';
	@override String trashingMultiple({required Object count}) => '正在将 ${count} 个项目移入回收站';
	@override String restoringTrashSingle({required Object name}) => '正在从回收站还原 ${name}';
	@override String restoringTrashMultiple({required Object count}) => '正在从回收站还原 ${count} 个项目';
	@override String deletingTrashSingle({required Object name}) => '正在从回收站删除 ${name}';
	@override String deletingTrashMultiple({required Object count}) => '正在从回收站删除 ${count} 个项目';
	@override String extractingSingle({required Object name}) => '正在解压 ${name}';
	@override String extractingMultiple({required Object count}) => '正在解压 ${count} 个压缩包';
	@override String compressingTo({required Object name}) => '正在压缩到 ${name}';
	@override String get updatingArchive => '正在更新压缩包';
	@override String splittingSingle({required Object name}) => '正在分割 ${name}';
	@override String splittingMultiple({required Object count}) => '正在分割 ${count} 个项目';
	@override String combiningSingle({required Object name}) => '正在合并 ${name}';
	@override String combiningMultiple({required Object count}) => '正在合并 ${count} 个项目';
	@override late final _Translations$tasks$status$zh status = _Translations$tasks$status$zh._(_root);
}

// Path: git
class _Translations$git$zh extends Translations$git$en {
	_Translations$git$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get clean => '干净';
	@override String get detachedHead => '分离 HEAD';
	@override String get merging => '合并中';
	@override String get rebasing => '变基中';
	@override String get cherryPicking => '拣选中';
	@override String get reverting => '还原中';
	@override String get bisecting => '二分查找中';
	@override String checkoutFailed({required Object message}) => '切换分支失败：${message}';
	@override String get uncommittedChanges => '未提交的更改';
	@override String stashPrompt({required Object branch}) => '切换到“${branch}”将覆盖你的本地更改。\n\n现在暂存它们吗？它们会保存在一个 stash 中，之后可以在此分支上恢复。';
	@override String get stashSwitch => '暂存并切换';
	@override String stashSwitchFailed({required Object message}) => '暂存并切换失败：${message}';
	@override String stashEntry({required Object index, required Object message}) => 'stash@{${index}} · ${message}';
	@override String get stashPop => '弹出（应用并移除）';
	@override String get stashApply => '应用（保留 stash）';
	@override String get stashDrop => '丢弃';
	@override String stashFailed({required Object message}) => '暂存失败：${message}';
	@override String get noRepository => '不是仓库';
	@override String get gitCheckoutFailed => 'git checkout 失败';
	@override String get gitStashFailed => 'git stash 失败';
	@override String changesStashedSwitchFailed({required Object message}) => '更改已暂存，但切换失败：${message}';
}

// Path: openWith
class _Translations$openWith$zh extends Translations$openWith$en {
	_Translations$openWith$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '打开方式';
	@override String subtitle({required Object name}) => '选择用于打开“${name}”的应用';
	@override String get recent => '最近';
	@override String get recommended => '推荐应用';
	@override String get allApps => '所有应用';
	@override String get noApps => '未找到可打开此文件类型的应用。';
	@override String get setDefault => '始终使用此应用打开此文件类型';
	@override String get setDefaultUnavailable => '此平台无法更改默认应用';
	@override String get moreApps => '更多应用…';
	@override String get open => '打开';
	@override String failed({required Object app}) => '无法使用 ${app} 打开文件';
	@override String get setDefaultFailed => '无法设置默认应用';
	@override String get unsupportedPlatform => '不支持的平台';
	@override String get windowsDefaultDialogRequired => '使用系统“打开方式”对话框更改 Windows 上的默认应用';
}

// Path: hiddenList
class _Translations$hiddenList$zh extends Translations$hiddenList$en {
	_Translations$hiddenList$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '隐藏列表';
	@override String get pathHint => '每行一个完整路径（支持粘贴多行）';
	@override String get add => '添加';
	@override String get empty => '暂无隐藏条目';
	@override String added({required Object count}) => '已添加 ${count} 个条目';
}

// Path: preferences.categories
class _Translations$preferences$categories$zh extends Translations$preferences$categories$en {
	_Translations$preferences$categories$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get general => '常规';
	@override String get appearance => '外观';
	@override String get terminal => '终端';
	@override String get quickLook => '快速预览';
	@override String get bookmarks => '书签';
	@override String get plugins => '插件';
	@override String get diagnostics => '诊断';
	@override String get about => '关于';
}

// Path: preferences.plugins
class _Translations$preferences$plugins$zh extends Translations$preferences$plugins$en {
	_Translations$preferences$plugins$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '插件';
	@override String get subtitle => '使用 Lua 插件扩展 Waydir。每个插件是一个包含 manifest.json 和 init.lua 的文件夹。';
	@override String get installedSection => '已安装';
	@override String get openFolder => '打开插件文件夹';
	@override String get reload => '重新加载';
	@override String get empty => '尚未安装插件。';
	@override String get disabled => '已禁用';
	@override String loadError({required Object message}) => '加载错误：${message}';
	@override String actionsCount({required Object count}) => '${count} 个操作';
	@override String reloaded({required Object count}) => '已重新加载 ${count} 个插件';
	@override String get taskRunning => '正在运行…';
	@override String get taskDone => '完成';
	@override String taskFailed({required Object code}) => '失败（退出码 ${code}）';
	@override String taskFailedError({required Object error}) => '失败：${error}';
	@override String get actionFailed => '插件操作失败';
	@override String get taskTimeout => '超时';
	@override String get enable => '启用';
	@override String get disable => '禁用';
	@override String get configure => '配置';
	@override String configureTitle({required Object name}) => '${name} 设置';
	@override String get noSettings => '此插件没有设置。';
	@override String shortcutPrefix({required Object name}) => '插件：${name}';
}

// Path: preferences.general
class _Translations$preferences$general$zh extends Translations$preferences$general$en {
	_Translations$preferences$general$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '常规';
	@override String get subtitle => '启动、文件操作和终端集成。';
	@override String get startupSection => '启动';
	@override String get restoreSession => '恢复上次会话';
	@override String get restoreSessionHint => '启动时重新打开上次的标签页和面板。';
	@override String get defaultPath => '默认起始路径';
	@override String get defaultPathHint => '当会话恢复被禁用或为空时使用。';
	@override String get defaultPathPlaceholder => 'C:/Users/user';
	@override String get browse => '浏览…';
	@override String get foldersSection => '文件夹';
	@override String get fileOpsSection => '文件操作';
	@override String get confirmDelete => '删除前确认';
	@override String get confirmDeleteHint => '删除文件或文件夹前显示对话框。';
	@override String get confirmCopy => '复制前确认';
	@override String get confirmCopyHint => '复制文件或文件夹前显示对话框。';
	@override String get confirmMove => '移动前确认';
	@override String get confirmMoveHint => '移动文件或文件夹前显示对话框。';
	@override String get autoOverwriteOlder => '自动覆盖较旧文件';
	@override String get autoOverwriteOlderHint => '复制时若源文件较新则自动覆盖已存在的文件；若较旧则跳过。';
	@override String get autoSkipSameSize => '自动跳过大小相同的文件';
	@override String get autoSkipSameSizeHint => '复制时若目标文件与源文件大小相同则自动跳过。';
	@override String get dragMovesByDefault => '拖拽时移动而非复制文件';
	@override String get dragMovesByDefaultHint => '开启时，拖拽文件为移动，按住 Alt 为复制。关闭时，拖拽为复制，按住 Alt 为移动。';
	@override String get rememberFolderState => '记住每个文件夹的选择状态';
	@override String get rememberFolderStateHint => '返回文件夹时恢复光标位置和已选文件。';
	@override String get rememberFolderSort => '记住每个文件夹的排序';
	@override String get rememberFolderSortHint => '为每个文件夹保存并复用排序列和方向。';
	@override String get typeAheadBuffer => '键入跳转多字符缓冲';
	@override String get typeAheadBufferHint => '快速键入的字母会组合成搜索字符串以跳转到匹配项；暂停会重置。关闭时，每个字母循环匹配以该字母开头的项目。';
	@override String get deleteKeyBehavior => 'Delete 键行为';
	@override String get deleteKeyBehaviorHint => 'Delete 键的默认行为。Shift+Delete 始终执行永久删除。';
	@override String get deleteKeyTrash => '移入回收站';
	@override String get deleteKeyPermanent => '永久删除';
	@override String get terminalSection => '终端';
	@override String get terminalLabel => '默认终端';
	@override String get terminalHint => '用于“在终端中打开”。';
	@override String get terminalBuiltin => '内置终端';
	@override String get terminalAuto => '外部（自动检测）';
	@override String get terminalCustom => '自定义命令…';
	@override String get terminalCustomLabel => '命令';
	@override String get terminalCustomHint => '例如 wt -d {dir}';
	@override String get terminalCustomHelp => '使用 {dir} 作为目录路径的占位符。';
}

// Path: preferences.terminal
class _Translations$preferences$terminal$zh extends Translations$preferences$terminal$en {
	_Translations$preferences$terminal$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '终端';
	@override String get subtitle => '内置终端字体和外部终端集成。';
	@override String get appearanceSection => '外观';
	@override String get useSystemFont => '使用系统字体';
	@override String get useSystemFontHint => '使用系统等宽字体渲染终端。';
	@override String get fontFamily => '字体';
	@override String get fontFamilyHint => '选择已安装的等宽字体。';
	@override String get fontSize => '字号';
	@override String get fontSizeHint => '使用 Ctrl++、Ctrl+- 和 Ctrl+0 即时调整。';
	@override String get lineHeight => '行高';
	@override String get lineHeightHint => '终端行之间的垂直间距。';
	@override String get shellSection => 'Shell';
	@override String get shellLabel => 'Shell';
	@override String get shellHint => '内置终端启动的程序。';
	@override String get shellSystem => '系统默认';
	@override String get externalSection => '在终端中打开';
	@override String get behaviorSection => '行为';
	@override String get copyPasteMode => '复制/粘贴修饰键';
	@override String get copyPasteModeHint => '终端中复制和粘贴使用的组合键。';
	@override String get copyPasteModeStandard => '标准（Ctrl+C / Ctrl+V）';
	@override String get copyPasteModeShift => '加 Shift（Ctrl+Shift+C / Ctrl+Shift+V）';
}

// Path: preferences.quickLook
class _Translations$preferences$quickLook$zh extends Translations$preferences$quickLook$en {
	_Translations$preferences$quickLook$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快速预览';
	@override String get subtitle => '快速预览中的编辑器字体、行号和模态编辑。';
	@override String get fontSection => '编辑器字体';
	@override String get editorSection => '编辑器';
	@override String get useSystemFont => '使用系统字体';
	@override String get useSystemFontHint => '使用系统等宽字体渲染编辑器。';
	@override String get fontFamily => '字体';
	@override String get fontFamilyHint => '选择已安装的等宽字体。';
	@override String get fontSize => '字号';
	@override String get fontSizeHint => '快速预览编辑器中的文本大小。';
	@override String get lineHeight => '行高';
	@override String get lineHeightHint => '编辑器行之间的垂直间距。';
	@override String get showLineNumbers => '显示行号';
	@override String get showLineNumbersHint => '在编辑器中显示行号栏。';
	@override String get relativeLineNumbers => '相对行号';
	@override String get relativeLineNumbersHint => '显示与当前行的距离而非绝对行号。';
	@override String get wrapLines => '自动换行';
	@override String get wrapLinesHint => '长行自动换行而不是水平滚动。';
	@override String get vimMode => 'Vim 模式';
	@override String get vimModeHint => '基础模态编辑：移动、插入和简单编辑。';
	@override String get showStatistics => '显示统计';
	@override String get showStatisticsHint => '检查多个项目时计算大小和类型分布。';
}

// Path: preferences.appearance
class _Translations$preferences$appearance$zh extends Translations$preferences$appearance$en {
	_Translations$preferences$appearance$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '外观';
	@override String get subtitle => '文件和侧边栏的显示默认值。';
	@override String get themeSection => '主题';
	@override String get theme => '主题';
	@override String get themeHint => '选择内置或自定义主题。';
	@override String get themeDark => '深色';
	@override String get themeLight => '浅色';
	@override String get themeNord => 'Nord';
	@override String get customThemes => '自定义主题';
	@override String get customThemesHint => '将主题 JSON 文件放入此文件夹。切换主题时加载更改。';
	@override String get addTheme => '添加主题';
	@override String get addThemeTitle => '新建自定义主题';
	@override String get addThemeNameHint => '主题名称';
	@override String get addThemeCreate => '创建';
	@override String get addThemeCancel => '取消';
	@override String get editTheme => '编辑';
	@override String get deleteTheme => '删除';
	@override String get deleteThemeTitle => '删除主题？';
	@override String deleteThemeMessage({required Object name}) => '删除“${name}”？此操作无法撤销。';
	@override String get loadingThemes => '正在加载主题…';
	@override String get noCustomThemes => '暂无自定义主题。';
	@override String get invalidTheme => '无效的主题 JSON';
	@override String get themeFileMustContainJsonObject => '主题文件必须包含一个 JSON 对象';
	@override String get missingThemeId => '缺少主题 id';
	@override String get missingThemeName => '缺少主题名称';
	@override String get missingThemeBrightness => '缺少主题亮度';
	@override String get missingThemePalette => '缺少主题调色板';
	@override String get invalidThemeBrightness => '无效的主题亮度';
	@override String missingColor({required Object key}) => '缺少颜色“${key}”';
	@override String invalidColor({required Object key}) => '无效的颜色“${key}”';
	@override String get couldNotLoadCustomThemes => '无法加载自定义主题';
	@override String unknownThemeUsingDefault({required Object id, required Object theme}) => '未知主题“${id}”，使用 ${theme}';
	@override String skippingDuplicateTheme({required Object id, required Object path}) => '跳过主题“${id}”（来自 ${path}）：id 重复';
	@override String skippingThemeFile({required Object path}) => '跳过主题文件 ${path}';
	@override String get filesSection => '文件';
	@override String get showHidden => '默认显示隐藏文件';
	@override String get showHiddenHint => '仅适用于新标签页。现有标签页保持原设置。';
	@override String get rowDensity => '行密度';
	@override String get rowDensityComfortable => '舒适';
	@override String get rowDensityCompact => '紧凑';
	@override String get fileListHorizontalSpacing => '水平间距';
	@override String get columnWidthMode => '列表列宽';
	@override String get columnWidthModeAutomatic => '自动列宽';
	@override String get columnWidthModeResizable => '可调整列宽';
	@override String get fileListVerticalSpacing => '垂直间距';
	@override String get dateFormat => '日期格式';
	@override String get dateFormatIso => 'ISO（2026-05-14 13:45）';
	@override String get dateFormatLocale => '系统区域';
	@override String get dateFormatRelative => '相对（2 小时前）';
	@override String get recentDatesRelative => '近期文件使用相对日期';
	@override String get recentDatesRelativeHint => '选择“系统区域”时，最近 24 小时内修改的文件显示为相对时间。';
	@override String get foldersFirst => '文件夹优先显示';
	@override String get foldersFirstHint => '无论排序方式如何，文件夹都排在文件前面。';
	@override String get sortFolders => '文件夹也参与排序';
	@override String get sortFoldersHint => '关闭时，仅文件参与排序，文件夹保持默认名称顺序。';
	@override String get naturalSort => '自然排序';
	@override String get naturalSortHint => '按数值对名称中的数字排序，使“file2”排在“file10”之前。';
	@override String get sortKey => '文件排序依据';
	@override String get sortKeyName => '名称';
	@override String get sortKeySize => '大小';
	@override String get sortKeyDate => '修改日期';
	@override String get sortDirection => '排序方向';
	@override String get sortAscending => '升序';
	@override String get sortDescending => '降序';
	@override String get sidebarSection => '侧边栏';
	@override String get sidebarCollapsed => '默认折叠';
}

// Path: preferences.bookmarks
class _Translations$preferences$bookmarks$zh extends Translations$preferences$bookmarks$en {
	_Translations$preferences$bookmarks$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '书签';
	@override String get subtitle => '管理固定到侧边栏的文件夹。';
	@override String get empty => '暂无书签。将文件夹拖到侧边栏即可添加。';
	@override String get rename => '重命名';
	@override String get remove => '移除';
}

// Path: preferences.shortcutBar
class _Translations$preferences$shortcutBar$zh extends Translations$preferences$shortcutBar$en {
	_Translations$preferences$shortcutBar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快捷栏';
	@override String get labelHint => '名称';
	@override String get targetHint => '文件夹、文件路径或命令';
	@override String get iconHint => '图标：文件路径或 路径,索引';
	@override String get pickFile => '文件';
	@override String get add => '添加';
	@override String get importTcBar => '导入 Total Commander 按钮栏…';
	@override String imported({required Object count}) => '已导入 ${count} 个按钮';
	@override String get importFailed => '导入按钮栏失败';
}

// Path: preferences.diagnostics
class _Translations$preferences$diagnostics$zh extends Translations$preferences$diagnostics$en {
	_Translations$preferences$diagnostics$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '诊断';
	@override String get subtitle => '最近的警告和错误。日志会写入磁盘用于错误报告。';
	@override String get empty => '本次会话没有记录警告或错误。';
	@override String get search => '筛选日志…';
	@override String get export => '导出当前日志';
	@override String get copy => '复制可见内容';
	@override String get clear => '清除';
	@override String get copied => '已复制到剪贴板';
	@override String get privacyNote => '日志可能包含文件路径。分享前请检查。';
	@override String get native => '原生';
	@override String get unavailable => '不可用';
}

// Path: preferences.about
class _Translations$preferences$about$zh extends Translations$preferences$about$en {
	_Translations$preferences$about$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get version => '版本';
	@override String get build => '构建';
	@override String get repository => '仓库';
	@override String get license => '许可证';
	@override String get copy => '复制';
}

// Path: help.groups
class _Translations$help$groups$zh extends Translations$help$groups$en {
	_Translations$help$groups$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override late final _Translations$help$groups$gettingStarted$zh gettingStarted = _Translations$help$groups$gettingStarted$zh._(_root);
	@override late final _Translations$help$groups$navigating$zh navigating = _Translations$help$groups$navigating$zh._(_root);
	@override late final _Translations$help$groups$tabsPanes$zh tabsPanes = _Translations$help$groups$tabsPanes$zh._(_root);
	@override late final _Translations$help$groups$selecting$zh selecting = _Translations$help$groups$selecting$zh._(_root);
	@override late final _Translations$help$groups$files$zh files = _Translations$help$groups$files$zh._(_root);
	@override late final _Translations$help$groups$previewing$zh previewing = _Translations$help$groups$previewing$zh._(_root);
	@override late final _Translations$help$groups$searching$zh searching = _Translations$help$groups$searching$zh._(_root);
	@override late final _Translations$help$groups$commandPalette$zh commandPalette = _Translations$help$groups$commandPalette$zh._(_root);
	@override late final _Translations$help$groups$remote$zh remote = _Translations$help$groups$remote$zh._(_root);
	@override late final _Translations$help$groups$customization$zh customization = _Translations$help$groups$customization$zh._(_root);
	@override late final _Translations$help$groups$resources$zh resources = _Translations$help$groups$resources$zh._(_root);
}

// Path: keybindings.categories
class _Translations$keybindings$categories$zh extends Translations$keybindings$categories$en {
	_Translations$keybindings$categories$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get navigation => '导航';
	@override String get quickLook => '快速预览';
	@override String get view => '视图';
	@override String get tabs => '标签页';
	@override String get panes => '面板';
	@override String get terminal => '终端';
	@override String get fileOps => '文件操作';
	@override String get selection => '选择';
	@override String get search => '搜索';
	@override String get general => '常规';
}

// Path: fileView.date
class _Translations$fileView$date$zh extends Translations$fileView$date$en {
	_Translations$fileView$date$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get justNow => '刚刚';
	@override String minutesAgo({required Object count}) => '${count} 分钟前';
	@override String hoursAgo({required Object count}) => '${count} 小时前';
	@override String daysAgo({required Object count}) => '${count} 天前';
	@override String weeksAgo({required Object count}) => '${count} 周前';
	@override String monthsAgo({required Object count}) => '${count} 个月前';
	@override String yearsAgo({required Object count}) => '${count} 年前';
}

// Path: fileView.columns
class _Translations$fileView$columns$zh extends Translations$fileView$columns$en {
	_Translations$fileView$columns$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get name => '名称';
	@override String get size => '大小';
	@override String get dateModified => '修改日期';
	@override String get location => '位置';
	@override String get kind => '格式';
	@override String get dateCreated => '创建日期';
	@override String get dateAdded => '添加日期';
	@override String get permissions => '权限';
	@override String get owner => '所有者';
	@override String get configure => '配置列';
}

// Path: sidebar.connectDialog
class _Translations$sidebar$connectDialog$zh extends Translations$sidebar$connectDialog$en {
	_Translations$sidebar$connectDialog$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '连接到服务器';
	@override String get host => '服务器';
	@override String get hostHint => '例如 192.168.1.10 或 nas.local';
	@override String get port => '端口';
	@override String get username => '用户名';
	@override String get usernameHint => '可选';
	@override String get share => '共享';
	@override String get shareHint => '可选';
	@override String get pathLabel => '路径';
	@override String get pathHint => '可选';
	@override String get addBookmark => '添加书签';
	@override String get connect => '连接';
	@override String get invalidHost => '请输入服务器地址';
}

// Path: sidebar.driveSpace
class _Translations$sidebar$driveSpace$zh extends Translations$sidebar$driveSpace$en {
	_Translations$sidebar$driveSpace$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get used => '已用';
	@override String get free => '可用';
	@override String get total => '总计';
}

// Path: sidebar.drives
class _Translations$sidebar$drives$zh extends Translations$sidebar$drives$en {
	_Translations$sidebar$drives$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get localDisk => '本地磁盘';
	@override String get usbDrive => 'USB 驱动器';
	@override String get unknownDrive => '未知驱动器';
	@override String get networkDrive => '网络驱动器';
	@override String windowsDriveLabel({required Object name, required Object letter}) => '${name}（${letter}:）';
	@override String mountTitle({required Object name}) => '挂载 ${name}';
}

// Path: search.filterErrors
class _Translations$search$filterErrors$zh extends Translations$search$filterErrors$en {
	_Translations$search$filterErrors$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String unknownFilter({required Object key}) => '未知筛选器：${key}';
	@override String missingValue({required Object key}) => '${key} 缺少值';
	@override String unknownKind({required Object kind}) => '未知类型：${kind}';
	@override String unknownType({required Object type}) => '未知类型：${type}';
	@override String get invalidSize => '无效的大小筛选';
	@override String unknownModified({required Object value}) => '未知的修改时间值：${value}';
	@override String unknownCreated({required Object value}) => '未知的创建时间值：${value}';
	@override String get hiddenBoolean => '隐藏必须为 true 或 false';
}

// Path: search.filterDetails
class _Translations$search$filterDetails$zh extends Translations$search$filterDetails$en {
	_Translations$search$filterDetails$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get name => '文件名包含文本';
	@override String get kind => '类别，如图片或代码';
	@override String get ext => '扩展名列表，如 dart,png';
	@override String get type => '文件或文件夹';
	@override String get size => '比较，如 >10mb';
	@override String get modified => '今天、本周、本月或今年';
	@override String get created => '今天、本周、本月或今年';
	@override String get hidden => 'true 或 false';
}

// Path: tasks.status
class _Translations$tasks$status$zh extends Translations$tasks$status$en {
	_Translations$tasks$status$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get waiting => '等待中...';
	@override String get scanning => '正在扫描文件...';
	@override String conflicts({required Object count}) => '${count} 个冲突';
	@override String running({required Object current, required Object processed, required Object total}) => '${current}（${processed}/${total}）';
	@override String get cancelling => '正在取消...';
	@override String completedWithErrors({required Object count}) => '完成，${count} 个错误';
	@override String get completed => '已完成';
	@override String get failed => '失败';
	@override String get cancelled => '已取消';
}

// Path: help.groups.gettingStarted
class _Translations$help$groups$gettingStarted$zh extends Translations$help$groups$gettingStarted$en {
	_Translations$help$groups$gettingStarted$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快速上手';
	@override late final _Translations$help$groups$gettingStarted$welcome$zh welcome = _Translations$help$groups$gettingStarted$welcome$zh._(_root);
	@override late final _Translations$help$groups$gettingStarted$interface$zh interface = _Translations$help$groups$gettingStarted$interface$zh._(_root);
	@override late final _Translations$help$groups$gettingStarted$keyboardBasics$zh keyboardBasics = _Translations$help$groups$gettingStarted$keyboardBasics$zh._(_root);
}

// Path: help.groups.navigating
class _Translations$help$groups$navigating$zh extends Translations$help$groups$navigating$en {
	_Translations$help$groups$navigating$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '导航';
	@override late final _Translations$help$groups$navigating$moving$zh moving = _Translations$help$groups$navigating$moving$zh._(_root);
	@override late final _Translations$help$groups$navigating$breadcrumb$zh breadcrumb = _Translations$help$groups$navigating$breadcrumb$zh._(_root);
	@override late final _Translations$help$groups$navigating$bookmarks$zh bookmarks = _Translations$help$groups$navigating$bookmarks$zh._(_root);
	@override late final _Translations$help$groups$navigating$drives$zh drives = _Translations$help$groups$navigating$drives$zh._(_root);
	@override late final _Translations$help$groups$navigating$typeAhead$zh typeAhead = _Translations$help$groups$navigating$typeAhead$zh._(_root);
}

// Path: help.groups.tabsPanes
class _Translations$help$groups$tabsPanes$zh extends Translations$help$groups$tabsPanes$en {
	_Translations$help$groups$tabsPanes$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标签页与面板';
	@override late final _Translations$help$groups$tabsPanes$tabs$zh tabs = _Translations$help$groups$tabsPanes$tabs$zh._(_root);
	@override late final _Translations$help$groups$tabsPanes$dualPane$zh dualPane = _Translations$help$groups$tabsPanes$dualPane$zh._(_root);
	@override late final _Translations$help$groups$tabsPanes$compare$zh compare = _Translations$help$groups$tabsPanes$compare$zh._(_root);
}

// Path: help.groups.selecting
class _Translations$help$groups$selecting$zh extends Translations$help$groups$selecting$en {
	_Translations$help$groups$selecting$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '选择';
	@override late final _Translations$help$groups$selecting$basics$zh basics = _Translations$help$groups$selecting$basics$zh._(_root);
	@override late final _Translations$help$groups$selecting$pattern$zh pattern = _Translations$help$groups$selecting$pattern$zh._(_root);
}

// Path: help.groups.files
class _Translations$help$groups$files$zh extends Translations$help$groups$files$en {
	_Translations$help$groups$files$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '处理文件';
	@override late final _Translations$help$groups$files$operations$zh operations = _Translations$help$groups$files$operations$zh._(_root);
	@override late final _Translations$help$groups$files$dragDrop$zh dragDrop = _Translations$help$groups$files$dragDrop$zh._(_root);
	@override late final _Translations$help$groups$files$multiRename$zh multiRename = _Translations$help$groups$files$multiRename$zh._(_root);
	@override late final _Translations$help$groups$files$archives$zh archives = _Translations$help$groups$files$archives$zh._(_root);
	@override late final _Translations$help$groups$files$openWith$zh openWith = _Translations$help$groups$files$openWith$zh._(_root);
	@override late final _Translations$help$groups$files$tags$zh tags = _Translations$help$groups$files$tags$zh._(_root);
	@override late final _Translations$help$groups$files$hiddenList$zh hiddenList = _Translations$help$groups$files$hiddenList$zh._(_root);
}

// Path: help.groups.previewing
class _Translations$help$groups$previewing$zh extends Translations$help$groups$previewing$en {
	_Translations$help$groups$previewing$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '预览';
	@override late final _Translations$help$groups$previewing$quickLook$zh quickLook = _Translations$help$groups$previewing$quickLook$zh._(_root);
	@override late final _Translations$help$groups$previewing$editor$zh editor = _Translations$help$groups$previewing$editor$zh._(_root);
}

// Path: help.groups.searching
class _Translations$help$groups$searching$zh extends Translations$help$groups$searching$en {
	_Translations$help$groups$searching$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '搜索';
	@override late final _Translations$help$groups$searching$folder$zh folder = _Translations$help$groups$searching$folder$zh._(_root);
	@override late final _Translations$help$groups$searching$function$zh function = _Translations$help$groups$searching$function$zh._(_root);
}

// Path: help.groups.commandPalette
class _Translations$help$groups$commandPalette$zh extends Translations$help$groups$commandPalette$en {
	_Translations$help$groups$commandPalette$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '命令面板';
	@override late final _Translations$help$groups$commandPalette$basics$zh basics = _Translations$help$groups$commandPalette$basics$zh._(_root);
	@override late final _Translations$help$groups$commandPalette$files$zh files = _Translations$help$groups$commandPalette$files$zh._(_root);
}

// Path: help.groups.remote
class _Translations$help$groups$remote$zh extends Translations$help$groups$remote$en {
	_Translations$help$groups$remote$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '远程与集成';
	@override late final _Translations$help$groups$remote$sftp$zh sftp = _Translations$help$groups$remote$sftp$zh._(_root);
	@override late final _Translations$help$groups$remote$network$zh network = _Translations$help$groups$remote$network$zh._(_root);
	@override late final _Translations$help$groups$remote$terminal$zh terminal = _Translations$help$groups$remote$terminal$zh._(_root);
	@override late final _Translations$help$groups$remote$git$zh git = _Translations$help$groups$remote$git$zh._(_root);
}

// Path: help.groups.customization
class _Translations$help$groups$customization$zh extends Translations$help$groups$customization$en {
	_Translations$help$groups$customization$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '自定义';
	@override late final _Translations$help$groups$customization$themes$zh themes = _Translations$help$groups$customization$themes$zh._(_root);
	@override late final _Translations$help$groups$customization$shortcuts$zh shortcuts = _Translations$help$groups$customization$shortcuts$zh._(_root);
	@override late final _Translations$help$groups$customization$plugins$zh plugins = _Translations$help$groups$customization$plugins$zh._(_root);
	@override late final _Translations$help$groups$customization$shortcutBar$zh shortcutBar = _Translations$help$groups$customization$shortcutBar$zh._(_root);
}

// Path: help.groups.resources
class _Translations$help$groups$resources$zh extends Translations$help$groups$resources$en {
	_Translations$help$groups$resources$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '资源';
	@override late final _Translations$help$groups$resources$links$zh links = _Translations$help$groups$resources$links$zh._(_root);
}

// Path: help.groups.gettingStarted.welcome
class _Translations$help$groups$gettingStarted$welcome$zh extends Translations$help$groups$gettingStarted$welcome$en {
	_Translations$help$groups$gettingStarted$welcome$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '欢迎使用 MyExplorer';
	@override String get body => 'MyExplorer 是一款快速、键盘驱动的文件管理器。本指南将带你了解从基本导航到远程服务器、终端和自定义的方方面面。\n\n- 使用左侧的树在主题之间跳转。\n- 大多数操作都有快捷键，以 `Ctrl+C` 的形式内联显示。\n- 所有快捷键都可以在 **设置 -> 键盘** 中重新绑定。\n\n选择一个主题开始，或从头到尾通读。';
}

// Path: help.groups.gettingStarted.interface
class _Translations$help$groups$gettingStarted$interface$zh extends Translations$help$groups$gettingStarted$interface$en {
	_Translations$help$groups$gettingStarted$interface$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '界面';
	@override String get body => '窗口由几个简单的部分构成。\n\n- **侧边栏** - 书签、驱动器和远程位置。使用 `Ctrl+B` 切换。\n- **标签栏** - 每个打开的文件夹一个标签。\n- **面包屑栏** - 当前路径；点击任意片段即可跳转。\n- **文件列表** - 主视图，支持列表、树或网格模式。\n- **状态栏** - 项目数量、选中大小和操作进度。';
}

// Path: help.groups.gettingStarted.keyboardBasics
class _Translations$help$groups$gettingStarted$keyboardBasics$zh extends Translations$help$groups$gettingStarted$keyboardBasics$en {
	_Translations$help$groups$gettingStarted$keyboardBasics$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '键盘优先基础';
	@override String get body => 'MyExplorer 设计为完全通过键盘驱动。\n\n- `↑` / `↓` 移动光标；`Enter` 打开；`Backspace` 返回上级。\n- 直接输入字符可跳转到匹配文件（键入跳转）。\n- `Ctrl+F` 搜索，`Space` 预览，`F2` 重命名。\n- 几乎所有操作都不需要鼠标 - 而且每个按键绑定都可以自定义。';
}

// Path: help.groups.navigating.moving
class _Translations$help$groups$navigating$moving$zh extends Translations$help$groups$navigating$moving$en {
	_Translations$help$groups$navigating$moving$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '四处移动';
	@override String get body => '无需鼠标即可浏览。MyExplorer 将光标、选择和历史记录保持在主文件列表附近。\n\n- `↑` / `↓` 在可见文件中移动光标。\n- `Enter` 打开选中项；双击效果相同。\n- `Backspace` 返回上级文件夹。\n- `Alt+←` / `Alt+→` 在文件夹历史中后退和前进。\n- `Ctrl+R` 刷新当前文件夹。';
}

// Path: help.groups.navigating.breadcrumb
class _Translations$help$groups$navigating$breadcrumb$zh extends Translations$help$groups$navigating$breadcrumb$en {
	_Translations$help$groups$navigating$breadcrumb$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '面包屑栏';
	@override String get body => '面包屑栏显示你所在的位置，让你快速移动。\n\n- 点击任意片段直接跳转到该文件夹。\n- 导航时路径保持同步。\n- 直接输入路径可前往特定位置。';
}

// Path: help.groups.navigating.bookmarks
class _Translations$help$groups$navigating$bookmarks$zh extends Translations$help$groups$navigating$bookmarks$en {
	_Translations$help$groups$navigating$bookmarks$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '书签与侧边栏';
	@override String get body => '侧边栏让你最常用的文件夹一键可达。\n\n- 将文件夹拖入侧边栏即可添加书签。\n- 根据需要重新排序、重命名或隐藏侧边栏条目。\n- `Ctrl+B` 完全显示或隐藏侧边栏。\n- 分区（收藏、设备、网络）可以独立折叠。';
}

// Path: help.groups.navigating.drives
class _Translations$help$groups$navigating$drives$zh extends Translations$help$groups$navigating$drives$en {
	_Translations$help$groups$navigating$drives$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '驱动器与设备';
	@override String get body => '已挂载的驱动器和可移动设备显示在侧边栏的“设备”下。\n\n- 点击设备即可打开。\n- 从右键菜单弹出可移动设备。\n- 网络共享和远程挂载与本地驱动器并列显示。';
}

// Path: help.groups.navigating.typeAhead
class _Translations$help$groups$navigating$typeAhead$zh extends Translations$help$groups$navigating$typeAhead$en {
	_Translations$help$groups$navigating$typeAhead$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '键入跳转';
	@override String get body => '文件列表获得焦点时直接输入，即可跳转到匹配的名称。\n\n- 匹配是增量的 - 继续输入以精确定位。\n- 输入时光标移动到第一个匹配项。\n- 可以在 **设置 -> 常规** 中关闭键入跳转。';
}

// Path: help.groups.tabsPanes.tabs
class _Translations$help$groups$tabsPanes$tabs$zh extends Translations$help$groups$tabsPanes$tabs$en {
	_Translations$help$groups$tabsPanes$tabs$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标签页';
	@override String get body => '同时打开多个文件夹并即时切换。每个标签记住自己的文件夹、选择和历史。\n\n- `Ctrl+T` 新建标签页。\n- `Ctrl+W` 关闭当前标签页。\n- `Ctrl+Tab` / `Ctrl+Shift+Tab` 切换到下一个或上一个标签页。\n- `Ctrl+1`…`Ctrl+9` 按位置直接跳转到标签页。\n- 标签栏上的 `+` 按钮在当前文件夹中新建标签页。';
}

// Path: help.groups.tabsPanes.dualPane
class _Translations$help$groups$tabsPanes$dualPane$zh extends Translations$help$groups$tabsPanes$dualPane$en {
	_Translations$help$groups$tabsPanes$dualPane$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '双栏模式';
	@override String get body => '并排显示源和目标。活动面板拥有键盘焦点，复制/移动快捷键作用于对面面板。\n\n- `F9`（或 `Ctrl+D`）切换双栏模式。\n- `Tab` 切换活动面板。\n- `F5` 将选中文件复制到另一面板。\n- `F6` 将选中文件移动到另一面板。\n- 拖动分隔条调整空间分配。';
}

// Path: help.groups.tabsPanes.compare
class _Translations$help$groups$tabsPanes$compare$zh extends Translations$help$groups$tabsPanes$compare$en {
	_Translations$help$groups$tabsPanes$compare$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件夹比较与同步';
	@override String get body => '在双栏模式下比较两个面板以查看差异，然后将一侧同步到另一侧。\n\n- 双栏模式激活时 `F8` 开启比较。\n- 行会着色：仅在此处、较新、较旧或相同。\n- 切换 **递归** 以比较嵌套文件夹或仅比较顶层。\n- `Ctrl+→` / `Ctrl+←` 将差异从左到右或从右到左同步。\n- 导航离开比较的文件夹时比较会自动关闭。`Esc` 退出。';
}

// Path: help.groups.selecting.basics
class _Translations$help$groups$selecting$basics$zh extends Translations$help$groups$selecting$basics$en {
	_Translations$help$groups$selecting$basics$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '选择基础';
	@override String get body => '在操作前精确构建你想要的文件集合。\n\n- `Ctrl+A` 全选文件夹中的内容。\n- `Insert` 切换当前项目并向下移动。\n- `Esc` 清除选择。\n- 点击、`Shift+点击` 选择范围，`Ctrl+点击` 添加或移除单个项目。\n- `Ctrl+Shift+S` 将当前选择保存到文件；`Ctrl+Shift+L` 加载回来。';
}

// Path: help.groups.selecting.pattern
class _Translations$help$groups$selecting$pattern$zh extends Translations$help$groups$selecting$pattern$en {
	_Translations$help$groups$selecting$pattern$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '按模式选择';
	@override String get body => '使用通配符模式选择文件，而不是手动挑选。\n\n- `Ctrl+S` 打开按模式选择。\n- 使用 `*.png` 或 `report-*.pdf` 之类的通配符。\n- 匹配的集合会添加到当前选择中。';
}

// Path: help.groups.files.operations
class _Translations$help$groups$files$operations$zh extends Translations$help$groups$files$operations$en {
	_Translations$help$groups$files$operations$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '复制、移动与删除';
	@override String get body => '标准的剪贴板和文件操作处处可用，包括跨面板和跨标签页。\n\n- `Ctrl+C` / `Ctrl+X` / `Ctrl+V` 复制、剪切和粘贴。\n- `F2` 重命名当前项目；`F7` 新建文件夹。\n- `Delete` 将选择移入回收站；使用右键菜单可永久删除。\n- 大型复制、移动和删除在后台运行，名称冲突时会出现冲突提示。';
}

// Path: help.groups.files.dragDrop
class _Translations$help$groups$files$dragDrop$zh extends Translations$help$groups$files$dragDrop$en {
	_Translations$help$groups$files$dragDrop$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '拖放';
	@override String get body => '在面板、标签页和侧边栏之间拖放文件 - 或拖入/拖出其他应用。\n\n- 默认拖拽 **复制** 文件；按住 `Alt` **移动**。\n- 在 **设置 -> 常规** 中翻转默认行为，使拖拽移动、`Alt` 复制。\n- 拖拽提示显示本次放下将复制还是移动。\n- 放到文件夹上可将文件放入其中，放到空白区域则放入当前文件夹。';
}

// Path: help.groups.files.multiRename
class _Translations$help$groups$files$multiRename$zh extends Translations$help$groups$files$multiRename$en {
	_Translations$help$groups$files$multiRename$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '批量重命名';
	@override String get body => '通过实时前后预览一次重命名多个文件。选择多个项目，然后从右键菜单中选择 **批量重命名**。\n\n- **模板** 模式使用令牌构建名称：`{name}`、`{ext}`、`{n}`（从 1 开始）、`{index}`（从 0 开始）和 `{date}`。\n- **查找与替换** 模式交换文本，支持可选的正则表达式和大小写敏感。\n- 预览会在提交前列出每个结果，*仅显示更改* 隐藏未修改的行。';
}

// Path: help.groups.files.archives
class _Translations$help$groups$files$archives$zh extends Translations$help$groups$files$archives$en {
	_Translations$help$groups$files$archives$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '压缩包';
	@override String get body => '压缩包像可浏览的文件夹一样工作，可以在解压前查看内容。\n\n- `Enter` 打开支持的压缩包并浏览其内容。\n- 右键菜单可以解压到此处、解压到命名文件夹，或逐个解压每个压缩包。\n- **压缩** 从选择构建新压缩包 - 选择格式和压缩级别。\n- 解压和压缩在后台运行，文件列表保持响应。';
}

// Path: help.groups.files.openWith
class _Translations$help$groups$files$openWith$zh extends Translations$help$groups$files$openWith$en {
	_Translations$help$groups$files$openWith$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '打开方式与默认应用';
	@override String get body => '在任何已安装的应用中打开文件，而不只是系统默认应用。\n\n- 右键菜单中的 **打开方式** 列出可用应用。\n- 为每种文件类型设置默认应用，以后直接打开。\n- 最近使用的应用显示在顶部，方便快速访问。';
}

// Path: help.groups.files.tags
class _Translations$help$groups$files$tags$zh extends Translations$help$groups$files$tags$en {
	_Translations$help$groups$files$tags$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '颜色标签';
	@override String get body => '用彩色标签标记文件和文件夹，方便快速找到它们。开箱即用提供三个标签 - **红**、**绿** 和 **蓝**。\n\n- 从右键菜单的 **标签** 子菜单分配或移除标签，或将文件拖到侧边栏的标签上。\n- 标记的项目在文件列表中显示彩色圆点，一个项目可以带多个标签。\n- 每个标签显示在侧边栏的 **标签** 分区中；点击即可列出所有带该标签的文件，无论它们在哪里。\n- 在标签视图中，使用右键菜单的 **打开位置** 跳转到文件的真实文件夹。\n- 右键点击侧边栏中的标签可重命名、更改颜色或删除；删除标签会从所有文件中移除。\n- 标签仅适用于本地文件 - 不适用于 SFTP、网络共享或压缩包内的项目。';
}

// Path: help.groups.files.hiddenList
class _Translations$help$groups$files$hiddenList$zh extends Translations$help$groups$files$hiddenList$en {
	_Translations$help$groups$files$hiddenList$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '隐藏列表';
	@override String get body => '无需改动文件本身，即可从所有列表视图中隐藏选中的文件和文件夹。\n\n- 选中一个或多个项目，右键并选择**加入隐藏列表**。\n- 隐藏的项目会从文件列表、树形视图、侧边栏和最近访问中消失。\n- 条目存储在可执行文件旁的 `隐藏文件.ini` 中。\n- 要重新显示某个项目，请打开**视图 -> 隐藏列表...** 并删除其条目。\n- 隐藏文件夹只隐藏该文件夹本身；打开它时其内容仍然可见。';
}

// Path: help.groups.previewing.quickLook
class _Translations$help$groups$previewing$quickLook$zh extends Translations$help$groups$previewing$quickLook$en {
	_Translations$help$groups$previewing$quickLook$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快速预览';
	@override String get body => '无需打开其他应用即可检查文件。快速预览支持图片、文本、代码、Markdown 和其他类型。\n\n- `Space` 为当前选择打开快速预览。\n- `↑` / `↓` 在不离开预览的情况下切换到上一个或下一个文件。\n- `Esc` 关闭预览。\n- 信息面板显示大小、日期和权限。';
}

// Path: help.groups.previewing.editor
class _Translations$help$groups$previewing$editor$zh extends Translations$help$groups$previewing$editor$en {
	_Translations$help$groups$previewing$editor$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快速预览编辑器';
	@override String get body => '文本和代码预览可以直接编辑。\n\n- `Ctrl+S` 保存更改而不离开预览。\n- 切换行号、相对行号和自动换行。\n- 启用 **Vim 模式** 进行模态编辑。\n- Markdown 文件可以渲染格式或显示原始源码。\n- 所有编辑器选项位于 **设置 -> 快速预览**。';
}

// Path: help.groups.searching.folder
class _Translations$help$groups$searching$folder$zh extends Translations$help$groups$searching$folder$en {
	_Translations$help$groups$searching$folder$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '在文件夹中搜索';
	@override String get body => '筛选当前文件夹或扫描其下的所有内容。\n\n- `Ctrl+F` 输入时按名称筛选当前文件夹。\n- `Ctrl+Shift+F` 将搜索扩展到所有子文件夹。\n- 打开 **内容** 可在文件内容中搜索（仅限本地文件夹 - 不支持 SFTP）。\n- 在 **子串**、**通配符** 和 **正则** 匹配之间切换。\n- `Esc` 关闭搜索并恢复完整列表。';
}

// Path: help.groups.searching.function
class _Translations$help$groups$searching$function$zh extends Translations$help$groups$searching$function$en {
	_Translations$help$groups$searching$function$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '功能与命令搜索';
	@override String get body => '无需在菜单中翻找即可查找并运行任何 MyExplorer 操作。\n\n- 打开命令搜索并输入操作名称。\n- 结果显示匹配的命令及其当前快捷键。\n- 直接从列表中运行 - 适合不常用的操作。';
}

// Path: help.groups.commandPalette.basics
class _Translations$help$groups$commandPalette$basics$zh extends Translations$help$groups$commandPalette$basics$en {
	_Translations$help$groups$commandPalette$basics$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '运行命令';
	@override String get body => '命令面板是无需离开键盘触发操作的最快方式。\n\n- 按 `Ctrl+P` 打开。\n- 输入操作、设置、书签、驱动器、最近路径或插件命令。\n- 结果包含已分配的快捷键。\n- 不适用的操作以弱化状态保持可见。\n- 按 `Enter` 运行高亮命令，或按 `Esc` 关闭面板。';
}

// Path: help.groups.commandPalette.files
class _Translations$help$groups$commandPalette$files$zh extends Translations$help$groups$commandPalette$files$en {
	_Translations$help$groups$commandPalette$files$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '从面板查找文件';
	@override String get body => '面板还可以作为当前文件夹的快速文件跳转器。\n\n- 输入文件或文件夹名称匹配可见项目。\n- 继续输入片刻，MyExplorer 也会搜索子文件夹。\n- 递归文件匹配会显示其所在文件夹作为副标题。\n- 选择文件或文件夹会在当前面板中聚焦它，以便打开、预览或操作。';
}

// Path: help.groups.remote.sftp
class _Translations$help$groups$remote$sftp$zh extends Translations$help$groups$remote$sftp$en {
	_Translations$help$groups$remote$sftp$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'SFTP 与远程服务器';
	@override String get body => '直接在本地文件夹旁边使用 SFTP 服务器。\n\n- 从侧边栏使用 **连接到服务器** 添加远程位置。\n- 连接后，浏览远程文件夹与本地完全相同。\n- 常访问的文件夹添加书签，一键可达。\n- 选择、右键菜单和文件操作与本地一致 - 只有内容搜索在 SFTP 上不可用。';
}

// Path: help.groups.remote.network
class _Translations$help$groups$remote$network$zh extends Translations$help$groups$remote$network$en {
	_Translations$help$groups$remote$network$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '网络路径与 WSL';
	@override String get body => 'MyExplorer 处理网络共享和适用于 Linux 的 Windows 子系统路径。\n\n- 像本地文件夹一样浏览已挂载的 SMB / 网络共享。\n- 在 Windows 上，WSL 发行版路径可被识别和打开。\n- 网络位置受到保护，慢速共享不会冻结界面。';
}

// Path: help.groups.remote.terminal
class _Translations$help$groups$remote$terminal$zh extends Translations$help$groups$remote$terminal$en {
	_Translations$help$groups$remote$terminal$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '终端';
	@override String get body => '每个面板都有自己的内置终端，在你查看的文件夹中打开。\n\n- `Ctrl` + 反引号打开或聚焦终端。\n- `Ctrl+Shift` + 反引号显示或隐藏终端面板。\n- `Ctrl+Shift+T` 新建终端标签页；`Ctrl+Shift+W` 关闭一个。\n- `Ctrl++` / `Ctrl+-` 调整字号，`Ctrl+0` 重置。\n- 更喜欢外部终端？在 **设置 -> 终端** 中选择一个。';
}

// Path: help.groups.remote.git
class _Translations$help$groups$remote$git$zh extends Translations$help$groups$remote$git$en {
	_Translations$help$groups$remote$git$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Git 状态';
	@override String get body => 'MyExplorer 为版本控制下的文件夹显示 Git 信息。\n\n- 列表中标记已更改、已暂存和未跟踪的文件。\n- 显示文件夹的当前分支。\n- 在仓库中工作时状态实时更新。';
}

// Path: help.groups.customization.themes
class _Translations$help$groups$customization$themes$zh extends Translations$help$groups$customization$themes$en {
	_Translations$help$groups$customization$themes$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '主题与外观';
	@override String get body => '让 MyExplorer 看起来符合你的喜好。\n\n- 在 **设置 -> 外观** 中选择内置主题或添加自己的主题。\n- 选择列表、树或网格视图、行密度和列布局。\n- 配置日期格式、间距和显示哪些列。\n- 可开启可调整列宽进行精细控制。';
}

// Path: help.groups.customization.shortcuts
class _Translations$help$groups$customization$shortcuts$zh extends Translations$help$groups$customization$shortcuts$en {
	_Translations$help$groups$customization$shortcuts$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '键盘快捷键';
	@override String get body => '几乎所有操作都可以重新绑定为你选择的按键。\n\n- 打开 **设置 -> 键盘** 查看和编辑所有快捷键。\n- 冲突会被标记，两个操作不会争抢同一个按键。\n- 随时将单个绑定或全部绑定重置为默认值。';
}

// Path: help.groups.customization.plugins
class _Translations$help$groups$customization$plugins$zh extends Translations$help$groups$customization$plugins$en {
	_Translations$help$groups$customization$plugins$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '插件';
	@override String get body => '使用 Lua 编写的插件扩展 MyExplorer。\n\n- 插件通过原生核心运行，可以添加新操作。\n- 在 **设置 -> 插件** 中启用或禁用已安装的插件。\n- 查看项目文档中的插件编写指南，构建你自己的插件。';
}

// Path: help.groups.customization.shortcutBar
class _Translations$help$groups$customization$shortcutBar$zh extends Translations$help$groups$customization$shortcutBar$en {
	_Translations$help$groups$customization$shortcutBar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '快捷方式栏';
	@override String get body => '标题栏下方的快捷方式栏可一键启动文件夹、文件或命令，遵循 Total Commander 的惯例。\n\n- 右键按钮可编辑或删除；`+` 区域用于添加新按钮。\n- 按钮可以打开文件夹或文件、运行命令行，或使用 `CD <路径>` 跳转。\n- 支持内置命令，如 `cm_OpenDesktop`、`cm_OpenDrives` 和 `cm_OpenRecycled`。\n- 图标可来自文件（`icon.png`）、exe/dll（`app.exe,0`）或系统库中的索引（`shell32.dll,34`）。\n- 使用**导入 Total Commander 按钮栏...** 加载 `.bar` 文件（UTF-8 或 GBK）。\n- 留空条目可创建分隔符。';
}

// Path: help.groups.resources.links
class _Translations$help$groups$resources$links$zh extends Translations$help$groups$resources$links$en {
	_Translations$help$groups$resources$links$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '链接与资源';
	@override String get body => '更多关于 MyExplorer 的信息以及下一步。\n\n- **更新日志** - 每个版本的新内容（在菜单中）。\n- **键盘快捷键** - 完整参考位于 **设置 -> 键盘**。\n- **GitHub** - [源代码、问题和发布](https://github.com/MyExplorer/MyExplorer)。\n- **插件指南** - [如何编写自己的插件](https://github.com/MyExplorer/MyExplorer/blob/main/docs/plugins.md)。';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'MyExplorer',
			'app.tagline' => '随心浏览你的文件。',
			'app.description' => '一款基于 Flutter 构建的快速、键盘优先的桌面文件管理器。',
			'terminal.title' => '终端',
			'menu.view' => '视图',
			'menu.open' => '打开',
			'menu.openItems' => ({required Object count}) => '打开 ${count} 个项目',
			'menu.copy' => '复制',
			'menu.cut' => '剪切',
			'menu.paste' => '粘贴',
			'menu.duplicate' => '复制到此处（副本）',
			'menu.copyPath' => '复制路径',
			'menu.delete' => '删除',
			'menu.deleteItems' => ({required Object count}) => '删除 ${count} 个项目',
			'menu.moveToTrash' => '移入回收站',
			'menu.moveToTrashItems' => ({required Object count}) => '将 ${count} 个项目移入回收站',
			'menu.deletePermanently' => '永久删除',
			'menu.deletePermanentlyItems' => ({required Object count}) => '永久删除 ${count} 个项目',
			'menu.restore' => '还原',
			'menu.restoreItems' => ({required Object count}) => '还原 ${count} 个项目',
			'menu.showHidden' => '显示隐藏文件',
			'menu.hideSelected' => '加入隐藏列表',
			'menu.hiddenList' => '隐藏列表…',
			'menu.selectAll' => '全选',
			'menu.selectByPattern' => '按模式选择…',
			'menu.deselectAll' => '取消全选',
			'menu.invertSelection' => '反向选择',
			'menu.saveSelection' => '保存选择到文件…',
			'menu.loadSelection' => '从文件加载选择…',
			'menu.openInTerminal' => '在终端中打开',
			'menu.rename' => '重命名',
			'menu.openLocation' => '打开位置',
			'menu.openInNewTab' => '在新标签页中打开',
			'menu.removeBookmark' => '移除书签',
			'menu.addBookmark' => '添加到书签',
			'menu.eject' => '弹出',
			'menu.disconnect' => '断开连接',
			'menu.dualPaneMode' => '双栏模式',
			'menu.toggleTerminal' => '切换终端',
			'menu.newTerminalTab' => '新建终端标签页',
			'menu.closeTerminalTab' => '关闭终端标签页',
			'menu.properties' => '属性',
			'menu.openWith' => '打开方式',
			'menu.openWithApp' => ({required Object app}) => '使用 ${app} 打开',
			'menu.openWithChoose' => '其他应用…',
			'menu.extract' => '解压',
			'menu.extractHere' => '解压到此处',
			'menu.extractToFolder' => ({required Object name}) => '解压到 ${name}/',
			'menu.extractEach' => '逐个解压到独立文件夹',
			'menu.compress' => '压缩',
			'menu.compressTo' => ({required Object name}) => '压缩到 ${name}',
			'menu.compressOptions' => '添加到压缩包…',
			'menu.multiRename' => '批量重命名…',
			'menu.verifyChecksum' => '校验校验和…',
			'menu.verifyChecksumManifest' => '验证校验文件…',
			'menu.createChecksumManifest' => '生成校验文件…',
			'menu.splitFile' => '分割文件…',
			'menu.combineParts' => '合并分卷…',
			'menu.sortBy' => '排序方式',
			'menu.sortAscending' => '升序',
			'menu.sortDescending' => '降序',
			'menu.copyToOtherPane' => '复制到对面窗口',
			'menu.moveToOtherPane' => '移动到对面窗口',
			'menu.selectGroup' => '选一组',
			'menu.deselectGroup' => '不选一组',
			'multiRename.title' => '批量重命名',
			'multiRename.subtitle' => ({required Object count}) => '已选择 ${count} 个项目',
			'multiRename.modeTemplate' => '模板',
			'multiRename.modeFindReplace' => '查找与替换',
			'multiRename.namePattern' => '名称模式',
			'multiRename.tokens' => '令牌',
			'multiRename.tokenFilename' => '不含扩展名的原始名称',
			'multiRename.tokenExt' => '原始扩展名（含点）',
			'multiRename.tokenN' => '序号（从 1 开始）',
			'multiRename.tokenIndex' => '序号索引（从 0 开始）',
			'multiRename.tokenDate' => '今天的日期（YYYY-MM-DD）',
			'multiRename.find' => '查找',
			'multiRename.replaceWith' => '替换为',
			'multiRename.useRegex' => '正则表达式',
			'multiRename.caseSensitive' => '区分大小写',
			'multiRename.preview' => '预览',
			'multiRename.columnBefore' => '之前',
			'multiRename.columnAfter' => '之后',
			'multiRename.showOnlyChanged' => '仅显示更改项',
			'multiRename.changedOfTotal' => ({required Object changed, required Object total}) => '${changed} / ${total} 将被更改',
			'multiRename.errorCount' => ({required Object count}) => '${count} 个冲突',
			'multiRename.noChanges' => '没有文件会被重命名',
			'multiRename.cancel' => '取消',
			'multiRename.rename' => '重命名',
			'multiRename.renameCount' => ({required Object count}) => '重命名 ${count} 个文件',
			'multiRename.errorInvalid' => '无效名称',
			'multiRename.errorDuplicate' => '重名',
			'compress.title' => '添加到压缩包',
			'compress.archiveName' => '压缩包名称',
			'compress.format' => '格式',
			'compress.level' => '压缩级别',
			'compress.destination' => '目标位置',
			'compress.levelStore' => '仅存储（不压缩）',
			'compress.levelNormal' => '标准',
			'compress.levelMaximum' => '最大',
			'compress.create' => '创建',
			'compress.cancel' => '取消',
			'checksum.title' => '校验校验和',
			'checksum.md5' => 'MD5',
			'checksum.sha256' => 'SHA-256',
			'checksum.expected' => '期望的校验和',
			'checksum.expectedHint' => ({required Object algorithm}) => '${algorithm} 摘要',
			'checksum.verify' => '校验',
			'checksum.calculating' => '正在计算…',
			'checksum.match' => '校验和匹配',
			'checksum.mismatch' => '校验和不匹配',
			'checksum.copy' => '复制',
			'checksum.copied' => '已复制',
			'checksum.invalidExpected' => ({required Object algorithm, required Object length}) => '${algorithm} 校验和必须为 ${length} 位十六进制字符',
			'checksum.readError' => '无法读取文件',
			'checksum.createManifest' => '生成校验文件',
			'checksum.createManifestFiles' => ({required Object count}) => '将为 ${count} 个文件生成校验文件',
			'checksum.create' => '生成',
			'checksum.verifyManifest' => '验证校验文件',
			'checksum.verifySummary' => ({required Object ok, required Object total}) => '${ok} 个文件验证通过，共 ${total} 个',
			'checksum.manifestEmpty' => '校验文件中没有有效条目',
			'compare.toolbarTooltip' => '比较文件夹',
			'compare.unique' => '仅在此处',
			'compare.newer' => '较新',
			'compare.older' => '较旧',
			'compare.differ' => '不同',
			'compare.identical' => '相同',
			'compare.syncRight' => '同步 →',
			'compare.syncLeft' => '← 同步',
			'compare.recursive' => '递归',
			'compare.done' => '完成',
			'compare.running' => '正在比较…',
			'compare.counts' => ({required Object identical, required Object differ, required Object uniqueLeft, required Object uniqueRight}) => '${identical} 个相同 · ${differ} 个不同 · ${uniqueLeft} 个仅在左侧 · ${uniqueRight} 个仅在右侧',
			'properties.title' => '属性',
			'properties.name' => '名称',
			'properties.type' => '类型',
			'properties.location' => '位置',
			'properties.size' => '大小',
			'properties.modified' => '修改时间',
			'properties.accessed' => '访问时间',
			'properties.changed' => '更改时间',
			'properties.permissions' => '权限',
			'properties.contains' => '包含',
			'properties.typeFolder' => '文件夹',
			'properties.typeFile' => '文件',
			'properties.sizeDetail' => ({required Object formatted, required Object count}) => '${formatted}（${count} 字节）',
			'properties.containsItems' => ({required Object count}) => '${count} 个项目',
			'properties.calculating' => '正在计算…',
			'properties.close' => '关闭',
			'preferences.title' => '设置',
			'preferences.menuLabel' => '设置…',
			'preferences.close' => '关闭',
			'preferences.searchPlaceholder' => '搜索设置…',
			'preferences.searchNoResults' => '未找到设置',
			'preferences.comingSoon' => '即将推出',
			'preferences.categories.general' => '常规',
			'preferences.categories.appearance' => '外观',
			'preferences.categories.terminal' => '终端',
			'preferences.categories.quickLook' => '快速预览',
			'preferences.categories.bookmarks' => '书签',
			'preferences.categories.plugins' => '插件',
			'preferences.categories.diagnostics' => '诊断',
			'preferences.categories.about' => '关于',
			'preferences.plugins.title' => '插件',
			'preferences.plugins.subtitle' => '使用 Lua 插件扩展 Waydir。每个插件是一个包含 manifest.json 和 init.lua 的文件夹。',
			'preferences.plugins.installedSection' => '已安装',
			'preferences.plugins.openFolder' => '打开插件文件夹',
			'preferences.plugins.reload' => '重新加载',
			'preferences.plugins.empty' => '尚未安装插件。',
			'preferences.plugins.disabled' => '已禁用',
			'preferences.plugins.loadError' => ({required Object message}) => '加载错误：${message}',
			'preferences.plugins.actionsCount' => ({required Object count}) => '${count} 个操作',
			'preferences.plugins.reloaded' => ({required Object count}) => '已重新加载 ${count} 个插件',
			'preferences.plugins.taskRunning' => '正在运行…',
			'preferences.plugins.taskDone' => '完成',
			'preferences.plugins.taskFailed' => ({required Object code}) => '失败（退出码 ${code}）',
			'preferences.plugins.taskFailedError' => ({required Object error}) => '失败：${error}',
			'preferences.plugins.actionFailed' => '插件操作失败',
			'preferences.plugins.taskTimeout' => '超时',
			'preferences.plugins.enable' => '启用',
			'preferences.plugins.disable' => '禁用',
			'preferences.plugins.configure' => '配置',
			'preferences.plugins.configureTitle' => ({required Object name}) => '${name} 设置',
			'preferences.plugins.noSettings' => '此插件没有设置。',
			'preferences.plugins.shortcutPrefix' => ({required Object name}) => '插件：${name}',
			'preferences.general.title' => '常规',
			'preferences.general.subtitle' => '启动、文件操作和终端集成。',
			'preferences.general.startupSection' => '启动',
			'preferences.general.restoreSession' => '恢复上次会话',
			'preferences.general.restoreSessionHint' => '启动时重新打开上次的标签页和面板。',
			'preferences.general.defaultPath' => '默认起始路径',
			'preferences.general.defaultPathHint' => '当会话恢复被禁用或为空时使用。',
			'preferences.general.defaultPathPlaceholder' => 'C:/Users/user',
			'preferences.general.browse' => '浏览…',
			'preferences.general.foldersSection' => '文件夹',
			'preferences.general.fileOpsSection' => '文件操作',
			'preferences.general.confirmDelete' => '删除前确认',
			'preferences.general.confirmDeleteHint' => '删除文件或文件夹前显示对话框。',
			'preferences.general.confirmCopy' => '复制前确认',
			'preferences.general.confirmCopyHint' => '复制文件或文件夹前显示对话框。',
			'preferences.general.confirmMove' => '移动前确认',
			'preferences.general.confirmMoveHint' => '移动文件或文件夹前显示对话框。',
			'preferences.general.autoOverwriteOlder' => '自动覆盖较旧文件',
			'preferences.general.autoOverwriteOlderHint' => '复制时若源文件较新则自动覆盖已存在的文件；若较旧则跳过。',
			'preferences.general.autoSkipSameSize' => '自动跳过大小相同的文件',
			'preferences.general.autoSkipSameSizeHint' => '复制时若目标文件与源文件大小相同则自动跳过。',
			'preferences.general.dragMovesByDefault' => '拖拽时移动而非复制文件',
			'preferences.general.dragMovesByDefaultHint' => '开启时，拖拽文件为移动，按住 Alt 为复制。关闭时，拖拽为复制，按住 Alt 为移动。',
			'preferences.general.rememberFolderState' => '记住每个文件夹的选择状态',
			'preferences.general.rememberFolderStateHint' => '返回文件夹时恢复光标位置和已选文件。',
			'preferences.general.rememberFolderSort' => '记住每个文件夹的排序',
			'preferences.general.rememberFolderSortHint' => '为每个文件夹保存并复用排序列和方向。',
			'preferences.general.typeAheadBuffer' => '键入跳转多字符缓冲',
			'preferences.general.typeAheadBufferHint' => '快速键入的字母会组合成搜索字符串以跳转到匹配项；暂停会重置。关闭时，每个字母循环匹配以该字母开头的项目。',
			'preferences.general.deleteKeyBehavior' => 'Delete 键行为',
			'preferences.general.deleteKeyBehaviorHint' => 'Delete 键的默认行为。Shift+Delete 始终执行永久删除。',
			'preferences.general.deleteKeyTrash' => '移入回收站',
			'preferences.general.deleteKeyPermanent' => '永久删除',
			'preferences.general.terminalSection' => '终端',
			'preferences.general.terminalLabel' => '默认终端',
			'preferences.general.terminalHint' => '用于“在终端中打开”。',
			'preferences.general.terminalBuiltin' => '内置终端',
			'preferences.general.terminalAuto' => '外部（自动检测）',
			'preferences.general.terminalCustom' => '自定义命令…',
			'preferences.general.terminalCustomLabel' => '命令',
			'preferences.general.terminalCustomHint' => '例如 wt -d {dir}',
			'preferences.general.terminalCustomHelp' => '使用 {dir} 作为目录路径的占位符。',
			'preferences.terminal.title' => '终端',
			'preferences.terminal.subtitle' => '内置终端字体和外部终端集成。',
			'preferences.terminal.appearanceSection' => '外观',
			'preferences.terminal.useSystemFont' => '使用系统字体',
			'preferences.terminal.useSystemFontHint' => '使用系统等宽字体渲染终端。',
			'preferences.terminal.fontFamily' => '字体',
			'preferences.terminal.fontFamilyHint' => '选择已安装的等宽字体。',
			'preferences.terminal.fontSize' => '字号',
			'preferences.terminal.fontSizeHint' => '使用 Ctrl++、Ctrl+- 和 Ctrl+0 即时调整。',
			'preferences.terminal.lineHeight' => '行高',
			'preferences.terminal.lineHeightHint' => '终端行之间的垂直间距。',
			'preferences.terminal.shellSection' => 'Shell',
			'preferences.terminal.shellLabel' => 'Shell',
			'preferences.terminal.shellHint' => '内置终端启动的程序。',
			'preferences.terminal.shellSystem' => '系统默认',
			'preferences.terminal.externalSection' => '在终端中打开',
			'preferences.terminal.behaviorSection' => '行为',
			'preferences.terminal.copyPasteMode' => '复制/粘贴修饰键',
			'preferences.terminal.copyPasteModeHint' => '终端中复制和粘贴使用的组合键。',
			'preferences.terminal.copyPasteModeStandard' => '标准（Ctrl+C / Ctrl+V）',
			'preferences.terminal.copyPasteModeShift' => '加 Shift（Ctrl+Shift+C / Ctrl+Shift+V）',
			'preferences.quickLook.title' => '快速预览',
			'preferences.quickLook.subtitle' => '快速预览中的编辑器字体、行号和模态编辑。',
			'preferences.quickLook.fontSection' => '编辑器字体',
			'preferences.quickLook.editorSection' => '编辑器',
			'preferences.quickLook.useSystemFont' => '使用系统字体',
			'preferences.quickLook.useSystemFontHint' => '使用系统等宽字体渲染编辑器。',
			'preferences.quickLook.fontFamily' => '字体',
			'preferences.quickLook.fontFamilyHint' => '选择已安装的等宽字体。',
			'preferences.quickLook.fontSize' => '字号',
			'preferences.quickLook.fontSizeHint' => '快速预览编辑器中的文本大小。',
			'preferences.quickLook.lineHeight' => '行高',
			'preferences.quickLook.lineHeightHint' => '编辑器行之间的垂直间距。',
			'preferences.quickLook.showLineNumbers' => '显示行号',
			'preferences.quickLook.showLineNumbersHint' => '在编辑器中显示行号栏。',
			'preferences.quickLook.relativeLineNumbers' => '相对行号',
			'preferences.quickLook.relativeLineNumbersHint' => '显示与当前行的距离而非绝对行号。',
			'preferences.quickLook.wrapLines' => '自动换行',
			'preferences.quickLook.wrapLinesHint' => '长行自动换行而不是水平滚动。',
			'preferences.quickLook.vimMode' => 'Vim 模式',
			'preferences.quickLook.vimModeHint' => '基础模态编辑：移动、插入和简单编辑。',
			'preferences.quickLook.showStatistics' => '显示统计',
			'preferences.quickLook.showStatisticsHint' => '检查多个项目时计算大小和类型分布。',
			'preferences.appearance.title' => '外观',
			'preferences.appearance.subtitle' => '文件和侧边栏的显示默认值。',
			'preferences.appearance.themeSection' => '主题',
			'preferences.appearance.theme' => '主题',
			'preferences.appearance.themeHint' => '选择内置或自定义主题。',
			'preferences.appearance.themeDark' => '深色',
			'preferences.appearance.themeLight' => '浅色',
			'preferences.appearance.themeNord' => 'Nord',
			'preferences.appearance.customThemes' => '自定义主题',
			'preferences.appearance.customThemesHint' => '将主题 JSON 文件放入此文件夹。切换主题时加载更改。',
			'preferences.appearance.addTheme' => '添加主题',
			'preferences.appearance.addThemeTitle' => '新建自定义主题',
			'preferences.appearance.addThemeNameHint' => '主题名称',
			'preferences.appearance.addThemeCreate' => '创建',
			'preferences.appearance.addThemeCancel' => '取消',
			'preferences.appearance.editTheme' => '编辑',
			'preferences.appearance.deleteTheme' => '删除',
			'preferences.appearance.deleteThemeTitle' => '删除主题？',
			'preferences.appearance.deleteThemeMessage' => ({required Object name}) => '删除“${name}”？此操作无法撤销。',
			'preferences.appearance.loadingThemes' => '正在加载主题…',
			'preferences.appearance.noCustomThemes' => '暂无自定义主题。',
			'preferences.appearance.invalidTheme' => '无效的主题 JSON',
			'preferences.appearance.themeFileMustContainJsonObject' => '主题文件必须包含一个 JSON 对象',
			'preferences.appearance.missingThemeId' => '缺少主题 id',
			'preferences.appearance.missingThemeName' => '缺少主题名称',
			'preferences.appearance.missingThemeBrightness' => '缺少主题亮度',
			'preferences.appearance.missingThemePalette' => '缺少主题调色板',
			'preferences.appearance.invalidThemeBrightness' => '无效的主题亮度',
			'preferences.appearance.missingColor' => ({required Object key}) => '缺少颜色“${key}”',
			'preferences.appearance.invalidColor' => ({required Object key}) => '无效的颜色“${key}”',
			'preferences.appearance.couldNotLoadCustomThemes' => '无法加载自定义主题',
			'preferences.appearance.unknownThemeUsingDefault' => ({required Object id, required Object theme}) => '未知主题“${id}”，使用 ${theme}',
			'preferences.appearance.skippingDuplicateTheme' => ({required Object id, required Object path}) => '跳过主题“${id}”（来自 ${path}）：id 重复',
			'preferences.appearance.skippingThemeFile' => ({required Object path}) => '跳过主题文件 ${path}',
			'preferences.appearance.filesSection' => '文件',
			'preferences.appearance.showHidden' => '默认显示隐藏文件',
			'preferences.appearance.showHiddenHint' => '仅适用于新标签页。现有标签页保持原设置。',
			'preferences.appearance.rowDensity' => '行密度',
			'preferences.appearance.rowDensityComfortable' => '舒适',
			'preferences.appearance.rowDensityCompact' => '紧凑',
			'preferences.appearance.fileListHorizontalSpacing' => '水平间距',
			'preferences.appearance.columnWidthMode' => '列表列宽',
			'preferences.appearance.columnWidthModeAutomatic' => '自动列宽',
			'preferences.appearance.columnWidthModeResizable' => '可调整列宽',
			'preferences.appearance.fileListVerticalSpacing' => '垂直间距',
			'preferences.appearance.dateFormat' => '日期格式',
			'preferences.appearance.dateFormatIso' => 'ISO（2026-05-14 13:45）',
			'preferences.appearance.dateFormatLocale' => '系统区域',
			'preferences.appearance.dateFormatRelative' => '相对（2 小时前）',
			'preferences.appearance.recentDatesRelative' => '近期文件使用相对日期',
			'preferences.appearance.recentDatesRelativeHint' => '选择“系统区域”时，最近 24 小时内修改的文件显示为相对时间。',
			'preferences.appearance.foldersFirst' => '文件夹优先显示',
			'preferences.appearance.foldersFirstHint' => '无论排序方式如何，文件夹都排在文件前面。',
			'preferences.appearance.sortFolders' => '文件夹也参与排序',
			'preferences.appearance.sortFoldersHint' => '关闭时，仅文件参与排序，文件夹保持默认名称顺序。',
			'preferences.appearance.naturalSort' => '自然排序',
			'preferences.appearance.naturalSortHint' => '按数值对名称中的数字排序，使“file2”排在“file10”之前。',
			'preferences.appearance.sortKey' => '文件排序依据',
			'preferences.appearance.sortKeyName' => '名称',
			'preferences.appearance.sortKeySize' => '大小',
			'preferences.appearance.sortKeyDate' => '修改日期',
			'preferences.appearance.sortDirection' => '排序方向',
			'preferences.appearance.sortAscending' => '升序',
			'preferences.appearance.sortDescending' => '降序',
			'preferences.appearance.sidebarSection' => '侧边栏',
			'preferences.appearance.sidebarCollapsed' => '默认折叠',
			'preferences.bookmarks.title' => '书签',
			'preferences.bookmarks.subtitle' => '管理固定到侧边栏的文件夹。',
			'preferences.bookmarks.empty' => '暂无书签。将文件夹拖到侧边栏即可添加。',
			'preferences.bookmarks.rename' => '重命名',
			'preferences.bookmarks.remove' => '移除',
			'preferences.shortcutBar.title' => '快捷栏',
			'preferences.shortcutBar.labelHint' => '名称',
			'preferences.shortcutBar.targetHint' => '文件夹、文件路径或命令',
			'preferences.shortcutBar.iconHint' => '图标：文件路径或 路径,索引',
			'preferences.shortcutBar.pickFile' => '文件',
			'preferences.shortcutBar.add' => '添加',
			'preferences.shortcutBar.importTcBar' => '导入 Total Commander 按钮栏…',
			'preferences.shortcutBar.imported' => ({required Object count}) => '已导入 ${count} 个按钮',
			'preferences.shortcutBar.importFailed' => '导入按钮栏失败',
			'preferences.diagnostics.title' => '诊断',
			'preferences.diagnostics.subtitle' => '最近的警告和错误。日志会写入磁盘用于错误报告。',
			'preferences.diagnostics.empty' => '本次会话没有记录警告或错误。',
			'preferences.diagnostics.search' => '筛选日志…',
			'preferences.diagnostics.export' => '导出当前日志',
			'preferences.diagnostics.copy' => '复制可见内容',
			'preferences.diagnostics.clear' => '清除',
			'preferences.diagnostics.copied' => '已复制到剪贴板',
			'preferences.diagnostics.privacyNote' => '日志可能包含文件路径。分享前请检查。',
			'preferences.diagnostics.native' => '原生',
			'preferences.diagnostics.unavailable' => '不可用',
			'preferences.about.title' => '关于',
			'preferences.about.version' => '版本',
			'preferences.about.build' => '构建',
			'preferences.about.repository' => '仓库',
			'preferences.about.license' => '许可证',
			'preferences.about.copy' => '复制',
			'update.title' => '更新',
			'update.available' => '有可用更新',
			'update.downloading' => '正在下载更新',
			'update.ready' => '准备安装',
			'update.launching' => '正在启动安装程序...',
			'update.error' => '更新错误',
			'update.checking' => '正在检查更新...',
			'update.unknownError' => '未知错误',
			'update.upToDate' => ({required Object version}) => '你已是最新版本（v${version}）。',
			'update.noRelease' => '没有发布信息。',
			'update.noMatch' => '此平台没有匹配的下载。',
			'update.noNotes' => '未提供发布说明。',
			'update.versionLabel' => ({required Object version}) => 'v${version}',
			'update.titleWithVersion' => ({required Object title, required Object version}) => '${title} - v${version}',
			'update.tooltipAvailable' => ({required Object version}) => '有可用更新 - v${version}',
			'update.tooltipUpToDate' => '已是最新',
			'update.checkForUpdates' => '检查更新',
			'update.releasePage' => '发布页面',
			'update.downloaded' => '已下载',
			'update.btnDownload' => '下载',
			'update.btnGetUpdate' => '获取更新',
			'update.appImageManual' => 'AppImage 不会自我更新。请下载新版本并替换此文件。',
			'update.btnDownloading' => '正在下载...',
			'update.btnCheckNow' => '立即检查',
			'update.btnRetry' => '重试',
			'update.btnInstall' => '安装',
			'update.btnUpdate' => '更新',
			'update.btnOpenDmg' => '打开 DMG',
			'update.statusCheckingInline' => '检查中...',
			'update.statusUpToDateInline' => '已是最新',
			'update.formatInstaller' => '安装程序',
			'update.formatPortable' => '便携版',
			'update.formatUnknown' => '未知',
			'update.downloadFailed' => ({required Object statusCode}) => '下载失败：HTTP ${statusCode}',
			'update.githubApiError' => ({required Object statusCode, required Object reason}) => 'GitHub API ${statusCode}：${reason}',
			'update.missingChecksum' => ({required Object asset}) => '更新资源 ${asset} 未提供有效的 SHA-256 校验和。',
			'update.checksumMismatch' => ({required Object asset}) => '更新资源 ${asset} 未通过 SHA-256 校验。',
			'update.bundleNotWritable' => '无法写入程序目录。请手动安装新版本。',
			'update.installerLaunchFailed' => ({required Object error}) => '启动安装程序失败：${error}',
			'appMenu.help' => '帮助',
			'appMenu.managePlugins' => '管理插件',
			'appMenu.changelog' => '更新日志',
			'appMenu.repository' => '仓库',
			'appMenu.createIssue' => '报告问题',
			'appMenu.starOnGithub' => '在 GitHub 上点赞',
			'appMenu.quit' => '退出',
			'changelog.title' => '更新日志',
			'changelog.loadError' => '无法加载更新日志。',
			'help.title' => '应用内教程',
			'help.menuLabel' => '应用内教程',
			'help.groups.gettingStarted.title' => '快速上手',
			'help.groups.gettingStarted.welcome.title' => '欢迎使用 MyExplorer',
			'help.groups.gettingStarted.welcome.body' => 'MyExplorer 是一款快速、键盘驱动的文件管理器。本指南将带你了解从基本导航到远程服务器、终端和自定义的方方面面。\n\n- 使用左侧的树在主题之间跳转。\n- 大多数操作都有快捷键，以 `Ctrl+C` 的形式内联显示。\n- 所有快捷键都可以在 **设置 -> 键盘** 中重新绑定。\n\n选择一个主题开始，或从头到尾通读。',
			'help.groups.gettingStarted.interface.title' => '界面',
			'help.groups.gettingStarted.interface.body' => '窗口由几个简单的部分构成。\n\n- **侧边栏** - 书签、驱动器和远程位置。使用 `Ctrl+B` 切换。\n- **标签栏** - 每个打开的文件夹一个标签。\n- **面包屑栏** - 当前路径；点击任意片段即可跳转。\n- **文件列表** - 主视图，支持列表、树或网格模式。\n- **状态栏** - 项目数量、选中大小和操作进度。',
			'help.groups.gettingStarted.keyboardBasics.title' => '键盘优先基础',
			'help.groups.gettingStarted.keyboardBasics.body' => 'MyExplorer 设计为完全通过键盘驱动。\n\n- `↑` / `↓` 移动光标；`Enter` 打开；`Backspace` 返回上级。\n- 直接输入字符可跳转到匹配文件（键入跳转）。\n- `Ctrl+F` 搜索，`Space` 预览，`F2` 重命名。\n- 几乎所有操作都不需要鼠标 - 而且每个按键绑定都可以自定义。',
			'help.groups.navigating.title' => '导航',
			'help.groups.navigating.moving.title' => '四处移动',
			'help.groups.navigating.moving.body' => '无需鼠标即可浏览。MyExplorer 将光标、选择和历史记录保持在主文件列表附近。\n\n- `↑` / `↓` 在可见文件中移动光标。\n- `Enter` 打开选中项；双击效果相同。\n- `Backspace` 返回上级文件夹。\n- `Alt+←` / `Alt+→` 在文件夹历史中后退和前进。\n- `Ctrl+R` 刷新当前文件夹。',
			'help.groups.navigating.breadcrumb.title' => '面包屑栏',
			'help.groups.navigating.breadcrumb.body' => '面包屑栏显示你所在的位置，让你快速移动。\n\n- 点击任意片段直接跳转到该文件夹。\n- 导航时路径保持同步。\n- 直接输入路径可前往特定位置。',
			'help.groups.navigating.bookmarks.title' => '书签与侧边栏',
			'help.groups.navigating.bookmarks.body' => '侧边栏让你最常用的文件夹一键可达。\n\n- 将文件夹拖入侧边栏即可添加书签。\n- 根据需要重新排序、重命名或隐藏侧边栏条目。\n- `Ctrl+B` 完全显示或隐藏侧边栏。\n- 分区（收藏、设备、网络）可以独立折叠。',
			'help.groups.navigating.drives.title' => '驱动器与设备',
			'help.groups.navigating.drives.body' => '已挂载的驱动器和可移动设备显示在侧边栏的“设备”下。\n\n- 点击设备即可打开。\n- 从右键菜单弹出可移动设备。\n- 网络共享和远程挂载与本地驱动器并列显示。',
			'help.groups.navigating.typeAhead.title' => '键入跳转',
			'help.groups.navigating.typeAhead.body' => '文件列表获得焦点时直接输入，即可跳转到匹配的名称。\n\n- 匹配是增量的 - 继续输入以精确定位。\n- 输入时光标移动到第一个匹配项。\n- 可以在 **设置 -> 常规** 中关闭键入跳转。',
			'help.groups.tabsPanes.title' => '标签页与面板',
			'help.groups.tabsPanes.tabs.title' => '标签页',
			'help.groups.tabsPanes.tabs.body' => '同时打开多个文件夹并即时切换。每个标签记住自己的文件夹、选择和历史。\n\n- `Ctrl+T` 新建标签页。\n- `Ctrl+W` 关闭当前标签页。\n- `Ctrl+Tab` / `Ctrl+Shift+Tab` 切换到下一个或上一个标签页。\n- `Ctrl+1`…`Ctrl+9` 按位置直接跳转到标签页。\n- 标签栏上的 `+` 按钮在当前文件夹中新建标签页。',
			'help.groups.tabsPanes.dualPane.title' => '双栏模式',
			'help.groups.tabsPanes.dualPane.body' => '并排显示源和目标。活动面板拥有键盘焦点，复制/移动快捷键作用于对面面板。\n\n- `F9`（或 `Ctrl+D`）切换双栏模式。\n- `Tab` 切换活动面板。\n- `F5` 将选中文件复制到另一面板。\n- `F6` 将选中文件移动到另一面板。\n- 拖动分隔条调整空间分配。',
			'help.groups.tabsPanes.compare.title' => '文件夹比较与同步',
			'help.groups.tabsPanes.compare.body' => '在双栏模式下比较两个面板以查看差异，然后将一侧同步到另一侧。\n\n- 双栏模式激活时 `F8` 开启比较。\n- 行会着色：仅在此处、较新、较旧或相同。\n- 切换 **递归** 以比较嵌套文件夹或仅比较顶层。\n- `Ctrl+→` / `Ctrl+←` 将差异从左到右或从右到左同步。\n- 导航离开比较的文件夹时比较会自动关闭。`Esc` 退出。',
			'help.groups.selecting.title' => '选择',
			'help.groups.selecting.basics.title' => '选择基础',
			'help.groups.selecting.basics.body' => '在操作前精确构建你想要的文件集合。\n\n- `Ctrl+A` 全选文件夹中的内容。\n- `Insert` 切换当前项目并向下移动。\n- `Esc` 清除选择。\n- 点击、`Shift+点击` 选择范围，`Ctrl+点击` 添加或移除单个项目。\n- `Ctrl+Shift+S` 将当前选择保存到文件；`Ctrl+Shift+L` 加载回来。',
			'help.groups.selecting.pattern.title' => '按模式选择',
			'help.groups.selecting.pattern.body' => '使用通配符模式选择文件，而不是手动挑选。\n\n- `Ctrl+S` 打开按模式选择。\n- 使用 `*.png` 或 `report-*.pdf` 之类的通配符。\n- 匹配的集合会添加到当前选择中。',
			'help.groups.files.title' => '处理文件',
			'help.groups.files.operations.title' => '复制、移动与删除',
			'help.groups.files.operations.body' => '标准的剪贴板和文件操作处处可用，包括跨面板和跨标签页。\n\n- `Ctrl+C` / `Ctrl+X` / `Ctrl+V` 复制、剪切和粘贴。\n- `F2` 重命名当前项目；`F7` 新建文件夹。\n- `Delete` 将选择移入回收站；使用右键菜单可永久删除。\n- 大型复制、移动和删除在后台运行，名称冲突时会出现冲突提示。',
			'help.groups.files.dragDrop.title' => '拖放',
			'help.groups.files.dragDrop.body' => '在面板、标签页和侧边栏之间拖放文件 - 或拖入/拖出其他应用。\n\n- 默认拖拽 **复制** 文件；按住 `Alt` **移动**。\n- 在 **设置 -> 常规** 中翻转默认行为，使拖拽移动、`Alt` 复制。\n- 拖拽提示显示本次放下将复制还是移动。\n- 放到文件夹上可将文件放入其中，放到空白区域则放入当前文件夹。',
			'help.groups.files.multiRename.title' => '批量重命名',
			'help.groups.files.multiRename.body' => '通过实时前后预览一次重命名多个文件。选择多个项目，然后从右键菜单中选择 **批量重命名**。\n\n- **模板** 模式使用令牌构建名称：`{name}`、`{ext}`、`{n}`（从 1 开始）、`{index}`（从 0 开始）和 `{date}`。\n- **查找与替换** 模式交换文本，支持可选的正则表达式和大小写敏感。\n- 预览会在提交前列出每个结果，*仅显示更改* 隐藏未修改的行。',
			'help.groups.files.archives.title' => '压缩包',
			'help.groups.files.archives.body' => '压缩包像可浏览的文件夹一样工作，可以在解压前查看内容。\n\n- `Enter` 打开支持的压缩包并浏览其内容。\n- 右键菜单可以解压到此处、解压到命名文件夹，或逐个解压每个压缩包。\n- **压缩** 从选择构建新压缩包 - 选择格式和压缩级别。\n- 解压和压缩在后台运行，文件列表保持响应。',
			'help.groups.files.openWith.title' => '打开方式与默认应用',
			'help.groups.files.openWith.body' => '在任何已安装的应用中打开文件，而不只是系统默认应用。\n\n- 右键菜单中的 **打开方式** 列出可用应用。\n- 为每种文件类型设置默认应用，以后直接打开。\n- 最近使用的应用显示在顶部，方便快速访问。',
			'help.groups.files.tags.title' => '颜色标签',
			'help.groups.files.tags.body' => '用彩色标签标记文件和文件夹，方便快速找到它们。开箱即用提供三个标签 - **红**、**绿** 和 **蓝**。\n\n- 从右键菜单的 **标签** 子菜单分配或移除标签，或将文件拖到侧边栏的标签上。\n- 标记的项目在文件列表中显示彩色圆点，一个项目可以带多个标签。\n- 每个标签显示在侧边栏的 **标签** 分区中；点击即可列出所有带该标签的文件，无论它们在哪里。\n- 在标签视图中，使用右键菜单的 **打开位置** 跳转到文件的真实文件夹。\n- 右键点击侧边栏中的标签可重命名、更改颜色或删除；删除标签会从所有文件中移除。\n- 标签仅适用于本地文件 - 不适用于 SFTP、网络共享或压缩包内的项目。',
			'help.groups.files.hiddenList.title' => '隐藏列表',
			'help.groups.files.hiddenList.body' => '无需改动文件本身，即可从所有列表视图中隐藏选中的文件和文件夹。\n\n- 选中一个或多个项目，右键并选择**加入隐藏列表**。\n- 隐藏的项目会从文件列表、树形视图、侧边栏和最近访问中消失。\n- 条目存储在可执行文件旁的 `隐藏文件.ini` 中。\n- 要重新显示某个项目，请打开**视图 -> 隐藏列表...** 并删除其条目。\n- 隐藏文件夹只隐藏该文件夹本身；打开它时其内容仍然可见。',
			'help.groups.previewing.title' => '预览',
			'help.groups.previewing.quickLook.title' => '快速预览',
			'help.groups.previewing.quickLook.body' => '无需打开其他应用即可检查文件。快速预览支持图片、文本、代码、Markdown 和其他类型。\n\n- `Space` 为当前选择打开快速预览。\n- `↑` / `↓` 在不离开预览的情况下切换到上一个或下一个文件。\n- `Esc` 关闭预览。\n- 信息面板显示大小、日期和权限。',
			'help.groups.previewing.editor.title' => '快速预览编辑器',
			'help.groups.previewing.editor.body' => '文本和代码预览可以直接编辑。\n\n- `Ctrl+S` 保存更改而不离开预览。\n- 切换行号、相对行号和自动换行。\n- 启用 **Vim 模式** 进行模态编辑。\n- Markdown 文件可以渲染格式或显示原始源码。\n- 所有编辑器选项位于 **设置 -> 快速预览**。',
			'help.groups.searching.title' => '搜索',
			'help.groups.searching.folder.title' => '在文件夹中搜索',
			'help.groups.searching.folder.body' => '筛选当前文件夹或扫描其下的所有内容。\n\n- `Ctrl+F` 输入时按名称筛选当前文件夹。\n- `Ctrl+Shift+F` 将搜索扩展到所有子文件夹。\n- 打开 **内容** 可在文件内容中搜索（仅限本地文件夹 - 不支持 SFTP）。\n- 在 **子串**、**通配符** 和 **正则** 匹配之间切换。\n- `Esc` 关闭搜索并恢复完整列表。',
			'help.groups.searching.function.title' => '功能与命令搜索',
			'help.groups.searching.function.body' => '无需在菜单中翻找即可查找并运行任何 MyExplorer 操作。\n\n- 打开命令搜索并输入操作名称。\n- 结果显示匹配的命令及其当前快捷键。\n- 直接从列表中运行 - 适合不常用的操作。',
			'help.groups.commandPalette.title' => '命令面板',
			'help.groups.commandPalette.basics.title' => '运行命令',
			'help.groups.commandPalette.basics.body' => '命令面板是无需离开键盘触发操作的最快方式。\n\n- 按 `Ctrl+P` 打开。\n- 输入操作、设置、书签、驱动器、最近路径或插件命令。\n- 结果包含已分配的快捷键。\n- 不适用的操作以弱化状态保持可见。\n- 按 `Enter` 运行高亮命令，或按 `Esc` 关闭面板。',
			'help.groups.commandPalette.files.title' => '从面板查找文件',
			'help.groups.commandPalette.files.body' => '面板还可以作为当前文件夹的快速文件跳转器。\n\n- 输入文件或文件夹名称匹配可见项目。\n- 继续输入片刻，MyExplorer 也会搜索子文件夹。\n- 递归文件匹配会显示其所在文件夹作为副标题。\n- 选择文件或文件夹会在当前面板中聚焦它，以便打开、预览或操作。',
			'help.groups.remote.title' => '远程与集成',
			'help.groups.remote.sftp.title' => 'SFTP 与远程服务器',
			'help.groups.remote.sftp.body' => '直接在本地文件夹旁边使用 SFTP 服务器。\n\n- 从侧边栏使用 **连接到服务器** 添加远程位置。\n- 连接后，浏览远程文件夹与本地完全相同。\n- 常访问的文件夹添加书签，一键可达。\n- 选择、右键菜单和文件操作与本地一致 - 只有内容搜索在 SFTP 上不可用。',
			'help.groups.remote.network.title' => '网络路径与 WSL',
			'help.groups.remote.network.body' => 'MyExplorer 处理网络共享和适用于 Linux 的 Windows 子系统路径。\n\n- 像本地文件夹一样浏览已挂载的 SMB / 网络共享。\n- 在 Windows 上，WSL 发行版路径可被识别和打开。\n- 网络位置受到保护，慢速共享不会冻结界面。',
			'help.groups.remote.terminal.title' => '终端',
			'help.groups.remote.terminal.body' => '每个面板都有自己的内置终端，在你查看的文件夹中打开。\n\n- `Ctrl` + 反引号打开或聚焦终端。\n- `Ctrl+Shift` + 反引号显示或隐藏终端面板。\n- `Ctrl+Shift+T` 新建终端标签页；`Ctrl+Shift+W` 关闭一个。\n- `Ctrl++` / `Ctrl+-` 调整字号，`Ctrl+0` 重置。\n- 更喜欢外部终端？在 **设置 -> 终端** 中选择一个。',
			'help.groups.remote.git.title' => 'Git 状态',
			'help.groups.remote.git.body' => 'MyExplorer 为版本控制下的文件夹显示 Git 信息。\n\n- 列表中标记已更改、已暂存和未跟踪的文件。\n- 显示文件夹的当前分支。\n- 在仓库中工作时状态实时更新。',
			'help.groups.customization.title' => '自定义',
			'help.groups.customization.themes.title' => '主题与外观',
			'help.groups.customization.themes.body' => '让 MyExplorer 看起来符合你的喜好。\n\n- 在 **设置 -> 外观** 中选择内置主题或添加自己的主题。\n- 选择列表、树或网格视图、行密度和列布局。\n- 配置日期格式、间距和显示哪些列。\n- 可开启可调整列宽进行精细控制。',
			'help.groups.customization.shortcuts.title' => '键盘快捷键',
			'help.groups.customization.shortcuts.body' => '几乎所有操作都可以重新绑定为你选择的按键。\n\n- 打开 **设置 -> 键盘** 查看和编辑所有快捷键。\n- 冲突会被标记，两个操作不会争抢同一个按键。\n- 随时将单个绑定或全部绑定重置为默认值。',
			'help.groups.customization.plugins.title' => '插件',
			'help.groups.customization.plugins.body' => '使用 Lua 编写的插件扩展 MyExplorer。\n\n- 插件通过原生核心运行，可以添加新操作。\n- 在 **设置 -> 插件** 中启用或禁用已安装的插件。\n- 查看项目文档中的插件编写指南，构建你自己的插件。',
			'help.groups.customization.shortcutBar.title' => '快捷方式栏',
			'help.groups.customization.shortcutBar.body' => '标题栏下方的快捷方式栏可一键启动文件夹、文件或命令，遵循 Total Commander 的惯例。\n\n- 右键按钮可编辑或删除；`+` 区域用于添加新按钮。\n- 按钮可以打开文件夹或文件、运行命令行，或使用 `CD <路径>` 跳转。\n- 支持内置命令，如 `cm_OpenDesktop`、`cm_OpenDrives` 和 `cm_OpenRecycled`。\n- 图标可来自文件（`icon.png`）、exe/dll（`app.exe,0`）或系统库中的索引（`shell32.dll,34`）。\n- 使用**导入 Total Commander 按钮栏...** 加载 `.bar` 文件（UTF-8 或 GBK）。\n- 留空条目可创建分隔符。',
			'help.groups.resources.title' => '资源',
			'help.groups.resources.links.title' => '链接与资源',
			'help.groups.resources.links.body' => '更多关于 MyExplorer 的信息以及下一步。\n\n- **更新日志** - 每个版本的新内容（在菜单中）。\n- **键盘快捷键** - 完整参考位于 **设置 -> 键盘**。\n- **GitHub** - [源代码、问题和发布](https://github.com/MyExplorer/MyExplorer)。\n- **插件指南** - [如何编写自己的插件](https://github.com/MyExplorer/MyExplorer/blob/main/docs/plugins.md)。',
			'tags.menuLabel' => '标签',
			'tags.newTag' => '新建标签',
			'tags.newTagDots' => '新建标签…',
			'tags.editTag' => '编辑标签',
			'tags.deleteTag' => '删除标签',
			'tags.clear' => '清除标签',
			'tags.save' => '保存',
			'keybindings.title' => '键盘快捷键',
			'keybindings.menuLabel' => '快捷键',
			'keybindings.categories.navigation' => '导航',
			'keybindings.categories.quickLook' => '快速预览',
			'keybindings.categories.view' => '视图',
			'keybindings.categories.tabs' => '标签页',
			'keybindings.categories.panes' => '面板',
			_ => null,
		} ?? switch (path) {
			'keybindings.categories.terminal' => '终端',
			'keybindings.categories.fileOps' => '文件操作',
			'keybindings.categories.selection' => '选择',
			'keybindings.categories.search' => '搜索',
			'keybindings.categories.general' => '常规',
			'keybindings.or' => '或',
			'keybindings.fixed' => '固定快捷键',
			'keybindings.change' => '更改快捷键',
			'keybindings.reset' => '重置快捷键',
			'keybindings.pressShortcut' => '按下快捷键',
			'keybindings.escapeToCancel' => 'Esc 取消',
			'keybindings.conflict' => ({required Object action}) => '已被 ${action} 使用',
			'keybindings.dualHint' => '双栏',
			'keybindings.openItem' => '打开',
			'keybindings.goUp' => '返回上级',
			'keybindings.goBack' => '后退',
			'keybindings.goForward' => '前进',
			'keybindings.refresh' => '刷新',
			'keybindings.focusPath' => '聚焦路径栏',
			'keybindings.quickLook' => '打开快速预览',
			'keybindings.quickLookClose' => '关闭快速预览',
			'keybindings.quickLookPrevFile' => '上一个文件',
			'keybindings.quickLookNextFile' => '下一个文件',
			'keybindings.quickLookPrevFileEdit' => '编辑时上一个文件',
			'keybindings.quickLookNextFileEdit' => '编辑时下一个文件',
			'keybindings.quickLookSave' => '保存更改',
			'keybindings.quickViewPanel' => '切换快速查看面板',
			'keybindings.cursorUp' => '上移',
			'keybindings.cursorDown' => '下移',
			'keybindings.pageUp' => '上翻一页',
			'keybindings.pageDown' => '下翻一页',
			'keybindings.home' => '跳到开头',
			'keybindings.end' => '跳到结尾',
			'keybindings.newTab' => '新建标签页',
			'keybindings.closeTab' => '关闭标签页',
			'keybindings.nextTab' => '下一个标签页',
			'keybindings.prevTab' => '上一个标签页',
			'keybindings.switchTab' => '切换到标签页',
			'keybindings.jumpBookmark' => '跳转到书签',
			'keybindings.toggleDual' => '切换双栏模式',
			'keybindings.switchPane' => '切换活动面板',
			'keybindings.compare' => '比较文件夹',
			'keybindings.compareSyncRight' => '从左到右同步',
			'keybindings.compareSyncLeft' => '从右到左同步',
			'keybindings.compareExit' => '退出比较模式',
			'keybindings.focusTerminal' => '打开 / 聚焦终端',
			'keybindings.toggleTerminal' => '切换终端',
			'keybindings.newTerminalTab' => '新建终端标签页',
			'keybindings.closeTerminalTab' => '关闭终端标签页',
			'keybindings.insertRelativePaths' => '在终端中插入相对路径',
			'keybindings.insertAbsolutePaths' => '在终端中插入绝对路径',
			'keybindings.terminalFontIncrease' => '增大终端字体',
			'keybindings.terminalFontDecrease' => '减小终端字体',
			'keybindings.terminalFontReset' => '重置终端字体',
			'keybindings.fileListZoomIn' => '放大文件列表',
			'keybindings.fileListZoomOut' => '缩小文件列表',
			'keybindings.fileListZoomReset' => '重置文件列表缩放',
			'keybindings.toggleSidebar' => '切换侧边栏',
			'keybindings.toggleView' => '切换列表/树/网格视图',
			'keybindings.copy' => '复制',
			'keybindings.cut' => '剪切',
			'keybindings.paste' => '粘贴',
			'keybindings.duplicate' => '复制到此处（副本）',
			'keybindings.delete' => '删除',
			'keybindings.deletePermanent' => '永久删除',
			'keybindings.rename' => '重命名',
			'keybindings.newFolder' => '新建文件夹',
			'keybindings.dualCopy' => '复制到另一面板',
			'keybindings.dualMove' => '移动到另一面板',
			'keybindings.selectAll' => '全选',
			'keybindings.selectPattern' => '按模式选择',
			'keybindings.deselectAll' => '取消全选',
			'keybindings.invertSelection' => '反向选择',
			'keybindings.toggleSelect' => '切换选择',
			'keybindings.saveSelection' => '保存选择到文件',
			'keybindings.loadSelection' => '从文件加载选择',
			'keybindings.computeFolderSize' => '计算文件夹大小',
			'keybindings.search' => '搜索',
			'keybindings.recursiveSearch' => '递归搜索',
			'keybindings.closeSearch' => '关闭搜索',
			'keybindings.commandPalette' => '命令面板',
			'keybindings.preferences' => '设置',
			'commandPalette.title' => '命令面板',
			'commandPalette.placeholder' => '输入命令或设置…',
			'commandPalette.empty' => '没有匹配的命令',
			'commandPalette.unavailable' => '当前不可用',
			'commandPalette.categoryBookmark' => '书签',
			'commandPalette.categoryRecent' => '最近',
			'commandPalette.categoryDrive' => '驱动器',
			'commandPalette.categoryFile' => '文件',
			'commandPalette.categoryFolder' => '文件夹',
			'commandPalette.categoryPlugin' => '插件',
			'commandPalette.openPreferences' => '打开设置',
			'commandPalette.preferencesSubtitle' => '打开完整的设置对话框',
			'commandPalette.enabled' => '已启用',
			'commandPalette.disabled' => '已禁用',
			'commandPalette.searchingDeep' => ({required Object count}) => '正在搜索子文件夹… 找到 ${count} 个',
			'commandPalette.ready' => ({required Object count}) => '${count} 个结果',
			'quickLook.title' => '快速预览',
			'quickLook.noSelection' => '未选择文件',
			'quickLook.folder' => '文件夹',
			'quickLook.noPreview' => '无可用预览',
			'quickLook.binaryFile' => '二进制文件 - 无法预览',
			'quickLook.tooLarge' => '文件太大，无法预览',
			'quickLook.readError' => '无法读取文件',
			'quickLook.save' => '保存',
			'quickLook.saved' => '已保存',
			'quickLook.unsaved' => '未保存',
			'quickLook.saveError' => '无法保存文件',
			'quickLook.largeFileReadOnly' => '大文件 - 为速度以只读方式打开',
			'quickLook.editAnyway' => '仍要编辑',
			'quickLook.unsavedTitle' => '未保存的更改',
			'quickLook.unsavedMessage' => '你有未保存的更改。关闭前保存吗？',
			'quickLook.discard' => '放弃',
			'quickLook.cancel' => '取消',
			'quickLook.vimNormal' => '普通',
			'quickLook.vimInsert' => '插入',
			'quickLook.vimVisual' => '可视',
			'quickLook.accessed' => '访问时间',
			'quickLook.changed' => '更改时间',
			'quickLook.permissions' => '权限',
			'quickLook.contains' => '包含',
			'quickLook.calculating' => '正在计算…',
			'quickLook.items' => ({required Object count}) => '${count} 个项目',
			'quickLook.pdfPages' => ({required Object count}) => '${count} 页',
			'quickLook.sectionDetails' => '详细信息',
			'quickLook.info' => '信息',
			'quickLook.name' => '名称',
			'quickLook.type' => '类型',
			'quickLook.size' => '大小',
			'quickLook.path' => '路径',
			'quickLook.location' => '位置',
			'quickLook.modified' => '修改时间',
			'quickLook.created' => '创建时间',
			'quickLook.typeFolder' => '文件夹',
			'quickLook.typeFile' => '文件',
			'quickLook.dimensions' => '尺寸',
			'quickLook.camera' => '相机',
			'quickLook.lens' => '镜头',
			'quickLook.exposure' => '曝光',
			'quickLook.aperture' => '光圈',
			'quickLook.iso' => 'ISO',
			'quickLook.focalLength' => '焦距',
			'quickLook.dateTaken' => '拍摄日期',
			'quickLook.linePosition' => ({required Object line, required Object count}) => '第 ${line} / ${count} 行',
			'quickLook.lines' => '行数',
			'quickLook.characters' => '字符数',
			'quickLook.sectionGeneral' => '常规',
			'quickLook.sectionStatistics' => '统计',
			'quickLook.sizeBreakdown' => '大小分布',
			'quickLook.typeBreakdown' => '类型分布',
			'quickLook.noExtension' => '无扩展名',
			'quickLook.sectionImage' => '图片',
			'quickLook.sectionText' => '文本',
			'quickLook.hintSwitchFile' => '切换文件',
			'quickLook.hintClose' => '关闭',
			'quickLook.viewSource' => '查看源码',
			'quickLook.viewRendered' => '查看渲染效果',
			'quickLook.saveBeforePreview' => '保存更改以预览',
			'toast.copiedItems' => ({required Object count}) => '已复制 ${count} 个项目',
			'toast.duplicatedItems' => ({required Object count}) => '已复制 ${count} 个项目（副本）',
			'toast.cutItems' => ({required Object count}) => '已剪切 ${count} 个项目',
			'toast.selectionSaved' => ({required Object count, required Object path}) => '已将 ${count} 个名称保存到 ${path}',
			'toast.selectionLoaded' => ({required Object count}) => '已选择 ${count} 个可见项目',
			'toast.selectionLoadEmpty' => '没有可见项目匹配',
			'toast.terminalUnavailable' => '终端不可用：原生核心未加载',
			'toast.terminalNotVisible' => '终端未打开',
			'toast.selectionFileError' => ({required Object message}) => '选择文件错误：${message}',
			'toast.taskErrors' => ({required Object label, required Object count}) => '${label} - ${count} 个错误',
			'toast.renameAlreadyExists' => ({required Object name}) => '名为“${name}”的项目已存在',
			'toast.renameInvalidName' => '无效名称',
			'toast.renameError' => ({required Object message}) => '无法重命名：${message}',
			'toast.multiRenameSuccess' => ({required Object count}) => '已重命名 ${count} 个文件',
			'toast.multiRenamePartial' => ({required Object succeeded, required Object total, required Object details}) => '已重命名 ${succeeded} / ${total}（${details}）',
			'toast.multiRenameCollisions' => ({required Object count}) => '${count} 个已存在',
			'toast.multiRenameInvalid' => ({required Object count}) => '${count} 个无效名称',
			'toast.multiRenameOtherErrors' => ({required Object count}) => '${count} 个错误',
			'toast.multiRenameTrashBlocked' => '回收站中无法使用批量重命名',
			'terminalInsert.title' => ({required Object count}) => '插入 ${count} 个选中项目',
			'terminalInsert.separator' => '分隔符',
			'terminalInsert.customHint' => '分隔符',
			'terminalInsert.preview' => '预览',
			'terminalInsert.insert' => '插入',
			'selectionFile.saveTitle' => '保存选择',
			'selectionFile.loadTitle' => '加载选择',
			'selectionFile.pathLabel' => '文本文件',
			'selectionFile.pathHint' => 'selection.txt',
			'selectionFile.save' => '保存',
			'selectionFile.load' => '加载',
			'dragHint.copyTo' => ({required Object name}) => '复制到“${name}”',
			'dragHint.moveTo' => ({required Object name}) => '移动到“${name}”',
			'dragHint.tabToSwitch' => '（按住 Alt 拖动以移动）',
			'fileView.movingItems' => ({required Object count}) => '正在移动 ${count} 个项目',
			'fileView.empty' => '文件夹为空',
			'fileView.date.justNow' => '刚刚',
			'fileView.date.minutesAgo' => ({required Object count}) => '${count} 分钟前',
			'fileView.date.hoursAgo' => ({required Object count}) => '${count} 小时前',
			'fileView.date.daysAgo' => ({required Object count}) => '${count} 天前',
			'fileView.date.weeksAgo' => ({required Object count}) => '${count} 周前',
			'fileView.date.monthsAgo' => ({required Object count}) => '${count} 个月前',
			'fileView.date.yearsAgo' => ({required Object count}) => '${count} 年前',
			'fileView.columns.name' => '名称',
			'fileView.columns.size' => '大小',
			'fileView.columns.dateModified' => '修改日期',
			'fileView.columns.location' => '位置',
			'fileView.columns.kind' => '格式',
			'fileView.columns.dateCreated' => '创建日期',
			'fileView.columns.dateAdded' => '添加日期',
			'fileView.columns.permissions' => '权限',
			'fileView.columns.owner' => '所有者',
			'fileView.columns.configure' => '配置列',
			'sidebar.places' => '位置',
			'sidebar.devices' => '设备',
			'sidebar.home' => '主页',
			'sidebar.desktop' => '桌面',
			'sidebar.documents' => '文档',
			'sidebar.downloads' => '下载',
			'sidebar.pictures' => '图片',
			'sidebar.music' => '音乐',
			'sidebar.videos' => '视频',
			'sidebar.trash' => '回收站',
			'sidebar.root' => '根目录',
			'sidebar.network' => '网络',
			'sidebar.containers' => '容器',
			'sidebar.containerRunning' => '运行中',
			'sidebar.bookmarks' => '书签',
			'sidebar.tags' => '标签',
			'sidebar.noTags' => '标记文件后它们会显示在这里',
			'sidebar.dropBookmark' => '拖放文件夹以添加书签',
			'sidebar.editLayout' => '编辑侧边栏',
			'sidebar.editDone' => '完成',
			'sidebar.hide' => '隐藏',
			'sidebar.show' => '显示',
			'sidebar.connectToServer' => '连接到服务器',
			'sidebar.connectDialog.title' => '连接到服务器',
			'sidebar.connectDialog.host' => '服务器',
			'sidebar.connectDialog.hostHint' => '例如 192.168.1.10 或 nas.local',
			'sidebar.connectDialog.port' => '端口',
			'sidebar.connectDialog.username' => '用户名',
			'sidebar.connectDialog.usernameHint' => '可选',
			'sidebar.connectDialog.share' => '共享',
			'sidebar.connectDialog.shareHint' => '可选',
			'sidebar.connectDialog.pathLabel' => '路径',
			'sidebar.connectDialog.pathHint' => '可选',
			'sidebar.connectDialog.addBookmark' => '添加书签',
			'sidebar.connectDialog.connect' => '连接',
			'sidebar.connectDialog.invalidHost' => '请输入服务器地址',
			'sidebar.driveSpace.used' => '已用',
			'sidebar.driveSpace.free' => '可用',
			'sidebar.driveSpace.total' => '总计',
			'sidebar.drives.localDisk' => '本地磁盘',
			'sidebar.drives.usbDrive' => 'USB 驱动器',
			'sidebar.drives.unknownDrive' => '未知驱动器',
			'sidebar.drives.networkDrive' => '网络驱动器',
			'sidebar.drives.windowsDriveLabel' => ({required Object name, required Object letter}) => '${name}（${letter}:）',
			'sidebar.drives.mountTitle' => ({required Object name}) => '挂载 ${name}',
			'sidebar.collapse' => '折叠侧边栏',
			'sidebar.expand' => '展开侧边栏',
			'sidebar.collapseSection' => '折叠分区',
			'sidebar.expandSection' => '展开分区',
			'folderAccess.deniedTitle' => '无法访问此文件夹',
			'folderAccess.deniedBody' => '系统阻止了对此文件夹的访问。请重试或检查文件夹权限。',
			'folderAccess.retry' => '重试',
			'folderAccess.errorTitle' => '无法打开此文件夹',
			'toolbar.back' => '后退',
			'toolbar.forward' => '前进',
			'toolbar.up' => '上级',
			'toolbar.refresh' => '刷新',
			'toolbar.viewOptions' => '视图选项',
			'toolbar.newFolder' => '新建文件夹',
			'toolbar.operations' => '操作',
			'toolbar.notifications' => '通知',
			'toolbar.search' => '搜索',
			'toolbar.multiRename' => '批量重命名…',
			'toolbar.selectByPattern' => '按模式选择…',
			'toolbar.showHidden' => '显示隐藏文件',
			'toolbar.copyPath' => '复制路径',
			'toolbar.saveSelection' => '保存选择…',
			'toolbar.loadSelection' => '加载选择…',
			'toolbar.listView' => '列表视图',
			'toolbar.treeView' => '树形视图',
			'toolbar.gridView' => '网格视图',
			'toolbar.more' => '更多',
			'toolbar.newFile' => '新建文件',
			'toolbar.sync' => '同步',
			'notifications.title' => '通知',
			'notifications.empty' => '暂无通知',
			'notifications.clear' => '清除',
			'search.placeholder' => '筛选…',
			'search.filterPlaceholder' => 'kind:image size:>10mb modified:week',
			'search.subfolders' => '子文件夹',
			'search.subfoldersShortcut' => '子文件夹（Ctrl+Shift+F）',
			'search.content' => '内容',
			'search.contentSearch' => '在文件内容中搜索',
			'search.contentSftpUnsupported' => 'SFTP 上不支持内容搜索',
			'search.close' => '关闭搜索',
			'search.results' => ({required Object count}) => '${count} 个结果',
			'search.found' => ({required Object count}) => '找到 ${count} 个',
			'search.scanning' => ({required Object dirs}) => '已扫描 ${dirs} 个目录',
			'search.truncated' => ({required Object limit}) => '（前 ${limit} 个）',
			'search.noMatches' => '没有匹配',
			'search.starting' => '正在开始…',
			'search.clear' => '清除搜索',
			'search.modeSubstring' => '子串',
			'search.modeGlob' => '通配符',
			'search.modeRegex' => '正则',
			'search.modeFilter' => '筛选构建器',
			'search.invalidGlob' => '无效的通配符模式',
			'search.invalidRegex' => '无效的正则表达式',
			'search.filterErrors.unknownFilter' => ({required Object key}) => '未知筛选器：${key}',
			'search.filterErrors.missingValue' => ({required Object key}) => '${key} 缺少值',
			'search.filterErrors.unknownKind' => ({required Object kind}) => '未知类型：${kind}',
			'search.filterErrors.unknownType' => ({required Object type}) => '未知类型：${type}',
			'search.filterErrors.invalidSize' => '无效的大小筛选',
			'search.filterErrors.unknownModified' => ({required Object value}) => '未知的修改时间值：${value}',
			'search.filterErrors.unknownCreated' => ({required Object value}) => '未知的创建时间值：${value}',
			'search.filterErrors.hiddenBoolean' => '隐藏必须为 true 或 false',
			'search.filterDetails.name' => '文件名包含文本',
			'search.filterDetails.kind' => '类别，如图片或代码',
			'search.filterDetails.ext' => '扩展名列表，如 dart,png',
			'search.filterDetails.type' => '文件或文件夹',
			'search.filterDetails.size' => '比较，如 >10mb',
			'search.filterDetails.modified' => '今天、本周、本月或今年',
			'search.filterDetails.created' => '今天、本周、本月或今年',
			'search.filterDetails.hidden' => 'true 或 false',
			'search.complete' => '完成',
			'search.go' => '前往',
			'statusBar.items' => ({required Object count}) => '${count} 个项目',
			'statusBar.folders' => ({required Object count}) => '${count} 个文件夹',
			'statusBar.files' => ({required Object count}) => '${count} 个文件',
			'statusBar.selected' => ({required Object count}) => '已选 ${count} 个',
			'statusBar.zoomOut' => '缩小',
			'statusBar.zoomIn' => '放大',
			'statusBar.zoomReset' => '重置缩放',
			'dialog.create' => '创建',
			'dialog.cancel' => '取消',
			'dialog.folderNameHint' => '文件夹名称',
			'dialog.close' => '关闭',
			'dialog.delete' => '删除',
			'dialog.moveToTrash' => '移入回收站',
			'dialog.confirmDeleteTitle' => '永久删除？',
			'dialog.confirmDeleteSingle' => ({required Object name}) => '删除“${name}”？此操作无法撤销。',
			'dialog.confirmDeleteMultiple' => ({required Object count}) => '删除 ${count} 个项目？此操作无法撤销。',
			'dialog.confirmTrashTitle' => '移入回收站？',
			'dialog.confirmTrashSingle' => ({required Object name}) => '将“${name}”移入回收站？',
			'dialog.confirmTrashMultiple' => ({required Object count}) => '将 ${count} 个项目移入回收站？',
			'dialog.copy' => '复制',
			'dialog.move' => '移动',
			'dialog.confirmCopyTitle' => '复制项目？',
			'dialog.confirmCopySingle' => ({required Object name}) => '将“${name}”复制到这里？',
			'dialog.confirmCopyMultiple' => ({required Object count}) => '将 ${count} 个项目复制到这里？',
			'dialog.confirmMoveTitle' => '移动项目？',
			'dialog.confirmMoveSingle' => ({required Object name}) => '将“${name}”移动到这里？',
			'dialog.confirmMoveMultiple' => ({required Object count}) => '将 ${count} 个项目移动到这里？',
			'password.authenticationRequired' => '需要身份验证',
			'password.dismiss' => '取消',
			'password.mountPrompt' => '输入密码以挂载此驱动器。',
			'password.smbPrompt' => '输入此网络共享的凭据。',
			'password.sftpPrompt' => 'SSH/SFTP 身份验证',
			'password.username' => '用户名',
			'password.password' => '密码',
			'password.privateKey' => '私钥',
			'password.privateKeyPath' => '私钥路径',
			'password.passphraseOptional' => '口令（可选）',
			'password.unlock' => '解锁',
			'selectPattern.title' => '按模式选择',
			'selectPattern.hint' => '*.jpg, *.png',
			'selectPattern.help' => '通配符：*（任意）、?（单个字符）。用逗号分隔多个模式。',
			'selectPattern.select' => '选择',
			'split.title' => '分割文件',
			'split.filesCount' => ({required Object count}) => '分割 ${count} 个文件',
			'split.partSize' => '分卷大小',
			'split.custom' => '自定义…',
			'split.customHint' => '大小（字节）',
			'split.split' => '分割',
			'operations.title' => '操作',
			'operations.clear' => '清除',
			'operations.noActive' => '没有正在进行的操作',
			'operations.pause' => '暂停',
			'operations.resume' => '继续',
			'operations.resolveConflicts' => '解决冲突',
			'operations.errorsCount' => ({required Object count}) => '${count} 个错误',
			'operations.compressing' => '正在压缩…',
			'operations.compressingGzip' => '正在压缩（gzip）…',
			'operations.compressingBzip2' => '正在压缩（bzip2）…',
			'operations.compressingXz' => '正在压缩（xz）…',
			'operations.justNow' => '刚刚',
			'operations.secondsAgo' => ({required Object count}) => '${count} 秒前',
			'operations.minutesAgo' => ({required Object count}) => '${count} 分钟前',
			'operations.hoursAgo' => ({required Object count}) => '${count} 小时前',
			'operations.eta' => ({required Object time}) => '预计 ${time}',
			'operations.conflictsDetected' => '检测到冲突',
			'operations.filesExist' => ({required Object count}) => '目标位置已有 ${count} 个文件。',
			'operations.overwriteAll' => '全部覆盖',
			'operations.skipAll' => '全部跳过',
			'operations.review' => '查看',
			'operations.fileConflict' => ({required Object index, required Object total}) => '文件冲突（${index}/${total}）',
			'operations.replace' => '替换',
			'operations.keepBoth' => '两者都保留',
			'operations.skip' => '跳过',
			'operations.errors' => ({required Object count}) => '错误（${count}）',
			'operations.filesCount' => ({required Object processed, required Object count}) => '${processed} / ${count} 个文件',
			'operations.fileExists' => '已存在同名文件：',
			'operations.source' => ({required Object size, required Object date}) => '来源：${size} · ${date}',
			'operations.target' => ({required Object size, required Object date}) => '目标：${size} · ${date}',
			'operations.newer' => '  ← 较新',
			'operations.applyToAll' => ({required Object count}) => '应用于所有剩余冲突（${count}）',
			'errors.permissionDenied' => '权限被拒绝',
			'errors.authenticationRequired' => '需要身份验证',
			'errors.noSpace' => '设备上没有剩余空间',
			'errors.readOnly' => '只读文件系统',
			'errors.notFound' => '文件不存在',
			'errors.sourceNotFound' => '源不存在',
			'errors.pathNotFound' => '路径不存在',
			'errors.invalidPartSize' => '无效的分卷大小',
			'errors.missingSmbHost' => 'smb:// URI 中缺少主机',
			'errors.missingSftpHost' => 'sftp:// URI 中缺少主机',
			'errors.invalidSmbUri' => '无效的 smb:// URI',
			'errors.smbPortsNotSupportedOnWindows' => 'Windows 上不支持 SMB 端口',
			'errors.smbShareNotMounted' => 'SMB 共享未挂载',
			'errors.netUnavailable' => ({required Object message}) => 'net 不可用：${message}',
			'errors.netViewFailed' => ({required Object code}) => 'net view 失败（${code}）',
			'errors.failedToCreatePath' => ({required Object path, required Object error}) => '创建 ${path} 失败：${error}',
			'errors.notEmpty' => '目录非空',
			'errors.crossDevice' => '无法跨设备移动',
			'errors.targetExists' => '目标已存在',
			'errors.sftpNotSupported' => '不支持 SFTP',
			'errors.sftpConnectFailed' => 'SFTP 连接失败',
			'errors.sftpError' => ({required Object error}) => 'SFTP：${error}',
			'errors.sftpNoActiveSession' => '没有活动的 SFTP 会话',
			'errors.sftpNoActiveSessionFor' => ({required Object path}) => '${path} 没有活动的 SFTP 会话',
			'errors.sftpListingFailed' => 'SFTP 列表失败',
			'errors.sftpReadFailed' => 'SFTP 读取失败',
			'errors.sftpWriteFailed' => 'SFTP 写入失败',
			'errors.sftpMkdirFailed' => 'SFTP 创建目录失败',
			'errors.sftpRemoveFailed' => 'SFTP 删除失败',
			'errors.sftpRenameFailed' => 'SFTP 重命名失败',
			'errors.sftpOpenReaderFailed' => 'SFTP 打开读取器失败',
			'errors.sftpOpenWriterFailed' => 'SFTP 打开写入器失败',
			'errors.sftpCloseFailed' => 'SFTP 关闭失败',
			'errors.directoryNotReadable' => '目录不可读',
			'errors.transferIntoSelf' => '不能将文件夹复制或移动到自身内部。',
			'errors.workerExitedUnexpectedly' => '工作进程意外退出',
			'errors.appearedDuring' => '操作期间目标位置出现了文件',
			'errors.archiveError' => '无法读取压缩包',
			'errors.archiveCreateFailed' => ({required Object error}) => '无法创建压缩包：${error}',
			'errors.archiveReadFailed' => ({required Object error}) => '压缩包错误：${error}',
			'errors.archiveEntryNotFound' => ({required Object path}) => '压缩包条目不存在：${path}',
			'errors.unsupportedArchiveFormat' => '不支持的压缩包格式',
			'errors.nativeCoreNotFound' => ({required Object paths}) => '未找到原生 waydir_core；已搜索：${paths}',
			'errors.moveFileExFailed' => ({required Object error}) => 'MoveFileEx 失败，Windows 错误 ${error}',
			'errors.nativeTrashListFailed' => '原生回收站列表失败',
			'errors.nativeTrashListFailedWithMessage' => ({required Object message}) => '原生回收站列表失败：${message}',
			'errors.smbNotSupportedOnPlatform' => '此平台尚不支持网络共享（smb://）。',
			'tasks.copyingSingle' => ({required Object name}) => '正在复制 ${name}',
			'tasks.copyingMultiple' => ({required Object count}) => '正在复制 ${count} 个项目',
			'tasks.movingSingle' => ({required Object name}) => '正在移动 ${name}',
			'tasks.movingMultiple' => ({required Object count}) => '正在移动 ${count} 个项目',
			'tasks.deletingSingle' => ({required Object name}) => '正在删除 ${name}',
			'tasks.deletingMultiple' => ({required Object count}) => '正在删除 ${count} 个项目',
			'tasks.trashingSingle' => ({required Object name}) => '正在将 ${name} 移入回收站',
			'tasks.trashingMultiple' => ({required Object count}) => '正在将 ${count} 个项目移入回收站',
			'tasks.restoringTrashSingle' => ({required Object name}) => '正在从回收站还原 ${name}',
			'tasks.restoringTrashMultiple' => ({required Object count}) => '正在从回收站还原 ${count} 个项目',
			'tasks.deletingTrashSingle' => ({required Object name}) => '正在从回收站删除 ${name}',
			'tasks.deletingTrashMultiple' => ({required Object count}) => '正在从回收站删除 ${count} 个项目',
			'tasks.extractingSingle' => ({required Object name}) => '正在解压 ${name}',
			'tasks.extractingMultiple' => ({required Object count}) => '正在解压 ${count} 个压缩包',
			'tasks.compressingTo' => ({required Object name}) => '正在压缩到 ${name}',
			'tasks.updatingArchive' => '正在更新压缩包',
			'tasks.splittingSingle' => ({required Object name}) => '正在分割 ${name}',
			'tasks.splittingMultiple' => ({required Object count}) => '正在分割 ${count} 个项目',
			'tasks.combiningSingle' => ({required Object name}) => '正在合并 ${name}',
			'tasks.combiningMultiple' => ({required Object count}) => '正在合并 ${count} 个项目',
			'tasks.status.waiting' => '等待中...',
			'tasks.status.scanning' => '正在扫描文件...',
			'tasks.status.conflicts' => ({required Object count}) => '${count} 个冲突',
			'tasks.status.running' => ({required Object current, required Object processed, required Object total}) => '${current}（${processed}/${total}）',
			'tasks.status.cancelling' => '正在取消...',
			'tasks.status.completedWithErrors' => ({required Object count}) => '完成，${count} 个错误',
			'tasks.status.completed' => '已完成',
			'tasks.status.failed' => '失败',
			'tasks.status.cancelled' => '已取消',
			'git.clean' => '干净',
			'git.detachedHead' => '分离 HEAD',
			'git.merging' => '合并中',
			'git.rebasing' => '变基中',
			'git.cherryPicking' => '拣选中',
			'git.reverting' => '还原中',
			'git.bisecting' => '二分查找中',
			'git.checkoutFailed' => ({required Object message}) => '切换分支失败：${message}',
			'git.uncommittedChanges' => '未提交的更改',
			'git.stashPrompt' => ({required Object branch}) => '切换到“${branch}”将覆盖你的本地更改。\n\n现在暂存它们吗？它们会保存在一个 stash 中，之后可以在此分支上恢复。',
			'git.stashSwitch' => '暂存并切换',
			'git.stashSwitchFailed' => ({required Object message}) => '暂存并切换失败：${message}',
			'git.stashEntry' => ({required Object index, required Object message}) => 'stash@{${index}} · ${message}',
			'git.stashPop' => '弹出（应用并移除）',
			'git.stashApply' => '应用（保留 stash）',
			'git.stashDrop' => '丢弃',
			'git.stashFailed' => ({required Object message}) => '暂存失败：${message}',
			'git.noRepository' => '不是仓库',
			'git.gitCheckoutFailed' => 'git checkout 失败',
			'git.gitStashFailed' => 'git stash 失败',
			'git.changesStashedSwitchFailed' => ({required Object message}) => '更改已暂存，但切换失败：${message}',
			'openWith.title' => '打开方式',
			'openWith.subtitle' => ({required Object name}) => '选择用于打开“${name}”的应用',
			'openWith.recent' => '最近',
			'openWith.recommended' => '推荐应用',
			'openWith.allApps' => '所有应用',
			'openWith.noApps' => '未找到可打开此文件类型的应用。',
			'openWith.setDefault' => '始终使用此应用打开此文件类型',
			'openWith.setDefaultUnavailable' => '此平台无法更改默认应用',
			_ => null,
		} ?? switch (path) {
			'openWith.moreApps' => '更多应用…',
			'openWith.open' => '打开',
			'openWith.failed' => ({required Object app}) => '无法使用 ${app} 打开文件',
			'openWith.setDefaultFailed' => '无法设置默认应用',
			'openWith.unsupportedPlatform' => '不支持的平台',
			'openWith.windowsDefaultDialogRequired' => '使用系统“打开方式”对话框更改 Windows 上的默认应用',
			'hiddenList.title' => '隐藏列表',
			'hiddenList.pathHint' => '每行一个完整路径（支持粘贴多行）',
			'hiddenList.add' => '添加',
			'hiddenList.empty' => '暂无隐藏条目',
			'hiddenList.added' => ({required Object count}) => '已添加 ${count} 个条目',
			_ => null,
		};
	}
}
