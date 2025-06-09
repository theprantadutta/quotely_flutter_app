import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';

import '../database/database.dart';
import 'analytics_service.dart';
import 'app_database_service.dart';

final getIt = GetIt.instance;

void initServiceLocator() {
  getIt.registerSingleton<AppDatabase>(AppDatabaseService.database);
  getIt.registerSingleton<FirebaseAnalytics>(AnalyticsService.analytics);
}
