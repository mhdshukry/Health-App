import 'dart:io';

import 'package:pedometer/pedometer.dart';

class DeviceStepCounter {
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Future<Stream<int>> stepCountStream() async {
    if (!isSupported) {
      return Stream<int>.error(
        'Step counter is available on Android and iOS only.',
      );
    }
    final stream = Pedometer.stepCountStream;
    return stream.map((event) => event.steps);
  }
}
