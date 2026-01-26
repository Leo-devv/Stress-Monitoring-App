import 'package:flutter/material.dart';

class PrivacySection extends StatelessWidget {
  final bool dataCollectionEnabled;
  final int dataRetentionDays;
  final bool isDeletingData;
  final ValueChanged<bool> onDataCollectionChanged;
  final ValueChanged<int> onRetentionDaysChanged;
  final VoidCallback onNukeData;

  const PrivacySection({
    super.key,
    required this.dataCollectionEnabled,
    required this.dataRetentionDays,
    required this.isDeletingData,
    required this.onDataCollectionChanged,
    required this.onRetentionDaysChanged,
    required this.onNukeData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Data Collection Toggle
          _buildSettingTile(
            icon: Icons.cloud_upload,
            iconColor: const Color(0xFF3B82F6),
            title: 'Data Collection',
            subtitle: 'Store analysis data in the cloud',
            trailing: Switch(
              value: dataCollectionEnabled,
              onChanged: onDataCollectionChanged,
              activeColor: const Color(0xFF6366F1),
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Data Retention
          _buildSettingTile(
            icon: Icons.schedule,
            iconColor: const Color(0xFFF59E0B),
            title: 'Data Retention',
            subtitle: 'Keep data for $dataRetentionDays days',
            trailing: DropdownButton<int>(
              value: dataRetentionDays,
              dropdownColor: const Color(0xFF334155),
              underline: const SizedBox(),
              items: [7, 14, 30, 60, 90].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days days'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onRetentionDaysChanged(value);
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Export Data
          _buildSettingTile(
            icon: Icons.download,
            iconColor: const Color(0xFF22C55E),
            title: 'Export My Data',
            subtitle: 'Download all your data (GDPR)',
            trailing: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
              onPressed: () {
                // TODO: Implement data export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export coming soon'),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Nuke Data Button
          InkWell(
            onTap: isDeletingData ? null : onNukeData,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isDeletingData
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        : const Icon(
                            Icons.delete_forever,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delete All My Data',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permanently remove all data (GDPR)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
