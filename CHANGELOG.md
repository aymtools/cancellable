## 2.1.3

* Fix the bugs related to registerXXX in CancellableZoned.

## 2.1.2

* Improve some Deprecated descriptions

## 2.1.1

* Upgrade the dependency version of weak_collections.

## 2.1.0

* The base management of `CancellableGroup` changed to `Set`

## 2.0.1

* Added `CancellableEvery`, the group will be canceled only after all `ables` are executed
* Added `CancellableAny`, canceling any `able` will result in canceling the execution of all `ables`

## 2.0.0

* Removed `Cancellable.release`
* Added a new `runCancellableZoned`, within this zone, all registered events will not execute after
  a cancel
* Abstracted `Cancellable` as an interface
* Unified `byXXX` to `bindCancellable`

## 1.1.5

* Optimized `WeakSet` initialization in `Cancellable`, now it initializes only when used to reduce
  memory usage
* Fixed some cases where no exception was thrown when `throwWhenCancel=true`
  during `Cancellable.bindCancellable`
* Unified `Stream` extensions to use `bindCancellable`
* `Cancellable.release` is marked as deprecated due to possible cancel chains, and releasing
  directly could lead to issues. It will be removed in future versions.

## 1.1.4

* Allowed throwing `[CancelledException]` to continue during `Future.bindCancellable`

## 1.1.3

* Fixed the issue where `Stream.bindCancellable` did not close during certain cancellation scenarios

## 1.1.2

* Added `Cancellable.bindCancellable`, where canceling either one will also cancel the other when
  bound

## 1.1.1

* Fixed some cases where `Stream.bindCancellable` was not initialized properly
* `Stream.bindCancellable` now defaults to `closeWhenCancel = true`

## 1.1.0

* Declared that `Cancellable` cannot be used across `isolates`

## 1.0.9

* Added an exception definition for when already canceled

## 1.0.8

* Now supports passing the reason for cancellation when executing cancel

## 1.0.7

* When a canceled task spawns children, `Future.microtask()` is used to improve the timing of
  cancellation execution

## 1.0.6

* Added synchronous cancel callback `onCancel` to `Cancellable`

## 1.0.5

* Updated library documentation, updated soft references in child `Cancellable` to improve execution
  efficiency

## 1.0.4

* Added stream usability extensions

## 1.0.3

* Added availability checks, along with new tools for `future` and `stream`

## 1.0.2

* Added resource release functionality, canceled related functions removed

## 1.0.1

* Optimized soft references to facilitate timely garbage collection

## 1.0.0

* First version release
