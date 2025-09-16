import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('async', () {
    test('not cancel', () async {
      Cancellable cancellable = Cancellable();
      CancellableCompleter<int> computer = CancellableCompleter(cancellable);

      int testValue = 0;
      computer.future.then((v) => testValue = v);

      expect(testValue, 0);

      computer.complete(1);

      cancellable.cancel();
      await Future.delayed(Duration.zero);
      expect(testValue, 1);
    });

    test('cancel', () async {
      Cancellable cancellable = Cancellable();
      CancellableCompleter<int> computer = CancellableCompleter(cancellable);
      int testValue = 0;
      Object? error;
      Future<void> testAsync() async {
        try {
          testValue = await computer.future;
        } catch (e) {
          error = e;
        }
      }

      testAsync();

      expect(testValue, 0);
      expect(error, isNull);
      cancellable.cancel();
      computer.complete(1);
      await Future.delayed(Duration.zero);
      expect(testValue, 0);
      expect(error, isNotNull);
      expect(error, isA<CancelledException>());
    });

    test('cancel throwWhenCancel: false', () async {
      Cancellable cancellable = Cancellable();
      CancellableCompleter<int> computer =
          CancellableCompleter(cancellable, throwWhenCancel: false);
      int testValue = 0;
      computer.future.then((v) => testValue = v);
      expect(testValue, 0);
      cancellable.cancel();
      expect(testValue, 0);
    });

    test('cancel has whenCancel', () async {
      Cancellable cancellable = Cancellable();
      int testValue = 0;
      Object? error;
      CancellableCompleter<int> computer =
          CancellableCompleter(cancellable, whenCancel: () => 2);

      Future<void> testAsync() async {
        try {
          testValue = await computer.future;
        } catch (e) {
          error = e;
        }
      }

      testAsync();

      expect(testValue, 0);
      expect(error, isNull);
      cancellable.cancel();
      computer.complete(1);
      await Future.delayed(Duration.zero);
      expect(testValue, 2);
      expect(error, isNull);
    });
  });

  group('sync', () {
    test('not cancel', () {
      Cancellable cancellable = Cancellable();
      CancellableCompleter computer = CancellableCompleter.sync(cancellable);
      int testValue = 0;
      computer.future.then((_) => testValue++);
      expect(testValue, 0);
      computer.complete();
      cancellable.cancel();
      expect(testValue, 1);
    });

    test('cancel', () {
      Cancellable cancellable = Cancellable();
      CancellableCompleter<int> computer =
          CancellableCompleter.sync(cancellable);
      int testValue = 0;
      Object? error;
      Future<void> testAsync() async {
        try {
          testValue = await computer.future;
        } catch (e) {
          error = e;
        }
      }

      testAsync();
      expect(testValue, 0);
      expect(error, isNull);
      cancellable.cancel();
      computer.complete(1);
      expect(testValue, 0);
      expect(error, isNotNull);
      expect(error, isA<CancelledException>());
    });

    test('cancel throwOnCancel: false', () {
      Cancellable cancellable = Cancellable();
      CancellableCompleter<int> computer =
          CancellableCompleter.sync(cancellable, throwOnCancel: false);
      int testValue = 0;
      Object? error;
      Future<void> testAsync() async {
        try {
          testValue = await computer.future;
        } catch (e) {
          error = e;
        }
      }

      testAsync();

      expect(testValue, 0);
      expect(error, isNull);
      cancellable.cancel();
      expect(testValue, 0);
      expect(error, isNull);
    });

    test('cancel has onCancel', () {
      Cancellable cancellable = Cancellable();
      int testValue = 0;
      Object? error;
      CancellableCompleter<int> computer =
          CancellableCompleter.sync(cancellable, onCancel: () => 2);
      Future<void> testAsync() async {
        try {
          testValue = await computer.future;
        } catch (e) {
          error = e;
        }
      }

      testAsync();
      expect(testValue, 0);
      expect(error, isNull);
      cancellable.cancel();
      computer.complete(1);
      expect(testValue, 2);
      expect(error, isNull);
    });
  });
}
