import 'dart:async';

import 'package:weak_collections/weak_collections.dart';

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
    return Future<T>.delayed(timeLimit, onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return this;
  }
}

///用于取消 不支持跨isolate使用
@pragma('vm:isolate-unsendable')
class Cancellable {
  final Completer<dynamic> _completer = Completer();
  final Completer<dynamic> _completerSync = Completer.sync();

  WeakSet<Cancellable>? _caches;

  bool _isCancelled = false;

  ///是否已经取消
  ///使用 [isAvailable] 或 [isUnavailable] 代替
  @Deprecated('Use isAvailable or isUnavailable')
  bool get isCancelled => _isCancelled;

  ///当取消时的处理
  Future<dynamic> get whenCancel =>
      _isReleased ? NeverExecFuture<dynamic>() : _completer.future;

  ///当取消时的处理 同步处理
  Future<dynamic> get onCancel =>
      _isReleased ? NeverExecFuture() : _completerSync.future;

  void Function()? _notifyCancelled;

  bool _isReleased = false;

  /// 当前是否是不可用状态
  bool get isUnavailable => _isCancelled | _isReleased;

  /// 当前是否是可用状态
  bool get isAvailable => !isUnavailable;

  dynamic _reason;

  ///执行通知取消时传递的消息
  dynamic get reason => _reason;

  ///通知执行取消
  void cancel([dynamic reason]) => _cancel(true, reason);

  void _cancel(bool notifyCancelled, dynamic reason) {
    if (isUnavailable) return;
    _isCancelled = true;
    _reason = reason;
    _completerSync.complete(reason);
    _completer.complete(reason);
    _caches
        ?.where((element) => element.isAvailable)
        .forEach((element) => element._cancel(false, reason));
    _caches?.clear();
    _caches = null;

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
      Future.microtask(() => c._cancel(false, _reason ?? father?._reason));
    } else {
      c._notifyCancelled = () {
        _releaseCache();
        father?._releaseCache();
        if (infectious) {
          cancel();
          father?.cancel();
        }
      };
      _addToCache(c);
      father?._addToCache(c);
    }
    return c;
  }

  void _addToCache(Cancellable cancellable) {
    _caches ??= WeakSet<Cancellable>();
    _caches?.add(cancellable);
  }

  /// 移除由当前生产的able
  void removeCancellable(Cancellable cancellable) {
    if (isUnavailable || cancellable.isUnavailable) return;
    _caches?.remove(cancellable);
    _releaseCache();
  }

  void _releaseCache() {
    _caches?.removeWhere((c) => c.isUnavailable);
  }

  /// 施放资源 当前able不在使用
  /// After making multiple times, it is easy to trigger unforeseen hidden problems when using release.
  /// It is no longer recommended. If this scenario is needed,
  /// it is recommended to use double cancelable.bind to bind each other.
  /// [Cancellable.bindCancellable]
  /// Expected to be removed in the future
  @Deprecated(
      'After making multiple times, it is easy to trigger unforeseen hidden problems when using release. '
      'It is no longer recommended. If this scenario is needed, '
      'it is recommended to use double cancelable.bind to bind each other.')
  void release({bool notifyToChild = true}) {
    if (isUnavailable) return;
    _isReleased = true;
    if (notifyToChild) _caches?.forEach((c) => c.release());
    _caches?.clear();
    _notifyCancelled = null;
  }
}
