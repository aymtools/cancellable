import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:cancellable/src/tools/current.dart';

main() async {
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
