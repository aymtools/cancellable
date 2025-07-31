import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('CancellableAny', () {
    test('sync', () {
      CancellableAny manager = CancellableAny();

      Cancellable cancellable = Cancellable();

      manager.add(cancellable);
      cancellable.cancel();

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
    });

    test('async', () async {
      CancellableAny manager = CancellableAny.async();

      Cancellable cancellable = Cancellable();

      manager.add(cancellable);
      cancellable.cancel();

      expect(manager.isAvailable, true);
      await Future.delayed(Duration.zero);
      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
    });

    test('manager cancel', () {
      CancellableAny manager = CancellableAny();

      Cancellable cancellable = Cancellable();

      manager.add(cancellable);
      manager.cancel();

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
    });

    test('manager cancel async', () async {
      CancellableAny manager = CancellableAny.async();
      Cancellable cancellable = Cancellable();
      manager.add(cancellable);
      manager.cancel();

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      await Future.delayed(Duration.zero);
      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
    });
  });

  group('CancellableEvery', () {
    test('sync', () {
      CancellableEvery manager = CancellableEvery();

      Cancellable cancellable = Cancellable();
      Cancellable cancellable2 = Cancellable();
      manager.add(cancellable);
      manager.add(cancellable2);
      cancellable.cancel();

      expect(manager.isAvailable, true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, true);
      cancellable2.cancel();
      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('async', () async {
      CancellableEvery manager = CancellableEvery.async();

      Cancellable cancellable = Cancellable();
      Cancellable cancellable2 = Cancellable();
      manager.add(cancellable);
      manager.add(cancellable2);
      cancellable.cancel();

      expect(manager.isAvailable, true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, true);

      await Future.delayed(Duration.zero);
      expect(manager.isAvailable, true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, true);

      cancellable2.cancel();
      expect(manager.isAvailable, true);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);

      await Future.delayed(Duration.zero);

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('manager cancel', () {
      CancellableEvery manager = CancellableEvery();
      Cancellable cancellable = Cancellable();
      Cancellable cancellable2 = Cancellable();
      manager.add(cancellable);
      manager.add(cancellable2);

      expect(manager.isAvailable, true);
      expect(cancellable.isAvailable, true);
      expect(cancellable2.isAvailable, true);
      manager.cancel();

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });

    test('manager cancel async', () async {
      CancellableEvery manager = CancellableEvery.async();
      Cancellable cancellable = Cancellable();
      Cancellable cancellable2 = Cancellable();
      manager.add(cancellable);
      manager.add(cancellable2);

      manager.cancel();

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);

      await Future.delayed(Duration.zero);

      expect(manager.isAvailable, false);
      expect(cancellable.isAvailable, false);
      expect(cancellable2.isAvailable, false);
    });
  });
}
