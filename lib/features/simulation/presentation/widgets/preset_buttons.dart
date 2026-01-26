import 'package:flutter/material.dart';
import '../../providers/simulation_provider.dart';

class PresetButtons extends StatelessWidget {
  final ValueChanged<DemoPreset> onPresetSelected;

  const PresetButtons({
    super.key,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PresetChip(
          label: 'Relaxed',
          icon: Icons.spa,
          color: const Color(0xFF22C55E),
          onTap: () => onPresetSelected(DemoPreset.relaxed),
        ),
        _PresetChip(
          label: 'Normal',
          icon: Icons.directions_walk,
          color: const Color(0xFF3B82F6),
          onTap: () => onPresetSelected(DemoPreset.normalActivity),
        ),
        _PresetChip(
          label: 'Stressed',
          icon: Icons.trending_up,
          color: const Color(0xFFF59E0B),
          onTap: () => onPresetSelected(DemoPreset.stressed),
        ),
        _PresetChip(
          label: 'High Stress',
          icon: Icons.warning_amber,
          color: const Color(0xFFEF4444),
          onTap: () => onPresetSelected(DemoPreset.highStress),
        ),
        _PresetChip(
          label: 'Low Battery',
          icon: Icons.battery_alert,
          color: const Color(0xFFEF4444),
          onTap: () => onPresetSelected(DemoPreset.lowBattery),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
