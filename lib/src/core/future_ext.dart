import 'dart:async';

import 'package:cancellable/cancellable.dart';

import 'cancellable.dart';

extension CancellableFuture<T> on Future<T> {
  Future<T> bindCancellable(Cancellable cancellable,
      {bool throwWhenCancel = false}) {
    if (cancellable.isUnavailable) {
      if (cancellable.isCancelled && throwWhenCancel) {
        return Future.error(
            CancelledException(cancellable.reason), StackTrace.current);
      }
      return NeverExecFuture<T>();
    }
    var completer = Completer<T>.sync();
    this.then((value) {
      if (cancellable.isAvailable) {
        completer.complete(value);
      }
    });
    this.catchError((err, st) {
      if (cancellable.isAvailable) {
        completer.completeError(err, st);
      }
      return Future<T>.value();
    });
    if (throwWhenCancel) {
      cancellable.whenCancel.then((value) =>
          completer.completeError(CancelledException(value), StackTrace.empty));
    }
    this.whenComplete(() => cancellable.release());
    return completer.future;
  }
}
