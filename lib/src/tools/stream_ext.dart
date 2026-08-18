import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/core/cancellable_zone.dart';
import 'package:cancellable/src/exception/cancelled_exception.dart';

extension CancellableStream<T> on Stream<T> {
  /// 将stream关联到 Cancellable cancel后自动解绑
  /// * [emitCancelledException]  是否将CancelledException加入到Stream
  /// * [onCancel] 自定义取消l时的处理 优先级低于[emitCancelledException]
  Stream<T> bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = true,
      bool? emitCancelledException,
      void Function(CancelledException exception, StreamSink<T> sink)?
          onCancel}) {
    var result = this;
    runWhenCancellableZone((cancellableZone) => result =
        runNotInCancellableZone(() => result._bindCancellable(cancellableZone,
            closeWhenCancel: closeWhenCancel,
            emitCancelledException: emitCancelledException,
            onCancelCallback: null)));

    return runNotInCancellableZone(() {
      return result._bindCancellable(cancellable,
          closeWhenCancel: closeWhenCancel,
          emitCancelledException: emitCancelledException,
          onCancelCallback: onCancel);
    });
  }

  Stream<T> _bindCancellable(Cancellable cancellable,
      {required bool closeWhenCancel,
      required bool? emitCancelledException,
      required void Function(CancelledException exception, StreamSink<T> sink)?
          onCancelCallback}) {
    // Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;

    StreamSubscription<T>? sub;
    void onListen() {
      if (cancellable.isUnavailable) {
        if (!controller.isClosed) {
          if (emitCancelledException == true) {
            controller.addError(
                cancellable.reasonAsException!, StackTrace.empty);
          } else if (onCancelCallback != null) {
            _safeRunOnCancel(onCancelCallback, cancellable.reasonAsException!,
                controller.sink, () => controller.isClosed);
          }
          if (closeWhenCancel && !controller.isClosed) {
            // Future.microtask(() {
              if (!controller.isClosed) {
                controller.close();
              }
            // });
          }
        }
        return;
      }
      try {
        sub ??= listen((event) {
          if (cancellable.isAvailable && !controller.isClosed) {
            controller.add(event);
          }
        }, onError: (err, st) {
          if (cancellable.isAvailable && !controller.isClosed) {
            controller.addError(err, st);
          }
        }, onDone: () {
          if (cancellable.isAvailable && !controller.isClosed) {
            controller.close();
          }
        });
      } catch (err, st) {
        /// 暂时没有解决这个问题 将listen的异常 转化为stream的异常了
        if (closeWhenCancel && !controller.isClosed) {
          controller.addError(err, st);
        }
      }
    }

    void onCancelSub() {
      sub?.cancel();
      sub = null;
    }

    if (isBroadcast) {
      controller = StreamController<T>.broadcast(
          onListen: onListen, onCancel: onCancelSub, sync: true);
    } else {
      controller = StreamController<T>(
          onListen: onListen, onCancel: onCancelSub, sync: true);
    }

    if (cancellable.isAvailable) {
      cancellable.onCancel.then((ex) {
        onCancelSub();
        if (!controller.isClosed) {
          if (emitCancelledException == true) {
            controller.addError(ex, StackTrace.empty);
          } else if (onCancelCallback != null) {
            _safeRunOnCancel(onCancelCallback, ex, controller.sink,
                () => controller.isClosed);
          }
        }
      });
      if (closeWhenCancel) {
        cancellable.whenCancel.then((_) {
          if (!controller.isClosed) {
            controller.close();
          }
        });
      }

      // void whenCancel(exception) {
      //   if (closeWhenCancel && !controller.isClosed) {
      //     controller.close();
      //   }
      // }
      //
      // cancellable.onCancel.then(whenCancel);
    }
    return controller.stream;
    // }
    //
    // return transform(StreamTransformer.fromBind(bind));
  }

  /// 自动取消 StreamSubscription
  @Deprecated('use bindCancellable')
  StreamSubscription<T> listenC({
    required Cancellable cancellable,
    required void Function(T event) onData,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onDataX(T event) {
      if (cancellable.isAvailable) onData.call(event);
    }

    var sub = listen(onDataX,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    cancellable.whenCancel.then((value) => sub.cancel());
    return sub;
  }

  /// 自动取消 StreamSubscription
  @Deprecated('use bindCancellable')
  StreamSubscription<T> listenCC(
    void Function(T event) onData, {
    required Cancellable cancellable,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onDataX(T event) {
      if (cancellable.isAvailable) onData.call(event);
    }

    var sub = listen(onDataX,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    cancellable.whenCancel.then((value) => sub.cancel());
    return sub;
  }
}

extension CancellableStreamController<T> on StreamController<T> {
  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamController<T> cancelByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable, closeWhenCancel: false);

  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamController<T> closeByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable, closeWhenCancel: true);

  /// 绑定到 Cancellable cancel时 closeWhenCancel=true close 否则取消
  StreamController<T> bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = true,
      bool sync = false,
      bool? emitCancelledException,
      void Function(CancelledException exception, StreamSink<T> sink)?
          onCancel}) {
    final onCancelController = this.onCancel;
    runNotInCancellableZone(() {
      if (sync) {
        cancellable.onCancel.then((ex) {
          if (closeWhenCancel) {
            if (emitCancelledException == true) {
              addError(ex, StackTrace.empty);
            } else if (onCancel != null) {
              _safeRunOnCancel(onCancel, ex, sink, () => isClosed);
            }
            if (!isClosed) {
              close.call();
            }
          } else {
            if (onCancel != null) {
              _safeRunOnCancel(onCancel, ex, sink, () => isClosed);
            }
            onCancelController?.call();
          }
        });
      } else {
        cancellable.whenCancel.then((ex) {
          if (closeWhenCancel) {
            if (emitCancelledException == true) {
              addError(ex, StackTrace.empty);
            } else if (onCancel != null) {
              _safeRunOnCancel(onCancel, ex, sink, () => isClosed);
            }
            if (!isClosed) {
              close.call();
            }
          } else {
            if (onCancel != null) {
              _safeRunOnCancel(onCancel, ex, sink, () => isClosed);
            }
            onCancelController?.call();
          }
        });
      }
    });
    return this;
  }
}

extension CancellableStreamSinkr<T> on StreamSink<T> {
  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamSink<T> closeByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  /// 绑定到 Cancellable cancel时close
  StreamSink<T> bindCancellable(Cancellable cancellable,
      {bool sync = false,
      bool? emitCancelledException,
      void Function(CancelledException exception, StreamSink<T> sink)?
          onCancel}) {
    runNotInCancellableZone(() {
      if (sync) {
        cancellable.onCancel.then((ex) {
          if (emitCancelledException == true) {
            addError(ex, StackTrace.empty);
          } else if (onCancel != null) {
            _safeRunOnCancel(onCancel, ex, this, () => false);
          }
          close.call();
        });
      } else {
        cancellable.whenCancel.then((ex) {
          if (emitCancelledException == true) {
            addError(ex, StackTrace.empty);
          } else if (onCancel != null) {
            _safeRunOnCancel(onCancel, ex, this, () => false);
          }
          return close.call();
        });
      }
    });
    return this;
  }
}

extension CancellableStreamSubscription<T> on StreamSubscription<T> {
  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamSubscription<T> cancelByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  /// 绑定到 Cancellable cancel时取消
  StreamSubscription<T> bindCancellable(Cancellable cancellable,
      {bool sync = true}) {
    runNotInCancellableZone(() {
      if (sync) {
        cancellable.onCancel.then((_) => cancel());
      } else {
        cancellable.whenCancel.then((_) => cancel());
      }
    });
    return this;
  }
}

void _safeRunOnCancel<T>(
    void Function(CancelledException exception, StreamSink<T> sink) onCancel,
    CancelledException exception,
    StreamSink<T> sink,
    bool Function() isClosed) {
  try {
    onCancel(exception, sink);
  } catch (error, stackTrace) {
    if (!isClosed()) {
      sink.addError(error, stackTrace);
    } else {
      rethrow;
    }
  }
}
