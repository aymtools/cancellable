import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('zone', () {
    test('is inCancellableZone', () {
      expect(Zone.current.isCancellableZone, false);
      expect(Zone.current.isCancellableActive, true);
      int hash = Zone.current.hashCode;
      Cancellable cancellable = Cancellable();
      cancellable.withRunZone(() {
        expect(Zone.current.isCancellableZone, true);
        expect(Zone.current.hashCode == hash, false);
        expect(Zone.current.isCancellableActive, true);

        runNotInCancellableZone(() {
          expect(Zone.current.isCancellableZone, false);
          expect(Zone.current.hashCode, hash);
          expect(Zone.current.isCancellableActive, true);
        });
      });
    });

    test('cancel', () async {
      Cancellable cancellable = Cancellable();
      int testValue = 0;
      cancellable.withRunZone(() async {
        expect(Zone.current.isCancellableZone, true);
        expect(Zone.current.isCancellableActive, true);
        Zone.current.ensureCancellableActive();
        expect(Zone.current.isCancellableActive, true);
        testValue++;
        await Future.delayed(Duration(seconds: 1, milliseconds: 200));
        testValue++;
      });

      await Future.delayed(Duration(seconds: 1));
      cancellable.cancel();
      expect(Zone.current.isCancellableZone, false);
      expect(Zone.current.isCancellableActive, true);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 1);
      await Future.delayed(Duration(milliseconds: 500));
      expect(testValue, 1);
    });

    test('zone in zone', () {
      Cancellable cancellable = Cancellable();
      Cancellable? zone2Cancellable;
      Cancellable? zone3Cancellable;
      Cancellable? zone3CancellableChild;
      // final rootZone = Zone.root;
      final zone1 = Zone.current;
      // expect(zone1, rootZone);
      cancellable.withRunZone(() {
        expect(Zone.current.isCancellableZone, true);
        expect(Zone.current.isCancellableActive, true);
        Zone.current.ensureCancellableActive();
        expect(Zone.current.isCancellableActive, true);
        final zone2 = Zone.current;
        expect(zone2, isNot(zone1));
        zone2Cancellable = zone2.cancellable;

        runWhenCancellableZone((cancellable) {
          expect(zone2Cancellable, isNot(cancellable));
        });

        runZoned(() {
          expect(Zone.current.isCancellableZone, true);
          expect(Zone.current.isCancellableActive, true);
          Zone.current.ensureCancellableActive();
          expect(Zone.current.isCancellableActive, true);

          final zone3 = Zone.current;
          expect(zone3, isNot(zone2));
          zone3Cancellable = zone3.cancellable;

          runWhenCancellableZone((cancellable) {
            expect(zone3Cancellable, isNot(cancellable));
            zone3CancellableChild = cancellable;
          });
        });
      }, forkZoneWithCancellable: true);

      expect(zone2Cancellable, isNotNull);
      expect(zone3Cancellable, isNotNull);
      expect(zone3CancellableChild, isNotNull);

      expect(zone2Cancellable, isNot(zone3Cancellable));

      final tester = zone2Cancellable?.makeCancellable();

      zone2Cancellable?.cancel();
      expect(zone2Cancellable, equals(cancellable));

      expect(cancellable.isAvailable, isFalse);
      expect(zone2Cancellable?.isAvailable, isFalse);
      expect(tester?.isAvailable, isFalse);
      expect(zone3Cancellable?.isAvailable, isFalse);
      expect(zone3CancellableChild?.isAvailable, isFalse);
    });

    test('zone stream cancel', () async {
      Cancellable cancellable = Cancellable();
      Stream<int> stream = _createStream();
      int testValue = 0;
      cancellable.withRunZone(() {
        stream.listen((event) => testValue = event);
      });

      expect(testValue, 0);
      await Future.delayed(Duration(milliseconds: 50));
      cancellable.cancel();
      expect(testValue, 0);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 0);
    });

    test('zone cancel', () async {
      Cancellable cancellable = Cancellable();
      late Stream<int> stream;
      int testValue = 0;
      cancellable.withRunZone(() {
        stream = _createStream();
        stream.listen((event) => testValue = event);
      });

      expect(testValue, 0);
      await Future.delayed(Duration(milliseconds: 50));
      cancellable.cancel();
      expect(testValue, 0);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 0);
    });

    test('zone cancel 2', () async {
      Cancellable cancellable = Cancellable();
      late Stream<int> stream;
      late StreamSubscription<int> subscription;
      int testValue = 0;
      cancellable.withRunZone(() {
        stream = _createStream();
        subscription = stream.listen((event) => testValue = event);
      });
      expect(testValue, 0);

      await Future.delayed(Duration(milliseconds: 50));
      expect(testValue, 0);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 1);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 2);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 3);
      cancellable.cancel();
      expect(testValue, 3);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 3);
      await Future.delayed(Duration(milliseconds: 100));
      expect(testValue, 3);
    });
  });
}

Stream<int> _createStream() async* {
  print('object ${Zone.current.isCancellableZone}');
  await Future.delayed(Duration(milliseconds: 100));
  yield 1;
  await Future.delayed(Duration(milliseconds: 100));
  yield 2;
  await Future.delayed(Duration(milliseconds: 100));
  yield 3;
  await Future.delayed(Duration(milliseconds: 100));
  yield 4;
  await Future.delayed(Duration(milliseconds: 100));
  yield 5;
}
