import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/sensor/sensor_manager.dart';
import '../../../../services/sensor/heart_rate_source.dart';
import '../../../../di/injection_container.dart';
import '../widgets/camera_ppg_view.dart';

/// Device connection screen with real BLE scanning, camera PPG, and demo mode.
class DeviceConnectionPage extends ConsumerStatefulWidget {
  const DeviceConnectionPage({super.key});

  @override
  ConsumerState<DeviceConnectionPage> createState() =>
      _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends ConsumerState<DeviceConnectionPage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _bleSupported = true;
  final List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  late AnimationController _pulseController;

  SensorManager? _sensorManager;
  bool _cameraPpgActive = false;
  int? _cameraPpgHr;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initSensorManager();
    _checkBleSupport();
  }

  void _initSensorManager() {
    try {
      _sensorManager = sl<SensorManager>();
    } catch (_) {
      // SensorManager not registered yet; will be wired in DI phase
    }
  }

  Future<void> _checkBleSupport() async {
    try {
      _bleSupported = await FlutterBluePlus.isSupported;
    } catch (_) {
      _bleSupported = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // --------------- BLE scanning ---------------

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final result in results) {
          final idx = _scanResults.indexWhere(
              (r) => r.device.remoteId == result.device.remoteId);
          if (idx >= 0) {
            _scanResults[idx] = result;
          } else {
            _scanResults.add(result);
          }
        }
      });
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid('180D')], // Heart Rate Service
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('BLE scan error: $e');
    }

    if (mounted) setState(() => _isScanning = false);
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);
  }

  Future<void> _connectBleDevice(BluetoothDevice device) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to ${device.platformName}...',
              style: AppTypography.bodyMedium),
          backgroundColor: AppColors.primary.withAlpha(230),
        ),
      );

      _sensorManager?.useBle(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.platformName}',
                style: AppTypography.bodyMedium),
            backgroundColor: AppColors.stressLow.withAlpha(230),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e',
                style: AppTypography.bodyMedium),
            backgroundColor: AppColors.danger.withAlpha(230),
          ),
        );
      }
    }
  }

  // --------------- Camera PPG ---------------

  void _startCameraPpg() {
    _sensorManager?.useCameraPpg();
    setState(() => _cameraPpgActive = true);
  }

  void _stopCameraPpg() {
    _sensorManager?.activeSource?.stop();
    setState(() {
      _cameraPpgActive = false;
      _cameraPpgHr = null;
    });
  }

  // --------------- Demo mode ---------------

  void _enableDemoMode() {
    _sensorManager?.useSimulator();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo mode enabled — using simulated sensor data',
            style: AppTypography.bodyMedium),
        backgroundColor: AppColors.accent.withAlpha(230),
      ),
    );
    setState(() {});
  }

  // --------------- UI helpers ---------------

  bool get _isConnected =>
      _sensorManager?.activeSource?.isActive ?? false;

  String get _activeSourceName =>
      _sensorManager?.activeSource?.sourceName ?? 'None';

  SensorSourceType? get _activeSourceType =>
      _sensorManager?.activeSource?.sourceType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Device Connection', style: AppTypography.h3),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: AppSpacing.lg),

            // BLE section
            if (!_isConnected || _activeSourceType == SensorSourceType.ble)
              _buildBleSection(),

            const SizedBox(height: AppSpacing.lg),

            // Camera PPG section
            CameraPpgView(
              isActive: _cameraPpgActive,
              heartRate: _cameraPpgHr,
              onStart: _startCameraPpg,
              onStop: _stopCameraPpg,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Demo mode
            _buildDemoModeCard(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final connected = _isConnected;
    final sourceColor = connected ? AppColors.stressLow : AppColors.accent;
    final sourceIcon = _activeSourceType == SensorSourceType.ble
        ? Icons.bluetooth_connected
        : _activeSourceType == SensorSourceType.cameraPpg
            ? Icons.camera_alt
            : _activeSourceType == SensorSourceType.simulator
                ? Icons.science
                : Icons.bluetooth;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sourceColor.withAlpha(50),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: connected ? sourceColor.withAlpha(80) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sourceColor.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(sourceIcon, color: sourceColor, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Connected' : 'Not Connected',
                  style: AppTypography.h3.copyWith(
                    color: connected ? sourceColor : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? 'Receiving data from $_activeSourceName'
                      : 'Choose a heart rate source below',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          if (connected) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: sourceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: sourceColor.withAlpha(130),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBleSection() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cloudMode.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bluetooth_searching,
                    color: AppColors.cloudMode, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bluetooth Heart Rate', style: AppTypography.h3),
                    Text(
                      _bleSupported
                          ? 'Polar, Garmin, Wahoo, or any HR strap'
                          : 'Bluetooth not available on this device',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Scan animation area
          if (_bleSupported) ...[
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isScanning)
                    ...List.generate(3, (i) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final value =
                              (_pulseController.value + i * 0.33) % 1.0;
                          return Container(
                            width: 60 + (value * 60),
                            height: 60 + (value * 60),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cloudMode
                                    .withAlpha((255 * (1 - value)).round()),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cloudMode.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isScanning
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth,
                      color: AppColors.cloudMode,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? _stopScan : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning
                      ? AppColors.surfaceElevated
                      : AppColors.cloudMode,
                  foregroundColor:
                      _isScanning ? AppColors.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isScanning) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _isScanning ? 'Scanning...' : 'Scan for HR Devices',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isScanning
                            ? AppColors.textPrimary
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Discovered devices
          if (_scanResults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Discovered Devices',
                style: AppTypography.label
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(_scanResults.length, (i) {
              final result = _scanResults[i];
              return _BleDeviceTile(
                result: result,
                onConnect: () => _connectBleDevice(result.device),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoModeCard() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_outlined,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo Mode', style: AppTypography.h3),
                    Text(
                      'Use simulated sensor data for testing',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Generates realistic WESAD-format sensor data with '
            'simulated RR intervals for HRV analysis. '
            'Ideal for thesis demos without physical hardware.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enableDemoMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: Text(
                'Enable Demo Mode',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a discovered BLE device with signal strength and connect button.
class _BleDeviceTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;

  const _BleDeviceTile({
    required this.result,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown Device';
    final rssi = result.rssi;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cloudMode.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.watch, color: AppColors.cloudMode, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  result.device.remoteId.toString(),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SignalBars(rssi: rssi),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onConnect,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.badge,
                  ),
                  child: Text(
                    'Connect',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int rssi;

  const _SignalBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = rssi > -60
        ? 3
        : rssi > -75
            ? 2
            : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${rssi}dBm ',
            style: AppTypography.caption
                .copyWith(fontSize: 9, color: AppColors.textMuted)),
        ...List.generate(3, (i) {
          final isActive = i < bars;
          return Container(
            width: 4,
            height: 8.0 + (i * 4),
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.stressLow : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ],
    );
  }
}
