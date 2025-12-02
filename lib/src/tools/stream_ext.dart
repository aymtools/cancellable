import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';
import 'package:cancellable/src/core/cancellable_zone.dart';

extension CancellableStream<T> on Stream<T> {
  /// 将stream关联到 Cancellable cancel后自动解绑
  Stream<T> bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = true}) {
    var result = this;
    runWhenCancellableZone((cancellableZone) => result =
        runNotInCancellableZone(() => result._bindCancellable(cancellableZone,
            closeWhenCancel: closeWhenCancel)));

    return runNotInCancellableZone(() {
      return result._bindCancellable(cancellable,
          closeWhenCancel: closeWhenCancel);
    });
  }

  Stream<T> _bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = true}) {
    Stream<T> bind(Stream<T> stream) {
      late StreamController<T> controller;
      if (cancellable.isUnavailable) {
        controller = isBroadcast
            ? StreamController<T>.broadcast(sync: true)
            : StreamController<T>(sync: true);
        if (closeWhenCancel) {
          controller.close();
        }
        return controller.stream;
      } else {
        StreamSubscription<T>? sub;
        void onListen() {
          if (cancellable.isUnavailable) {
            if (closeWhenCancel && !controller.isClosed) {
              controller.close();
            }
            return;
          }
          try {
            sub ??= listen((event) {
              if (cancellable.isAvailable) controller.add(event);
            }, onError: (err, st) {
              if (cancellable.isAvailable) controller.addError(err, st);
            }, onDone: () {
              if (cancellable.isAvailable) controller.close();
            });
          } catch (err, st) {
            /// 暂时没有解决这个问题 将listen的异常 转化为stream的异常了
            if (closeWhenCancel && !controller.isClosed) {
              controller.addError(err, st);
            }
          }
        }

        void onCancel() {
          sub?.cancel();
          sub = null;
        }

        if (isBroadcast) {
          controller = StreamController<T>.broadcast(
              onListen: onListen, onCancel: onCancel, sync: true);
        } else {
          controller = StreamController<T>(
              onListen: onListen, onCancel: onCancel, sync: true);
        }

        void whenCancel() {
          onCancel();
          if (closeWhenCancel && !controller.isClosed) {
            controller.close();
          }
        }

        cancellable.whenCancel.then((_) => whenCancel());
      }
      return controller.stream;
    }

    return transform(StreamTransformer.fromBind(bind));
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
      {bool closeWhenCancel = true, bool sync = false}) {
    runNotInCancellableZone(() {
      if (sync) {
        cancellable.onCancel
            .then((_) => closeWhenCancel ? close.call() : onCancel?.call());
      } else {
        cancellable.whenCancel
            .then((_) => closeWhenCancel ? close.call() : onCancel?.call());
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
  StreamSink<T> bindCancellable(Cancellable cancellable, {bool sync = false}) {
    runNotInCancellableZone(() {
      if (sync) {
        cancellable.onCancel.then((_) => close.call());
      } else {
        cancellable.whenCancel.then((_) => close.call());
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
