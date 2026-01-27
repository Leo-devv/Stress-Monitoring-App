import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

/// Device Connection Screen - BLE pairing simulation
class DeviceConnectionPage extends ConsumerStatefulWidget {
  const DeviceConnectionPage({super.key});

  @override
  ConsumerState<DeviceConnectionPage> createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends ConsumerState<DeviceConnectionPage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDevice;
  List<_MockDevice> _discoveredDevices = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Connection'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildStatusCard(),
            const SizedBox(height: AppSpacing.lg),

            // Scanning Section
            if (!_isConnected) ...[
              _buildScanSection(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Discovered Devices
            if (_discoveredDevices.isNotEmpty && !_isConnected) ...[
              _buildDeviceList(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Connected Device Info
            if (_isConnected) ...[
              _buildConnectedDeviceCard(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Demo Mode Card
            _buildDemoModeCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [AppColors.stressLow.withOpacity(0.2), AppColors.surface]
              : [AppColors.accent.withOpacity(0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: _isConnected ? AppColors.stressLow.withOpacity(0.3) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_isConnected ? AppColors.stressLow : AppColors.accent).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: _isConnected ? AppColors.stressLow : AppColors.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Connected' : 'Not Connected',
                  style: AppTypography.h3.copyWith(
                    color: _isConnected ? AppColors.stressLow : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected
                      ? 'Receiving sensor data from $_connectedDevice'
                      : 'Scan for nearby wearable devices',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          if (_isConnected)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.stressLow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.stressLow.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Scanning Animation
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isScanning) ...[
                  // Pulse rings
                  ...List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final value = (_pulseController.value + i * 0.33) % 1.0;
                        return Container(
                          width: 80 + (value * 80),
                          height: 80 + (value * 80),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withOpacity(1 - value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
                // Center icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                    color: AppColors.accent,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Scan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? AppColors.surfaceElevated : AppColors.accent,
                foregroundColor: _isScanning ? AppColors.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                    _isScanning ? 'Scanning...' : 'Scan for Devices',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isScanning ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
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
          Text('Discovered Devices', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_discoveredDevices.length, (i) {
            final device = _discoveredDevices[i];
            return _DeviceListTile(
              device: device,
              onConnect: () => _connectToDevice(device),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.stressLow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connected Device', style: AppTypography.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.stressLow.withOpacity(0.2),
                  borderRadius: AppRadius.badge,
                ),
                child: Text(
                  'Active',
                  style: AppTypography.caption.copyWith(color: AppColors.stressLow),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Device Info
          _InfoRow(icon: Icons.watch, label: 'Device', value: _connectedDevice ?? 'Unknown'),
          const SizedBox(height: 12),
          const _InfoRow(icon: Icons.signal_cellular_alt, label: 'Signal', value: 'Strong (-45 dBm)'),
          const SizedBox(height: 12),
          const _InfoRow(icon: Icons.battery_full, label: 'Battery', value: '78%'),
          const SizedBox(height: 12),
          const _InfoRow(icon: Icons.access_time, label: 'Connected', value: '2 min ago'),
          const SizedBox(height: AppSpacing.lg),
          // Disconnect Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _disconnect,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: Text('Disconnect', style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            ),
          ),
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
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_outlined, color: AppColors.accent, size: 20),
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
            'Perfect for thesis demonstrations when physical hardware is unavailable. '
            'Generates realistic WESAD-format sensor data.',
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

  void _startScan() {
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    // Simulate discovering devices over time
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isScanning) {
        setState(() {
          _discoveredDevices.add(_MockDevice(
            name: 'Empatica E4',
            id: 'E4:23:AB:CD:EF:01',
            rssi: -52,
            type: 'Wristband',
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isScanning) {
        setState(() {
          _discoveredDevices.add(_MockDevice(
            name: 'Polar H10',
            id: 'H10:12:34:56:78:90',
            rssi: -68,
            type: 'Heart Rate Monitor',
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _isScanning) {
        setState(() {
          _discoveredDevices.add(_MockDevice(
            name: 'Garmin Vivosmart',
            id: 'GA:98:76:54:32:10',
            rssi: -74,
            type: 'Fitness Tracker',
          ));
        });
      }
    });

    // Auto stop after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _stopScan();
    });
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(_MockDevice device) {
    setState(() {
      _isConnected = true;
      _connectedDevice = device.name;
      _discoveredDevices = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected to ${device.name}', style: AppTypography.bodyMedium),
        backgroundColor: AppColors.stressLow.withOpacity(0.9),
      ),
    );
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
    });
  }

  void _enableDemoMode() {
    setState(() {
      _isConnected = true;
      _connectedDevice = 'Demo Sensor (Simulated)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo mode enabled - Using simulated data', style: AppTypography.bodyMedium),
        backgroundColor: AppColors.accent.withOpacity(0.9),
      ),
    );
  }
}

class _MockDevice {
  final String name;
  final String id;
  final int rssi;
  final String type;

  _MockDevice({
    required this.name,
    required this.id,
    required this.rssi,
    required this.type,
  });
}

class _DeviceListTile extends StatelessWidget {
  final _MockDevice device;
  final VoidCallback onConnect;

  const _DeviceListTile({
    required this.device,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: AppColors.cloudMode.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.watch, color: AppColors.cloudMode, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(device.type, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SignalIndicator(rssi: device.rssi),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onConnect,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

class _SignalIndicator extends StatelessWidget {
  final int rssi;

  const _SignalIndicator({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = rssi > -60 ? 3 : (rssi > -75 ? 2 : 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i < bars;
        return Container(
          width: 4,
          height: 8 + (i * 4),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.stressLow : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.bodySmall),
        const Spacer(),
        Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
