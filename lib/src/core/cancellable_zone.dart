import 'dart:async';

import 'cancellable.dart';
import '../exception/cancelled_exception.dart';

dynamic _nullCallback() {}

dynamic _nullUnaryCallback() {}

dynamic _nullBinaryCallback() {}

// final dynamic _nullFuture = Zone.root.run(() => Future.value(null));

class _Token<T> {
  Type typeOf() => T;
}

bool isFuture<T>() => _Token<T>() is _Token<Future>;

R _makeFuture<R>() => Future<Never>.error('') as R;

// late final Never _neverReturn = Zone.root
//     .fork(
//         specification: ZoneSpecification(
//             handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
//                 Object error, StackTrace stackTrace) {}))
//     .registerCallback(() => throw '')();

// late final Never _neverReturn = Zone.root
//     .fork(
//         specification: ZoneSpecification(
//             handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
//                 Object error, StackTrace stackTrace) {}))
//     .run(() => throw '');

R? runCancellableZoned<R>(
  R body(), {
  Map<Object?, Object?>? zoneValues,
  required Cancellable cancellable,
  void onCancel(CancelledException reason)?,
  bool ignoreCancelledException = true,
  bool forkZoneWithCancellable = true,
}) {
  if (onCancel != null) {
    runNotInCancellableZone(
        () => cancellable.onCancel.then((value) => onCancel(value)));
  }
  R1 runHandler<R1>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function() f) {
    if (cancellable.isAvailable) {
      return parent.run(zone, f);
    }
    // throw cancellable.reasonAsException!;
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    print(
        'Zone runHandler curr:${Zone.current.hashCode} self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 0');
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 runUnary<R1, T>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T arg) f, T arg) {
    if (cancellable.isAvailable) {
      return parent.runUnary(zone, f, arg);
    }
    // throw cancellable.reasonAsException!;
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    print(
        'Zone runUnary self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 1');
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 runBinary<R1, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R1 Function(T1 arg1, T2 arg2) f, T1 arg1, T2 arg2) {
    if (cancellable.isAvailable) {
      return parent.runBinary(zone, f, arg1, arg2);
    }
    // throw cancellable.reasonAsException!;
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    print(
        'Zone runBinary self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 2');
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 Function() registerCallback<R1>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function() f) {
    if (cancellable.isAvailable) {
      return parent.registerCallback(zone, f);
    }
    // throw cancellable.reasonAsException!;
    print(
        'Zone registerCallback curr:${Zone.current.hashCode} self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 2');
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return _nullCallback();
  }

  R1 Function(T1) registerUnaryCallback<R1, T1>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T1) f) {
    if (cancellable.isAvailable) {
      return parent.registerUnaryCallback(zone, f);
    }
    // throw cancellable.reasonAsException!;
    print(
        'Zone registerUnaryCallback curr:${Zone.current.hashCode} self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 2');
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return _nullUnaryCallback();
  }

  R1 Function(T1, T2) registerBinaryCallback<R1, T1, T2>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T1, T2) f) {
    if (cancellable.isAvailable) {
      return parent.registerBinaryCallback(zone, f);
    }
    // throw cancellable.reasonAsException!;
    print(
        'Zone registerBinaryCallback curr:${Zone.current.hashCode} self:${self.hashCode} parent:${parent.hashCode} zone:${zone.hashCode} 2');

    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return _nullBinaryCallback();
  }

  bool isFirst = true;
  void handleUncaughtError(
      Zone self, ZoneDelegate parent, Zone zone, err, StackTrace stackTrace) {
    // print('handleUncaughtError $err $stackTrace');
    if (err == cancellable.reasonAsException) {
      if (isFirst) {
        if (!ignoreCancelledException) {
          parent.handleUncaughtError(zone, err, stackTrace);
        }
        isFirst = false;
      } else {}
    } else {
      parent.handleUncaughtError(zone, err, stackTrace);
    }
  }

  Zone fork(Zone self, ZoneDelegate parent, Zone zone,
      ZoneSpecification? specification, Map<Object?, Object?>? zoneValue) {
    return parent.fork(zone.parent!, specification, zoneValues);
  }

  final zValues = {};
  if (zoneValues != null) {
    zValues.addAll(zoneValues);
  }
  zValues[_cancellableKey] = cancellable;
  return runZoned(
    body,
    zoneValues: zValues,
    zoneSpecification: ZoneSpecification(
      run: runHandler,
      runUnary: runUnary,
      runBinary: runBinary,
      registerCallback: registerCallback,
      registerUnaryCallback: registerUnaryCallback,
      registerBinaryCallback: registerBinaryCallback,
      handleUncaughtError: handleUncaughtError,
      fork: forkZoneWithCancellable ? null : fork,
    ),
  );
  // return runZonedGuarded(() {
  //   return runZoned(
  //     body,
  //     zoneValues: zValues,
  //     zoneSpecification: ZoneSpecification(
  //       run: runHandler,
  //       runUnary: runUnary,
  //       runBinary: runBinary,
  //       registerCallback: registerCallback,
  //       registerUnaryCallback: registerUnaryCallback,
  //       registerBinaryCallback: registerBinaryCallback,
  //       handleUncaughtError: handleUncaughtError,
  //       fork: forkZoneWithCancellable ? null : fork,
  //     ),
  //   );
  // }, (error, stack) {
  //   if (error != cancellable.reasonAsException)
  //     Zone.current.parent?.handleUncaughtError(error, stack);
  // });
}

class _ZoneKey {
  final String key;

  const _ZoneKey(this.key);
}

const _ZoneKey _cancellableKey = _ZoneKey('cancellable');

extension CancellableZoneCheck on Zone {
  bool get isCancellableZone => this[_cancellableKey] != null;

  bool get isCancellableActive {
    if (isCancellableZone) {
      return _requiredCancellable.isAvailable;
    }
    return true;
  }

  void ensureCancellableActive() {
    if (!isCancellableActive) {
      throw _requiredCancellable.reasonAsException ?? CancelledException();
    }
  }

  Cancellable get _requiredCancellable => this[_cancellableKey]!;
}

R runNotInCancellableZone<R>(R Function() action) {
  var zone = Zone.current;
  while (zone.isCancellableZone) {
    zone = zone.parent!;
  }
  return zone.run(() => action());
}

///若当前zone是CancellableZone则会执行action 如果不是则直接跳过action
void runWhenCancellableZone(void Function(Cancellable cancellable) action) {
  final zone = Zone.current;
  if (zone.isCancellableZone && zone._requiredCancellable.isAvailable) {
    action(zone._requiredCancellable.makeCancellable());
  }
}

extension CancellableRunZone on Cancellable {
  R? withRunZone<R>(
    R body(), {
    Map<Object?, Object?>? zoneValues,
    void onCancel(CancelledException reason)?,
    bool ignoreCancelledException = true,
    bool forkZoneWithCancellable = true,
  }) =>
      runCancellableZoned(body,
          cancellable: this,
          zoneValues: zoneValues,
          onCancel: onCancel,
          ignoreCancelledException: ignoreCancelledException,
          forkZoneWithCancellable: forkZoneWithCancellable);
}
