import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet that asks the user to self-report their perceived stress
/// on a 1–10 scale.  Returns the selected value or null if dismissed.
class SubjectiveStressDialog extends StatefulWidget {
  const SubjectiveStressDialog({super.key});

  /// Shows the dialog and returns the user's rating (1-10), or null.
  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SubjectiveStressDialog(),
    );
  }

  @override
  State<SubjectiveStressDialog> createState() => _SubjectiveStressDialogState();
}

class _SubjectiveStressDialogState extends State<SubjectiveStressDialog> {
  double _rating = 5;

  String get _label {
    if (_rating <= 2) return 'Very relaxed';
    if (_rating <= 4) return 'Slightly stressed';
    if (_rating <= 6) return 'Moderately stressed';
    if (_rating <= 8) return 'Quite stressed';
    return 'Extremely stressed';
  }

  Color get _color {
    if (_rating <= 2) return AppColors.stressLow;
    if (_rating <= 4) return AppColors.stressNormal;
    if (_rating <= 6) return AppColors.stressElevated;
    if (_rating <= 8) return AppColors.stressHigh;
    return AppColors.stressCritical;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'How stressed do you feel right now?',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'This helps validate the monitoring accuracy.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Rating number
          Text(
            _rating.round().toString(),
            style: AppTypography.numeric.copyWith(
              fontSize: 48,
              color: _color,
            ),
          ),
          Text(
            _label,
            style: AppTypography.bodyMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Slider
          Row(
            children: [
              Text('1', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: _color,
                  inactiveColor: _color.withAlpha(50),
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
              Text('10', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(_rating.round()),
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
