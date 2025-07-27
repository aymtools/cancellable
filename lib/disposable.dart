library disposable;

import 'dart:async';

import 'package:cancellable/src/core/cancellable.dart'
    show Cancellable, CancellableSupport;
import 'package:cancellable/src/exception/cancelled_exception.dart'
    show CancelledException;
import 'package:cancellable/src/tools/future_ext.dart'
    show CancellableFutureExt;
import 'package:cancellable/src/tools/stream_ext.dart'
    show
        CancellableStream,
        CancellableStreamController,
        CancellableStreamSinkr,
        CancellableStreamSubscription;

typedef Disposable = Cancellable;

typedef DisposedException = CancelledException;

extension CancellableDisposeExt on Cancellable {
  ///当 dispose 时的处理 同步处理
  Future<DisposedException> get onDispose => onCancel;

  ///当 dispose 时的处理 异步处理
  Future<DisposedException> get whenDispose => whenCancel;

  ///通知执行取消
  void dispose([dynamic reason]) => cancel(reason);

  /// 当前是否是 Disposed
  bool get isDisposed => isUnavailable;
}

extension DisposableFutureExt<T> on Future<T> {
  /// 将future 关联到 Disposable 当 dispose 后 不执行then 和 err
  /// [throwWhenDispose] == true 抛出 CancelledException ==false 时不执行任何操作
  Future<T> bindDisposable(Disposable disposable,
          {bool throwWhenDispose = false}) =>
      bindCancellable(disposable, throwWhenCancel: throwWhenDispose);
}

extension StreamDisposableExt<T> on Stream<T> {
  /// 将stream关联到 Disposable dispose后自动解绑
  /// [closeWhenDispose] == true closeStream  ==false cancelStream
  Stream<T> bindDisposable(Disposable disposable,
          {bool closeWhenDispose = true}) =>
      bindCancellable(disposable, closeWhenCancel: closeWhenDispose);
}

extension StreamControllerDisposableExt<T> on StreamController<T> {
  /// 绑定到 Disposable dispose 时 closeWhenCancel=true close 否则取消
  /// [closeWhenDispose] == true closeStream  ==false cancelStream
  StreamController<T> bindDisposable(Disposable disposable,
          {bool closeWhenDispose = true}) =>
      bindCancellable(disposable, closeWhenCancel: closeWhenDispose);
}

extension StreamSinkDisposableExt<T> on StreamSink<T> {
  /// 绑定到 Disposable dispose 时close
  StreamSink<T> bindDisposable(Disposable disposable) =>
      bindCancellable(disposable);
}

extension StreamSubscriptionDisposableExt<T> on StreamSubscription<T> {
  /// 绑定到 Disposable dispose 时 取消订阅
  StreamSubscription<T> bindDisposable(Disposable disposable) =>
      bindCancellable(disposable);
}
