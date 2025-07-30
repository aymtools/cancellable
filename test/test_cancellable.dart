import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('Available', () {
    test('Cancellable.canceled()', () {
      Cancellable cancellable = Cancellable.cancelled();
      expect(cancellable.isAvailable, false);
      expect(cancellable.isUnavailable, true);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
    });
    test('Cancellable()', () {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      expect(cancellable.isUnavailable, false);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(cancellable.isUnavailable, true);
    });

    test('makeCancellable()', () {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);

      final cancellable2 = cancellable.makeCancellable();
      expect(cancellable2.isAvailable, true);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });
    test('makeCancellable() infectious: true', () {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);

      final cancellable2 = cancellable.makeCancellable(infectious: true);
      expect(cancellable2.isAvailable, true);
      cancellable2.cancel();
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('makeCancellable()  father not null', () {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);

      Cancellable father = Cancellable();
      expect(father.isAvailable, true);

      final cancellable2 = cancellable.makeCancellable(father: father);
      expect(cancellable.isAvailable, true);
      expect(cancellable2.isAvailable, true);
      expect(father.isAvailable, true);

      father.cancel();
      expect(cancellable.isAvailable, true);
      expect(father.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('makeCancellable() father not null infectious: true', () {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      Cancellable father = Cancellable();
      expect(father.isAvailable, true);

      final cancellable2 =
          cancellable.makeCancellable(father: father, infectious: true);
      expect(cancellable.isAvailable, true);
      expect(cancellable2.isAvailable, true);
      expect(father.isAvailable, true);

      cancellable2.cancel();
      expect(cancellable.isAvailable, false);
      expect(father.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('canceled makeCancellable() father not null infectious: true', () {
      Cancellable cancellable = Cancellable.cancelled();
      expect(cancellable.isAvailable, false);
      Cancellable father = Cancellable();
      expect(father.isAvailable, true);

      final cancellable2 =
          cancellable.makeCancellable(father: father, infectious: true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
      expect(father.isAvailable, false);

      cancellable2.cancel();
      expect(cancellable.isAvailable, false);
      expect(father.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });
  });

  group('cancel then', () {
    test('Cancellable.canceled() onCancel', () {
      int testValue = 0;
      Cancellable cancellable = Cancellable.cancelled();
      expect(testValue, 0);
      expect(cancellable.isAvailable, false);
      cancellable.onCancel.then((_) => testValue++);
      expect(testValue, 1);
    });

    test('onCancel', () {
      int testValue = 0;
      Cancellable cancellable = Cancellable();
      expect(testValue, 0);
      cancellable.onCancel.then((_) => testValue++);
      expect(testValue, 0);
      cancellable.cancel();
      expect(testValue, 1);
      cancellable.onCancel.then((_) => testValue++);
      expect(testValue, 2);
    });

    test(
        'onCancel for canceled makeCancellable() father not null infectious: true',
        () {
      Cancellable cancellable = Cancellable.cancelled();
      expect(cancellable.isAvailable, false);
      Cancellable father = Cancellable();
      expect(father.isAvailable, true);

      int testValue = 0;
      cancellable.onCancel.then((_) => testValue++);
      expect(testValue, 1);
      father.onCancel.then((_) => testValue++);
      expect(testValue, 1);
      final cancellable2 =
          cancellable.makeCancellable(father: father, infectious: true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
      expect(father.isAvailable, false);

      expect(testValue, 2);
      cancellable2.onCancel.then((_) => testValue++);
      expect(testValue, 3);

      cancellable2.cancel();
      expect(testValue, 3);

      cancellable2.onCancel.then((_) => testValue++);
      expect(testValue, 4);
    });

    test('whenCancel', () {
      int testValue = 0;
      Cancellable cancellable = Cancellable();
      expect(testValue, 0);
      cancellable.whenCancel.then((_) => testValue++);
      expect(testValue, 0);
      cancellable.cancel();
      expect(testValue, 0);

      Future.delayed(Duration.zero).then((_) {
        expect(testValue, 1);
      });

      expect(testValue, 0);
    });

    test('cancelled reason', () {
      String reason = 'test reason';
      String test = '';
      Cancellable cancellable = Cancellable.cancelled(reason);
      expect(test, '');
      expect(cancellable.reasonAsException, isNotNull);
      cancellable.onCancel.then((e) => test = e.reason);

      expect(cancellable.reasonAsException?.reason, reason);
      expect(test, reason);
    });

    test('reason', () {
      String reason = 'test reason';
      String test = '';
      Cancellable cancellable = Cancellable();
      expect(test, '');
      cancellable.onCancel.then((e) => test = e.reason);
      expect(test, '');
      expect(cancellable.reasonAsException, isNull);
      cancellable.cancel(reason);
      expect(test, reason);
      expect(cancellable.reasonAsException?.reason, reason);
    });
  });

  group('Future cancel', () {
    test('cancelFuture throwWhenCancel:false', () async {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      int testValue = 0;
      Object? error;

      expect(testValue, 0);
      expect(error, isNull);

      void testFunc() async {
        try {
          await delayFuture()
              .bindCancellable(cancellable, throwWhenCancel: false);
          testValue++;
        } catch (e) {
          error = e;
        }
      }

      testFunc();

      await Future.delayed(Duration(seconds: 1));

      expect(testValue, 0);
      expect(error, isNull);

      cancellable.cancel();

      expect(testValue, 0);
      expect(error, isNull);

      await Future.delayed(Duration(seconds: 2));

      expect(testValue, 0);
      expect(error, isNull);
    });

    test('cancelFuture throwWhenCancel:true', () async {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      int testValue = 0;
      Object? error;

      expect(testValue, 0);
      expect(error, isNull);

      void testFunc() async {
        try {
          await delayFuture()
              .bindCancellable(cancellable, throwWhenCancel: true);
          testValue++;
        } catch (e) {
          error = e;
        }
      }

      testFunc();

      await Future.delayed(Duration(seconds: 1));

      expect(testValue, 0);
      expect(error, isNull);

      cancellable.cancel();

      expect(testValue, 0);
      expect(error, isNotNull);

      await Future.delayed(Duration(seconds: 2));

      expect(testValue, 0);
      expect(error, isNotNull);
      expect(error, isA<CancelledException>());
    });
  });

  group('Stream cancel', () {
    test('auto cancel sub', () async {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      int testValue = 0;
      bool done = false;
      Stream.periodic(Duration(seconds: 1), (i) => i)
          .bindCancellable(cancellable)
          .listen(
        (event) {
          testValue++;
        },
        onDone: () {
          done = true;
        },
      );
      expect(testValue, 0);
      expect(done, false);
      await Future.delayed(Duration(seconds: 2, milliseconds: 500));
      expect(testValue, 2);
      expect(done, false);

      cancellable.cancel();

      expect(testValue, 2);
      expect(done, false);
      await Future.delayed(Duration(seconds: 2));
      expect(testValue, 2);
      expect(done, true);
    });

    test('auto cancel sub not close', () async {
      Cancellable cancellable = Cancellable();
      expect(cancellable.isAvailable, true);
      int testValue = 0;
      bool done = false;
      Stream.periodic(Duration(seconds: 1), (i) => i)
          .bindCancellable(cancellable, closeWhenCancel: false)
          .listen(
        (event) {
          testValue++;
        },
        onDone: () {
          done = true;
        },
      );
      expect(testValue, 0);
      expect(done, false);
      await Future.delayed(Duration(seconds: 2, milliseconds: 500));
      expect(testValue, 2);
      expect(done, false);

      cancellable.cancel();

      expect(testValue, 2);
      expect(done, false);
      await Future.delayed(Duration(seconds: 2));
      expect(testValue, 2);
      expect(done, false);
    });
  });

  group('StreamController cancel', () {
    test('closeWhenCancel: true', () async {
      int testValue = 0;
      final controller = StreamController(onCancel: () => testValue++);
      Cancellable cancellable = Cancellable();
      controller.bindCancellable(cancellable);
      expect(controller.isClosed, false);
      expect(cancellable.isAvailable, true);
      expect(testValue, 0);
      cancellable.cancel();
      await Future.delayed(Duration.zero);
      expect(controller.isClosed, true);
      expect(cancellable.isAvailable, false);
      expect(testValue, 0);
    });

    test('closeWhenCancel: false', () async {
      int testValue = 0;
      final controller = StreamController(onCancel: () => testValue++);
      Cancellable cancellable = Cancellable();
      controller.bindCancellable(cancellable, closeWhenCancel: false);
      expect(controller.isClosed, false);
      expect(cancellable.isAvailable, true);
      expect(testValue, 0);
      cancellable.cancel();
      await Future.delayed(Duration.zero);
      expect(controller.isClosed, false);
      expect(cancellable.isAvailable, false);
      expect(testValue, 1);
    });
  });
}

Future<void> delayFuture() async {
  await Future.delayed(Duration(seconds: 2));
}
