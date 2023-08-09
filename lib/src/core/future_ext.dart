import 'dart:async';

import 'cancellable.dart';

extension CancellableFuture<T> on Future<T> {
  Future<T> bindCancellable(Cancellable cancellable) {
    if (cancellable.isUnavailable) return NeverExecFuture<T>();
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
    });
    this.whenComplete(() => cancellable.release());
    return completer.future;
  }
}
