import 'myexplorer_core_loader.dart';

abstract class TrashService {
  Future<List<MyExplorerTrashFailure>> trashAll(List<String> paths);

  static final TrashService instance = _NativeTrashService();
}

class _NativeTrashService implements TrashService {
  @override
  Future<List<MyExplorerTrashFailure>> trashAll(List<String> paths) async {
    return MyExplorerCoreLoader.trash(paths);
  }
}
