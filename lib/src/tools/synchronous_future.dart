//  受 flutter/lib/src/foundation/synchronous_future.dart 启发
import 'dart:async';

/// 同步的future，支持 .value .error
/// [asStream] , [timeout] 依然是异步的
abstract class SynchronousFuture<T> implements Future<T> {
  const SynchronousFuture._();

  factory SynchronousFuture.value(T value) = _SynchronousValueFuture<T>;

  factory SynchronousFuture(T value) = _SynchronousValueFuture<T>;

  factory SynchronousFuture.error(Object error, [StackTrace? stackTrace]) =
      _SynchronousErrorFuture<T>;

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
      // 当 R 是 void 时，result（Null）转换为 void 是绝对安全的
      return _SynchronousValueFuture<R>(result as R);
    } catch (e, stack) {
      return _SynchronousErrorFuture<R>(e, stack);
    }
  }
}

/// 2. 私有类：专职处理成功流
class _SynchronousValueFuture<T> extends SynchronousFuture<T> {
  final T _value;

  const _SynchronousValueFuture(this._value) : super._();

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    try {
      final dynamic result = onValue(_value);
      if (result is Future<R>) return result;
      return _SynchronousValueFuture<R>(result as R);
    } catch (e, stack) {
      if (onError != null) {
        return _handleError<R>(onError, e, stack);
      }
      return _SynchronousErrorFuture<R>(e, stack);
    }
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      this;

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    try {
      final dynamic result = action();
      if (result is Future) return result.then((_) => this);
      return this;
    } catch (e, stack) {
      return _SynchronousErrorFuture<T>(e, stack);
    }
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<T> asStream() => Stream<T>.value(_value);
}

/// 3. 私有类：专职处理失败流
class _SynchronousErrorFuture<T> extends SynchronousFuture<T> {
  final Object error;
  final StackTrace stackTrace;

  _SynchronousErrorFuture(this.error, [StackTrace? stackTrace])
      : stackTrace = stackTrace ?? StackTrace.empty,
        super._();

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    if (onError != null) {
      return _handleError<R>(onError, error, stackTrace);
    }
    return _SynchronousErrorFuture<R>(error, stackTrace);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    if (test == null || test(error)) {
      return _handleError<T>(onError, error, stackTrace);
    }
    return this;
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    try {
      final dynamic result = action();
      if (result is Future) {
        return result
            .then((_) => _SynchronousErrorFuture<T>(error, stackTrace));
      }
      return this;
    } catch (e, stack) {
      return _SynchronousErrorFuture<T>(e, stack);
    }
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      Future<T>.error(error, stackTrace)
          .timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => Stream<T>.error(error, stackTrace);
}

/// 同步执行的Completer，优化了Completer&lt;T&gt;.sync()在complete后变成异步的问题
class SynchronousCompleter<T> implements Completer<T> {
  // 状态机代理：一旦真正拿到结果，它就会替代原生的 Completer
  SynchronousFuture<T>? _syncFuture;

  // 使用原生的 Completer.sync 作为未完成状态下的核心桥梁
  Completer<T>? _syncCompleter;

  // 记录是否已经触发了完成行为
  bool _isCompleted = false;

  @override
  bool get isCompleted => _isCompleted;

  @override
  void complete([FutureOr<T>? value]) {
    // 1. 第一时间拦截，防止重复触发，完美符合原生契约
    if (_isCompleted) throw StateError('The completer is already completed.');
    _isCompleted = true;

    if (value is Future<T>) {
      // 2. 如果是异步 Future，它在未来才会调用 _finalize，但此时 isCompleted 已经是 true 了
      value.then(
        (v) => _finalize(SynchronousFuture<T>.value(v)),
        onError: (e, st) => _finalize(
          SynchronousFuture<T>.error(e, st),
        ),
      );
    } else {
      // 3. 如果是同步纯值，立刻、原地同步定性
      _finalize(SynchronousFuture<T>.value(value as T));
    }
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_isCompleted) throw StateError('The completer is already completed.');
    _isCompleted = true;

    _finalize(SynchronousFuture<T>.error(error, stackTrace));
  }

  void _finalize(SynchronousFuture<T> proxy) {
    _syncFuture = proxy;

    // 如果在真正完成前，外部注册过监听，此时立即通过 _syncCompleter
    if (_syncCompleter != null) {
      proxy.then<void>(
        (v) => _syncCompleter!.complete(v),
        onError: (e, st) => _syncCompleter!.completeError(e, st),
      );
      _syncCompleter = null; // 释放内存
    }
  }

  @override
  Future<T> get future {
    // 当 _syncFuture 真正有值时，才说明已经完全可以走同步代理了
    if (_syncFuture != null) return _syncFuture!;

    // 还没完全定性（或处于异步等待状态中），懒加载单例 _syncCompleter 并返回它的 future
    _syncCompleter ??= Completer<T>.sync();
    return _syncCompleter!.future;
  }
}
