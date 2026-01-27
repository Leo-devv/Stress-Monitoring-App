import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class StressGaugeWidget extends StatelessWidget {
  final int stressLevel;

  const StressGaugeWidget({
    super.key,
    required this.stressLevel,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStressColor(stressLevel);
    final label = AppColors.getStressLabel(stressLevel);

    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SfRadialGauge(
        animationDuration: 500,
        enableLoadingAnimation: true,
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 100,
            showLabels: false,
            showTicks: true,
            startAngle: 135,
            endAngle: 45,
            radiusFactor: 0.9,
            axisLineStyle: const AxisLineStyle(
              thickness: 0.15,
              thicknessUnit: GaugeSizeUnit.factor,
              color: AppColors.border,
            ),
            majorTickStyle: MajorTickStyle(
              length: 10,
              thickness: 2,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            minorTicksPerInterval: 4,
            minorTickStyle: MinorTickStyle(
              length: 5,
              thickness: 1,
              color: AppColors.textMuted.withOpacity(0.3),
            ),
            pointers: <GaugePointer>[
              // Arc pointer showing current level
              RangePointer(
                value: stressLevel.toDouble(),
                width: 0.15,
                sizeUnit: GaugeSizeUnit.factor,
                cornerStyle: CornerStyle.bothCurve,
                gradient: SweepGradient(
                  colors: [
                    color.withOpacity(0.4),
                    color,
                  ],
                  stops: const [0.25, 1.0],
                ),
              ),
              // Needle pointer - shorter to not overlap text
              NeedlePointer(
                value: stressLevel.toDouble(),
                needleLength: 0.5,
                needleStartWidth: 1,
                needleEndWidth: 3,
                needleColor: AppColors.textPrimary,
                knobStyle: const KnobStyle(
                  color: AppColors.textPrimary,
                  sizeUnit: GaugeSizeUnit.factor,
                  knobRadius: 0.06,
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              // Stress level value - positioned higher to avoid needle
              GaugeAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$stressLevel%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                angle: 90,
                positionFactor: 0.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
