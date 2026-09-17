import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/exception/cancelled_exception.dart';
import 'package:cancellable/src/tools/future_ext.dart';
import 'package:cancellable/src/tools/stream_ext.dart';

/// 将普通的future包装为可取消的Future 取消时不再等待源，直接以抛CancelledException的方式结束
/// * 不会处理同步问题；默认按照异步，就算源是同步的也不保证同步执行
class CancellableFuture<T> implements Future<T> {
  final Future<T> _future;
  final Cancellable _cancellable;

  late final Future<T> _lazyFuture = () {
    if (_cancellable.isUnavailable) {
      return Future<T>.error(
          _cancellable.reasonAsException ?? CancelledException());
    }
    return _future.bindCancellable(_cancellable, throwWhenCancel: true);
  }();

  CancellableFuture(this._future, this._cancellable);

  CancellableFuture.cancelled([Cancellable? cancellable])
      : assert(cancellable == null || cancellable.isUnavailable,
            'cancelled future must be unavailable'),
        _future = Completer<T>().future,
        _cancellable = cancellable ?? Cancellable.cancelled();

  void cancel([dynamic reason]) => _cancellable.cancel(reason);

  @override
  Stream<T> asStream() {
    if (_cancellable.isUnavailable) {
      return Stream.error(
          _cancellable.reasonAsException ?? CancelledException());
    }
    return _future
        .asStream()
        .bindCancellable(_cancellable, emitCancelledException: true);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    if (_cancellable.isUnavailable) {
      final error = _cancellable.reasonAsException ?? CancelledException();
      if (test == null || test(error)) {
        return _handleError<T>(onError, error, StackTrace.empty);
      }
      return Future<T>.error(error);
    }
    return _lazyFuture.catchError(onError, test: test);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    if (_cancellable.isUnavailable) {
      final error = _cancellable.reasonAsException ?? CancelledException();
      return Future<T>.error(error);
    }
    return _lazyFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    if (_cancellable.isUnavailable) {
      final error = _cancellable.reasonAsException ?? CancelledException();
      try {
        final dynamic result = action();
        if (result is Future) {
          return result.then((_) => Future<T>.error(error, StackTrace.empty));
        }
        return this;
      } catch (e, stack) {
        return Future<T>.error(e, stack);
      }
    }
    return _lazyFuture.whenComplete(action);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    if (_cancellable.isUnavailable) {
      final error = _cancellable.reasonAsException ?? CancelledException();
      if (onError != null) {
        return _handleError<R>(onError, error, StackTrace.empty);
      }
      return Future<R>.error(error);
    }
    return _lazyFuture.then(onValue, onError: onError);
  }
}

Future<R> _handleError<R>(
    Function onError, Object error, StackTrace stackTrace) {
  try {
    dynamic result;
    if (onError is Function(Object, StackTrace)) {
      result = onError(error, stackTrace);
    } else if (onError is Function(Object)) {
      result = onError(error);
    } else {
      throw ArgumentError.value(
          onError,
          "onError",
          "Error handler must accept one Object or one Object and a StackTrace"
              " as arguments, and return a value of the returned future's type");
    }

    if (result is Future<R>) return result;
    return Future.value(result as R);
  } catch (e, stack) {
    return Future.error(e, stack);
  }
}

extension AsCancellableFutureExt<T> on Future<T> {
  /// 将普通future包装为可取消的future
  CancellableFuture<T> asCancellableFuture({Cancellable? cancellable}) {
    return CancellableFuture<T>(this, cancellable ?? Cancellable());
  }
}
