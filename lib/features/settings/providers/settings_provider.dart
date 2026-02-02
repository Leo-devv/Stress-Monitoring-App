import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/offloading_manager.dart';
import '../../../services/stress_analysis_service.dart';
import '../../../services/sync_queue_service.dart';
import '../../../di/injection_container.dart';
import '../../../core/constants/app_constants.dart';

// Settings state
class SettingsState {
  final OffloadingStrategy offloadingStrategy;
  final double batteryThreshold;
  final bool notificationsEnabled;
  final bool highStressAlerts;
  final bool dataCollectionEnabled;
  final int dataRetentionDays;
  final bool isDeletingData;
  final String? lastDeleteTime;

  const SettingsState({
    this.offloadingStrategy = OffloadingStrategy.auto,
    this.batteryThreshold = 0.20,
    this.notificationsEnabled = true,
    this.highStressAlerts = true,
    this.dataCollectionEnabled = true,
    this.dataRetentionDays = 30,
    this.isDeletingData = false,
    this.lastDeleteTime,
  });

  SettingsState copyWith({
    OffloadingStrategy? offloadingStrategy,
    double? batteryThreshold,
    bool? notificationsEnabled,
    bool? highStressAlerts,
    bool? dataCollectionEnabled,
    int? dataRetentionDays,
    bool? isDeletingData,
    String? lastDeleteTime,
  }) {
    return SettingsState(
      offloadingStrategy: offloadingStrategy ?? this.offloadingStrategy,
      batteryThreshold: batteryThreshold ?? this.batteryThreshold,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      highStressAlerts: highStressAlerts ?? this.highStressAlerts,
      dataCollectionEnabled: dataCollectionEnabled ?? this.dataCollectionEnabled,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      isDeletingData: isDeletingData ?? this.isDeletingData,
      lastDeleteTime: lastDeleteTime ?? this.lastDeleteTime,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final OffloadingManager _offloadingManager;
  final StressAnalysisService _analysisService;

  SettingsNotifier({
    required OffloadingManager offloadingManager,
    required StressAnalysisService analysisService,
  })  : _offloadingManager = offloadingManager,
        _analysisService = analysisService,
        super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from Hive if available
    try {
      final box = await Hive.openBox(AppConstants.userSettingsBox);
      final strategyIndex = box.get('offloadingStrategy', defaultValue: 0);
      final threshold = box.get('batteryThreshold', defaultValue: 0.20);
      final notifications = box.get('notificationsEnabled', defaultValue: true);
      final alerts = box.get('highStressAlerts', defaultValue: true);
      final collection = box.get('dataCollectionEnabled', defaultValue: true);
      final retention = box.get('dataRetentionDays', defaultValue: 30);

      state = state.copyWith(
        offloadingStrategy: OffloadingStrategy.values[strategyIndex],
        batteryThreshold: threshold,
        notificationsEnabled: notifications,
        highStressAlerts: alerts,
        dataCollectionEnabled: collection,
        dataRetentionDays: retention,
      );

      _offloadingManager.strategy = state.offloadingStrategy;
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox(AppConstants.userSettingsBox);
      await box.put('offloadingStrategy', state.offloadingStrategy.index);
      await box.put('batteryThreshold', state.batteryThreshold);
      await box.put('notificationsEnabled', state.notificationsEnabled);
      await box.put('highStressAlerts', state.highStressAlerts);
      await box.put('dataCollectionEnabled', state.dataCollectionEnabled);
      await box.put('dataRetentionDays', state.dataRetentionDays);
    } catch (e) {
      // Ignore save errors
    }
  }

  void setOffloadingStrategy(OffloadingStrategy strategy) {
    state = state.copyWith(offloadingStrategy: strategy);
    _offloadingManager.strategy = strategy;
    _saveSettings();
  }

  void setBatteryThreshold(double threshold) {
    state = state.copyWith(batteryThreshold: threshold);
    _saveSettings();
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _saveSettings();
  }

  void setHighStressAlerts(bool enabled) {
    state = state.copyWith(highStressAlerts: enabled);
    _saveSettings();
  }

  void setDataCollectionEnabled(bool enabled) {
    state = state.copyWith(dataCollectionEnabled: enabled);
    _saveSettings();
  }

  void setDataRetentionDays(int days) {
    state = state.copyWith(dataRetentionDays: days);
    _saveSettings();
  }

  /// GDPR "Nuke Data" — Deletes all local and cloud user data.
  Future<bool> nukeAllData() async {
    state = state.copyWith(isDeletingData: true);

    try {
      // Clear in-memory analysis history
      _analysisService.clearHistory();

      // Clear all Hive boxes (local data)
      await Hive.deleteBoxFromDisk(AppConstants.sensorReadingsBox);
      await Hive.deleteBoxFromDisk(AppConstants.stressHistoryBox);

      // Clear offline sync queue
      try {
        await sl<SyncQueueService>().clearQueue();
      } catch (_) {}

      // Delete Firestore user document + subcollections
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(uid);

        // Delete stress_assessments subcollection in chunks of 500
        // (Firestore batch limit)
        QuerySnapshot chunk;
        do {
          chunk = await userDoc
              .collection('stress_assessments')
              .limit(500)
              .get();
          if (chunk.docs.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in chunk.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }
        } while (chunk.docs.length == 500);

        // Delete user document itself
        await userDoc.delete();
        debugPrint('Firestore: deleted users/$uid and subcollections');
      }

      state = state.copyWith(
        isDeletingData: false,
        lastDeleteTime: DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      debugPrint('nukeAllData error: $e');
      state = state.copyWith(isDeletingData: false);
      return false;
    }
  }

  /// Export data for GDPR data portability
  Future<Map<String, dynamic>> exportAllData() async {
    // Collect all user data
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'settings': {
        'offloadingStrategy': state.offloadingStrategy.name,
        'batteryThreshold': state.batteryThreshold,
        'notificationsEnabled': state.notificationsEnabled,
        'highStressAlerts': state.highStressAlerts,
        'dataCollectionEnabled': state.dataCollectionEnabled,
        'dataRetentionDays': state.dataRetentionDays,
      },
      'stressHistory': _analysisService.history.map((a) => a.toJson()).toList(),
    };
  }
}

// Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    offloadingManager: sl<OffloadingManager>(),
    analysisService: sl<StressAnalysisService>(),
  );
});
