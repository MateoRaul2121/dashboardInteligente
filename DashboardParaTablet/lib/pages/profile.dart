import 'dart:io';
import 'package:face_net_authentication/pages/home.dart';
import 'package:face_net_authentication/pages/models/Room.dart';
import 'package:face_net_authentication/pages/roomDetail.dart' as detail;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bluetooth;
import 'package:permission_handler/permission_handler.dart';
import 'package:face_net_authentication/services/singleton_bluetooth.dart';

class Profile extends StatefulWidget {
  Profile(this.username, {Key? key, required this.imagePath}) : super(key: key);
  final String username;
  final String imagePath;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final List<Room> rooms = [
    Room('Sala', 'assets/img/living_room.jpg'),
    Room('Cocina', 'assets/img/kitchen.png'),
    Room('Cuarto', 'assets/img/bedroom.jpg'),
    Room('Baño', 'assets/img/bathroom.png'),
  ];

  List<bluetooth.BluetoothDevice> devicesList = [];
  bluetooth.BluetoothDevice? connectedDevice;
  BluetoothService _bluetoothService = BluetoothService();
  bool isBluetoothConnected = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  void requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth] != null &&
        statuses[Permission.bluetoothScan] != null &&
        statuses[Permission.bluetoothConnect] != null &&
        statuses[Permission.location] != null &&
        statuses[Permission.bluetooth]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      scanForDevices();
    } else {
      print("Permissions not granted. Cannot scan for devices.");
    }
  }

  void scanForDevices() async {
    try {
      var bondedDevices = await bluetooth.FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        devicesList = bondedDevices;
      });
    } catch (e) {
      print("Error getting bonded devices: $e");
    }
  }

  void connectToDevice(bluetooth.BluetoothDevice device) async {
    try {
      await _bluetoothService.connect(device.address);
      setState(() {
        connectedDevice = device;
        isBluetoothConnected = _bluetoothService.isConnected;
      });

      // Listen to the connection input if not already subscribed
      _bluetoothService.stream.listen((data) {
        print('Data incoming: ${String.fromCharCodes(data)}');
      }, onDone: () {
        print('Disconnected from device');
        setState(() {
          isBluetoothConnected = false;
          connectedDevice = null;
        });
      });
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        isBluetoothConnected = false;
        connectedDevice = null;
      });
    }
  }

  @override
  void dispose() {
    _bluetoothService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 49, 2, 123),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: FileImage(File(widget.imagePath)),
            ),
            SizedBox(width: 10),
            Text(widget.username, style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/img/background.jpg"), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButton<bluetooth.BluetoothDevice>(
                    hint: Text("Seleccione un dispositivo", style: TextStyle(color: Colors.white)),
                    items: devicesList.map((bluetooth.BluetoothDevice device) {
                      return DropdownMenuItem<bluetooth.BluetoothDevice>(
                        value: device,
                        child: Text(
                          device.name ?? "Unknown device",
                          style: TextStyle(color: Colors.white), 
                        ),
                      );
                    }).toList(),
                    onChanged: (device) {
                      connectToDevice(device!);
                    },
                    dropdownColor: Color.fromARGB(255, 49, 2, 123),
                    iconEnabledColor: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    isBluetoothConnected
                        ? 'Conectado a ${connectedDevice?.name ?? "desconocido"}'
                        : 'No conectado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 49, 2, 123)),
                  ),
                  SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return GestureDetector(
                        onTap: isBluetoothConnected
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => detail.RoomDetail(
                                      room: room,
                                      imagePath: widget.imagePath,
                                      username: widget.username,
                                      connection: _bluetoothService,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Card(
                          color: Color.fromARGB(255, 49, 2, 123),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  room.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  room.name,
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
