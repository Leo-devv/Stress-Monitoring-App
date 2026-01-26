import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../core/constants/stress_thresholds.dart';

class StressGaugeWidget extends StatelessWidget {
  final int stressLevel;

  const StressGaugeWidget({
    super.key,
    required this.stressLevel,
  });

  @override
  Widget build(BuildContext context) {
    final color = StressThresholds.getStressColor(stressLevel);
    final label = StressThresholds.getStressLabel(stressLevel);

    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
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
            axisLineStyle: AxisLineStyle(
              thickness: 0.15,
              thicknessUnit: GaugeSizeUnit.factor,
              color: Colors.white.withOpacity(0.1),
            ),
            majorTickStyle: const MajorTickStyle(
              length: 10,
              thickness: 2,
              color: Colors.white24,
            ),
            minorTicksPerInterval: 4,
            minorTickStyle: const MinorTickStyle(
              length: 5,
              thickness: 1,
              color: Colors.white12,
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
                    color.withOpacity(0.5),
                    color,
                  ],
                  stops: const [0.25, 1.0],
                ),
              ),
              // Needle pointer
              NeedlePointer(
                value: stressLevel.toDouble(),
                needleLength: 0.6,
                needleStartWidth: 1,
                needleEndWidth: 4,
                needleColor: Colors.white,
                knobStyle: const KnobStyle(
                  color: Colors.white,
                  sizeUnit: GaugeSizeUnit.factor,
                  knobRadius: 0.08,
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              // Stress level value
              GaugeAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$stressLevel',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                angle: 90,
                positionFactor: 0.1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
