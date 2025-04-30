import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../entities/quotes.dart';

part '../generated/database/database.g.dart';

@DriftDatabase(tables: [Quotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'quotely_database.db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }
}
