import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SharedBluetoothData extends ChangeNotifier {
  final List<Point> _points = [];
  List<Point> get points => _points;

  // simulate a data source
  void simulateDataStream() async {
    for (var i = 0; i < 100; i++) {
      await Future.delayed(const Duration(seconds: 2));
      _points.add(Point(_points.length, Random().nextDouble() * 100));
      notifyListeners(); // This will alert the widgets that are listening to this model.
    }
  }

  void addPoint() {
    simulateDataStream();
  }

  late BluetoothDevice _device;
  BluetoothDevice get device => _device;

  final List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> get devices => _devices;

  String _deviceName = "No device connected";
  String get deviceName => _deviceName;

  bool _disconnected = true;
  bool get disconnected => _disconnected;

  void connectDevice(index) async {
    _device = devices[index];
    await _device.connect();
    if (devices[index].platformName.toString() != "") {
      _deviceName = devices[index].platformName.toString();
    } else {
      _deviceName = devices[index].remoteId.toString();
    }
    notifyListeners();
  }

  void disconnectDevice() {
    _device.disconnect();
    _deviceName = "No device connected";
    _disconnected = true;
    notifyListeners();
  }

  void scanForDevices() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Clear the existing devices list
    _devices.clear();

    // Listen to scanResults and add devices to the list
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_devices.contains(result.device)) {
          //Only add devices that are named
          if (result.device.platformName != "") {
            _devices.add(result.device);
            notifyListeners();
          }
        }
      }
    });
    
  }

  void bluetoothDisabled() {
    _devices.clear();
    _deviceName = "No device connected";
    _disconnected = true;
    notifyListeners();
  }

  void readCharacteristic(BluetoothDevice device) async {
    List<BluetoothDevice> blue = FlutterBluePlus.connectedDevices;
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
      // Reads all characteristics
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.properties.read) {
          List<int> value = await c.read();
        }
      }
    });
  }
}
