import 'dart:math';

/// Pure-Dart implementation of the Lomb-Scargle periodogram for
/// unevenly-sampled RR interval series.
///
/// Reference: Lomb N.R. (1976), Scargle J.D. (1982).
/// Used to estimate power spectral density in the LF (0.04–0.15 Hz)
/// and HF (0.15–0.4 Hz) bands without requiring uniform resampling.
class LombScargle {
  /// Computes the Lomb-Scargle periodogram.
  ///
  /// [timestamps] – cumulative time in seconds for each RR sample.
  /// [values]     – RR interval durations in milliseconds.
  /// [frequencies] – list of angular frequencies (Hz) at which to evaluate PSD.
  ///
  /// Returns power spectral density values (ms^2/Hz) at each frequency.
  static List<double> periodogram({
    required List<double> timestamps,
    required List<double> values,
    required List<double> frequencies,
  }) {
    final n = values.length;
    if (n < 4) return List.filled(frequencies.length, 0.0);

    // Subtract mean
    final mean = values.reduce((a, b) => a + b) / n;
    final centered = values.map((v) => v - mean).toList();

    // Variance for normalisation
    final variance =
        centered.map((v) => v * v).reduce((a, b) => a + b) / (n - 1);
    if (variance == 0) return List.filled(frequencies.length, 0.0);

    final psd = <double>[];
    const twoPi = 2.0 * pi;

    for (final freq in frequencies) {
      if (freq <= 0) {
        psd.add(0.0);
        continue;
      }

      final omega = twoPi * freq;

      // Compute tau (time offset that makes the periodogram independent of
      // time origin shift)
      double sumSin2 = 0.0;
      double sumCos2 = 0.0;
      for (int i = 0; i < n; i++) {
        final angle = 2.0 * omega * timestamps[i];
        sumSin2 += sin(angle);
        sumCos2 += cos(angle);
      }
      final tau = atan2(sumSin2, sumCos2) / (2.0 * omega);

      // Compute the spectral power at this frequency
      double cosSum = 0.0, cosDen = 0.0;
      double sinSum = 0.0, sinDen = 0.0;
      for (int i = 0; i < n; i++) {
        final phase = omega * (timestamps[i] - tau);
        final c = cos(phase);
        final s = sin(phase);
        cosSum += centered[i] * c;
        cosDen += c * c;
        sinSum += centered[i] * s;
        sinDen += s * s;
      }

      double power = 0.0;
      if (cosDen > 0) power += (cosSum * cosSum) / cosDen;
      if (sinDen > 0) power += (sinSum * sinSum) / sinDen;
      power *= 0.5;

      psd.add(power);
    }

    return psd;
  }

  /// Integrates power in a frequency band using the trapezoidal rule.
  ///
  /// [frequencies] and [psd] are parallel arrays.
  /// [fLow] / [fHigh] define the integration band (Hz).
  static double bandPower({
    required List<double> frequencies,
    required List<double> psd,
    required double fLow,
    required double fHigh,
  }) {
    double power = 0.0;
    for (int i = 0; i < frequencies.length - 1; i++) {
      final f0 = frequencies[i];
      final f1 = frequencies[i + 1];
      // Only include segments within the band
      if (f1 < fLow || f0 > fHigh) continue;
      final lo = max(f0, fLow);
      final hi = min(f1, fHigh);
      if (hi <= lo) continue;

      // Linear interpolation for PSD at band edges
      final t0 = (lo - f0) / (f1 - f0);
      final t1 = (hi - f0) / (f1 - f0);
      final p0 = psd[i] + t0 * (psd[i + 1] - psd[i]);
      final p1 = psd[i] + t1 * (psd[i + 1] - psd[i]);

      power += 0.5 * (p0 + p1) * (hi - lo);
    }
    return power;
  }

  /// Generates evenly-spaced frequency points for periodogram evaluation.
  static List<double> frequencyGrid({
    double fMin = 0.01,
    double fMax = 0.5,
    int nFrequencies = 256,
  }) {
    final step = (fMax - fMin) / (nFrequencies - 1);
    return List.generate(nFrequencies, (i) => fMin + i * step);
  }
}
