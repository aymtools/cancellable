import 'dart:async';

import 'cancellable.dart';

extension CancellableStream<T> on Stream<T> {
  Stream<T> bindCancellable(Cancellable cancellable,
      {bool closeWhenCancel = false}) {
    Stream<T> bind(Stream<T> stream) {
      late StreamController<T> controller;
      if (cancellable.isUnavailable) {
        if (closeWhenCancel) {
          return Stream<T>.empty();
        }
      } else {
        StreamSubscription<T>? sub;
        void onListen() {
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
          if (closeWhenCancel) {
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
}
