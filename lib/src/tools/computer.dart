import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart';

@pragma("vm:isolate-unsendable")
class CancellableComputer<T> implements Completer<T> {
  final Completer<T> _completer;
  final Cancellable _cancellable;

  CancellableComputer(this._cancellable,
      {T Function()? whenCancel, bool throwWhenCancel = true})
      : _completer = Completer<T>() {
    if (whenCancel != null) {
      _cancellable.whenCancel.then((_) {
        if (!_completer.isCompleted) {
          _completer.complete(whenCancel());
        }
      });
    } else if (throwWhenCancel) {
      _cancellable.whenCancel.then((e) {
        if (!_completer.isCompleted) {
          _completer.completeError(e, StackTrace.current);
        }
      });
    }
  }

  CancellableComputer.sync(this._cancellable,
      {T Function()? onCancel, bool throwOnCancel = true})
      : _completer = Completer<T>.sync() {
    if (onCancel != null) {
      _cancellable.onCancel.then((_) {
        if (!_completer.isCompleted) {
          _completer.complete(onCancel());
        }
      });
    } else if (throwOnCancel) {
      _cancellable.onCancel.then((e) {
        if (!_completer.isCompleted) {
          _completer.completeError(e, StackTrace.current);
        }
      });
    }
  }

  @override
  void complete([FutureOr<T>? value]) {
    if (_cancellable.isAvailable) _completer.complete(value);
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_cancellable.isAvailable) _completer.completeError(error, stackTrace);
  }

  @override
  Future<T> get future => _completer.future;

  @override
  bool get isCompleted => _completer.isCompleted || _cancellable.isUnavailable;
}
