import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/exception/cancelled_exception.dart';
import 'package:cancellable/src/tools/never_exec_future.dart';

extension CancellableFutureExt<T> on Future<T> {
  /// 将future 关联到 Cancellable 当cancel后 不执行then 和 err
  /// * [throwWhenCancel] 将CancelledException以Future的异常发出
  /// * [onCancel] 自定义取消l时的处理 返回T或者抛异常 优先级低于[throwWhenCancel]
  Future<T> bindCancellable(Cancellable cancellable,
      {bool throwWhenCancel = false,
      FutureOr<T> Function(CancelledException exception)? onCancel}) {
    if (cancellable.isUnavailable) {
      if (throwWhenCancel) {
        return Future<T>.error(
            cancellable.reasonAsException!, StackTrace.empty);
      } else if (onCancel != null) {
        try {
          dynamic result = onCancel(cancellable.reasonAsException!);
          if (result is Future<T>) {
            return result;
          } else {
            return Future<T>.sync(() => result);
          }
        } catch (error, stackTrace) {
          return Future<T>.error(error, stackTrace);
        }
      }
      return NeverExecFuture<T>();
    }

    var completer = Completer<T>.sync();

    if (throwWhenCancel) {
      cancellable.onCancel.then((ex) {
        if (!completer.isCompleted) {
          completer.completeError(ex, StackTrace.empty);
        }
      });
    } else if (onCancel != null) {
      cancellable.onCancel.then((ex) {
        if (!completer.isCompleted) {
          try {
            completer.complete(onCancel(ex));
          } catch (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          }
        }
      });
    }

    then((value) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.complete(value);
      }
    }, onError: (err, st) {
      if (cancellable.isAvailable && !completer.isCompleted) {
        completer.completeError(err, st);
      }
      // return NeverExecFuture<T>();
    });

    return completer.future;
  }
}
