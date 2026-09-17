import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('CancellableFuture basic completion', () {
    test('should resolve with value when source future succeeds', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture(Future.value(42), cancellable);

      final result = await future;
      expect(result, equals(42));
    });

    test('should fail with error when source future throws error', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture<int>(
        Future.error(StateError('something went wrong')),
        cancellable,
      );

      await expectLater(future, throwsA(isA<StateError>()));
    });

    test('should resolve value asynchronously when using Completer', () async {
      final cancellable = Cancellable();
      final completer = Completer<String>();
      final future = CancellableFuture(completer.future, cancellable);

      completer.complete('hello');
      expect(await future, equals('hello'));
    });
  });

  group('CancellableFuture cancellation', () {
    test('should throw CancelledException when cancelled via Cancellable', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      final expectFuture = expectLater(
        future,
        throwsA(isA<CancelledException>()),
      );

      cancellable.cancel();
      completer.complete(100);

      await expectFuture;
    });

    test('should throw CancelledException with custom reason when cancelled via Cancellable', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      final expectFuture = expectLater(
        future,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'custom_reason')),
      );

      cancellable.cancel('custom_reason');

      await expectFuture;
    });

    test('should cancel via CancellableFuture.cancel() method', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      final expectFuture = expectLater(
        future,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'future_cancel_reason')),
      );

      future.cancel('future_cancel_reason');

      await expectFuture;
    });
  });

  group('CancellableFuture.cancelled constructor', () {
    test('should create an immediately cancelled future by default', () async {
      final future = CancellableFuture<int>.cancelled();

      await expectLater(
        future,
        throwsA(isA<CancelledException>()),
      );
    });

    test('should use provided cancelled Cancellable with reason', () async {
      final cancellable = Cancellable.cancelled('pre_cancelled');
      final future = CancellableFuture<int>.cancelled(cancellable);

      await expectLater(
        future,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'pre_cancelled')),
      );
    });

    test('should throw AssertionError when passing an available Cancellable', () {
      final availableCancellable = Cancellable();
      expect(
        () => CancellableFuture<int>.cancelled(availableCancellable),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('then method', () {
    test('should invoke onValue when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture(Future.value(10), cancellable);

      final result = await future.then((val) => val * 2);
      expect(result, equals(20));
    });

    test('should handle source error via onError callback when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture<int>(
        Future.error('error_val'),
        cancellable,
      );

      final result = await future.then(
        (val) => val,
        onError: (err) => 999,
      );

      expect(result, equals(999));
    });

    test('should trigger onError when already unavailable', () async {
      final cancellable = Cancellable.cancelled('cancelled_reason');
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final result = await future.then(
        (val) => val * 2,
        onError: (err) {
          expect(err, isA<CancelledException>());
          return 500;
        },
      );

      expect(result, equals(500));
    });

    test('should trigger onError accepting (Object, StackTrace) when unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final result = await future.then(
        (val) => val,
        onError: (err, stack) {
          expect(err, isA<CancelledException>());
          expect(stack, isA<StackTrace>());
          return 888;
        },
      );

      expect(result, equals(888));
    });

    test('should return Future.error when unavailable and onError is null', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      await expectLater(
        future.then((val) => val),
        throwsA(isA<CancelledException>()),
      );
    });

    test('should throw ArgumentError when onError has invalid signature and unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      await expectLater(
        future.then(
          (val) => val,
          onError: () => 123,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return Future from onError when onError returns a Future and unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final result = await future.then(
        (val) => val,
        onError: (err) => Future.value(777),
      );

      expect(result, equals(777));
    });

    test('should propagate error thrown inside onError when unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      await expectLater(
        future.then(
          (val) => val,
          onError: (err) => throw Exception('error_in_onError'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('catchError method', () {
    test('should handle source error when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture<int>(
        Future.error('err'),
        cancellable,
      );

      final result = await future.catchError((e) => 123);
      expect(result, equals(123));
    });

    test('should handle CancelledException when unavailable and test is null', () async {
      final cancellable = Cancellable.cancelled('stop');
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final result = await future.catchError((e) {
        expect(e, isA<CancelledException>());
        return 456;
      });

      expect(result, equals(456));
    });

    test('should handle error when test returns true and unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final result = await future.catchError(
        (e) => 321,
        test: (e) => e is CancelledException,
      );

      expect(result, equals(321));
    });

    test('should rethrow error when test returns false and unavailable', () async {
      final cancellable = Cancellable.cancelled();
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      await expectLater(
        future.catchError(
          (e) => 321,
          test: (e) => e is StateError,
        ),
        throwsA(isA<CancelledException>()),
      );
    });
  });

  group('timeout method', () {
    test('should complete normally within time limit when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture(
        Future.delayed(Duration(milliseconds: 10), () => 100),
        cancellable,
      );

      final result = await future.timeout(Duration(milliseconds: 100));
      expect(result, equals(100));
    });

    test('should timeout and invoke onTimeout when available', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      final result = await future.timeout(
        Duration(milliseconds: 10),
        onTimeout: () => 99,
      );

      expect(result, equals(99));
    });

    test('should throw TimeoutException when timing out without onTimeout when available', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      await expectLater(
        future.timeout(Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should immediately return Future.error when unavailable', () async {
      final cancellable = Cancellable.cancelled('already_done');
      final future = CancellableFuture<int>(
        Future.delayed(Duration(seconds: 10), () => 100),
        cancellable,
      );

      await expectLater(
        future.timeout(Duration(hours: 1)),
        throwsA(isA<CancelledException>()),
      );
    });
  });

  group('whenComplete method', () {
    test('should execute action when available and future succeeds', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture(Future.value(10), cancellable);
      var completed = false;

      final result = await future.whenComplete(() {
        completed = true;
      });

      expect(completed, isTrue);
      expect(result, equals(10));
    });

    test('should execute action when available and future fails', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture<int>(Future.error('err'), cancellable);
      var completed = false;

      await expectLater(
        future.whenComplete(() {
          completed = true;
        }),
        throwsA('err'),
      );

      expect(completed, isTrue);
    });

    test('should execute synchronous action when unavailable and return original future error', () async {
      final cancellable = Cancellable.cancelled('cancelled');
      final future = CancellableFuture<int>(Future.value(10), cancellable);
      var actionCalled = false;

      await expectLater(
        future.whenComplete(() {
          actionCalled = true;
        }),
        throwsA(isA<CancelledException>()),
      );

      expect(actionCalled, isTrue);
    });

    test('should execute asynchronous action when unavailable', () async {
      final cancellable = Cancellable.cancelled('cancelled');
      final future = CancellableFuture<int>(Future.value(10), cancellable);
      var actionCalled = false;

      await expectLater(
        future.whenComplete(() async {
          await Future.delayed(Duration(milliseconds: 10));
          actionCalled = true;
        }),
        throwsA(isA<CancelledException>()),
      );

      expect(actionCalled, isTrue);
    });

    test('should propagate error thrown by action when unavailable', () async {
      final cancellable = Cancellable.cancelled('cancelled');
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      await expectLater(
        future.whenComplete(() {
          throw FormatException('action_failed');
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('asStream method', () {
    test('should emit value and close when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture(Future.value(42), cancellable);

      expect(await future.asStream().toList(), equals([42]));
    });

    test('should emit source error when available', () async {
      final cancellable = Cancellable();
      final future = CancellableFuture<int>(Future.error('stream_error'), cancellable);

      expect(
        future.asStream(),
        emitsError('stream_error'),
      );
    });

    test('should emit CancelledException when cancelled while listening', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final future = CancellableFuture(completer.future, cancellable);

      final stream = future.asStream();
      final expectStream = expectLater(
        stream,
        emitsError(isA<CancelledException>()),
      );

      cancellable.cancel();

      await expectStream;
    });

    test('should emit CancelledException immediately when unavailable', () async {
      final cancellable = Cancellable.cancelled('stream_cancelled');
      final future = CancellableFuture<int>(Future.value(10), cancellable);

      final stream = future.asStream();
      await expectLater(
        stream,
        emitsError(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'stream_cancelled')),
      );
    });
  });

  group('AsCancellableFutureExt', () {
    test('should wrap Future with default Cancellable when cancellable is null', () async {
      final cancellableFuture = Future.value(100).asCancellableFuture();

      expect(cancellableFuture, isA<CancellableFuture<int>>());
      expect(await cancellableFuture, equals(100));
    });

    test('should allow cancelling created CancellableFuture when default Cancellable is used', () async {
      final completer = Completer<int>();
      final cancellableFuture = completer.future.asCancellableFuture();

      final expectFuture = expectLater(
        cancellableFuture,
        throwsA(isA<CancelledException>()),
      );

      cancellableFuture.cancel('cancelled_default');

      await expectFuture;
    });

    test('should wrap Future with explicitly provided Cancellable and allow cancelling via Cancellable', () async {
      final cancellable = Cancellable();
      final completer = Completer<String>();
      final cancellableFuture = completer.future.asCancellableFuture(cancellable: cancellable);

      final expectFuture = expectLater(
        cancellableFuture,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'explicit_cancel')),
      );

      cancellable.cancel('explicit_cancel');

      await expectFuture;
    });

    test('should allow cancelling via cancellableFuture.cancel() directly when explicit Cancellable is provided', () async {
      final cancellable = Cancellable();
      final completer = Completer<int>();
      final cancellableFuture = completer.future.asCancellableFuture(cancellable: cancellable);

      final expectFuture = expectLater(
        cancellableFuture,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'cancel_via_future')),
      );

      cancellableFuture.cancel('cancel_via_future');

      expect(cancellable.isUnavailable, isTrue);
      await expectFuture;
    });

    test('should complete normally when provided Cancellable is not cancelled', () async {
      final cancellable = Cancellable();
      final cancellableFuture = Future.value('success').asCancellableFuture(cancellable: cancellable);

      expect(await cancellableFuture, equals('success'));
    });

    test('should fail immediately if provided Cancellable is already cancelled', () async {
      final cancellable = Cancellable.cancelled('already_cancelled');
      final cancellableFuture = Future.value('val').asCancellableFuture(cancellable: cancellable);

      await expectLater(
        cancellableFuture,
        throwsA(isA<CancelledException>()
            .having((e) => e.reason, 'reason', 'already_cancelled')),
      );
    });
  });
}
