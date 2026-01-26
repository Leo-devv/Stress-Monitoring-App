import 'package:get_it/get_it.dart';
import '../core/network/network_info.dart';
import '../core/utils/battery_utils.dart';
import '../services/sensor_simulator_service.dart';
import '../services/offloading_manager.dart';
import '../services/edge_inference_service.dart';
import '../services/cloud_inference_service.dart';
import '../services/stress_analysis_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo());
  sl.registerLazySingleton<BatteryUtils>(() => BatteryUtils());

  // Services
  sl.registerLazySingleton<SensorSimulatorService>(
    () => SensorSimulatorService(),
  );

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

  // Initialize edge service
  await sl<EdgeInferenceService>().initialize();
}
