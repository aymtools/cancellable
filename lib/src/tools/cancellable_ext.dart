import 'package:cancellable/src/core/cancellable.dart';

extension CancellableExt on Cancellable {
  //将两个 Cancellable 互相关联 取消时 同步取消
  Cancellable bindCancellable(Cancellable? cancellable) {
    if (cancellable == null) return this;
    onCancel.then((value) => cancellable.cancel(value));

    cancellable.onCancel.then((value) => cancel(value));
    return this;
  }
}
