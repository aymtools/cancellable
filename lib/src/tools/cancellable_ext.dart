import 'package:cancellable/src/core/cancellable.dart';

extension CancellableExt on Cancellable {
  Cancellable bindCancellable(Cancellable? cancellable) {
    if (cancellable == null) return this;
    this.onCancel.then((value) => cancellable.cancel(value));

    cancellable.onCancel.then((value) => this.cancel(value));
    return this;
  }
}
