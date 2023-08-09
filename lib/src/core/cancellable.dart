import 'dart:async';

///永远也不会执行的 Future
class NeverExecFuture<T> implements Future<T> {
  @override
  Stream<T> asStream() => StreamController<T>().stream;

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      this;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return NeverExecFuture<R>();
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return this;
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return this;
  }
}

///用于取消
class Cancellable {
  final Completer _completer = Completer();
  final Set<WeakReference<Cancellable>> _caches = {};

  bool _isCancelled = false;

  ///是否已经取消
  ///使用 [isAvailable] 或 [isUnavailable] 代替
  @deprecated
  bool get isCancelled => _isCancelled;

  ///当取消时的处理
  Future get whenCancel => _isReleased ? NeverExecFuture() : _completer.future;

  void Function()? _notifyCancelled;

  bool _isReleased = false;

  /// 当前是否是不可用状态
  bool get isUnavailable => _isCancelled | _isReleased;

  /// 当前是否是可用状态
  bool get isAvailable => !isUnavailable;

  ///通知执行取消
  void cancel() => _cancel(true);

  void _cancel(bool notifyCancelled) {
    if (isUnavailable) return;
    _isCancelled = true;
    _completer.complete();
    _caches
        .map((element) => element.target)
        .where((element) =>
            element != null && element.isAvailable)
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
    _releaseCache();
    Cancellable c = Cancellable();
    if (_isReleased || (father != null && father._isReleased)) {
      c._isReleased = true;
      return c;
    }
    if (_isCancelled || (father != null && father._isCancelled)) {
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
    if (isUnavailable) return;
    cancellable.release();
    _releaseCache();
    _caches.removeWhere((c) => c.target == cancellable);
  }

  void _releaseCache() {
    _caches.removeWhere((c) => c.target?.isUnavailable ?? true);
  }

  // 施放资源 当前able不在使用
  void release({bool notifyToChild = true}) {
    if (isUnavailable) return;
    _isReleased = true;
    if (notifyToChild) _caches.forEach((c) => c.target?.release());
    _caches.clear();
  }
}
