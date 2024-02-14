import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// @fileoverview JavaScript functions for interacting with micro:bit microcontrollers over WebBluetooth
/// (Only works in Chrome browsers;  Pages must be either HTTPS or local)

const onDataTIMEOUT =
    1000; // Timeout after 1 second of no data (and expecting more)
const dataBurstSIZE = 100; // Number of packets to request at in a burst
const progressPacketThreshold =
    10; // More than 10 packets and report progress of transfer

/// @constant {string} serviceUUID - UUID of the micro:bit service
const serviceUUID = "accb4ce4-8a4b-11ed-a1eb-0242ac120002"; // BLE Service
const Map<String, String> serviceCharacteristics = {
  "accb4f64-8a4b-11ed-a1eb-0242ac120002":
      "securityChar", // Security   Read, Notify
  "accb50a4-8a4b-11ed-a1eb-0242ac120002": "passphraseChar", // Passphrase Write
  "accb520c-8a4b-11ed-a1eb-0242ac120002":
      "dataLenChar", // Data Length    Read, Notify
  "accb53ba-8a4b-11ed-a1eb-0242ac120002": "dataChar", // Data    Notify
  "accb552c-8a4b-11ed-a1eb-0242ac120002": "dataReqChar", // Data Request   Write
  "accb5946-8a4b-11ed-a1eb-0242ac120002": "eraseChar", // Erase   Write
  "accb5be4-8a4b-11ed-a1eb-0242ac120002": "usageChar", // Usage   Read, Notify
  "accb5dd8-8a4b-11ed-a1eb-0242ac120002": "timeChar" // Time    Read
};

class RetrieveTask {
  int start; // Start index of the data
  List<dynamic> segments; // Segment data
  int processed; // Number of segments processed
  int progress; // Progress of the task (0-100) at the start of this bundle or -1 if not shown
  bool finalTask; // Indicator of the final bundle for request
  Function? success; // Callback function for success (completion)

  RetrieveTask(this.start, int length,
      {this.progress = -1, required this.finalTask, this.success})
      : processed = 0,
        segments = List<dynamic>.filled(length, null, growable: false) {
    segments = List<dynamic>.filled(length, null, growable: false);
    processed = 0;
  }
}

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

  BluetoothCharacteristic? _securityChar;
  BluetoothCharacteristic? get securityChar => _securityChar;

  BluetoothCharacteristic? _passphraseChar;
  BluetoothCharacteristic? get passphraseChar => _passphraseChar;

  BluetoothCharacteristic? _dataLenChar;
  BluetoothCharacteristic? get dataLenChar => _dataLenChar;

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? get dataChar => _dataChar;

  BluetoothCharacteristic? _dataReqChar;
  BluetoothCharacteristic? get dataReqChar => _dataReqChar;

  BluetoothCharacteristic? _eraseChar;
  BluetoothCharacteristic? get eraseChar => _eraseChar;

  BluetoothCharacteristic? _usageChar;
  BluetoothCharacteristic? get usageChar => _usageChar;

  BluetoothCharacteristic? _timeChar;
  BluetoothCharacteristic? get timeChar => _timeChar;

  late BluetoothDevice _device;
  BluetoothDevice get device => _device;

  final List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> get devices => _devices;

  String _deviceName = "No device connected";
  String get deviceName => _deviceName;

  bool _disconnectedBool = true;
  bool get disconnectedBool => _disconnectedBool;

  List<String> _fullHeaders = [];
  List<String> get fullHeaders => _fullHeaders;

  int _dataLength = 0;
  int get dataLength => _dataLength;

  List<List<dynamic>> _rows = [];
  List<List<dynamic>> get rows => _rows;

  List<String> _rawData = [];
  List<String> get rawData => _rawData;

  DeviceIdentifier _id = DeviceIdentifier("0");
  DeviceIdentifier get id => _id;

  String _name = "";
  String get name => _name;

  List<BluetoothCharacteristic> _chars = [];
  List<BluetoothCharacteristic> get chars => _chars;

  BluetoothService _service =
      BluetoothService.fromProto(0 as BmBluetoothService);
  BluetoothService get service => _service;

  int _passwordAttempts = 0;
  int get passwordAttempts => _passwordAttempts;

  bool _nextDataAfterReboot = false;
  bool get nextDataAfterReboot => _nextDataAfterReboot;

  bool _firstConnectionUpdate = false;
  bool get firstConnectionUpdate => _firstConnectionUpdate;

  String _password = "";
  String get password => _password;

  Timer? _onDataTimeoutHandler;
  Timer? get onDataTimeoutHandler => _onDataTimeoutHandler;

  List<RetrieveTask> _retrieveQueue = [];
  List<RetrieveTask> get retrieveQueue => _retrieveQueue;

  int? _mbRebootTime;
  int? get mbRebootTime => _mbRebootTime;

  int? _bytesProcessed;
  int? get bytesProcessed => _bytesProcessed;

  /// @param {number} start Start row (inclusive)
  /// @param {number} end End row (exclusive)
  /// @returns Rows from start (inclusive) to end (inclusive) (do NOT mutate data)
  List<dynamic> getData({int start = 0, int? end}) {
    end ??= rows.length;
    return rows.sublist(start, end);
  }

  /// Get the data as a CSV representation
  /// This is the full, augmnted data.  The first column will be the miro:bit name (not label), then an indiator
  /// of the reboot, then the wall-clock time (UTC stamp in ISO format if it can reliably be identified),
  /// then the microbit's clock time, then the data.
  /// @returns {string} The CSV of the augmented data
  String getCSV() {
    String headers = fullHeaders.join(",") + "\n";
    String data = rows.map((r) => r.join(",")).join("\n");
    return headers + data;
  }

  /// Get the raw (micro:bit) data as a CSV representation. This should match the CSV retrieved from
  /// accessing the Micro:bit as a USB drive
  /// @returns {string} The CSV of the raw data
  String getRawCSV() {
    return rawData.join('');
  }

  /// Request an erase (if connected & authorized)
  void sendErase() {
    // print('sendErase');
    if (device != null && device.isConnected) {
      var dv = ByteData(5);
      var i = 0;
      for (var c in 'ERASE'.codeUnits) {
        dv.setUint8(i++, c);
      }
      eraseChar?.write(dv.buffer.asUint8List());
    }
  }

  /// Request authorization (if connected)
  ///
  /// A correct password will be retained for future connections
  ///
  /// @param {string} password The password to send
  void sendAuthorization(String password) {
    // print('sendAuthorization: $password');
    if (device != null && device.isConnected) {
      var dv = ByteData(password.length);
      var i = 0;
      for (var c in password.runes) {
        dv.setUint8(i++, c);
      }
      passphraseChar?.write(Uint8List.fromList(dv.buffer.asUint8List()));
      _password = password;
    }
  }

  void connectDevice(index) async {
    _device = devices[index];
    await _device.connect();

    if (devices[index].platformName.toString() != "") {
      _deviceName = devices[index].platformName.toString();
    } else {
      _deviceName = devices[index].remoteId.toString();
    }

    _disconnectedBool = false;

    initializeServicesAndCharacteristics();

    notifyListeners();
  }

  Future<void> initializeServicesAndCharacteristics() async {
    List<BluetoothService> services = await device.discoverServices();

    services =
        services.where((u) => u.serviceUuid.toString() == serviceUUID).toList();

    if (services.isNotEmpty) {
      BluetoothService service = services.first;
      List<BluetoothCharacteristic> chars = service.characteristics.toList();

      await onConnect(service, chars, device);
    }
  }

  /// Callback of actions to do on connection
  /// @param {BLEService} service
  /// @param {BLECharacteristics} chars
  /// @param {BLEDevice} device
  /// @private
  Future<void> onConnect(BluetoothService service,
      List<BluetoothCharacteristic> chars, BluetoothDevice device) async {
    // Add identity values if not already set (neither expected to change)
    _id = device.remoteId;
    _name = device.platformName;

    // Bluetooth & connection configuration
    _chars = chars;
    _service = service;
    _passwordAttempts = 0;
    _nextDataAfterReboot = false;
    _firstConnectionUpdate = true;

    chars.forEach((element) {
      String? charName = serviceCharacteristics[element.uuid.toString()];
      if (charName != null) {
        (this as dynamic)[charName] = element;
      } else {
        print('Char not found: ${element.uuid}');
      }
    });

    // Connect / disconnect handlers
    /**
   * @event connected
   * @type {object}
   * @property {uBit} detail.device The device that has successfully connected
   */
    notifyListeners();

    // listen for disconnection
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        (_) => onDisconnect();
      }
    });

// cleanup: cancel subscription when disconnected
// Note: `delayed:true` lets us receive the `disconnected` event in our handler
// Note: `next:true` means cancel on *next* disconnection. Without this, it
//   would cancel immediately because we're already disconnected right now.
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    final subscription2 = securityChar?.onValueReceived.listen((value) {
      // onValueReceived is updated:
      //   - anytime read() is called
      //   - anytime a notification arrives (if subscribed)
      onSecurity();
    });

    // cleanup: cancel subscription when disconnected
    device.cancelWhenDisconnected(subscription2!);
    await securityChar?.setNotifyValue(true);
  }

  /// Callback of actions to do when authorized
  /// @private
  Future<void> onAuthorized() async {
    // Subscribe to characteristics / notifications
    // Initial reads (need to be before notifies
    List<int> time = await timeChar?.read() ?? [];
    int msTime = (time[0].toUnsigned(8) |
            time[1].toUnsigned(8) << 8 |
            time[2].toUnsigned(8) << 16 |
            time[3].toUnsigned(8) << 24 |
            time[4].toUnsigned(8) << 32 |
            time[5].toUnsigned(8) << 40 |
            time[6].toUnsigned(8) << 48 |
            time[7].toUnsigned(8) << 56) ~/
        1000;

    // Compute the date/time that the micro:bit started in seconds since epoch start (as N.NN s)
    _mbRebootTime = DateTime.now().millisecondsSinceEpoch - msTime;

    final subscription = dataChar?.onValueReceived.listen((value) {
      onData();
    });
    device.cancelWhenDisconnected(subscription!);
    await dataChar?.setNotifyValue(true);

    final subscription2 = usageChar?.onValueReceived.listen((value) {
      onUsage();
    });
    device.cancelWhenDisconnected(subscription2!);
    await usageChar?.setNotifyValue(true);

    // Enabling notifications will get the current length;
    // Getting the current length will retrieve all "new" data since the last retrieve
    final subscription3 = dataLenChar?.onValueReceived.listen((value) {
      onDataLength();
    });
    device.cancelWhenDisconnected(subscription3!);
    await dataLenChar?.setNotifyValue(true);
  }

  /// Remove this device
  void remove() {
    removeDevice(id);

    // If connected, disconnect
    if (device != null && device.isConnected) {
      disconnectDevice();
    }

    // Discard any data, etc.
    _rawData = [];
    _rows = [];
    _dataLength = 0;
    _bytesProcessed = 0;

    // Make sure all references are cleared
    disconnected();
  }

  void removeDevice(dynamic id) {
    devices.remove(id);
    notifyListeners();
  }

  void onData() {}

  void onUsage() {}

  void onDataLength() {}

  void onDisconnect() {}

  void onSecurity() {}

  void disconnected() {}

  void disconnectDevice() {
    _device.disconnect();
    _deviceName = "No device connected";
    _disconnectedBool = true;
    notifyListeners();
  }

  /// Clear the "onData" timeout
  /// @private
  void clearDataTimeout() {
    // console.log(`clearDataTimeout: handler ID ${this.onDataTimeoutHandler}`)
    if (onDataTimeoutHandler != null) {
      clearTimeout(onDataTimeoutHandler!);
      _onDataTimeoutHandler = null;
    }
  }

  /// set the "onData" timeout
  /// @private
  void setDataTimeout() {
    clearDataTimeout();
    _onDataTimeoutHandler = setTimeout(onDataTimeout, onDataTIMEOUT);
    // console.log(`setDataTimeout: handler ID ${this.onDataTimeoutHandler}`)
  }

  /// Callback for "onData" timeout (checks to see if transfer is complete)
  /// @private
  void onDataTimeout() {
    // Stuff to do when onData is done
    if (this.onDataTimeoutHandler != null) {
      //console.log("onDataTimeout")
      clearDataTimeout();
      checkChunk();
    }
  }

  checkChunk() {}

  /// Do a BLE request for the data (to be streamed)
  /// @param {int} start 16-byte aligned start index (actual data index is "start*16")
  /// @param {int} length Number of 16-byte segments to retrieve
  /// @private
  Future<void> requestSegment(int start, int length) async {
    // print('requestSegment: Requesting @ $start $length *16 bytes');
    if (device != null && device.isConnected) {
      var dv = ByteData(8);
      dv.setUint32(0, start * 16, Endian.little);
      dv.setUint32(4, length * 16, Endian.little);
      await dataReqChar?.write(dv.buffer.asUint8List());
      clearDataTimeout();
      setDataTimeout();
    }
  }

  /// Notify of progress in retrieving large block of data
  /// @param {int} progress Progress of the task (0-100)
  /// @private
  void notifyDataProgress(progress) {
    notifyListeners();
  }

  /// Notify that new data is available
  /// @private
  void notifyDataReady() {
    notifyListeners();
  }

  /// Retrieve a range of data and re-request until it's all delivered.
  /// Assuming to be non-overlapping calls.  I.e. this won't be called again until all data is delivered
  /// @param {*} start 16-byte aligned start index (actual data index is "start*16")
  /// @param {*} length Number of 16-byte segments to retrieve
  /// @private
  void retrieveChunk(int start, int length, [Function? success]) {
    // // PERFORMANCE CHECKING
    // this.retrieveStartTime = DateTime.now().millisecondsSinceEpoch;
    // this.dataTransferred = 0;

    // print('retrieveChunk: Retrieving @$start $length *16 bytes');
    if (start * 16 > dataLength) {
      print('retrieveChunk: Start index $start is beyond end of data');
      return;
    }

    if (start + length > (dataLength / 16).ceil()) {
      print('retrieveChunk: Requested data extends beyond end of data');
      // return;
    }

    // Break it down into smaller units if needed
    bool noPending = retrieveQueue.isEmpty;
    bool progressIndicator = length > progressPacketThreshold;
    int numBursts = (length / dataBurstSIZE).ceil();
    int remainingData = length;
    int thisRequest = 0;
    while (remainingData > 0) {
      int thisLength =
          [remainingData, dataBurstSIZE].reduce((a, b) => a < b ? a : b);
      bool finalRequest = thisRequest == numBursts - 1;
      RetrieveTask newTask = RetrieveTask(
        start,
        thisLength,
        progress:
            progressIndicator ? ((thisRequest / numBursts) * 100).floor() : -1,
        finalTask: finalRequest,
        success: finalRequest ? success : null,
      );
      retrieveQueue.add(newTask);
      start += thisLength;
      remainingData -= thisLength;
      thisRequest++;
    }

    // If nothing is being processed now, start it
    if (noPending) {
      startNextRetrieve();
    }
  }

  startNextRetrieve() {}

  Timer setTimeout(callback, [int duration = 1000]) {
    return Timer(Duration(milliseconds: duration), callback);
  }

  void clearTimeout(Timer t) {
    t.cancel();
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
    _disconnectedBool = true;
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
