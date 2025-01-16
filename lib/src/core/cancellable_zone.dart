import 'dart:async';

import '../exception/cancelled_exception.dart';
import 'cancellable.dart';

// dynamic _nullCallback() {}
//
// dynamic _nullUnaryCallback() {}
//
// dynamic _nullBinaryCallback() {}

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

/// 利用cancellable绑定到zone 当cancel后zone所有的注册事件将不会调用 包含stream 的close 等相关的回调
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
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 runUnary<R1, T>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T arg) f, T arg) {
    if (cancellable.isAvailable) {
      return parent.runUnary(zone, f, arg);
    }
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 runBinary<R1, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R1 Function(T1 arg1, T2 arg2) f, T1 arg1, T2 arg2) {
    if (cancellable.isAvailable) {
      return parent.runBinary(zone, f, arg1, arg2);
    }
    self.handleUncaughtError(cancellable.reasonAsException!, StackTrace.empty);
    return isFuture<R1>() ? _makeFuture() : null as R1;
  }

  R1 Function() registerCallback<R1>(
          Zone self, ZoneDelegate parent, Zone zone, R1 Function() f) =>
      parent.registerCallback(zone, () {
        if (cancellable.isUnavailable) {
          self.handleUncaughtError(
              cancellable.reasonAsException!, StackTrace.empty);
        }
        return f();
      });

  R1 Function(T1) registerUnaryCallback<R1, T1>(
          Zone self, ZoneDelegate parent, Zone zone, R1 Function(T1) f) =>
      parent.registerUnaryCallback(zone, (p) {
        if (cancellable.isUnavailable) {
          self.handleUncaughtError(
              cancellable.reasonAsException!, StackTrace.empty);
        }
        return f(p);
      });

  R1 Function(T1, T2) registerBinaryCallback<R1, T1, T2>(
      Zone self, ZoneDelegate parent, Zone zone, R1 Function(T1, T2) f) {
    return parent.registerBinaryCallback(zone, (p1, p2) {
      if (cancellable.isUnavailable) {
        self.handleUncaughtError(
            cancellable.reasonAsException!, StackTrace.empty);
      }
      return f(p1, p2);
    });
  }

  bool isFirst = true;
  void handleUncaughtError(
      Zone self, ZoneDelegate parent, Zone zone, err, StackTrace stackTrace) {
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
  /// 检查当前zone是否为 CancellableZone
  bool get isCancellableZone => this[_cancellableKey] != null;

  /// 检查当前CancellableZone 是否是 isAvailable状态  如果不是CancellableZone则返回false
  bool get isCancellableActive {
    if (isCancellableZone) {
      return _requiredCancellable.isAvailable;
    }
    return true;
  }

  /// 检查当前CancellableZone 是否是 isUnavailable状态 如果是则直接抛出异常 如果不是CancellableZone不执行任何操作
  void ensureCancellableActive() {
    if (!isCancellableActive) {
      throw _requiredCancellable.reasonAsException ?? CancelledException();
    }
  }

  Cancellable get _requiredCancellable => this[_cancellableKey]!;
}

/// 必须不能运行在CancellableZone 如果是则寻找其parent
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
  /// 将使用当前Cancellable 执行runZone
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
