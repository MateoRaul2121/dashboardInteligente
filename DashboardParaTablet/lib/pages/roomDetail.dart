import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:face_net_authentication/pages/models/Room.dart';
import 'package:flutter/material.dart';
import 'foco_screen.dart';
import 'package:face_net_authentication/services/globals.dart';
import 'package:face_net_authentication/services/singleton_bluetooth.dart';

class RoomDetail extends StatefulWidget {
  final Room room;
  final String imagePath;
  final String username;
  final BluetoothService connection;

  RoomDetail({
    required this.room,
    required this.imagePath,
    required this.username,
    required this.connection,
  });

  @override
  _RoomDetailState createState() => _RoomDetailState();
}

class _RoomDetailState extends State<RoomDetail> {
  bool isLightOn = globalSwitchValue; // Initialize with the global value
  bool isDoorOpen = false;
  double temperature = 0.0;
  double humidity = 0.0;
  Timer? dataTimer;
  StreamSubscription? globalSubscription;

  @override
  void initState() {
    super.initState();
    getData();

    // Subscribe to Bluetooth data
    globalSubscription = widget.connection.stream.listen(handleData);
  }

  @override
  void dispose() {
    dataTimer?.cancel(); // Cancel the timer
    globalSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  void sendMessage(String message) {
    widget.connection.sendMessage(message);
  }

  void getData() {
    sendMessage("GET_DATA");
  }

  void handleData(Uint8List data) {
    String message = String.fromCharCodes(data);
    print("Data received: $message"); // For debugging
    if (message.startsWith("T:") && message.contains(",H:")) {
      List<String> parts = message.split(",");
      setState(() {
        temperature = double.parse(parts[0].substring(2));
        humidity = double.parse(parts[1].substring(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update the switch state from the global value
    isLightOn = globalSwitchValue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 49, 2, 123),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.room.name, style: TextStyle(color: Colors.white)),
        actions: [
          CircleAvatar(
            radius: 20,
            backgroundImage: FileImage(File(widget.imagePath)),
          ),
          SizedBox(width: 10),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Card(
                  color: Color.fromARGB(255, 49, 2, 123), // Ajusta el color de las cards
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        widget.room.imagePath,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.room.name,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // Ajusta el color del texto
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.thermostat,
                        size: 40,
                        color: Colors.white,
                      ),
                      Text(
                        'Temperatura',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        '$temperature°C',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Humedad',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        '$humidity%',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FocoScreen(
                          title: 'Foco',
                          initialValue: isLightOn,
                          imagePath: widget.imagePath,
                          connection: widget.connection,
                          username: widget.username,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        isLightOn = result;
                        globalSwitchValue = isLightOn; // Update the global value
                      });
                    }
                  },
                  child: ListTile(
                    title: Text(
                      isLightOn ? 'Apagar Luces' : 'Encender Luces',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Switch(
                      value: isLightOn,
                      onChanged: (value) {
                        setState(() {
                          isLightOn = value;
                          globalSwitchValue = isLightOn; // Update the global value
                          sendMessage(isLightOn ? "ON" : "OFF");
                        });
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    isDoorOpen ? 'Cerrar Puerta' : 'Abrir Puerta',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Switch(
                    value: isDoorOpen,
                    onChanged: (value) {
                      setState(() {
                        isDoorOpen = value;
                        sendMessage(isDoorOpen ? "DOOR_OPEN" : "DOOR_CLOSE");
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
