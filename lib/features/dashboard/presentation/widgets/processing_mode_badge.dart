import 'package:flutter/material.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../../../../services/offloading_manager.dart';

class ProcessingModeBadge extends StatelessWidget {
  final ProcessingMode mode;
  final OffloadingStatus? offloadingStatus;

  const ProcessingModeBadge({
    super.key,
    required this.mode,
    this.offloadingStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isEdge = mode == ProcessingMode.edge;
    final color = isEdge ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);
    final icon = isEdge ? Icons.phone_android : Icons.cloud;
    final label = isEdge ? 'EDGE' : 'CLOUD';

    return GestureDetector(
      onTap: () => _showStatusDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    if (offloadingStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text(
              'Processing Status',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
              'Mode',
              offloadingStatus!.currentMode == ProcessingMode.edge
                  ? 'Edge (On-Device)'
                  : 'Cloud (Firebase)',
              offloadingStatus!.currentMode == ProcessingMode.edge
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Battery',
              '${offloadingStatus!.batteryPercentage}%',
              offloadingStatus!.batteryLevel < 0.20
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'WiFi',
              offloadingStatus!.isWifiConnected ? 'Connected' : 'Disconnected',
              offloadingStatus!.isWifiConnected
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Strategy',
              _getStrategyLabel(offloadingStatus!.strategy),
              const Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offloadingStatus!.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getStrategyLabel(OffloadingStrategy strategy) {
    switch (strategy) {
      case OffloadingStrategy.auto:
        return 'Auto';
      case OffloadingStrategy.forceEdge:
        return 'Force Edge';
      case OffloadingStrategy.forceCloud:
        return 'Force Cloud';
    }
  }
}
