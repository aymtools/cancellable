import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/exception/cancelled_exception.dart';

/// 一个可管理一组able的管理器
abstract class _CancellableGroup implements Cancellable {
  final List<Cancellable> _cancellableList = [];

  late final Cancellable _manager = () {
    return Cancellable()
      ..onCancel.then((reason) {
        _cancellableList.forEach((c) => c.cancel(reason));
        _cancellableList.clear();
      });
  }();

  late final Cancellable _managerAs =
      _manager.makeCancellable(infectious: true);

  void add(Cancellable cancellable);

  Future<dynamic> get whenCancel => _manager.whenCancel;

  bool get isAvailable => _manager.isAvailable;

  bool get isUnavailable => _manager.isUnavailable;

  Future<CancelledException> get onCancel => _manager.onCancel;

  Cancellable asCancellable() => _managerAs;

  @override
  void cancel([reason]) => _manager.cancel(reason);

  @override
  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) =>
      _manager.makeCancellable(father: father, infectious: infectious);

  @override
  CancelledException? get reasonAsException => _manager.reasonAsException;
}

///所有的able执行完取消才会取消group
class CancellableEvery extends _CancellableGroup {
  @override
  void add(Cancellable cancellable) {
    if (_manager.isUnavailable) {
      cancellable.cancel(_manager.reasonAsException);
      return;
    }
    if (cancellable.isUnavailable) return;
    _cancellableList.add(cancellable);
    cancellable.onCancel.then((value) {
      _cancellableList.remove(cancellable);
      _check();
    });
  }

  _check() {
    _cancellableList.removeWhere((e) => e.isUnavailable);
    if (_cancellableList.isEmpty) {
      _manager.cancel();
    }
  }
}

///任意一个able的取消都会导致所有的able执行取消
class CancellableAny extends _CancellableGroup {
  @override
  void add(Cancellable cancellable) {
    if (_manager.isUnavailable) {
      cancellable.cancel(_manager.reasonAsException);
      return;
    }
    if (cancellable.isUnavailable) {
      _manager.cancel(cancellable.reasonAsException);
      return;
    }
    _cancellableList.add(cancellable);
    cancellable.onCancel.then((value) => _manager.cancel(value));
  }
}
