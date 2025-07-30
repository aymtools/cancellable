part of 'cancellable.dart';

///用于取消 不支持跨isolate使用
@pragma('vm:isolate-unsendable')
class _Cancellable implements Cancellable {
  final Completer<CancelledException> _completer = Completer.sync();
  final Completer<CancelledException> _completerAsync = Completer();

  Set<Cancellable>? _caches;

  Set<Cancellable>? _cachesStrongRef;

  bool _isCancelled = false;

  SynchronousFuture<CancelledException>? _synchronousFuture;

  ///当取消时的处理 同步处理
  @override
  Future<CancelledException> get onCancel =>
      _synchronousFuture ?? _completer.future;

  /// 当前是否是可用状态
  @override
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
  @override
  CancelledException? get reasonAsException => _reasonException;

  ///通知执行取消
  @override
  void cancel([dynamic reason]) => _cancel(reason);

  void _cancel(dynamic reason) {
    if (isUnavailable) return;
    _isCancelled = true;
    _reason = reason;

    _completer.complete(reasonAsException);
    _synchronousFuture = SynchronousFuture(reasonAsException!);
    _completerAsync.complete(reasonAsException);
    _caches
        ?.where((element) => element.isAvailable)
        .forEach((element) => element.cancel(reasonAsException));
    _caches?.clear();
    _caches = null;

    _cachesStrongRef
        ?.where((element) => element.isAvailable)
        .forEach((element) => element.cancel(reasonAsException));
    _cachesStrongRef?.clear();
    _cachesStrongRef = null;
  }

  ///基于当前 生产一个新的
  ///[father] 同时接受两个上级取消的控制 有任意其他取消的时候新的也执行取消
  ///[infectious] 传染 当新的able执行取消的时候将生产者同时取消
  ///[weakRef] 新建的able 当前对其管理的方式是否为 弱引用
  @override
  Cancellable makeCancellable(
      {Cancellable? father, bool infectious = false, bool weakRef = true}) {
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
            cancel(reason);
            father?.cancel(reason);
          }
        }

        c.onCancel.then(infectiousCancel);
        father?.onCancel.then(infectiousCancel);
        onCancel.then(infectiousCancel);
      }

      _addToCache(c, weakRef);
      c._bindParent(father, weakRef);
    }
    return c;
  }

  void _addToCache(_Cancellable cancellable, bool weakRef) {
    if (weakRef) {
      _caches ??= WeakHashSet<Cancellable>();
      _caches?.add(cancellable);

      WeakReference<Set<Cancellable>> weakCache = WeakReference(_caches!);
      WeakReference<_Cancellable> weakChild = WeakReference(cancellable);
      cancellable.whenCancel
          .then((value) => weakCache.target?.remove(weakChild.target));
    } else {
      _cachesStrongRef ??= HashSet<Cancellable>();
      _cachesStrongRef?.add(cancellable);
      cancellable.whenCancel.then((value) {
        if (isAvailable) {
          _cachesStrongRef?.remove(cancellable);
        }
      });
    }
  }

  void _bindParent(Cancellable? parent, bool weakRef) {
    if (parent == null) return;
    if (parent is _Cancellable) {
      parent._addToCache(this, weakRef);
    } else if (weakRef) {
      WeakReference<_Cancellable> weakThis = WeakReference(this);
      parent.onCancel.then((value) => weakThis.target?._cancel(value));
    } else {
      parent.onCancel.then(_cancel);
    }
  }
}
