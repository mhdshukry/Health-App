class DeviceStepCounter {
  bool get isSupported => false;

  Future<Stream<int>> stepCountStream() async =>
      Stream<int>.error('Step counter is available on Android and iOS only.');
}
