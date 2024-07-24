import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? _connection;
  StreamController<Uint8List> _streamController = StreamController.broadcast();
  String _buffer = '';

  Stream<Uint8List> get stream => _streamController.stream;

  Future<void> connect(String address) async {
    _connection = await BluetoothConnection.toAddress(address);
    _connection!.input!.listen((data) {
      _handleData(data);
    }).onDone(() {
      print('Disconnected by remote request');
      _connection = null;
      _streamController.close();
    });
  }

  void disconnect() {
    _connection?.finish();
    _connection = null;
  }

  bool get isConnected => _connection != null && _connection!.isConnected;

  void sendMessage(String message) async {
    if (isConnected) {
      _connection!.output.add(Uint8List.fromList(message.codeUnits));
      await _connection!.output.allSent;
    } else {
      print('Not connected to Bluetooth');
    }
  }

  void _handleData(Uint8List data) {
    _buffer += String.fromCharCodes(data);
    int index;
    while ((index = _buffer.indexOf('\n')) != -1) {
      String message = _buffer.substring(0, index).trim();
      _buffer = _buffer.substring(index + 1);
      _streamController.add(Uint8List.fromList(message.codeUnits));
    }
  }
}
