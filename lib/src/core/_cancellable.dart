part of 'cancellable.dart';

///用于取消 不支持跨isolate使用
@pragma('vm:isolate-unsendable')
class _Cancellable implements Cancellable {
  final Completer<CancelledException> _completer = Completer.sync();
  final Completer<CancelledException> _completerAsync = Completer();

  Set<Cancellable>? _caches;

  bool _isCancelled = false;

  ///当取消时的处理 同步处理
  Future<CancelledException> get onCancel => _completer.future;

  /// 当前是否是可用状态
  bool get isAvailable => !_isCancelled;

  CancelledException? _reasonException;

  set _reason(dynamic value) {
    if (value is CancelledException) {
      _reasonException = value;
    } else {
      _reasonException = CancelledException(value);
    }
  }

  ///执行通知取消时传递的消息包装的异常
  CancelledException? get reasonAsException => _reasonException;

  ///通知执行取消
  void cancel([dynamic reason]) => _cancel(reason);

  void _cancel(dynamic reason) {
    if (isUnavailable) return;
    _isCancelled = true;
    _reason = reason;

    _completer.complete(reasonAsException);
    _completerAsync.complete(reasonAsException);
    _caches
        ?.where((element) => element.isAvailable)
        .forEach((element) => element.cancel(reasonAsException));
    _caches?.clear();
    _caches = null;
  }

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) {
    _Cancellable c = _Cancellable();

    if (_isCancelled || (father != null && father.isUnavailable)) {
      c._cancel(_isCancelled ? _reasonException : father?.reasonAsException);
      if (infectious) {
        _isCancelled
            ? father?.cancel(_reasonException)
            : _cancel(father?.reasonAsException);
      }
    } else {
      if (infectious) {
        Cancellable infectiousWatcher = _Cancellable();
        infectiousCancel(reason) {
          if (infectiousWatcher.isAvailable) {
            infectiousWatcher.cancel(reason);
            c.cancel(reason);
            this.cancel(reason);
            father?.cancel(reason);
          }
        }

        c.onCancel.then(infectiousCancel);
        father?.onCancel.then(infectiousCancel);
        this.onCancel.then(infectiousCancel);
      }

      _addToCache(c);
      c._bindParent(father);
    }
    return c;
  }

  void _addToCache(_Cancellable cancellable) {
    _caches ??= WeakSet<Cancellable>();
    _caches?.add(cancellable);

    WeakReference<Set<Cancellable>> _weakCache = WeakReference(_caches!);
    cancellable.onCancel.then((value) => _weakCache.target?.remove(this));
  }

  void _bindParent(Cancellable? parent) {
    if (parent is _Cancellable) {
      parent._addToCache(this);
    } else {
      WeakReference<_Cancellable> weakThis = WeakReference(this);
      parent?.onCancel.then((value) => weakThis.target?._cancel(value));
    }
  }
}
