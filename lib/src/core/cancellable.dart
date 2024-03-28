import 'dart:async';

import 'package:cancellable/src/core/cancelled_exception.dart';
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
  Cancellable? father;
  Cancellable? mother;

  final Completer<CancelledException> _completer = Completer();
  final Completer<CancelledException> _completerSync = Completer.sync();

  Set<Cancellable>? _caches;

  bool _isCancelled = false;

  ///是否已经取消
  ///使用 [isAvailable] 或 [isUnavailable] 代替
  @Deprecated('Use isAvailable or isUnavailable')
  bool get isCancelled => _isCancelled;

  ///当取消时的处理
  Future<CancelledException> get whenCancel => _completer.future;

  ///当取消时的处理 同步处理
  Future<CancelledException> get onCancel => _completerSync.future;

  void Function()? _infectiousCancel;

  /// 当前是否是不可用状态
  bool get isUnavailable => _isCancelled;

  /// 当前是否是可用状态
  bool get isAvailable => !_isCancelled;

  ///请使用 [reasonAsException]
  @deprecated
  dynamic get reason => _reasonException?.reason;

  CancelledException? _reasonException;

  set _reason(dynamic value) {
    if (value is CancelledException) {
      _reasonException = value;
    } else {
      _reasonException = CancelledException(value);
    }
  }

  ///执行通知取消时传递的消息包装的异常
  CancelledException? get reasonAsException => _reasonException;

  ///通知执行取消
  void cancel([dynamic reason]) => _cancel(true, reason);

  void _cancel(bool runInfectiousCancel, dynamic reason) {
    if (isUnavailable) return;
    _isCancelled = true;
    _reason = reason;

    mother?._caches?.remove(this);
    mother = null;

    father?._caches?.remove(this);
    father = null;

    _completerSync.complete(reasonAsException);
    scheduleMicrotask(() => _completer.complete(reasonAsException));
    _caches
        ?.where((element) => element.isAvailable)
        .forEach((element) => element._cancel(false, reasonAsException));
    _caches?.clear();
    _caches = null;
    if (runInfectiousCancel) {
      _infectiousCancel?.call();
    }
  }

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) {
    // _releaseCache();
    Cancellable c = Cancellable();

    if (_isCancelled || (father != null && father._isCancelled)) {
      c._cancel(
          false, _isCancelled ? _reasonException : father?._reasonException);
      if (infectious) {
        _isCancelled
            ? father?._cancel(false, _reasonException)
            : _cancel(false, father?._reasonException);
      }
    } else {
      c.father = father;
      c.mother = this;

      if (infectious) {
        c._infectiousCancel = () {
          _cancel(false, c._reasonException);
          father?._cancel(false, c._reasonException);
        };
      }
      _addToCache(c);
      father?._addToCache(c);
    }
    return c;
  }

  void _addToCache(Cancellable cancellable) {
    _caches ??= WeakSet<Cancellable>();
    _caches?.add(cancellable);
  }

// /// 移除由当前生产的able
// void removeCancellable(Cancellable cancellable) {
//   if (isUnavailable || cancellable.isUnavailable) return;
//   _caches?.remove(cancellable);
//   _releaseCache();
// }
//
// void _releaseCache() {
//   _caches?.removeWhere((c) => c.isUnavailable);
// }
}
