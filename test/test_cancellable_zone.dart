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
  });
}
