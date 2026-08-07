<div align="center">

# MyExplorer

**v1.2.0** · Windows · [MIT License](LICENSE)

[Releases](https://github.com/lixi523/Waydir/releases) · [Changelog](CHANGELOG.md) · [Report Bug](https://github.com/lixi523/Waydir/issues)

</div>

> **Renamed from Waydir.** MyExplorer is the same fast, keyboard-first desktop file manager — new name, same project.

Fast, keyboard-first desktop file manager with dual panes, tabs, network drives, Quick Look, plugins and a native Rust core.

## Why MyExplorer?

MyExplorer is a native-feeling desktop file manager focused on speed, direct control and everyday file work.

| What you get | Why it matters |
|--------------|----------------|
| Dual panes and tabs | Move between folders without juggling windows. |
| Keyboard-first workflow | Navigate, select, preview, copy, move, rename and search without reaching for the mouse. |
| Command palette | Press `Ctrl+P` to fuzzy-search actions, bookmarks, drives, recent locations, files and plugin commands. |
| Native Rust core | Large directories, recursive search and trash operations stay off the UI thread. |
| SMB and SFTP drives | Remote files show up beside local files and behave like part of the same workspace. |
| Quick Look previews | Tap Space to preview images, PDFs, text, code and file properties. |
| Lua plugins | Add workflow actions, toolbar buttons, status bars and shortcuts without rebuilding the app. |

## See It Fast

## Install

Download the `.exe` installer or portable `.zip` from [Releases](https://github.com/lixi523/Waydir/releases). Run the installer, or unpack the archive and launch `MyExplorer.exe`.

## Features

### Browse and navigate

- Two folders side by side, each with its own draggable tabs.
- Command palette for fuzzy-searching actions, bookmarks, drives, recent locations, files and plugin commands.
- Sidebar with your places, drives, bookmarks and network locations.
- Quick path bar for jumping to any folder.
- List and grid views with image thumbnails and columns you choose.

### Work with files

- Copy, move, rename, trash and delete with progress you can cancel.
- Handles name clashes when copying, and renames many files at once.
- Open ZIP and TAR archives and browse inside without extracting.
- Hide selected files and folders from every list view: right-click → “Add to Hidden List”. Entries are stored in `隐藏文件.ini` next to the executable; edit the list from **View → Hidden List…** to show them again.

### Find and preview

- Fast search that fills in results as it scans, with pattern matching.
- Filter the current folder by type, size, date, name or hidden files.
- Quick Look on `Space` for images, PDFs, text, code and file details.
- Edit text right in the preview, with line numbers and optional Vim mode.

### Reach further

- Connect to SMB and SFTP and work with remote files like local ones.
- Browse files and open a terminal inside WSL distributions.
- Built-in terminal for each pane that opens in the current folder.
- Git status with branch switching and stash management.

### Make it yours

- Light, Dark, Nord and One Dark themes, plus your own themes.
- Adjust density, sorting, hidden files and date format to taste.
- Total Commander-style shortcut bar: import `.bar` button bars, app icons, separators and `CD` folder jumps.
- Simplified Chinese UI, selected automatically on Chinese systems.
- Launch from the command line with a folder to open.
- Opens maximized by default; only one instance runs at a time (launching again focuses the existing window).

## Plugins

Plugins let you add small workflow actions without rebuilding MyExplorer. They are plain Lua folders with a `manifest.json` and an `init.lua`.

Drop a plugin into the plugins folder, reload from Preferences -> Plugins and it can add:

- Selection context menu actions.
- Background context menu actions.
- Top Plugins menu entries.
- Location toolbar buttons.
- Keyboard shortcuts.
- Global and per-pane status bars.
- Long-running tasks in the Operations panel.

Plugins run in a sandbox and request explicit permissions for external commands or file operations.

Start here:

- [Plugin guide](docs/plugins.md)
- [Example plugins](docs/examples/plugins/)

Example plugin ideas already covered in the repository include opening the current folder in VS Code, adding 7-Zip actions, showing selection counts and running backup copies.

## Architecture

MyExplorer uses three layers so heavy work does not block the UI:

| Layer | Responsibility |
|-------|----------------|
| Flutter UI | Rendering, input and desktop chrome. |
| Dart isolates | Long-running copy, move, delete and network transfers. |
| Rust core | Directory listing, recursive search, trash and PTY work through FFI. |

Persistent state uses `drift` and `sqlite3`. Reactive UI state uses `signals`. The UI thread does no filesystem-heavy work.

The native Rust library is required. There is no Dart fallback for the Rust core.

## Build From Source

Requirements:

- Flutter 3.38+
- Dart 3.10+
- Rust stable from [rustup](https://rustup.rs)

Run from the repository root:

```powershell
git clone https://github.com/lixi523/Waydir.git
cd Waydir
flutter pub get
cargo build --release --manifest-path rust/waydir_core/Cargo.toml
flutter run -d windows
```

The Rust build must be `--release`. Rebuild and restart the app after editing `rust/waydir_core`, because Flutter hot reload does not reload the native library.

For packaged native libraries:

```powershell
scripts/build_waydir_core_windows.ps1
```

Build the Flutter app:

```powershell
flutter build windows
```

## Development

Before opening a pull request, run:

```bash
dart format .
flutter analyze
flutter test
```

Useful faster test commands:

```bash
flutter test --exclude-tags=integration
flutter test --tags=integration
```

Regenerate generated files when needed:

```bash
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

## Project Status

Current version: **1.2.0** — see [CHANGELOG.md](CHANGELOG.md) for release notes.

Windows is the main development and testing target.

Bug reports, crash reports and focused pull requests are welcome. For non-trivial changes, open an issue first so the approach can be discussed before implementation.

## License

[MIT](LICENSE)
