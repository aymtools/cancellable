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
        if (closeWhenCancel) {
          return Stream<T>.empty();
        }
        return StreamController<T>().stream;
      } else {
        StreamSubscription<T>? sub;
        void onListen() {
          if (cancellable.isUnavailable) {
            if (closeWhenCancel && !controller.isClosed) {
              controller.close();
            }
            return;
          }
          sub = this.listen((event) {
            if (cancellable.isAvailable) controller.add(event);
          }, onError: (err, st) {
            if (cancellable.isAvailable) controller.addError(err, st);
          }, onDone: () {
            if (cancellable.isAvailable) controller.close();
          });
        }

        void onCancel() {
          sub?.cancel();
          if (closeWhenCancel && !controller.isClosed) {
            controller.close();
          }
        }

        if (isBroadcast) {
          controller = StreamController<T>.broadcast(
              onListen: onListen, onCancel: onCancel, sync: true);
        } else {
          controller = StreamController<T>(
              onListen: onListen, onCancel: onCancel, sync: true);
        }
        cancellable.whenCancel.then((_) => controller.onCancel?.call());
      }
      return controller.stream;
    }

    return this.transform(StreamTransformer.fromBind(bind));
  }

  /// 自动取消 StreamSubscription
  @Deprecated('use bindCancellable')
  StreamSubscription<T> listenC({
    required Cancellable cancellable,
    required void onData(T event),
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  }) {
    var onDataX = (T event) {
      if (cancellable.isAvailable) onData.call(event);
    };
    var sub = this.listen(onDataX,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    cancellable.whenCancel.then((value) => sub.cancel());
    return sub;
  }

  /// 自动取消 StreamSubscription
  @Deprecated('use bindCancellable')
  StreamSubscription<T> listenCC(
    void onData(T event), {
    required Cancellable cancellable,
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  }) {
    var onDataX = (T event) {
      if (cancellable.isAvailable) onData.call(event);
    };
    var sub = this.listen(onDataX,
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
      {bool closeWhenCancel = true}) {
    runNotInCancellableZone(() => cancellable.whenCancel.then(
        (_) => closeWhenCancel ? this.close.call() : this.onCancel?.call()));
    return this;
  }
}

extension CancellableStreamSinkr<T> on StreamSink<T> {
  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamSink<T> closeByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  /// 绑定到 Cancellable cancel时close
  StreamSink<T> bindCancellable(Cancellable cancellable) {
    runNotInCancellableZone(
        () => cancellable.whenCancel.then((_) => this.close.call()));
    return this;
  }
}

extension CancellableStreamSubscription<T> on StreamSubscription<T> {
  /// 绑定到 Cancellable
  @Deprecated('use bindCancellable')
  StreamSubscription<T> cancelByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  /// 绑定到 Cancellable cancel时取消
  StreamSubscription<T> bindCancellable(Cancellable cancellable) {
    runNotInCancellableZone(
        () => cancellable.onCancel.then((_) => this.cancel()));
    return this;
  }
}
