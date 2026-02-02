import 'package:get_it/get_it.dart';
import '../core/network/network_info.dart';
import '../core/utils/battery_utils.dart';
import '../services/sensor_simulator_service.dart';
import '../services/sensor/simulator_source.dart';
import '../services/sensor/ble_heart_rate_source.dart';
import '../services/sensor/camera_ppg_source.dart';
import '../services/sensor/sensor_manager.dart';
import '../services/hrv_computation_service.dart';
import '../services/baseline_service.dart';
import '../services/notification_service.dart';
import '../services/offloading_manager.dart';
import '../services/edge_inference_service.dart';
import '../services/cloud_inference_service.dart';
import '../services/stress_analysis_service.dart';
import '../services/sync_queue_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo());
  sl.registerLazySingleton<BatteryUtils>(() => BatteryUtils());

  // Legacy simulator (used by SimulationProvider for manual overrides)
  sl.registerLazySingleton<SensorSimulatorService>(
    () => SensorSimulatorService(),
  );

  // Sensor sources
  sl.registerLazySingleton<SimulatorSource>(() => SimulatorSource());
  sl.registerLazySingleton<BleHeartRateSource>(() => BleHeartRateSource());
  sl.registerLazySingleton<CameraPpgSource>(() => CameraPpgSource());

  sl.registerLazySingleton<SensorManager>(
    () => SensorManager(
      bleSource: sl<BleHeartRateSource>(),
      cameraPpgSource: sl<CameraPpgSource>(),
      simulatorSource: sl<SimulatorSource>(),
    ),
  );

  // HRV computation + personal baseline
  sl.registerLazySingleton<HRVComputationService>(
    () => HRVComputationService(),
  );
  sl.registerLazySingleton<BaselineService>(() => BaselineService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Offloading + inference
  sl.registerLazySingleton<OffloadingManager>(
    () => OffloadingManager(
      networkInfo: sl(),
      batteryUtils: sl(),
    ),
  );

  sl.registerLazySingleton<EdgeInferenceService>(
    () => EdgeInferenceService(),
  );

  sl.registerLazySingleton<CloudInferenceService>(
    () => CloudInferenceService(),
  );

  sl.registerLazySingleton<StressAnalysisService>(
    () => StressAnalysisService(
      offloadingManager: sl(),
      edgeService: sl(),
      cloudService: sl(),
    ),
  );

  // Offline sync queue
  sl.registerLazySingleton<SyncQueueService>(
    () => SyncQueueService(cloudService: sl<CloudInferenceService>()),
  );

  // Initialize services that need async setup
  await sl<EdgeInferenceService>().initialize();
  await sl<BaselineService>().initialize();
  await sl<NotificationService>().initialize();

  // Initialize sync queue and wire it into cloud inference
  await sl<SyncQueueService>().initialize();
  sl<CloudInferenceService>().setSyncQueue(sl<SyncQueueService>());
}
