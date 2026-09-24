import '../models/file_entry.dart';

enum SortKey { name, size, date, kind, created, added, permissions, owner }

SortKey sortKeyFromString(String v) {
  switch (v) {
    case 'size':
      return SortKey.size;
    case 'date':
      return SortKey.date;
    case 'kind':
      return SortKey.kind;
    case 'created':
      return SortKey.created;
    case 'added':
      return SortKey.added;
    case 'permissions':
      return SortKey.permissions;
    case 'owner':
      return SortKey.owner;
    default:
      return SortKey.name;
  }
}

String sortKeyToString(SortKey k) => k.name;

/// Returns a new list sorted by the given criteria.
///
/// When [foldersFirst] is true, folders are always grouped before files
/// regardless of the sort key/direction. When [sortFolders] is false, folders
/// keep their default name-ascending order and only files follow the chosen
/// key/direction. Names use a case-insensitive comparison; ties always fall
/// back to name so the order is stable.
List<FileEntry> sortEntries(
  List<FileEntry> entries, {
  required SortKey key,
  required bool ascending,
  required bool foldersFirst,
  bool naturalSort = false,
  bool sortFolders = true,
  int? Function(FileEntry entry)? folderSize,
}) {
  final out = List<FileEntry>.of(entries);
  int byName(FileEntry a, FileEntry b) => naturalSort
      ? compareNatural(a.nameLower, b.nameLower)
      : a.nameLower.compareTo(b.nameLower);

  out.sort((a, b) {
    if (foldersFirst && a.type != b.type) {
      return a.type == FileItemType.folder ? -1 : 1;
    }
    final aFolder = a.type == FileItemType.folder;
    final bFolder = b.type == FileItemType.folder;
    final bothFolders = aFolder && bFolder;
    final aFolderSize = aFolder ? folderSize?.call(a) : null;
    final bFolderSize = bFolder ? folderSize?.call(b) : null;
    if (bothFolders &&
        (!sortFolders ||
            (key == SortKey.size &&
                aFolderSize == null &&
                bFolderSize == null))) {
      return byName(a, b);
    }
    int cmp;
    switch (key) {
      case SortKey.name:
        cmp = byName(a, b);
      case SortKey.size:
        final asize = aFolder ? (aFolderSize ?? 0) : a.size;
        final bsize = bFolder ? (bFolderSize ?? 0) : b.size;
        cmp = asize.compareTo(bsize);
      case SortKey.date:
        cmp = a.modifiedMs.compareTo(b.modifiedMs);
      case SortKey.kind:
        cmp = a.kind.toLowerCase().compareTo(b.kind.toLowerCase());
      case SortKey.created:
        cmp = a.createdMs.compareTo(b.createdMs);
      case SortKey.added:
        cmp = a.addedMs.compareTo(b.addedMs);
      case SortKey.permissions:
        cmp = a.mode.compareTo(b.mode);
      case SortKey.owner:
        cmp = a.ownerName.toLowerCase().compareTo(b.ownerName.toLowerCase());
    }
    if (cmp == 0) cmp = byName(a, b);

    return ascending ? cmp : -cmp;
  });

  return out;
}

int _metaType(int c) {
  if (c == 0x2E) {
    return 0; // period
  }
  if (c >= 0x30 && c <= 0x39) {
    return 1; // digit
  }

  return 2; // character
}

int _lower(int c) => (c >= 0x41 && c <= 0x5A) ? c + 0x20 : c;

(int, int, int, int) _parseDigits(String s, int i) {
  final n = s.length;
  var zeros = 0;
  while (i < n && s.codeUnitAt(i) == 0x30) {
    zeros++;
    i++;
  }
  final sigStart = i;
  while (i < n && _metaType(s.codeUnitAt(i)) == 1) {
    i++;
  }

  return (zeros, sigStart, i - sigStart, i);
}

/// Compares two file names the way Windows Explorer does (StrCmpLogicalW,
/// Vista+ semantics):
/// - Runs of digits are compared by numeric value ("file2" < "file10").
/// - A full stop (".") acts as a break between chunks and sorts before any
///   number or character, so base names group before their extensions.
/// - Meta-characters order as period < number < character, so a letter sorts
///   after a digit at the same position ("a1" < "ab").
/// - Comparison is case-insensitive.
/// - Among numbers with equal value, the one with more leading zeros is
///   lesser, but only when the strings are otherwise identical ("v01" < "v1").
int compareNatural(String a, String b) {
  final la = a.length;
  final lb = b.length;
  var i = 0;
  var j = 0;
  var tieZerosA = 0;
  var tieZerosB = 0;

  while (i < la && j < lb) {
    final ta = _metaType(a.codeUnitAt(i));
    final tb = _metaType(b.codeUnitAt(j));

    if (ta == 1 && tb == 1) {
      final ra = _parseDigits(a, i);
      final rb = _parseDigits(b, j);
      final sigLenA = ra.$3;
      final sigLenB = rb.$3;
      if (sigLenA != sigLenB) return sigLenA < sigLenB ? -1 : 1;
      for (var k = 0; k < sigLenA; k++) {
        final d = a.codeUnitAt(ra.$2 + k) - b.codeUnitAt(rb.$2 + k);
        if (d != 0) return d < 0 ? -1 : 1;
      }
      tieZerosA += ra.$1;
      tieZerosB += rb.$1;
      i = ra.$4;
      j = rb.$4;
    } else if (ta != tb) {
      return ta < tb ? -1 : 1;
    } else if (ta == 0) {
      i++;
      j++;
    } else {
      final ca = _lower(a.codeUnitAt(i));
      final cb = _lower(b.codeUnitAt(j));
      if (ca != cb) return ca < cb ? -1 : 1;
      i++;
      j++;
    }
  }

  if (i < la) {
    return 1;
  }
  if (j < lb) {
    return -1;
  }
  if (tieZerosA != tieZerosB) {
    return tieZerosA > tieZerosB ? -1 : 1;
  }

  return 0;
}
