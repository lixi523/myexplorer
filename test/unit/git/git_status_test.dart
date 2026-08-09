import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/git/git_status_store.dart';

Future<ProcessResult> _git(String cwd, List<String> args) =>
    Process.run('git', ['-C', cwd, ...args]);

Future<void> _initRepo(Directory dir, {String branch = 'main'}) async {
  final init = await _git(dir.path, ['init', '-q']);
  expect(init.exitCode, 0, reason: 'git init failed: ${init.stderr}');
  final checkout = await _git(dir.path, ['checkout', '-q', '-b', branch]);
  expect(checkout.exitCode, 0);
  await _git(dir.path, ['config', 'user.name', 'test']);
  await _git(dir.path, ['config', 'user.email', 'test@example.com']);
}

Future<void> _commitAll(Directory dir, String message) async {
  await _git(dir.path, ['add', '-A']);
  final commit = await _git(dir.path, ['commit', '-q', '-m', message]);
  expect(commit.exitCode, 0, reason: 'git commit failed: ${commit.stderr}');
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    final probe = await Process.run('git', ['--version']);
    if (probe.exitCode != 0) {
      markTestSkipped('git is not available in this environment');
    }
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('waydir_git_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('GitStatusStore', () {
    test('refresh reports a clean repository', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final status = store.status.value;
      expect(status, isNotNull);
      expect(status!.branch, 'main');
      expect(status.detached, isFalse);
      expect(status.staged, 0);
      expect(status.unstaged, 0);
      expect(status.untracked, 0);
      expect(status.hasChanges, isFalse);
      expect(status.state, RepoState.clean);
    });

    test('refresh counts staged, unstaged and untracked changes', () async {
      await _initRepo(tmp);
      final sep = Platform.pathSeparator;
      File('${tmp.path}${sep}tracked.txt').writeAsStringSync('v1');
      File('${tmp.path}${sep}staged.txt').writeAsStringSync('s1');
      await _git(tmp.path, ['add', 'staged.txt']);
      await _commitAll(tmp, 'base');

      File('${tmp.path}${sep}tracked.txt').writeAsStringSync('v2');
      File('${tmp.path}${sep}staged.txt').writeAsStringSync('s2');
      await _git(tmp.path, ['add', 'staged.txt']);
      File('${tmp.path}${sep}new.txt').writeAsStringSync('n');

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final status = store.status.value!;
      expect(status.unstaged, 1);
      expect(status.staged, 1);
      expect(status.untracked, 1);
      expect(status.hasChanges, isTrue);
    });

    test('refresh returns null outside a git repository', () async {
      final store = GitStatusStore();
      await store.refresh(tmp.path);
      expect(store.status.value, isNull);
    });

    test('branches lists local branches with the current one first', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      await _git(tmp.path, ['checkout', '-q', '-b', 'feature']);
      await _git(tmp.path, ['checkout', '-q', 'main']);

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final names = await store.branches();
      expect(names.first, 'main');
      expect(names, containsAll(['main', 'feature']));
    });

    test('checkout switches branches and returns ok', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      await _git(tmp.path, ['checkout', '-q', '-b', 'feature']);

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final result = await store.checkout('main');
      expect(result.outcome, CheckoutOutcome.ok);
      expect(store.status.value!.branch, 'main');
    });

    test('checkout flags local changes that need a stash', () async {
      await _initRepo(tmp);
      final aPath = '${tmp.path}${Platform.pathSeparator}a.txt';
      File(aPath).writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      await _git(tmp.path, ['checkout', '-q', '-b', 'feature']);
      File(aPath).writeAsStringSync('feature version');
      await _commitAll(tmp, 'feature change');
      await _git(tmp.path, ['checkout', '-q', 'main']);
      File(aPath).writeAsStringSync('dirty');

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final result = await store.checkout('feature');
      expect(result.outcome, CheckoutOutcome.needsStash);
    });

    test('stashAndCheckout stashes changes then switches', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      await _git(tmp.path, ['checkout', '-q', '-b', 'feature']);
      await _git(tmp.path, ['checkout', '-q', 'main']);
      File(
        '${tmp.path}${Platform.pathSeparator}a.txt',
      ).writeAsStringSync('dirty');
      File(
        '${tmp.path}${Platform.pathSeparator}untracked.txt',
      ).writeAsStringSync('u');

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final error = await store.stashAndCheckout('feature');
      expect(error, isNull);
      expect(store.status.value!.branch, 'feature');
      expect(store.status.value!.hasChanges, isFalse);
    });

    test('stashes lists stash entries newest first', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      File(
        '${tmp.path}${Platform.pathSeparator}a.txt',
      ).writeAsStringSync('dirty');
      await _git(tmp.path, [
        'stash',
        'push',
        '-q',
        '-m',
        'wip stuff',
        '--',
        'a.txt',
      ]);

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final entries = await store.stashes();
      expect(entries, hasLength(1));
      expect(entries.first.index, 0);
      expect(entries.first.message, contains('wip stuff'));
      expect(entries.first.branch, 'main');
    });

    test('popStash restores changes and clears the stash', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');
      File(
        '${tmp.path}${Platform.pathSeparator}a.txt',
      ).writeAsStringSync('dirty');
      await _git(tmp.path, ['stash', 'push', '-q', '-m', 'wip', '--', 'a.txt']);

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      final error = await store.popStash(0);
      expect(error, isNull);
      expect((await store.stashes()), isEmpty);
      expect(store.status.value!.unstaged, 1);
    });

    test('watchPath debounces then refreshes', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');

      final store = GitStatusStore();
      store.watchPath(tmp.path);
      expect(store.status.value, isNull);
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (store.status.value == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(store.status.value, isNotNull);
      expect(store.status.value!.branch, 'main');
    });

    test('refreshCurrent refreshes the last watched path', () async {
      await _initRepo(tmp);
      File('${tmp.path}${Platform.pathSeparator}a.txt').writeAsStringSync('a');
      await _commitAll(tmp, 'initial');

      final store = GitStatusStore();
      await store.refresh(tmp.path);
      expect(store.status.value, isNotNull);
      File('${tmp.path}${Platform.pathSeparator}b.txt').writeAsStringSync('b');
      await store.refreshCurrent();
      expect(store.status.value!.untracked, 1);
    });

    test('empty path clears the status', () async {
      final store = GitStatusStore();
      store.watchPath('');
      expect(store.status.value, isNull);
    });
  });
}
