# cancellable

This package provides a capability for cancellation.

## Usage

```
  Cancellable cancellable = Cancellable();

  var sub =
      Stream.periodic(Duration(milliseconds: 100), (i) => i).listen((event) {
    print(event);
  });

  sub.cancelByCancellable(
      cancellable); //  cancellable.whenCancel.then((value) => sub.cancel());

  // 在其他任意的地方取消这个订阅 
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
```

See [example](https://github.com/aymtools/cancellable/blob/master/example/cancellable_example.dart)
for detailed test case.

For more usage in flutter,
see:[aymtools](https://github.com/aymtools/flutter_aymtools)

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/cancellable/issues):