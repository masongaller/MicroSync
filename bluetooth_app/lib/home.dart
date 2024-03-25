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

class _MyHomePageState extends State<MyHomePage> with AutomaticKeepAliveClientMixin<MyHomePage> {
  bool _disconnected = true;

  Future<void> _connectOrDisconnect(readBLE) async {
    bool isBluetoothSupported = await FlutterBluePlus.isSupported;

    var subscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        if (isBluetoothSupported) {
          _handleBluetoothOn(readBLE);
        } else {
          _handleBluetoothOff(readBLE);
        }
      } else {
        readBLE.bluetoothDisabled();
      }
    });
  }

  void _handleBluetoothOn(readBLE) {
    if (!readBLE.disconnectedBool) {
      readBLE.onDisconnect();
    } else {
      readBLE.scanForDevices();
      _disconnected = true;
    }
  }

  void _handleBluetoothOff(readBLE) async {
    readBLE.bluetoothDisabled();

    await _bluetoothAlert();
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

  Future<void> promptPassword(readBLE) async {
    String enteredPassword = ""; // Variable to store the entered password

    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Password Required'),
          content: Column(
            children: <Widget>[
              const Text('To access this micro:bit, please enter the password you set in the makecode editor.'),
              CupertinoTextField(
                placeholder: 'Password',
                obscureText: true,
                onChanged: (value) {
                  enteredPassword = value; // Update the entered password as the user types
                },
                style: const TextStyle(color: CupertinoColors.white), // Set text color
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                _connectOrDisconnect(readBLE);
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Submit'),
              onPressed: () {
                // Handle the entered password as needed
                readBLE.password = enteredPassword;
                readBLE.sendAuthorization(enteredPassword);
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
    super.build(context); // Invoke the overridden method

    final watchBLE = context
        .watch<SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readBLE = context.read<SharedBluetoothData>(); //To modify the data without rebuilding the widget

    var theme = Theme.of(context);

    // listen for password prompt
    var subscription = watchBLE.addListener(() async {
      if (watchBLE.needPasswordPrompt) {
        watchBLE.needPasswordPrompt = false;
        await promptPassword(readBLE);
      }
    });

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
                            leading: const Icon(Icons.bluetooth),
                            title: Text(watchBLE.devices[index].platformName.toString()),
                            subtitle: Text(watchBLE.devices[index].remoteId.toString()),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                watchBLE.connectDevice(index);
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
        label: Text(watchBLE.disconnectedBool ? 'Scan' : 'Disconnect'),
        onPressed: () {
          _connectOrDisconnect(readBLE);
        },
        tooltip: 'Connect Bluetooth Device',
        icon: watchBLE.disconnectedBool ? const Icon(Icons.bluetooth_disabled) : const Icon(Icons.bluetooth_connected),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
