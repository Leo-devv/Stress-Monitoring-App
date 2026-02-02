import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/breathing_circle.dart';

/// Guided 4-7-8 breathing exercise for stress reduction.
///
/// Pattern: Inhale (4s) -> Hold (7s) -> Exhale (8s) = 19s per cycle.
/// Default session length is 3 minutes (~9 cycles).
///
/// This is the standard intervention included in Garmin, Fitbit, Samsung
/// Health, Headspace, and nearly every commercial stress management app.
class BreathingExercisePage extends StatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const int _inhaleDuration = 4;
  static const int _holdDuration = 7;
  static const int _exhaleDuration = 8;
  static const int _cycleSeconds =
      _inhaleDuration + _holdDuration + _exhaleDuration;
  static const int _sessionMinutes = 3;
  static const int _totalCycles =
      (_sessionMinutes * 60) ~/ _cycleSeconds;

  bool _isRunning = false;
  int _currentCycle = 0;
  int _elapsedSeconds = 0;
  Timer? _sessionTimer;
  _BreathPhase _phase = _BreathPhase.idle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleSeconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _currentCycle = 0;
      _elapsedSeconds = 0;
    });

    _runCycle();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
        _updatePhase();
      });

      if (_elapsedSeconds >= _sessionMinutes * 60) {
        _endSession();
      }
    });
  }

  void _runCycle() {
    _controller.reset();
    // Animate from 0 -> 1 over the inhale portion,
    // stay at 1 during hold, then 1 -> 0 during exhale.
    _controller.forward();
    _currentCycle++;

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isRunning) {
        _controller.reset();
        _controller.forward();
        _currentCycle++;
      }
    });
  }

  void _updatePhase() {
    final positionInCycle = _elapsedSeconds % _cycleSeconds;
    if (positionInCycle < _inhaleDuration) {
      _phase = _BreathPhase.inhale;
    } else if (positionInCycle < _inhaleDuration + _holdDuration) {
      _phase = _BreathPhase.hold;
    } else {
      _phase = _BreathPhase.exhale;
    }
  }

  void _endSession() {
    _sessionTimer?.cancel();
    _controller.stop();
    setState(() {
      _isRunning = false;
      _phase = _BreathPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _phase.label;
    final phaseColor = _phase.color;
    final remaining = (_sessionMinutes * 60) - _elapsedSeconds;
    final remainingMin = remaining ~/ 60;
    final remainingSec = remaining % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Breathing Exercise', style: AppTypography.h3),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Instruction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.self_improvement,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('4-7-8 Technique',
                              style: AppTypography.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('Inhale 4s, Hold 7s, Exhale 8s',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Breathing circle
              BreathingCircle(
                animation: _controller,
                phaseLabel: _isRunning ? phaseLabel : 'Ready',
                phaseColor:
                    _isRunning ? phaseColor : AppColors.primary,
              ),

              const SizedBox(height: 32),

              // Timer display
              if (_isRunning)
                Text(
                  '$remainingMin:${remainingSec.toString().padLeft(2, '0')}',
                  style: AppTypography.numericLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

              if (_isRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Cycle $_currentCycle of $_totalCycles',
                    style: AppTypography.caption,
                  ),
                ),

              const Spacer(),

              // Start / Stop button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRunning ? _endSession : _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRunning ? AppColors.stressHigh : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  child: Text(
                    _isRunning ? 'End Session' : 'Begin Session',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BreathPhase {
  idle,
  inhale,
  hold,
  exhale;

  String get label {
    switch (this) {
      case _BreathPhase.idle:
        return 'Ready';
      case _BreathPhase.inhale:
        return 'Inhale';
      case _BreathPhase.hold:
        return 'Hold';
      case _BreathPhase.exhale:
        return 'Exhale';
    }
  }

  Color get color {
    switch (this) {
      case _BreathPhase.idle:
        return AppColors.primary;
      case _BreathPhase.inhale:
        return AppColors.stressLow;
      case _BreathPhase.hold:
        return AppColors.stressNormal;
      case _BreathPhase.exhale:
        return AppColors.cloudMode;
    }
  }
}
