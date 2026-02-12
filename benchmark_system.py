"""
System Resource Utilization Benchmark
Measures actual computation latency for threshold-based stress classification.
"""

import time
import statistics
import sys

# Thresholds from stress_thresholds.dart
RMSSD_RELAXED, RMSSD_NORMAL, RMSSD_ELEVATED = 60.0, 40.0, 20.0
SDNN_RELAXED, SDNN_NORMAL, SDNN_ELEVATED = 80.0, 50.0, 30.0
PNN50_RELAXED, PNN50_NORMAL, PNN50_ELEVATED = 25.0, 10.0, 3.0
SI_RELAXED, SI_NORMAL, SI_ELEVATED = 100.0, 250.0, 500.0
LFHF_RELAXED, LFHF_NORMAL, LFHF_ELEVATED = 0.5, 2.0, 4.0
HF_RELAXED, HF_NORMAL, HF_ELEVATED = 400.0, 150.0, 40.0
HR_RELAXED, HR_NORMAL, HR_ELEVATED = 65.0, 80.0, 95.0

WEIGHTS = {'rmssd': 0.25, 'sdnn': 0.15, 'pnn50': 0.10, 'si': 0.15,
           'lfhf': 0.15, 'hf': 0.10, 'hr': 0.10}

def inverted_piecewise(value, relaxed, normal, elevated):
    if value >= relaxed:
        return max(0, 12.0 * (1 - (value - relaxed) / relaxed))
    elif value >= normal:
        return 13.0 + ((relaxed - value) / (relaxed - normal)) * 24.0
    elif value >= elevated:
        return 38.0 + ((normal - value) / (normal - elevated)) * 24.0
    else:
        t = min(1.0, (elevated - value) / elevated) if elevated > 0 else 1.0
        return 63.0 + t * 37.0

def direct_piecewise(value, relaxed, normal, elevated):
    if value <= relaxed:
        return (value / relaxed * 12.0) if relaxed > 0 else 0
    elif value <= normal:
        return 13.0 + ((value - relaxed) / (normal - relaxed)) * 24.0
    elif value <= elevated:
        return 38.0 + ((value - normal) / (elevated - normal)) * 24.0
    else:
        overshoot = min(1.0, (value - elevated) / elevated) if elevated > 0 else 1.0
        return 63.0 + overshoot * 37.0

def compute_stress_score(rmssd, sdnn, pnn50, si, lfhf, hf, hr):
    scores = {
        'rmssd': inverted_piecewise(rmssd, RMSSD_RELAXED, RMSSD_NORMAL, RMSSD_ELEVATED),
        'sdnn': inverted_piecewise(sdnn, SDNN_RELAXED, SDNN_NORMAL, SDNN_ELEVATED),
        'pnn50': inverted_piecewise(pnn50, PNN50_RELAXED, PNN50_NORMAL, PNN50_ELEVATED),
        'si': direct_piecewise(si, SI_RELAXED, SI_NORMAL, SI_ELEVATED),
        'lfhf': direct_piecewise(lfhf, LFHF_RELAXED, LFHF_NORMAL, LFHF_ELEVATED),
        'hf': inverted_piecewise(hf, HF_RELAXED, HF_NORMAL, HF_ELEVATED),
        'hr': direct_piecewise(hr, HR_RELAXED, HR_NORMAL, HR_ELEVATED),
    }
    composite = sum(scores[k] * WEIGHTS[k] for k in WEIGHTS)
    return int(round(max(0, min(100, composite))))

def benchmark():
    print("=" * 65)
    print("SYSTEM RESOURCE UTILIZATION BENCHMARK")
    print("Threshold-Based Stress Classification Engine")
    print("=" * 65)

    # Test samples representing different stress states
    test_samples = [
        (70, 90, 30, 80, 0.4, 500, 62),    # Relaxed
        (48, 60, 15, 170, 1.2, 250, 72),   # Normal
        (28, 38, 6, 380, 3.0, 90, 88),     # Elevated
        (14, 22, 1.5, 620, 5.5, 25, 102),  # High
    ]

    # Warm-up runs
    for _ in range(100):
        for sample in test_samples:
            compute_stress_score(*sample)

    # Benchmark runs
    n_iterations = 10000
    latencies = []

    print(f"\nRunning {n_iterations:,} iterations...")

    for i in range(n_iterations):
        sample = test_samples[i % 4]
        start = time.perf_counter_ns()
        compute_stress_score(*sample)
        end = time.perf_counter_ns()
        latencies.append((end - start) / 1000)  # Convert to microseconds

    # Calculate statistics
    mean_latency = statistics.mean(latencies)
    median_latency = statistics.median(latencies)
    stdev_latency = statistics.stdev(latencies)
    min_latency = min(latencies)
    max_latency = max(latencies)
    p95 = sorted(latencies)[int(0.95 * len(latencies))]
    p99 = sorted(latencies)[int(0.99 * len(latencies))]

    # Memory estimation
    constants_count = 21  # threshold values
    weights_count = 7
    total_floats = constants_count + weights_count
    memory_bytes = total_floats * 8  # 64-bit floats

    print("\n" + "-" * 65)
    print("EDGE INFERENCE LATENCY")
    print("-" * 65)
    print(f"  Iterations:        {n_iterations:,}")
    print(f"  Mean:              {mean_latency:.2f} us")
    print(f"  Median:            {median_latency:.2f} us")
    print(f"  Std Dev:           {stdev_latency:.2f} us")
    print(f"  Min:               {min_latency:.2f} us")
    print(f"  Max:               {max_latency:.2f} us")
    print(f"  P95:               {p95:.2f} us")
    print(f"  P99:               {p99:.2f} us")

    print("\n" + "-" * 65)
    print("RESOURCE CONSUMPTION")
    print("-" * 65)
    print(f"  HRV Features:      7")
    print(f"  Threshold Values:  {constants_count}")
    print(f"  Feature Weights:   {weights_count}")
    print(f"  Memory (constants): {memory_bytes} bytes")
    print(f"  Training Required: None")

    print("\n" + "-" * 65)
    print("CLOUD PATH OVERHEAD")
    print("-" * 65)
    print(f"  Network RTT:       200 ms (simulated)")
    print(f"  Total Cloud:       ~200 ms + computation")

    print("\n" + "-" * 65)
    print("OFFLOADING THRESHOLDS")
    print("-" * 65)
    print(f"  Battery Low:       20%")
    print(f"  Battery Critical:  10%")
    print(f"  WiFi Required:     Yes (for cloud path)")

    print("\n" + "=" * 65)
    print(f"Python {sys.version.split()[0]}")
    print("=" * 65)

if __name__ == "__main__":
    benchmark()
