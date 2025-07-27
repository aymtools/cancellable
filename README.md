# cancellable

This package provides a capability for cancellation.
This feature allows termination or revocation of operations through a certain mechanism during task
execution.

## Usage

```dart

main() async {
  Cancellable cancellable = Cancellable();

  //可用性判断
  print('isAvailable:${cancellable.isAvailable}');

  // 同步的
  cancellable.onCancel.then((value) {
    print('onCancel');
    scheduleMicrotask(() {
      print('onCancel scheduleMicrotask');
    });
  });
  // 异步的
  cancellable.whenCancel.then((_) {
    print('whenCancel');
  });

  /// print
  // onCancel
  // onCancel scheduleMicrotask
  // whenCancel

  Cancellable childCancellable = cancellable.makeCancellable();
  // steam.bindCancellable 绑定Cancellable 当cancel时自动解除订阅
  Stream.periodic(Duration(milliseconds: 100), (i) => i)
      .bindCancellable(childCancellable)
      .listen((event) => print(event));

  ///print
  ///0
  // 1
  // 2
  // 3
  // 4
  // 5
  // 6
  // 7
  // 8
  // 9
  // end

  // 在其他任意的地方执行取消
  Future.delayed(Duration(seconds: 1)).then((value) => cancellable.cancel());

  // 可以获取取消的原因
  Future.delayed(Duration(seconds: 2)).then((value) {
    // 可以通过 cancellable.cancel(reason) 自定义缘由
    CancelledException? exception = cancellable.reasonAsException;
  });

  Cancellable cancellable2 = cancellable.makeCancellable();

  print('Zone root ${current.zone.hashCode}');
  try {
    await cancellable2.withRunZone(() async {
      print('withRunZone 1');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 2');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 3');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 4');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 5');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 6');
      await Future.delayed(Duration(milliseconds: 200));
      print('withRunZone 6');
    }, ignoreCancelledException: true);
  } catch (err) {
    print('xxxxxxxx  $err');
  }

  /// print
  // withRunZone 1
  // withRunZone 2
  // withRunZone 3
  // withRunZone 4
  // withRunZone 5
}

```

## Disposable

Disposable is just an alias for Cancellable.
Additionally, DisposedException is an alias for CancelledException.
onDispose = onCancel
whenDispose = whenCancel
Extensions related to Dispose have been added for Stream and Future.

See [example](https://github.com/aymtools/cancellable/blob/master/example/example.dart)
for detailed test case.

For more usage in flutter,
see:[an_lifecycle_cancellable](https://pub.dev/packages/an_lifecycle_cancellable)

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/cancellable/issues):