import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'ui/window/window.dart';
import 'app/app_info.dart';
import 'app/launch_args.dart';
import 'app/myexplorer_app.dart';
import 'core/fs/fs_backend.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/fs/local_fs.dart';
import 'core/fs/sftp_fs.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/app_dirs.dart';
import 'core/settings/settings_store.dart';
import 'core/update/update_store.dart';
import 'features/navigation/sidebar_store.dart';
import 'features/hidden/hidden_list_store.dart';
import 'features/plugins/plugin_settings_store.dart';
import 'features/plugins/plugin_store.dart';
import 'features/tags/tag_store.dart';
import 'i18n/strings.g.dart';
import 'ui/theme/app_theme_registry.dart';

void main(List<String> args) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      LaunchArgs.parse(args);
      if (LaunchArgs.options.showHelp) {
        stdout.writeln(LaunchArgs.helpText);
        exit(0);
      }

      await AppLogger.instance.init();

      final exeDir = p.dirname(Platform.resolvedExecutable);
      final supportDir = await AppDirs.support();
      if (supportDir != exeDir) {
        log.warn(
          'platform',
          'Program folder is read-only ($exeDir); '
              'falling back to per-user data folder: $supportDir',
        );
      }

      FlutterError.onError = (details) {
        log.error('flutter', details.exceptionAsString(), stack: details.stack);
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        log.error('platform', '$error', stack: stack);

        return true;
      };

      await LocaleSettings.useDeviceLocale();
      try {
        await initializeDateFormatting();
      } catch (e, st) {
        log.warn(
          'i18n',
          'date formatting initialization failed',
          error: e,
          stack: st,
        );
      }
      FsBackendRegistry.registerLocal(const LocalFs());
      FsBackendRegistry.register(const SftpFs());
      unawaited(FsWorkerPool.instance.ensureStarted());
      await AppThemeRegistry.instance.load();
      await SettingsStore.instance.load();
      await HiddenListStore.instance.load();
      await SidebarStore.instance.load();
      await PluginSettingsStore.instance.load(SettingsStore.instance.db);
      await TagStore.instance.load();
      await AppInfo.init();
      if (LaunchArgs.options.showVersion) {
        stdout.writeln('MyExplorer ${AppInfo.version.value}');
        exit(0);
      }
      const fakeVersion = String.fromEnvironment('MYEXPLORER_FAKE_VERSION');
      UpdateStore.init(
        currentVersion: fakeVersion.isNotEmpty
            ? fakeVersion
            : AppInfo.version.value,
      );
      unawaited(UpdateStore.instance.checkOnStartup());
      unawaited(PluginStore.instance.loadAll());
      runApp(TranslationProvider(child: const MyExplorerApp()));

      if (isWindowChromeSupported) {
        appWindow.minSize = const Size(700, 450);
        appWindow.size = const Size(1100, 700);
        appWindow.alignment = Alignment.center;
        appWindow.title = t.app.title;
        // Show the window after the first frame is rendered, so the user
        // never sees a blank native window before Flutter paints its content.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appWindow.show();
          appWindow.maximize();
        });
      }
    },
    (error, stack) {
      log.error('zone', '$error', stack: stack);
    },
  );
}
