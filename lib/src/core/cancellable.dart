import 'dart:async';

///用于取消
class Cancellable {
  final Completer _completer = Completer();
  final Set<WeakReference<Cancellable>> _caches = {};

  bool _isCancelled = false;

  ///是否已经取消
  bool get isCancelled => _isCancelled;

  ///当取消时的处理
  Future get whenCancel => _completer.future;

  void Function()? _notifyCancelled;

  ///通知执行取消
  void cancel() => _cancel(true);

  void _cancel(bool notifyCancelled) {
    if (_isCancelled == true) return;
    _isCancelled = true;
    _completer.complete();
    _caches
        .map((element) => element.target)
        .where((element) => element != null && !element.isCancelled)
        .forEach((element) => element?._cancel(false));
    _caches.clear();

    if (notifyCancelled) {
      _notifyCancelled?.call();
    }

    _notifyCancelled = null;
  }

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) {
    Cancellable c = Cancellable();
    if (isCancelled || (father != null && father.isCancelled)) {
      Future.delayed(const Duration(), () => c._cancel(false));
    } else {
      c._notifyCancelled = () {
        _releaseCache();
        father?._releaseCache();
        if (infectious) {
          cancel();
          father?.cancel();
        }
      };
      var wc = WeakReference(c);
      _caches.add(wc);
      father?._caches.add(wc);
    }
    return c;
  }

  /// 移除由当前生产的able
  void removeCancellable(Cancellable cancellable) {
    _releaseCache();
    _caches.removeWhere((c) => c.target == cancellable);
  }

  void _releaseCache() =>
      _caches.removeWhere((c) => c.target?.isCancelled ?? true);
}
