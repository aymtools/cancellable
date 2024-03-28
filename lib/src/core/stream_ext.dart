import 'dart:async';

import 'cancellable_zone.dart';

import 'cancellable.dart';

extension CancellableStream<T> on Stream<T> {
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

  /// use [Stream.bindCancellable]
  @deprecated
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

  /// use [Stream.bindCancellable]
  @deprecated
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
  /// use [StreamController.bindCancellable]
  @deprecated
  StreamController<T> cancelByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable, closeWhenCancel: false);

  /// use [StreamController.bindCancellable]
  @deprecated
  StreamController<T> closeByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable, closeWhenCancel: true);

  StreamController<T> bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = true}) {
    runNotInCancellableZone(() => cancellable.whenCancel.then(
        (_) => closeWhenCancel ? this.close.call() : this.onCancel?.call()));
    return this;
  }
}

extension CancellableStreamSinkr<T> on StreamSink<T> {
  /// use [StreamSink.bindCancellable]
  @deprecated
  StreamSink<T> closeByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  StreamSink<T> bindCancellable(Cancellable cancellable) {
    runNotInCancellableZone(
        () => cancellable.whenCancel.then((_) => this.close.call()));
    return this;
  }
}

extension CancellableStreamSubscription<T> on StreamSubscription<T> {
  /// use [StreamSubscription.bindCancellable]
  @deprecated
  StreamSubscription<T> cancelByCancellable(Cancellable cancellable) =>
      bindCancellable(cancellable);

  StreamSubscription<T> bindCancellable(Cancellable cancellable) {
    runNotInCancellableZone(
        () => cancellable.onCancel.then((_) => this.cancel()));
    return this;
  }
}
