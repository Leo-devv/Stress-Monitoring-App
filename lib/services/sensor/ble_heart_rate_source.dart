import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/rr_interval.dart';
import 'heart_rate_source.dart';

/// Connects to any standard Bluetooth LE heart rate monitor.
///
/// Works with Polar H10, Garmin HRM, Wahoo TICKR, Xiaomi bands,
/// or any device that advertises the Heart Rate Service (0x180D).
///
/// Reference: Bluetooth SIG Heart Rate Profile specification.
class BleHeartRateSource implements HeartRateSource {
  static final Guid _hrServiceUuid = Guid('180D');
  static final Guid _hrMeasurementUuid = Guid('2A37');

  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _characteristicSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  final _hrController = StreamController<HeartRateReading>.broadcast();
  final _rrController = StreamController<RRInterval>.broadcast();

  bool _active = false;
  String _deviceName = '';

  @override
  Stream<HeartRateReading> get heartRateStream => _hrController.stream;

  @override
  Stream<RRInterval> get rrIntervalStream => _rrController.stream;

  @override
  bool get isActive => _active;

  @override
  String get sourceName => _deviceName.isNotEmpty ? _deviceName : 'BLE HR';

  @override
  SensorSourceType get sourceType => SensorSourceType.ble;

  /// Scans for nearby BLE heart rate monitors.
  /// Returns discovered devices as they are found.
  Stream<ScanResult> scanForDevices({Duration timeout = const Duration(seconds: 10)}) {
    return FlutterBluePlus.onScanResults.expand((results) => results).where((r) {
      final uuids = r.advertisementData.serviceUuids;
      return uuids.contains(_hrServiceUuid);
    });
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.startScan(
      withServices: [_hrServiceUuid],
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connects to a specific BLE heart rate device and begins streaming.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _device = device;
    _deviceName = device.platformName;

    await device.connect(autoConnect: false);

    _connectionSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _active = false;
        debugPrint('BLE HR device disconnected: $_deviceName');
      }
    });

    final services = await device.discoverServices();
    final hrService = services.firstWhere(
      (s) => s.serviceUuid == _hrServiceUuid,
      orElse: () => throw StateError('Heart Rate Service not found on device'),
    );

    final measurement = hrService.characteristics.firstWhere(
      (c) => c.characteristicUuid == _hrMeasurementUuid,
      orElse: () =>
          throw StateError('HR Measurement characteristic not found'),
    );

    await measurement.setNotifyValue(true);
    _characteristicSub = measurement.onValueReceived.listen(_parseHrData);
    _active = true;
    debugPrint('BLE HR streaming from: $_deviceName');
  }

  /// Parses the Heart Rate Measurement characteristic per Bluetooth SIG spec.
  ///
  /// Byte layout:
  ///   [0]    Flags: bit0 = HR format (0=uint8, 1=uint16), bit4 = RR present
  ///   [1..n] HR value (1 or 2 bytes depending on format flag)
  ///   [n+1..]  RR intervals as uint16 in 1/1024 second units (if present)
  void _parseHrData(List<int> data) {
    if (data.isEmpty) return;

    final flags = data[0];
    final isHrFormat16 = (flags & 0x01) != 0;
    final hasRrIntervals = (flags & 0x10) != 0;

    int hr;
    int offset;
    if (isHrFormat16) {
      hr = data[1] | (data[2] << 8);
      offset = 3;
    } else {
      hr = data[1];
      offset = 2;
    }

    // Skip energy expended field if present (bit 3)
    if ((flags & 0x08) != 0) {
      offset += 2;
    }

    final now = DateTime.now();
    _hrController.add(HeartRateReading(
      bpm: hr,
      timestamp: now,
      source: SensorSourceType.ble,
    ));

    if (hasRrIntervals) {
      while (offset + 1 < data.length) {
        final rawRr = data[offset] | (data[offset + 1] << 8);
        // Convert from 1/1024 seconds to milliseconds
        final rrMs = (rawRr * 1000) ~/ 1024;
        _rrController.add(RRInterval(timestamp: now, milliseconds: rrMs));
        offset += 2;
      }
    }
  }

  @override
  Future<void> start() async {
    // start() is a no-op for BLE; use connectToDevice() instead
  }

  @override
  Future<void> stop() async {
    _characteristicSub?.cancel();
    _characteristicSub = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    _active = false;

    try {
      await _device?.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting BLE device: $e');
    }
    _device = null;
    _deviceName = '';
  }

  void dispose() {
    stop();
    _hrController.close();
    _rrController.close();
  }
}
