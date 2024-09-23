# cancellable

This package provides a capability for cancellation.
This feature allows termination or revocation of operations through a certain mechanism during task
execution.

## Usage

```dart
main() {
  Cancellable cancellable = Cancellable();

  Stream.periodic(Duration(milliseconds: 100), (i) => i)
      .bindCancellable(cancellable.makeCancellable())
      .listen((event) => print(event));

  // 在其他任意的地方执行取消
  Future.delayed(Duration(seconds: 1)).then((value) => cancellable.cancel());

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
  Cancellable cancellable2 = cancellable.makeCancellable();

  cancellable2
    ..withRunZone(() async {
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
    });

  /// print
  // withRunZone 1
  // withRunZone 2
  // withRunZone 3
  // withRunZone 4
  // withRunZone 5
}
```

See [example](https://github.com/aymtools/cancellable/blob/master/example/example.dart)
for detailed test case.

For more usage in flutter,
see:[an_lifecycle_cancellable](https://pub.dev/packages/an_lifecycle_cancellable)

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/cancellable/issues):