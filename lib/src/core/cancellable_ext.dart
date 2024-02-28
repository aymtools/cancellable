import 'dart:async';

import 'cancellable.dart';
import 'cancelled_exception.dart';

extension CancellableExt on Cancellable {
  Cancellable bindCancellable(Cancellable? cancellable) {
    if (cancellable == null) return this;
    this.onCancel.then((value) => cancellable.cancel(value));

    cancellable.onCancel.then((value) => this.cancel(value));
    return this;
  }
}

R runCancellableZoned<R>(
  R body(), {
  Map<Object?, Object?>? zoneValues,
  required Cancellable cancellable,
  void onCancel()?,
}) {
  if (onCancel != null) cancellable.onCancel.then((value) => onCancel());
  R1 runHandler<R1>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function() f) {
    if (cancellable.isAvailable) {
      return parent.run(zone, f);
    }
    throw CancelledException(cancellable.reason);
  }

  R1 runUnary<R1, T>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T arg) f, T arg) {
    if (cancellable.isAvailable) {
      return parent.runUnary(zone, f, arg);
    }
    throw CancelledException(cancellable.reason);
  }

  R1 runBinary<R1, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R1 Function(T1 arg1, T2 arg2) f, T1 arg1, T2 arg2) {
    if (cancellable.isAvailable) {
      return parent.runBinary(zone, f, arg1, arg2);
    }

    throw CancelledException(cancellable.reason);
  }

  return runZoned(
    body,
    zoneValues: zoneValues,
    zoneSpecification: ZoneSpecification(
        run: runHandler, runUnary: runUnary, runBinary: runBinary),
  );
}
