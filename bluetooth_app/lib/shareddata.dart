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
  //TODO: Remove this after refactor
  List<Point> _points = [];
  List<Point> get points => _points;

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

  late BluetoothDevice? _device;
  BluetoothDevice? get device => _device;

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

  BluetoothService? _service;
  BluetoothService? get service => _service;

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

  int _bytesProcessed = 0;
  int get bytesProcessed => _bytesProcessed;

  List<String> _headers = [];
  List<String> get headers => _headers;

  int? _indexOfTime;
  int? get indexOfTime => _indexOfTime;

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
    if (device != null && device!.isConnected) {
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
    if (device != null && device!.isConnected) {
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
    await _device!.connect();

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
    List<BluetoothService> services = await device!.discoverServices();

    services =
        services.where((u) => u.serviceUuid.toString() == serviceUUID).toList();

    if (services.isNotEmpty) {
      BluetoothService service = services.first;
      List<BluetoothCharacteristic> chars = service.characteristics.toList();

      await onConnect(service, chars, device!);
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
      switch (charName) {
        case "securityChar":
          _securityChar = element;
          break;
        case "passphraseChar":
          _passphraseChar = element;
          break;
        case "dataLenChar":
          _dataLenChar = element;
          break;
        case "dataChar":
          _dataChar = element;
          break;
        case "dataReqChar":
          _dataReqChar = element;
          break;
        case "eraseChar":
          _eraseChar = element;
          break;
        case "usageChar":
          _usageChar = element;
          break;
        case "timeChar":
          _timeChar = element;
          break;
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
      onSecurity(value);
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
      onData(value);
    });
    device!.cancelWhenDisconnected(subscription!);
    await dataChar?.setNotifyValue(true);

    final subscription2 = usageChar?.onValueReceived.listen((value) {
      onUsage(value);
    });
    device!.cancelWhenDisconnected(subscription2!);
    await usageChar?.setNotifyValue(true);

    // Enabling notifications will get the current length;
    // Getting the current length will retrieve all "new" data since the last retrieve
    final subscription3 = dataLenChar?.onValueReceived.listen((value) {
      onDataLength(value);
    });
    device!.cancelWhenDisconnected(subscription3!);
    await dataLenChar?.setNotifyValue(true);
  }

  /// Remove this device
  void remove() {
    removeDevice(id);

    // If connected, disconnect
    if (device != null && device!.isConnected) {
      onDisconnect();
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

  /// Refresh (reload) all data from micro:bit (removes all local data)
  void refreshData() {
    _rawData = [];
    _dataLength = 0;
    _bytesProcessed = 0; // Reset to the beginning of processing
    discardRetrieveQueue(); // Clear any pending requests

    _bytesProcessed = 0;
    _headers = [];
    _indexOfTime = 0;
    _fullHeaders = [];
    _rows = [];

    /**
   * @event graph-cleared
   * @type {object}
   * @property {uBit} detail.device The device that clear all data (completed an erase at some time)
   */
    notifyListeners();
  }

  ///
  /// @param {event} event The event data
  /// @private
  void onDataLength(dynamic event) {
    // Updated length / new data

    int valLow = event[0];
    int valMed1 = event[1];
    int valMed2 = event[2];
    int valHigh = event[3];

    int length = (valHigh << 24) | (valMed2 << 16) | (valMed1 << 8) | valLow;

    // print('New Length: $length (was ${this.dataLength})');

    // If there's new data, update
    if (dataLength != length) {
      // Probably erased. Retrieve it all
      if (length < dataLength) {
        print('Log smaller than expected. Retrieving all data');
        refreshData();
      }

      // Get the index of the last known value (since the last update)
      // floor(n/16) = index of the last full segment
      // ceil(n/16) = index of the last segment total (or count of total segments)
      int lastIndex =
          (dataLength / 16).floor(); // Index of first non-full segment
      int totalSegments = (length / 16).ceil(); // Total segments now
      _dataLength = length;
      // Retrieve checks dataLength; Must update it first;
      retrieveChunk(
          lastIndex, totalSegments - lastIndex, onConnectionSyncCompleted);
    }
  }

  /// Update data with wall clock time.
  /// @private
  void processTime() {
    // Add in clock times (if possible)
    // print('Adding times');
    if (firstConnectionUpdate == false && indexOfTime != -1) {
      int start = rows.length - 1;
      // print('Start: $start');
      // Valid index, wtc time is null
      while (start >= 0 && rows[start][2] == null) {
        // Until a "Reboot" or another time is set
        int sampleTime =
            mbRebootTime! + ((rows[start][3] as int) * 1000).round();
        String timeString = DateTime.fromMillisecondsSinceEpoch(sampleTime)
            .toUtc()
            .toIso8601String();
        // print('Setting time for row $start to $timeString');
        rows[start][2] = timeString;
        updatedRow(start);
        // Don't update rows before "Reboot"
        if (rows[start][1] != 'false') {
          break;
        }
        start--;
      }
    }
  }

  /// Post event to indicate a row of data has changed or been added
  /// @private
  updatedRow(rowIndex) {
    /** 
        * @event row-updated
        * @type {object}
        * @property {uBit} detail.device The device that has an update on a row of data
        * @property {int} detail.row the index of the row that has been updated (may be a new row)
        * @property {string[]} detail.data the current data for the row
        * @property {headers[]} detail.headers the headers for the row (same order as data)
        */
    notifyListeners();
  }

  /// A block of data is ready to be parsed
  /// @private
  void parseData() {
    // print('parseData');

    // Bytes processed always ends on a newline
    int index = (bytesProcessed! / 16).floor();
    int offset = bytesProcessed! % 16;

    String partialItem = rawData[index].substring(offset);
    String mergedData = partialItem + rawData.sublist(index + 1).join('');

    // print('mergedData: $mergedData');
    List<String> lines = mergedData.split('\n');
    int startRow = rows.length;

    // Discard the last / partial line
    lines.removeLast();

    for (String line in lines) {
      if (line == '0') {
        // Single 0 is reboot
        // print('Reboot');
        _nextDataAfterReboot = true;
      } else if (line.contains('Time')) {
        // Header: Time header found
        // print('Header: $line');
        List<String> parts = line.split(',');

        if (parts.length != headers.length) {
          // New Header!
          _headers = parts;
          _indexOfTime =
              parts.indexWhere((element) => element.contains('Time'));

          _fullHeaders = [
            'Microbit Label',
            'Reboot Before Data',
            'Time (local)'
          ];

          if (indexOfTime == -1) {
            fullHeaders.addAll(parts);
          } else {
            // Time then data
            fullHeaders.add(parts[indexOfTime!]);
            fullHeaders.addAll(parts.sublist(0, indexOfTime));
            fullHeaders.addAll(parts.sublist(indexOfTime! + 1));
          }

          // print('Full Headers now: $fullHeaders');
          /**
         * @event headers-updated
         * @type {object}
         * @property {uBit} detail.device The device that has an update on the headers
         * @property {List<String>} detail.headers the new headers for the device
         */
          notifyListeners();
        }
      } else {
        List<String> parts = line.split(',');

        if (parts.length < headers.length) {
          print('Invalid line: $line $bytesProcessed');
        } else {
          double? time = null;
          int? intTime = null;

          if (indexOfTime != -1) {
            time = double.parse(parts[indexOfTime!]);
            intTime = time.floor() ~/ 60;
          }

          parts = List<String>.from(parts.sublist(0, indexOfTime)
            ..addAll(parts.sublist(indexOfTime! + 1)));

          // name, reboot, local time, time, data...
          List<dynamic> newRow = [
            getLabel().toString(),
            nextDataAfterReboot ? 'true' : 'false',
            "null",
            intTime,
            ...parts
          ];

          // print('New Row: $newRow');
          rows.add(newRow);
          _nextDataAfterReboot = false;
        }
      }
    }

    processTime();

    // If we've already done the first connection...
    if (firstConnectionUpdate == false) {
      notifyDataReady();
    }

    // Advance by total contents of lines and newlines
    _bytesProcessed = _bytesProcessed! +
        lines.length +
        lines.fold<int>(0, (a, b) => a + b.length);

    // Notify any listeners
    for (int i = startRow; i < rows.length; i++) {
      updatedRow(i);
    }
  }

  /// Callback when a security message is received
  /// @param {event}} event The BLE security data
  /// @private
  void onSecurity(dynamic event) {
    int value = event[0];

    if (value != 0) {
      onAuthorized();
    } else {
      if (password != null && passwordAttempts == 0) {
        // If we're on the first connect and we have a stored password, try it
        sendAuthorization(password!);
        _passwordAttempts++;
      } else {
        // Need a password or password didn't work
        /**
       * @event unauthorized
       * @type {object}
       * @property {uBit} detail.device The device that is not authorized (must provide a valid password to use the device. See {@link uBit#sendAuthorization})
       */
        notifyListeners();
      }
    }
  }

  /// Start the next data request (if there is one pending)
  /// @private
  void startNextRetrieve() {
    // If there's another one queued up, start it
    if (retrieveQueue.isNotEmpty) {
      // Request the next chunk
      var nextRetrieve = retrieveQueue[0];
      requestSegment(nextRetrieve.start, nextRetrieve.segments.length);

      // Post the progress of the next transaction
      if (nextRetrieve.progress >= 0) {
        notifyDataProgress(nextRetrieve.progress);
      }
    }
  }

  /// Initial data request on connection (or reconnect) is done (or at least being checked)
  /// @private
  void onConnectionSyncCompleted() {
    if (firstConnectionUpdate) {
      // print('onConnectionSyncCompleted');
      _firstConnectionUpdate = false;
      processTime();
      notifyDataReady();

      // // PERFORMANCE CHECKING
      // retrieveStopTime = DateTime.now().millisecondsSinceEpoch;
      // int delta = retrieveStopTime - retrieveStartTime;
      // double rate = dataTransferred / delta * 1000;
      // print('Final Packet;  Elapsed time: $delta $dataTransferred Rate: $rate bytes/s');
    }
  }

  /// Process the data from a retrieveTask that has completed (all data available)
  /// @param {retrieveTask} retrieve The retrieve task to try to check/process
  /// @private
  void processChunk(RetrieveTask retrieve) {
    // If the final packet and we care about progress, send completion notification
    // print('processChunk: ${retrieve.progress} ${retrieve.final} ${retrieve.success} ${retrieve.segments.length}');
    if (retrieve.progress >= 0 && retrieve.finalTask) {
      notifyDataProgress(100);
    }

    // Pop off the retrieval task
    retrieveQueue.removeAt(0);

    // Start the next one (if any)
    startNextRetrieve();

    // Copy data from this to raw data
    for (int i = 0; i < retrieve.segments.length; i++) {
      if (retrieve.segments[i] == null) {
        print('ERROR: Null segment: $i');
      }
      _rawData.add(retrieve.segments[i]);
      //rawData[retrieve.start + i] = retrieve.segments[i];
    }
    parseData();

    // If we're done with the entire transaction, call the completion handler if one
    if (retrieve.success != null) {
      retrieve.success!();
    }
  }

  /// A retrieveTask is done.  Check to see if it's complete and ready for processing (if not, make more requests)
  /// @private
  void checkChunk() {
    // print('checkChunk');
    if (retrieveQueue.isEmpty) {
      print('No retrieve queue');
      return;
    }

    var retrieve = retrieveQueue[0];

    // If done
    if (retrieve.processed == retrieve.segments.length) {
      processChunk(retrieve);
    } else {
      // Advance to the next missing packet
      while (retrieve.processed < retrieve.segments.length &&
          retrieve.segments[retrieve.processed] != null) {
        retrieve.processed = retrieve.processed + 1;
      }

      // If there's a non-set segment, request it
      if (retrieve.processed < retrieve.segments.length) {
        // Identify the run length of the missing piece(s)
        int length = 1;

        while (retrieve.processed + length < retrieve.segments.length &&
            retrieve.segments[retrieve.processed + length] == null) {
          length++;
        }

        // print('Re-Requesting ${retrieve.start + retrieve.processed} for $length');
        // Request them
        requestSegment(retrieve.start + retrieve.processed, length);
      } else {
        // No missing segments. Process it
        processChunk(retrieve);
      }
    }
  }

  /// Process the data notification from the device
  /// @param {event} event BLE data event is available
  /// @private
  void onData(dynamic event) {
    // Stop any timer from running
    clearDataTimeout();

    // If we're not trying to get data, ignore it
    if (retrieveQueue.isEmpty) {
      return;
    }

    // First four bytes are index/offset this is in reply to...
    var dv = event;
 
    // // PERFORMANCE CHECKING
    // dataTransferred += dv.byteLength;

    if (dv.length >= 4) {
      var index = dv[0] | (dv[1] << 8) | (dv[2] << 16) | (dv[3] << 24);
      var text = '';
      for (var i = 4; i < dv.length; i++) {
        var val = dv[i];
        if (val != 0) {
          text += String.fromCharCode(val);
        }
      }

      // print('Text at $index: $text');
      // print('Hex: ${showHex(dv)}');

      var retrieve = retrieveQueue[0];

      // if (Random().nextDouble() < 0.01) {
      //   print('Dropped Packet');
      // } else {
      var segmentIndex = ((index / 16) - retrieve.start).toInt();
      // print('Index: $index Start: ${retrieve.start}  index: $segmentIndex');
      if (segmentIndex == retrieve.processed) retrieve.processed++;

      if (retrieve.segments[segmentIndex] != null) {
        print(
            'ERROR:  Segment already set $segmentIndex: "${retrieve.segments[segmentIndex]}" "$text" ');
        if (retrieve.segments[segmentIndex].length != text.length &&
            retrieve.segments[segmentIndex] != text) {
          print('Segment is ok (duplicate / overlap)');
        } else {
          print('Duplicate segment');
        }
      }
      if (segmentIndex >= 0 && segmentIndex < retrieve.segments.length) {
        retrieve.segments[segmentIndex] = text;
      } else {
        print(
            'ERROR:  Segment out of range $segmentIndex (max ${retrieve.segments.length}');
      }
      // }  // END Dropped packet test

      // Not done:  Set the timeout
      setDataTimeout();
    } else if (event.length == 0) {
      // Done: Do the check / processing (timer already canceled)
      // print('Terminal packet.');
      // if (Random().nextDouble() < 0.10) {
      checkChunk();
      // } else {
      //   // Simulate timeout
      //   print('Dropped terminal packet');
      //   setDataTimeout();
      // }
    } else {
      print('ERROR:  Unexpected data length ${event.length}');
    }
  }

  /// Process an update on the BLE usage characteristics
  /// Prints the usage data to the console
  /// Percent of device space currently in use [0.0-100.0]
  /// 10 times the percentage of log currently in use (uint16_t from [0-1000], where 1000=100.0).
  ///
  /// @param {event} event The BLE event useage data
  /// @private
  void onUsage(dynamic event) {
    int lowByte = event[0];
    int highByte = event[1];
    int val = (highByte << 8) | lowByte;
    print('Usage: ${val / 10}%');
    notifyListeners();
  }

  void onDisconnect() {
    device!.disconnect();
    _deviceName = "No device connected";
    _disconnectedBool = true;
    disconnected();
    /** 
  * @event disconnected
  * @type {object}
  * @property {uBit} detail.device The device that has disconnected
  */
    notifyListeners();
  }

  int getLabel() {
    return 1;
  }

  /// Discard any pending retrieve tasks (and mark any in-progress as complete)
  /// @private
  void discardRetrieveQueue() {
    // If there's a transfer in-progress, notify it is completed
    if (retrieveQueue.isNotEmpty && retrieveQueue[0].progress >= 0) {
      notifyDataProgress(100);
    }
    retrieveQueue.clear();
  }

  /// Update state variables for a disconnected state
  /// @private
  void disconnected() {
    _device = null;
    _service = null;
    _chars = [];
    // Individual characteristics
    _securityChar = null;
    _passphraseChar = null;
    _dataLenChar = null;
    _dataChar = null;
    _dataReqChar = null;
    _eraseChar = null;
    _usageChar = null;
    _timeChar = null;
    // Update data to reflect what we actually have
    _dataLength = rawData.length > 1 ? (rawData.length - 1) * 16 : 0;

    discardRetrieveQueue();

    _mbRebootTime = null;
    clearDataTimeout();
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

  /// Do a BLE request for the data (to be streamed)
  /// @param {int} start 16-byte aligned start index (actual data index is "start*16")
  /// @param {int} length Number of 16-byte segments to retrieve
  /// @private
  Future<void> requestSegment(int start, int length) async {
    // print('requestSegment: Requesting @ $start $length *16 bytes');
    if (device != null && device!.isConnected) {
      var dv = ByteData(8);
      dv.setUint32(0, start * 16, Endian.little);
      dv.setUint32(4, length * 16, Endian.little);
      await dataReqChar?.write(dv.buffer.asUint8List(), withoutResponse: true);
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
}
