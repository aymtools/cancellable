import 'dart:async';

import 'package:cancellable/src/exception/cancelled_exception.dart';
import 'package:weak_collections/weak_collections.dart';

part '_cancellable.dart';

///用于取消 不支持跨isolate使用
@pragma('vm:isolate-unsendable')
abstract class Cancellable {
  ///当取消时的处理 同步处理
  Future<CancelledException> get onCancel;

  /// 当前是否是可用状态
  bool get isAvailable;

  ///执行通知取消时传递的消息包装的异常
  CancelledException? get reasonAsException;

  ///通知执行取消
  void cancel([dynamic reason]);

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  Cancellable makeCancellable({Cancellable? father, bool infectious = false});

  factory Cancellable() => _Cancellable();
}

mixin CancellableMixin implements Cancellable {
  Cancellable _delegate = _Cancellable();

  ///当取消时的处理 同步处理
  Future<CancelledException> get onCancel => _delegate.onCancel;

  /// 当前是否是可用状态
  bool get isAvailable => _delegate.isAvailable;

  ///执行通知取消时传递的消息包装的异常
  CancelledException? get reasonAsException => _delegate.reasonAsException;

  ///通知执行取消
  void cancel([dynamic reason]) => _delegate.cancel(reason);

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) =>
      _delegate.makeCancellable(father: father, infectious: infectious);
}

// Expando<Completer<CancelledException>> _whenCancel = Expando();

extension CancellableSupport on Cancellable {
  ///是否已经取消
  ///使用 [isAvailable] 或 [isUnavailable] 代替
  @Deprecated('Use isAvailable or isUnavailable')
  bool get isCancelled => isUnavailable;

  ///请使用 [reasonAsException]
  @Deprecated('use reasonAsException')
  dynamic get reason => reasonAsException?.reason;

  /// 当前是否是不可用状态
  bool get isUnavailable => !isAvailable;

  ///当取消时的处理 异步模式 需要等下一次事件循环
  Future<CancelledException> get whenCancel {
    if (this is _Cancellable) {
      return (this as _Cancellable)._completerAsync.future;
    }
    //将同步的转换为异步的cancel
    Completer<CancelledException> whenCancel = Completer();
    onCancel.then((value) => whenCancel.complete(value));
    return whenCancel.future;
  }
}
