import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Local usage log table for tracking session durations on-device.
class LocalUsageLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
}

@DriftDatabase(tables: [LocalUsageLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/zeroscroll.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
