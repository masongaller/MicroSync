import 'dart:io';
import 'package:bluetooth_app/shareddata.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

//Acknowledgement: https://medium.com/@nandhuraj/exploring-bluetooth-communication-with-flutter-blue-plus-package-3c442d0e6cdb
//Used this guide to help me setup scanning and connecting to a bluetooth device

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AutomaticKeepAliveClientMixin<MyHomePage> {
  String _currText = "Scan";
  Icon _currIcon = Icon(Icons.bluetooth_disabled);
  bool _disconnected = true;

  Future<void> _connectOrDisconnect(readBLE) async {
    bool isBluetoothSupported = await FlutterBluePlus.isSupported;

    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        if (isBluetoothSupported) {
          _handleBluetoothOn(readBLE);
        } else {
          _handleBluetoothOff(readBLE);
        }
      }
      else {
        readBLE.bluetoothDisabled();
      }
    });
  }

  void _handleBluetoothOn(readBLE) {
    if (_currIcon.icon != Icons.bluetooth_disabled) {
      readBLE.onDisconnect();
    } else {
      readBLE.scanForDevices();
      _disconnected = true;
    }
    _updateUI(Icons.bluetooth_disabled, "Scan");
  }

  void _handleBluetoothOff(readBLE) async {
    readBLE.bluetoothDisabled();
    _updateUI(Icons.bluetooth_disabled, "Scan");

    await _bluetoothAlert();
  }

  void _updateUI(IconData icon, String text) {
    setState(() {
      _currIcon = Icon(icon);
      _currText = text;
    });
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
    final watchBLE = context.watch<
        SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readBLE = context.read<
        SharedBluetoothData>(); //To modify the data without rebuilding the widget

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
              watchBLE.deviceName,
              style: theme.textTheme.titleMedium,
            ),
            Visibility(
              visible: _disconnected,
              child: Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: watchBLE.devices.length,
                  itemBuilder: (context, index) {
                    return Card(
                        child: ListTile(
                            leading: Icon(Icons.bluetooth),
                            title: Text(watchBLE.devices[index].platformName
                                .toString()),
                            subtitle: Text(
                                watchBLE.devices[index].remoteId.toString()),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                watchBLE.connectDevice(index);
                                _currIcon = Icon(Icons.bluetooth_connected);
                                _currText = "Disconnect";
                                _disconnected = false;
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
        onPressed: () {
          _connectOrDisconnect(readBLE);
        },
        tooltip: 'Connect Bluetooth Device',
        icon: _currIcon,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
