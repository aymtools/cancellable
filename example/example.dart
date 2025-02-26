import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:cancellable/src/tools/current.dart';

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
  // cancellable2.cancel();
  // runZoned(() {
  //
  //   print('Zone curr ${current.zone.hashCode}');
  //   cancellable2.withRunZone(() {
  //     print('not await ');
  //     throw 'xxxxx';
  //     return 1;
  //   }, ignoreCancelledException: true);
  // }, onError: (error,stackTrace) {
  //   print('xxxxxx $error $stackTrace');
  //   // Zone.current.parent?.handleUncaughtError(error, stackTrace);
  // });

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
