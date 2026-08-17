import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/tools/never_exec_future.dart';

extension CancellableFutureExt<T> on Future<T> {
  /// 将future 关联到 Cancellable 当cancel后 不执行then 和 err
  /// * [throwWhenCancel] 将CancelledException以Future的异常发出
  /// * [onCancel] 自定义取消l时的处理 返回T或者抛异常 优先级低于[throwWhenCancel]
  Future<T> bindCancellable(Cancellable cancellable,
      {bool throwWhenCancel = false, T Function()? onCancel}) {
    if (cancellable.isUnavailable && !throwWhenCancel) {
      if (onCancel != null) {
        return Future.sync(onCancel);
      }
      return NeverExecFuture<T>();
    }

    var completer = Completer<T>.sync();

    if (throwWhenCancel) {
      cancellable.onCancel.then((value) {
        if (!completer.isCompleted) {
          completer.completeError(value, StackTrace.empty);
        }
      });
    } else if (onCancel != null) {
      if (!completer.isCompleted) {
        try {
          completer.complete(onCancel());
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          } else {
            rethrow;
          }
        }
      }
    }

    then((value) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.complete(value);
      }
    });

    catchError((err, st) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.completeError(err, st);
      }
      // return Future<T>.error(err, st);
    });
    return completer.future;
  }
}
