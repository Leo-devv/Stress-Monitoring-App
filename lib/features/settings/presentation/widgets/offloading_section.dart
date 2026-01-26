import 'package:flutter/material.dart';
import '../../../../services/offloading_manager.dart';

class OffloadingSection extends StatelessWidget {
  final OffloadingStrategy currentStrategy;
  final double batteryThreshold;
  final ValueChanged<OffloadingStrategy> onStrategyChanged;
  final ValueChanged<double> onThresholdChanged;

  const OffloadingSection({
    super.key,
    required this.currentStrategy,
    required this.batteryThreshold,
    required this.onStrategyChanged,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strategy selector
          const Text(
            'Offloading Strategy',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how the app decides between Edge and Cloud processing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Strategy options
          _buildStrategyOption(
            title: 'Automatic',
            description: 'Let the app decide based on battery and network',
            icon: Icons.auto_mode,
            color: const Color(0xFF6366F1),
            isSelected: currentStrategy == OffloadingStrategy.auto,
            onTap: () => onStrategyChanged(OffloadingStrategy.auto),
          ),
          const SizedBox(height: 10),
          _buildStrategyOption(
            title: 'Force Edge',
            description: 'Always process on device (saves data)',
            icon: Icons.phone_android,
            color: const Color(0xFF22C55E),
            isSelected: currentStrategy == OffloadingStrategy.forceEdge,
            onTap: () => onStrategyChanged(OffloadingStrategy.forceEdge),
          ),
          const SizedBox(height: 10),
          _buildStrategyOption(
            title: 'Force Cloud',
            description: 'Always use cloud processing (best accuracy)',
            icon: Icons.cloud,
            color: const Color(0xFF3B82F6),
            isSelected: currentStrategy == OffloadingStrategy.forceCloud,
            onTap: () => onStrategyChanged(OffloadingStrategy.forceCloud),
          ),

          // Battery threshold slider (only shown for auto mode)
          if (currentStrategy == OffloadingStrategy.auto) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Threshold',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Switch to Edge mode below this level',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(batteryThreshold * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6366F1),
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: const Color(0xFF6366F1),
                trackHeight: 6,
              ),
              child: Slider(
                value: batteryThreshold,
                min: 0.10,
                max: 0.50,
                divisions: 8,
                onChanged: onThresholdChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStrategyOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white.withOpacity(0.5),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
