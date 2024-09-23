import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/tools/never_exec_future.dart';

extension CancellableFutureExt<T> on Future<T> {
  /// 将future 关联到 Cancellable 当cancel后 不执行then 和 err
  Future<T> bindCancellable(Cancellable cancellable,
      {bool throwWhenCancel = false}) {
    if (cancellable.isUnavailable && !throwWhenCancel) {
      return NeverExecFuture<T>();
    }

    var completer = Completer<T>.sync();

    if (throwWhenCancel) {
      cancellable.onCancel.then((value) {
        if (!completer.isCompleted) {
          completer.completeError(value, StackTrace.empty);
        }
      });
    }

    this.then((value) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.complete(value);
      }
    });

    this.catchError((err, st) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.completeError(err, st);
      }
      return Future<T>.error(err, st);
    });
    return completer.future;
  }
}
