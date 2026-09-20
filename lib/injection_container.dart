import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Repositories
import 'domain/repositories/scenario_repository.dart';
import 'data/repositories/scenario_repository_impl.dart';
import 'domain/repositories/content_repository.dart';
import 'data/repositories/content_repository_impl.dart';

// Data Sources
import 'data/datasources/remote_data_source.dart';

// Services
import 'services/ai_analysis_service.dart';
import 'services/tts_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_manager.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);

  sl.registerLazySingleton<FirebaseRemoteDataSource>(() => FirebaseRemoteDataSource());

  sl.registerLazySingleton(() => AiAnalysisService());
  sl.registerLazySingleton(() => TtsService());
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AdManager());

  sl.registerLazySingleton<ScenarioRepository>(
    () => ScenarioRepositoryImpl(),
  );
  
  sl.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(),
  );
}
