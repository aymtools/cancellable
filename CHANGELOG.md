## 1.0.0

* 第一个版本发布

## 1.0.1

* 优化软引用，以便及时回收

## 1.0.2

* 新增释放资源功能，cancel相关功能取消

## 1.0.3

* 新增可用性判断，新增future和stream工具

## 1.0.4

* 新增stream的易用性扩展

## 1.0.5

* 更新库说明，更新child的Cancellable的软引用，使执行效率更高

## 1.0.6

* Cancellable新增同步的cancel回调onCancel

## 1.0.7

* 当canceled 生成孩子的时,使用 Future.microtask() 提升执行cancel的时机

## 1.0.8

* 执行取消时可以传递被取消的原因

## 1.0.9

* 新增定义已取消时可用的抛出异常

## 1.1.0

* 声明Cancellable不可跨isolate使用

## 1.1.1

* 修复Stream.bindCancellable时部分情况未初始化，
* Stream.bindCancellable默认closeWhenCancel = true

## 1.1.2

* 增加Cancellable.bindCancellable,互相绑定后任意一个取消的同时会去取消另一个