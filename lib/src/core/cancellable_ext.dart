import 'dart:async';

import 'cancellable.dart';
import 'cancelled_exception.dart';

Map<Cancellable, Cancellable> _binds = {};

extension CancellableExt on Cancellable {
  Cancellable bindCancellable(Cancellable? cancellable) {
    if (cancellable == null) return this;
    this.onCancel.then((value) => cancellable.cancel(value));

    cancellable.onCancel.then((value) => this.cancel(value));
    return this;
  }
}
