import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  test('bindCancellable', () {
    Cancellable cancellable = Cancellable();
    expect(cancellable.isAvailable, true);
    Cancellable cancellable2 = Cancellable();
    expect(cancellable2.isAvailable, true);

    cancellable.bindCancellable(cancellable2);
    cancellable.cancel();
    expect(cancellable.isAvailable, false);
    expect(cancellable2.isAvailable, false);
  });
  test('bindCancellable cancel2', () {
    Cancellable cancellable = Cancellable();
    expect(cancellable.isAvailable, true);
    Cancellable cancellable2 = Cancellable();
    expect(cancellable2.isAvailable, true);

    cancellable.bindCancellable(cancellable2);
    cancellable2.cancel();
    expect(cancellable.isAvailable, false);
    expect(cancellable2.isAvailable, false);
  });
}
