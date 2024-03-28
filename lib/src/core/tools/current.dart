import 'dart:async';

class CurrentContext {
  const CurrentContext._();
}

const current = CurrentContext._();

extension CurrentZone on CurrentContext {
  Zone get zone => Zone.current;
}
