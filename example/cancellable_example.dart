import 'package:cancellable/cancellable.dart';

main() {
  Cancellable cancellable = Cancellable();

  var sub =
      Stream.periodic(Duration(milliseconds: 100), (i) => i).listen((event) {
    print(event);
  });

  sub.cancelByCancellable(
      cancellable); //  cancellable.whenCancel.then((value) => sub.cancel());

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
}
