import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('Future.bindCancellable', () {
    late Cancellable cancellable;

    setUp(() {
      cancellable = Cancellable();
    });

    test('should complete normally when available', () async {
      final future = Future.value(123).bindCancellable(cancellable);
      expect(await future, 123);
    });

    test('should complete with error when available', () async {
      final future = Future<int>.error('error').bindCancellable(cancellable);
      await expectLater(future, throwsA('error'));
    });

    test(
        'should not execute then/catchError when cancelled before source completion (default)',
        () async {
      final completer = Completer<int>();
      final future = completer.future.bindCancellable(cancellable);

      var completed = false;
      future.then((_) => completed = true).catchError((_) => completed = true);

      cancellable.cancel();
      completer.complete(123);

      await Future.delayed(Duration(milliseconds: 10));
      expect(completed, isFalse);
    });

    test(
        'should throw CancelledException when cancelled and throwWhenCancel is true',
        () async {
      final completer = Completer<int>();
      final future =
          completer.future.bindCancellable(cancellable, throwWhenCancel: true);

      // 1. 先设置监听期待
      final expectFuture = expectLater(
          future,
          throwsA(isA<CancelledException>()
              .having((e) => e.reason, 'reason', 'test reason')));

      // 2. 再执行可能触发异常的操作
      cancellable.cancel('test reason');

      // 3. 等待测试完成
      await expectFuture;
    });

    test('should throw onCancel error when cancelled', () async {
      final completer = Completer<int>();
      final future = completer.future.bindCancellable(
        cancellable,
        onCancel: (ex) => throw 'onCancel error',
      );

      // 1. 建立监听
      final expectFuture = expectLater(future, throwsA('onCancel error'));

      // 2. cancel
      cancellable.cancel();

      // 3. 同时验证返回的 future 也正确收到了错误
      await expectFuture;
    });

    test('should return onCancel result (Future) when cancelled', () async {
      final completer = Completer<int>();
      final future = completer.future.bindCancellable(
        cancellable,
        onCancel: (ex) => Future.value(456),
      );

      cancellable.cancel();

      expect(await future, 456);
    });

    test('already cancelled: should return NeverExecFuture (default)',
        () async {
      cancellable.cancel();
      final future = Future.value(123).bindCancellable(cancellable);

      var completed = false;
      future.then((_) => completed = true).catchError((_) => completed = true);

      await Future.delayed(Duration(milliseconds: 10));
      expect(completed, isFalse);
    });

    test('already cancelled: should return onCancel result', () async {
      cancellable.cancel('already');
      final future =
          Future.value(123).bindCancellable(cancellable, onCancel: (ex) => 789);

      expect(await future, 789);
    });

    test('already cancelled: should throw when throwWhenCancel is true',
        () async {
      cancellable.cancel('already');

      final future =
          Future.value(123).bindCancellable(cancellable, throwWhenCancel: true);

      expect(
          future,
          throwsA(isA<CancelledException>()
              .having((e) => e.reason, 'reason', 'already')));
    });

    test(
        'source future already completed but cancellable cancelled before binding',
        () async {
      final completer = Completer<int>();
      final source = completer.future;
      completer.complete(1);
      await source; // wait for it to complete

      cancellable.cancel();
      final future = source.bindCancellable(cancellable, onCancel: (e) => 2);
      expect(await future, 2);
    });

    test('source future error but cancellable cancelled before binding',
        () async {
      final completer = Completer<int>();
      final source = completer.future;
      completer.completeError('err');
      await source.catchError((_) => 0); // let it complete

      cancellable.cancel();
      final future = source.bindCancellable(cancellable, onCancel: (e) => 2);
      expect(await future, 2);
    });
  });
}
