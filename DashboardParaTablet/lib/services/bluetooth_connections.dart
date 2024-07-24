import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

BluetoothConnection? globalConnection;
StreamSubscription<Uint8List>? globalSubscription;
Stream<Uint8List>? globalBroadcastStream;

void initializeGlobalBroadcastStream() {
  if (globalConnection != null && globalBroadcastStream == null) {
    globalBroadcastStream = globalConnection!.input!.asBroadcastStream();
  }
}

void cancelGlobalSubscription() {
  globalSubscription?.cancel();
  globalSubscription = null;
}
