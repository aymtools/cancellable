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
    onTimeout ??= () => Future<T>.error(
        TimeoutException('NeverExecFuture timeout', timeLimit),
        StackTrace.empty);
    return Future<T>.delayed(timeLimit, onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return this;
  }
}
