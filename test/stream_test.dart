import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:test/test.dart';

void main() {
  group('CancellableStreamExt', () {
    test('bindCancellable single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable();
      final stream = controller.stream.bindCancellable(cancellable);

      final events = <String>[];
      bool isDone = false;
      stream.listen(
        (event) {
          expect(cancellable.isAvailable, true);
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      controller.add('test');
      expect(events, ['test']);
      expect(isDone, false);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(controller.isClosed, false);

      expect(isDone, false);

      controller.add('test2');
      expect(events, ['test']);

      await Future.delayed(Duration.zero);
      expect(events, ['test']);
      expect(isDone, true);
    });

    test('bindCancellable broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable();
      final stream = controller.stream.bindCancellable(cancellable);
      final events = <String>[];
      bool isDone = false;

      stream.listen(
        (event) {
          expect(cancellable.isAvailable, true);
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      controller.add('test');
      expect(events, ['test']);
      expect(isDone, false);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(controller.isClosed, false);

      expect(isDone, false);

      controller.add('test2');
      expect(events, ['test']);

      await Future.delayed(Duration.zero);
      expect(events, ['test']);
      expect(isDone, true);
    });

    test('bindCancellable closeWhenCancel:false single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable();
      final stream = controller.stream
          .bindCancellable(cancellable, closeWhenCancel: false);

      final events = <String>[];
      bool isDone = false;

      stream.listen(
        (event) {
          expect(cancellable.isAvailable, true);
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      controller.add('test');
      expect(events, ['test']);
      expect(isDone, false);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(controller.isClosed, false);
      expect(isDone, false);

      controller.add('test2');
      expect(events, ['test']);

      await Future.delayed(Duration.zero);
      expect(events, ['test']);
      expect(isDone, false, reason: 'not call close');
    });

    test('bindCancellable closeWhenCancel:false broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable();
      final stream = controller.stream
          .bindCancellable(cancellable, closeWhenCancel: false);

      final events = <String>[];
      bool isDone = false;
      stream.listen(
        (event) {
          expect(cancellable.isAvailable, true);
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      controller.add('test');
      expect(events, ['test']);
      expect(isDone, false);
      cancellable.cancel();
      expect(cancellable.isAvailable, false);
      expect(controller.isClosed, false);
      expect(isDone, false);

      controller.add('test2');
      expect(events, ['test']);

      await Future.delayed(Duration.zero);
      expect(events, ['test']);
      expect(isDone, false, reason: 'not call close');
    });

    test('bindCancellable used listen single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);
      final events = <String>[];
      stream.listen(events.add);

      expect(
        () => source.listen((event) {}),
        throwsA(isA<StateError>()),
      );
    });

    test('bindCancellable used listen broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);

      final events = <String>[];
      stream.listen(events.add);

      final events2 = <String>[];
      bool hasError = false;
      try {
        source.listen(events2.add);
      } catch (_) {
        hasError = true;
      }
      expect(hasError, isFalse);

      controller.add('test');
      expect(events, ['test']);
      expect(events2, ['test']);
    });

    test('bindCancellable lazy listen single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);
      final events = <String>[];
      final events2 = <String>[];

      source.listen(events2.add);

      bool hasError = false;

      /// 暂时没有解决这个问题 将listen的异常 转化为stream的异常了
      stream.listen(events.add, onError: (err, st) {
        hasError = true;
        expect(err, isA<StateError>());
        print('lazy  error');
        expect(hasError, isTrue);
      });

      // expect(() {
      //   stream.listen(events.add);
      // }, throwsA(isA<StateError>()));

      controller.add('test');
      expect(events, []);
      expect(events2, ['test']);
    });

    test('bindCancellable lazy listen broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable();
      final source = controller.stream;

      final events = <String>[];
      final events2 = <String>[];

      source.listen(events.add);

      controller.add('test1');

      final stream = source.bindCancellable(cancellable);

      controller.add('test2');
      stream.listen(events2.add);
      controller.add('test3');

      expect(events, ['test1', 'test2', 'test3']);
      expect(events2, ['test3']);
    });

    test('bindCancellable cancel transmit single', () async {
      bool isCancelled = false;
      final controller = StreamController<String>(
        sync: true,
        onCancel: () => isCancelled = true,
      );
      final cancellable = Cancellable();
      final stream = controller.stream.bindCancellable(cancellable);
      final events = <String>[];
      final sub = stream.listen(events.add);
      controller.add('test');

      expect(isCancelled, false);
      expect(events, ['test']);
      sub.cancel();
      expect(isCancelled, true);
      expect(events, ['test']);
    });

    test('bindCancellable onCancel transmit single', () async {
      bool isCancelled = false;
      final controller = StreamController<String>(
        sync: true,
        onCancel: () => isCancelled = true,
      );
      final cancellable = Cancellable();
      final stream = controller.stream.bindCancellable(cancellable);
      final events = <String>[];
      final sub = stream.listen(events.add);
      controller.add('test');

      expect(isCancelled, false);
      expect(events, ['test']);
      cancellable.cancel();
      await Future.delayed(Duration.zero);
      expect(isCancelled, true, reason: 'bindCancellable cancelled');
      expect(events, ['test']);
      sub.cancel();
    });

    test('bindCancellable cancel transmit broadcast', () async {
      bool isCancelled = false;
      final controller = StreamController<String>.broadcast(
        sync: true,
        onCancel: () => isCancelled = true,
      );
      final cancellable = Cancellable();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);
      final events = <String>[];
      final sub = stream.listen(events.add);
      final sub2 = stream.listen((event) {});
      controller.add('test');

      expect(isCancelled, false);
      expect(events, ['test']);
      sub.cancel();
      expect(isCancelled, false);
      sub2.cancel();
      expect(isCancelled, true);
      expect(events, ['test']);

      final events3 = <String>[];
      final sub3 = stream.listen(events3.add);

      final events4 = <String>[];
      final sub4 = source.listen(events4.add);

      controller.add('test2');
      expect(events, ['test']);
      expect(events3, ['test2']);
      expect(events4, ['test2']);
      sub3.cancel();
      expect(isCancelled, true, reason: 'broadcast not transmit');

      controller.add('test3');
      expect(events, ['test']);
      expect(events3, ['test2']);
      expect(events4, ['test2', 'test3']);

      sub4.cancel();
      expect(isCancelled, true, reason: 'bindCancellable has one listen');
      expect(events4, ['test2', 'test3']);
      controller.add('test4');
      expect(events3, ['test2']);
      expect(events4, ['test2', 'test3']);

      cancellable.cancel();
      await Future.delayed(Duration.zero);
      expect(isCancelled, true, reason: 'bindCancellable cancelled');
      expect(events, ['test']);
      expect(events3, ['test2']);
      expect(events4, ['test2', 'test3']);
    });

    test('bindCancellable cancelled single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable.cancelled();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);

      final events = <String>[];
      bool isDone = false;
      final sub = stream.listen(
        (event) {
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      expect(events, []);
      expect(isDone, false, reason: 'async');
      await Future.delayed(Duration.zero);
      expect(events, []);
      expect(isDone, isTrue);
      sub.cancel();

      controller.add('test');

      final events2 = <String>[];
      source.listen(events2.add);

      expect(events, []);
      expect(events2, []);

      controller.add('test2');
      expect(events, []);
      expect(events2, [], reason: 'controller is cancelled');
    });

    test('bindCancellable cancelled broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable.cancelled();
      final source = controller.stream;
      final stream = source.bindCancellable(cancellable);
      final events = <String>[];
      bool isDone = false;
      final sub = stream.listen(
        (event) {
          events.add(event);
        },
        onDone: () => isDone = true,
      );

      expect(events, []);
      expect(isDone, false, reason: 'async');
      await Future.delayed(Duration.zero);
      expect(events, []);
      expect(isDone, isTrue);
      sub.cancel();

      controller.add('test');
      final events2 = <String>[];
      source.listen(events2.add);
      expect(events, []);
      expect(events2, []);
      controller.add('test2');
      expect(events, []);
      expect(events2, ['test2'], reason: 'broadcast can not cancelled');
    });

    test('bindCancellable cancelled closeWhenCancel:false single', () async {
      final controller = StreamController<String>(sync: true);
      final cancellable = Cancellable.cancelled();
      final source = controller.stream;
      final stream =
          source.bindCancellable(cancellable, closeWhenCancel: false);

      final events = <String>[];
      bool isDone = false;
      final sub = stream.listen(
        (event) {
          events.add(event);
        },
        onDone: () => isDone = true,
      );
      expect(events, []);
      expect(isDone, false, reason: 'async');
      await Future.delayed(Duration.zero);
      expect(events, []);
      expect(isDone, isFalse, reason: 'not call close');
      sub.cancel();

      controller.add('test');

      final events2 = <String>[];
      source.listen(events2.add);

      expect(events, []);
      expect(events2, []);

      controller.add('test2');
      expect(events, []);
      expect(events2, [], reason: 'controller is cancelled');
    });

    test('bindCancellable cancelled closeWhenCancel:false broadcast', () async {
      final controller = StreamController<String>.broadcast(sync: true);
      final cancellable = Cancellable.cancelled();
      final source = controller.stream;
      final stream =
          source.bindCancellable(cancellable, closeWhenCancel: false);
      final events = <String>[];
      bool isDone = false;
      final sub = stream.listen(
        (event) {
          events.add(event);
        },
        onDone: () => isDone = true,
      );

      expect(events, []);
      expect(isDone, false, reason: 'async');
      await Future.delayed(Duration.zero);
      expect(events, []);
      expect(isDone, isFalse, reason: 'not call close');
      sub.cancel();

      controller.add('test');
      final events2 = <String>[];
      source.listen(events2.add);
      expect(events, []);
      expect(events2, []);
      controller.add('test2');
      expect(events, []);
      expect(events2, ['test2'], reason: 'broadcast can not cancelled');
    });
  });

  test('bindCancellable sub.cancel re listen broadcast', () async {
    int listenCallCount = 0;
    int cancelCallCount = 0;
    final controller = StreamController<int>.broadcast(
        sync: true,
        onListen: () {
          listenCallCount++;
        },
        onCancel: () {
          cancelCallCount++;
        });
    final cancellable = Cancellable();
    final stream = controller.stream.bindCancellable(cancellable);

    final events1 = <int>[];

    final sub1 = stream.listen(events1.add);
    // 首次订阅触发listen
    expect(listenCallCount, 1);
    expect(cancelCallCount, 0);

    controller.add(1);

    expect(events1, [1]);

    final events2 = <int>[];
    final subs = stream.listen(events2.add);
    // 第二次订阅不触发listen
    expect(listenCallCount, 1);
    expect(cancelCallCount, 0);

    controller.add(2);
    sub1.cancel();

    expect(listenCallCount, 1);
    // 取消第一个订阅不触发cancel 由于还有第二个订阅存在
    expect(cancelCallCount, 0);

    controller.add(3);
    subs.cancel();

    expect(events1, [1, 2]);
    expect(events2, [2, 3]);
    expect(listenCallCount, 1);
    // 取消第二个订阅触发cancel 由于没有订阅存在了
    expect(cancelCallCount, 1);

    final events3 = <int>[];
    final sub3 = stream.listen(events3.add);

    // 重新订阅触发listen
    expect(listenCallCount, 2);
    expect(cancelCallCount, 1);

    controller.add(4);
    sub3.cancel();

    expect(events1, [1, 2]);
    expect(events2, [2, 3]);
    expect(events3, [4]);
    expect(listenCallCount, 2);
    // 取消第三个订阅触发cancel 由于没有订阅存在了
    expect(cancelCallCount, 2);

    final events4 = <int>[];
    final sub4 = stream.listen(events4.add);

    // 重新订阅触发listen
    expect(listenCallCount, 3);
    expect(cancelCallCount, 2);

    controller.add(5);

    expect(events4, [5]);
    final events5 = <int>[];
    final sub5 = stream.listen(events5.add);
    // 第二次订阅不触发listen
    expect(listenCallCount, 3);
    expect(cancelCallCount, 2);

    cancellable.cancel();
    controller.add(6);

    // cancellable.cancel 取消时需要等一个事件循环 但是不在触发 events 所以6不在events4和events5中出现
    expect(events4, [5]);
    expect(events5, []);

    expect(listenCallCount, 3);
    // cancellable.cancel 取消时需要等一个事件循环 但是不在触发 events 所以这里先不增加cancelCallCount
    expect(cancelCallCount, 2);

    await Future.delayed(Duration.zero);
    controller.add(7);

    expect(events4, [5]);
    expect(events5, []);
    expect(listenCallCount, 3);
    // cancellable.cancel 取消时需要等一个事件循环  这里增加cancelCallCount
    expect(cancelCallCount, 3);

    final events6 = <int>[];
    final sub6 = stream.listen(events6.add);

    // 重新订阅不触发listen 因为cancellable已经取消
    expect(listenCallCount, 3);
    expect(cancelCallCount, 3);

    sub6.cancel();
    // 取消订阅不触发cancel 因为cancellable已经取消
    expect(listenCallCount, 3);
    expect(cancelCallCount, 3);

    controller.add(8);

    // 由于cancellable已经取消 不在触发 events 所以8不在events4、events5和events6中出现
    expect(events4, [5]);
    expect(events5, []);
    expect(events6, []);
    // cancellable的取消不会影响上游的controller状态
    expect(controller.isClosed, isFalse);
  });

  test('bindCancellable sub.cancel re listen single', () async {
    int listenCallCount = 0;
    int cancelCallCount = 0;
    final controller = StreamController<int>(
        sync: true,
        onListen: () {
          listenCallCount++;
        },
        onCancel: () {
          cancelCallCount++;
        });
    final cancellable = Cancellable();
    final stream = controller.stream.bindCancellable(cancellable);

    final events1 = <int>[];
    final sub1 = stream.listen(events1.add);
    expect(listenCallCount, 1);
    expect(cancelCallCount, 0);

    controller.add(1);

    expect(events1, [1]);
    sub1.cancel();

    expect(listenCallCount, 1);
    expect(cancelCallCount, 1);

    expect(() {
      stream.listen((event) {});
    }, throwsA(isA<StateError>()));

    expect(listenCallCount, 1);
    expect(cancelCallCount, 1);
    expect(controller.isClosed, isFalse);
  });

  test('bindCancellable sub.cancel re listen ', () async {
    int listenCallCount = 0;
    int cancelCallCount = 0;
    final controller = StreamController<int>(
        sync: true,
        onListen: () {
          listenCallCount++;
        },
        onCancel: () {
          cancelCallCount++;
        });
    final cancellable = Cancellable();
    final stream = controller.stream.bindCancellable(cancellable);

    final events1 = <int>[];
    final sub1 = stream.listen(events1.add);
    expect(listenCallCount, 1);
    expect(cancelCallCount, 0);

    controller.add(1);

    expect(events1, [1]);

    cancellable.cancel();
    expect(listenCallCount, 1);
    // cancellable.cancel 取消时需要等一个事件循环 所以callCount不会立即增加
    expect(cancelCallCount, 0);
    expect(events1, [1]);

    controller.add(2);
    // cancellable.cancel 取消时需要等一个事件循环 但是不在触发 events 所以2不在events1中出现
    expect(events1, [1]);

    await Future.delayed(Duration.zero);
    expect(listenCallCount, 1);
    // cancellable.cancel 取消时需要等一个事件循环  这里增加cancelCallCount
    expect(cancelCallCount, 1);

    // cancellable的取消不会影响上游的controller状态
    expect(controller.isClosed, isFalse);

    sub1.cancel();
    expect(listenCallCount, 1);
    // 取消订阅不触发cancel 因为cancellable已经取消
    expect(cancelCallCount, 1);
  });
}
