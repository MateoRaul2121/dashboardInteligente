import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:face_net_authentication/services/singleton_bluetooth.dart';
import 'package:face_net_authentication/services/globals.dart';

class FocoScreen extends StatefulWidget {
  final String title;
  final bool initialValue;
  final String imagePath;
  final String username;
  final BluetoothService connection;

  FocoScreen({
    required this.title,
    required this.initialValue,
    required this.imagePath,
    required this.connection,
    required this.username,
  });

  @override
  _FocoScreenState createState() => _FocoScreenState();
}

class _FocoScreenState extends State<FocoScreen> {
  late bool switchValue;
  late Color _currentColor;
  late double _intensity;
  final CircleColorPickerController _controller = CircleColorPickerController();

  Timer? debounceColor;

  @override
  void initState() {
    super.initState();
    switchValue = widget.initialValue;
    _currentColor = Colors.white;
    _intensity = 1.0;
    _controller.color = _currentColor;
  }

  void sendMessage(String message) async {
    if (widget.connection.isConnected) {
      widget.connection.sendMessage(message);
    } else {
      print('No está conectado a Bluetooth');
    }
  }

  void updateIntensity() {
    final adjustedColor = Color.fromRGBO(
      (_currentColor.red * _intensity).toInt(),
      (_currentColor.green * _intensity).toInt(),
      (_currentColor.blue * _intensity).toInt(),
      1.0,
    );
    sendMessage("C${adjustedColor.red},${adjustedColor.green},${adjustedColor.blue}");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, switchValue); // Return the switch value when the user navigates back
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 49, 2, 123),
          title: Text(widget.title, style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context, switchValue);
            },
          ),
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
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Opacity(
                      opacity: switchValue ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: !switchValue,
                        child: CircleColorPicker(
                          controller: _controller,
                          colorCodeBuilder: (context, color) {
                            return Text(
                              '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                              style: TextStyle(
                                color: _currentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            );
                          },
                          onChanged: (color) {
                            setState(() {
                              _currentColor = color;
                            });
                            if (debounceColor?.isActive ?? false) debounceColor?.cancel();
                            debounceColor = Timer(const Duration(milliseconds: 500), () {
                              updateIntensity();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Opacity(
                      opacity: switchValue ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: !switchValue,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 30.0,
                              activeTrackColor: _currentColor,
                              inactiveTrackColor: _currentColor.withOpacity(0.5),
                              thumbColor: _currentColor,
                              overlayColor: _currentColor.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _intensity,
                              onChanged: (value) {
                                setState(() {
                                  _intensity = value;
                                });
                                if (debounceColor?.isActive ?? false) debounceColor?.cancel();
                                debounceColor = Timer(const Duration(milliseconds: 500), () {
                                  updateIntensity();
                                });
                              },
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              label: "Intensidad: ${(_intensity * 100).round()}%",
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: _toggleLight,
                      child: Container(
                        padding: const EdgeInsets.all(50.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.power_settings_new, size: 70.0, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLight() {
    setState(() {
      switchValue = !switchValue;
      sendMessage(switchValue ? "ON" : "OFF");
      globalSwitchValue = switchValue;
    });
  }
}
