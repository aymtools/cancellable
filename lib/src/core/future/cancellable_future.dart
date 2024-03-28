// import 'dart:async';
//
// import 'package:cancellable/cancellable.dart';
//
// abstract class CancellableFuture<T> implements Future<T> {}
//
// class CancellableFutureProxy<T> implements Future<T> {
//   final Future<T> source;
//   final Cancellable cancellable = Cancellable();
//   final Completer<T> errCompleter = Completer();
//
//   CancellableFutureProxy(this.source, [Cancellable? cancellable]) {
//     this.cancellable.bindCancellable(cancellable).whenCancel.then((value) {});
//   }
//
//   void cancel([dynamic reason]) {
//     cancellable.cancel(reason);
//   }
//
//   @override
//   Stream<T> asStream() {
//     if (cancellable.isUnavailable) {
//       return Stream.error(
//           CancelledException(cancellable.reason), StackTrace.current);
//     }
//     return source.asStream().bindCancellable(cancellable);
//   }
//
//   @override
//   CancellableFutureProxy<T> catchError(Function onError,
//       {bool Function(Object error)? test}) {
//     return this;
//   }
//
//   @override
//   CancellableFutureProxy<R> then<R>(FutureOr<R> Function(T value) onValue,
//       {Function? onError}) {
//     // TODO: implement then
//     throw UnimplementedError();
//   }
//
//   @override
//   CancellableFutureProxy<T> timeout(Duration timeLimit,
//       {FutureOr<T> Function()? onTimeout}) {
//     // TODO: implement timeout
//     throw UnimplementedError();
//   }
//
//   @override
//   CancellableFutureProxy<T> whenComplete(FutureOr<void> Function() action) {
//     if (source is CancellableFutureProxy<T>) {
//       return source.whenComplete(action) as CancellableFutureProxy<T>;
//     }
//     source.whenComplete(() async {
//       if (cancellable.isAvailable) {
//         action.call();
//       }
//     });
//     return this;
//   }
// }
