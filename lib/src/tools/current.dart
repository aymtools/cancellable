import 'dart:async';

/// current 唯一实例 可扩展
class CurrentContext {
  const CurrentContext._();
}

/// current 唯一实例 可扩展
const current = CurrentContext._();

extension CurrentZone on CurrentContext {
  /// 获取当前在zone
  Zone get zone => Zone.current;
}
