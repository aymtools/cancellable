// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//  form flutter/lib/src/foundation/synchronous_future.dart
import 'dart:async';

/// A [Future] whose [then] implementation calls the callback immediately.
///
/// This is similar to [Future.value], except that the value is available in
/// the same event-loop iteration.
///
/// ⚠ This class is useful in cases where you want to expose a single API, where
/// you normally want to have everything execute synchronously, but where on
/// rare occasions you want the ability to switch to an asynchronous model. **In
/// general use of this class should be avoided as it is very difficult to debug
/// such bimodal behavior.**
///
/// A [SynchronousFuture] will never complete with an error.
class SynchronousFuture<T> implements Future<T> {
  /// Creates a synchronous future.
  ///
  /// See also:
  ///
  ///  * [Future.value] for information about creating a regular
  ///    [Future] that completes with a value.
  SynchronousFuture(this._value);

  final T _value;

  @override
  Stream<T> asStream() {
    final StreamController<T> controller = StreamController<T>();
    controller.add(_value);
    controller.close();
    return controller.stream;
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      Completer<T>().future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    final result = onValue(_value);
    if (result is Future<R>) {
      return result;
    }
    return SynchronousFuture<R>(result);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<dynamic> Function() action) {
    try {
      final FutureOr<dynamic> result = action();
      if (result is Future) {
        return result.then<T>((dynamic value) => _value);
      }
      return this;
    } catch (e, stack) {
      return Future<T>.error(e, stack);
    }
  }
}

// class SynchronousErrorFuture<T> implements Future<T> {
//   SynchronousErrorFuture(this._error, [this._stackTrace]);
//
//   final Object _error;
//   final StackTrace? _stackTrace;
//
//   @override
//   Stream<T> asStream() {
//     final StreamController<T> controller = StreamController<T>();
//     controller.addError(_error, _stackTrace);
//     controller.close();
//     return controller.stream;
//   }
//
//   @override
//   Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
//     if (onError is dynamic Function(Object, StackTrace)) {
//       errResult = onError(error, stackTrace);
//       hasValue = true;
//     } else if (onError is dynamic Function(Object)) {
//       errResult = onError(error);
//       hasValue = true;
//     }
//   }
//
//   @override
//   Future<R> then<R>(FutureOr<R> Function(T value) onValue,
//       {Function? onError}) {
//     if (onError == null) return SynchronousErrorFuture<R>(_error, _stackTrace);
//     if (onError is dynamic Function(Object, StackTrace)) {
//       errResult = onError(error, stackTrace);
//     } else if (onError is dynamic Function(Object)) {
//       errResult = onError(error);
//     }
//   }
//
//   @override
//   Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
//     if (timeLimit <= Duration.zero) {
//       return Future<T>.delayed(timeLimit, onTimeout);
//     }
//     return this;
//   }
//
//   @override
//   Future<T> whenComplete(FutureOr<dynamic> Function() action) {
//     try {
//       final FutureOr<dynamic> result = action();
//       if (result is Future) {
//         return result.then<T>((dynamic value) => _value);
//       }
//       return this;
//     } catch (e, stack) {
//       return SynchronousErrorFuture<T>(e, stack);
//     }
//   }
// }
