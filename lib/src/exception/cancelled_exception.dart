class CancelledException implements Exception {
  final dynamic reason;

  CancelledException([this.reason]);

  String toString() {
    Object? message = this.reason;
    if (message == null) return "CancelledException";
    return "CancelledException: $message";
  }

  @override
  int get hashCode => reason == null
      ? super.hashCode
      : Object.hashAll([CancelledException, reason]);

  @override
  bool operator ==(Object other) {
    return reason == null
        ? identical(this, other)
        : other is CancelledException && other.reason == reason;
  }
}
