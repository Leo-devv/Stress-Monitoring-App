import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/entities/stress_assessment.dart';
import 'cloud_inference_service.dart';

/// Offline-first sync queue for stress assessments.
///
/// When a Firestore write fails (e.g. airplane mode), the assessment
/// is serialised into a Hive box.  On reconnection the queue is
/// drained in FIFO order and each item retried.  Successfully synced
/// entries are removed from disk immediately.
class SyncQueueService {
  static const String _boxName = 'sync_queue';

  final CloudInferenceService _cloudService;
  final Connectivity _connectivity;

  Box<String>? _box;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isFlushing = false;

  SyncQueueService({
    required CloudInferenceService cloudService,
    Connectivity? connectivity,
  })  : _cloudService = cloudService,
        _connectivity = connectivity ?? Connectivity();

  /// Opens the Hive box and starts listening to connectivity changes.
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);

    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        flushQueue();
      }
    });

    // Also try flushing at startup in case items were queued last session.
    flushQueue();
  }

  /// Enqueues a failed assessment for later retry.
  Future<void> enqueue(StressAssessment assessment) async {
    final box = _box;
    if (box == null) return;
    await box.add(jsonEncode(assessment.toJson()));
    debugPrint('SyncQueue: enqueued assessment (queue size: ${box.length})');
  }

  /// The number of items currently waiting in the queue.
  int get pendingCount => _box?.length ?? 0;

  /// Attempts to drain the queue, writing each item to Firestore.
  Future<void> flushQueue() async {
    final box = _box;
    if (box == null || box.isEmpty || _isFlushing) return;
    _isFlushing = true;

    debugPrint('SyncQueue: flushing ${box.length} items');

    // Iterate over a copy of keys so we can delete during iteration.
    final keys = box.keys.toList();
    for (final key in keys) {
      final json = box.get(key);
      if (json == null) continue;

      try {
        final assessment = StressAssessment.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        await _cloudService.storeAssessment(assessment);
        await box.delete(key);
        debugPrint('SyncQueue: synced & removed item $key');
      } catch (e) {
        // Stop flushing on first failure — likely still offline.
        debugPrint('SyncQueue: flush stopped at item $key ($e)');
        break;
      }
    }

    _isFlushing = false;
  }

  /// Permanently clears all queued items (used by GDPR "nuke data").
  Future<void> clearQueue() async {
    await _box?.clear();
    debugPrint('SyncQueue: queue cleared');
  }

  void dispose() {
    _connectivitySub?.cancel();
    _box?.close();
  }
}
