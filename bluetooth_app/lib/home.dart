import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//Acknowledgement: https://medium.com/@nandhuraj/exploring-bluetooth-communication-with-flutter-blue-plus-package-3c442d0e6cdb
//Used this guide to help me setup scanning and connecting to a bluetooth device

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AutomaticKeepAliveClientMixin<MyHomePage> {
  String _deviceName = "No device connected";
  String _currText = "Scan";
  Icon _currIcon = Icon(Icons.bluetooth_disabled);
  List<BluetoothDevice> devices = [];
  late BluetoothDevice _device;
  bool _disconnected = true;

  Future<void> _connectOrDisconnect() async {
    // Check if Bluetooth is enabled and on
    bool isBluetoothEnabled = await FlutterBluePlus.isSupported;
    bool isBluetoothOn = await FlutterBluePlus.isOn;
    if (!isBluetoothEnabled || !isBluetoothOn) {
      setState(() {
        devices = [];
        _currIcon = Icon(Icons.bluetooth_disabled);
        _deviceName = "No device connected";
        _currText = "Scan";
        _disconnected = true;
      });
      await _bluetoothAlert();
      return;
    }

    // Toggle between connect and disconnect
    setState(() {
      if (_currIcon.icon != Icons.bluetooth_disabled) {
        _currIcon = Icon(Icons.bluetooth_disabled);
        _deviceName = "No device connected";
        _currText = "Scan";
        _disconnected = true;
        _device.disconnect();
      }
    });

    if (_currIcon.icon != Icons.bluetooth_connected) {
      // Start scan only when connecting
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Clear the existing devices list
      setState(() {
        devices.clear();
      });

      // Listen to scanResults and add devices to the list
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devices.contains(result.device)) {
            setState(() {
              devices.add(result.device);
            });
          }
        }
      });
    } else {
      // Stop scan when disconnecting
      FlutterBluePlus.stopScan();
    }
  }

  Future<void> _bluetoothAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user can tap out
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Bluetooth not enabled'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enable Bluetooth in your settings and try again.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You are currently connected to:',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '$_deviceName',
              style: theme.textTheme.titleMedium,
            ),
            Visibility(
              visible: _disconnected,
              child: Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return Card(
                        child: ListTile(
                            leading: Icon(Icons.bluetooth),
                            title: Text(devices[index].platformName.toString()),
                            subtitle: Text(devices[index].remoteId.toString()),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                // Connect to the selected device
                                await devices[index].connect();
                                _device = devices[index];
                                setState(() {
                                  if (devices[index].platformName.toString() !=
                                      "") {
                                    _deviceName =
                                        devices[index].platformName.toString();
                                  } else {
                                    _deviceName =
                                        devices[index].remoteId.toString();
                                  }
                                  _currIcon = Icon(Icons.bluetooth_connected);
                                  _currText = "Disconnect";
                                  _disconnected = false;
                                });
                              },
                              child: const Text('Connect'),
                            )));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(_currText),
        onPressed: _connectOrDisconnect,
        tooltip: 'Connect Bluetooth Device',
        icon: _currIcon,
      ),
    );
  }

//Method i was using for testing
  void readCharacteristic(BluetoothDevice device) async {
    List<BluetoothDevice> blue = FlutterBluePlus.connectedDevices;
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
      // Reads all characteristics
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.properties.read) {
          List<int> value = await c.read();
          print(value);
        }
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}
