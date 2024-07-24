import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConnectionManager {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _subscription;
  Function(Uint8List data)? _onDataReceived;
  static final ConnectionManager _instance = ConnectionManager._internal();

  factory ConnectionManager() {
    return _instance;
  }

  ConnectionManager._internal();

  Future<void> connect(BluetoothDevice device) async {
    _connection = await BluetoothConnection.toAddress(device.address);
  }

  void disconnect() {
    _subscription?.cancel();
    _connection?.dispose();
  }

  void listenToData(Function(Uint8List data) onDataReceived) {
    if (_subscription != null) {
      _subscription!.cancel();
    }
    _onDataReceived = onDataReceived;
    _subscription = _connection?.input?.listen((data) {
      _onDataReceived?.call(data);
    });
  }

  BluetoothConnection? get connection => _connection;

  bool get isConnected => _connection?.isConnected ?? false;
}
