<div align="center">

# Waydir

Fast, keyboard-first desktop file manager with dual panes, tabs, network drives, Quick Look, plugins and a native Rust core.

[![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white&style=flat-square)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white&style=flat-square)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Windows-informational?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

<p>
  <a href="https://github.com/Waydir/Waydir/releases"><b>Download</b></a>
  -
  <a href="#install"><b>Install</b></a>
  -
  <a href="docs/plugins.md"><b>Plugins</b></a>
  -
  <a href="CHANGELOG.md"><b>Changelog</b></a>
</p>

</div>

<p align="center">
  <img src="docs/screenshots/hero.png" alt="Waydir" width="860">
</p>

## Why Waydir?

Waydir is a native-feeling desktop file manager focused on speed, direct control and everyday file work.

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

<table>
  <tr>
    <td width="50%" align="center">
      <b>Keyboard-driven navigation</b><br>
      <img src="docs/gifs/navigating.gif" alt="Keyboard-driven navigation">
    </td>
    <td width="50%" align="center">
      <b>Dual-pane copy</b><br>
      <img src="docs/gifs/dual_pane_copy.gif" alt="Dual-pane copy">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>Quick Look preview</b><br>
      <img src="docs/gifs/quick_look_images.gif" alt="Quick Look preview">
    </td>
    <td width="50%" align="center">
      <b>Live recursive search</b><br>
      <img src="docs/gifs/search.gif" alt="Live recursive search">
    </td>
  </tr>
</table>

## Install

Download the `.exe` installer or portable `.zip` from [Releases](https://github.com/Waydir/Waydir/releases). Run the installer, or unpack the archive and launch `waydir.exe`.

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
- Launch from the command line with a folder to open.

## Plugins

Plugins let you add small workflow actions without rebuilding Waydir. They are plain Lua folders with a `manifest.json` and an `init.lua`.

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

Waydir uses three layers so heavy work does not block the UI:

| Layer | Responsibility |
|-------|----------------|
| Flutter UI | Rendering, input and desktop chrome. |
| Dart isolates | Long-running copy, move, delete and network transfers. |
| Rust core | Directory listing, recursive search, trash and PTY work through FFI. |

Persistent state uses `drift` and `sqlite3`. Reactive UI state uses `signals`. The UI thread does no filesystem-heavy work.

The native Rust library is required. There is no Dart fallback for the Rust core.

## Feature Gallery

<table>
  <tr>
    <td width="50%" align="center">
      <b>Browse remote files over SFTP</b><br>
      <img src="docs/gifs/sftp.gif" alt="SFTP browsing">
    </td>
    <td width="50%" align="center">
      <b>Archive browsing</b><br>
      <img src="docs/gifs/archive_browsing.gif" alt="Archive browsing">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>Built-in terminal per pane</b><br>
      <img src="docs/gifs/terminal.gif" alt="Built-in terminal">
    </td>
    <td width="50%" align="center">
      <b>Tabs per pane</b><br>
      <img src="docs/gifs/tabs.gif" alt="Tabs per pane">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>Filter search</b><br>
      <img src="docs/gifs/function_search.gif" alt="Filter search">
    </td>
    <td width="50%" align="center">
      <b>Customization</b><br>
      <img src="docs/gifs/customization.gif" alt="Customization">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>Selection workflow</b><br>
      <img src="docs/gifs/selection.gif" alt="Selection workflow">
    </td>
    <td width="50%" align="center">
      <b>Multi-rename</b><br>
      <img src="docs/gifs/multi_rename.gif" alt="Multi-rename">
    </td>
  </tr>
</table>

## Build From Source

Requirements:

- Flutter 3.35+
- Dart 3.10+
- Rust stable from [rustup](https://rustup.rs)

Run from the repository root:

```powershell
git clone https://github.com/Waydir/Waydir.git
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

Windows is the main development and testing target.

Bug reports, crash reports and focused pull requests are welcome. For non-trivial changes, open an issue first so the approach can be discussed before implementation.

## License

[MIT](LICENSE)
