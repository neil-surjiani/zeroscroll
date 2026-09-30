import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// Local Drift SQLite database managing ZeroScroll limits, sessions, and settings.
/// Operates strictly on-device with no remote network transmission.
class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS usage_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_time INTEGER NOT NULL,
              end_time INTEGER
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_usage_sessions_start 
            ON usage_sessions(start_time DESC);
          ''');

          await customStatement('''
            CREATE TABLE IF NOT EXISTS reel_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER NOT NULL,
              reel_id TEXT
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_reel_events_timestamp 
            ON reel_events(timestamp DESC);
          ''');

          await customStatement('''
            CREATE TABLE IF NOT EXISTS story_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER NOT NULL,
              username TEXT,
              story_id TEXT
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_story_events_timestamp 
            ON story_events(timestamp DESC);
          ''');

          await customStatement('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            );
          ''');
        },
      );

  // ==========================================
  // USAGE SESSIONS
  // ==========================================

  /// Inserts a new session start, returning the newly created session ID.
  Future<int> startUsageSession(DateTime startTime) async {
    return customInsert(
      'INSERT INTO usage_sessions (start_time) VALUES (?)',
      variables: [Variable.withInt(startTime.millisecondsSinceEpoch)],
    );
  }

  /// Closes an ongoing usage session with [endTime].
  Future<void> endUsageSession(int sessionId, DateTime endTime) async {
    await customUpdate(
      'UPDATE usage_sessions SET end_time = ? WHERE id = ?',
      variables: [
        Variable.withInt(endTime.millisecondsSinceEpoch),
        Variable.withInt(sessionId),
      ],
      updates: {},
    );
  }

  /// Closes all open sessions (useful on app launch or crash recovery).
  Future<void> closeOpenSessions(DateTime fallbackEndTime) async {
    await customUpdate(
      'UPDATE usage_sessions SET end_time = ? WHERE end_time IS NULL',
      variables: [Variable.withInt(fallbackEndTime.millisecondsSinceEpoch)],
      updates: {},
    );
  }

  /// Returns total usage in seconds within a given time range [from] to [to].
  Future<int> getUsageDurationSeconds(DateTime from, DateTime to) async {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;

    final rows = await customSelect(
      '''
      SELECT start_time, end_time FROM usage_sessions 
      WHERE start_time <= ? AND (end_time >= ? OR end_time IS NULL)
      ''',
      variables: [Variable.withInt(toMs), Variable.withInt(fromMs)],
    ).get();

    int totalSeconds = 0;
    for (final row in rows) {
      final s = row.read<int>('start_time');
      final e = row.readNullable<int>('end_time') ?? toMs;

      final sessionStart = s < fromMs ? fromMs : s;
      final sessionEnd = e > toMs ? toMs : e;

      if (sessionEnd > sessionStart) {
        totalSeconds += ((sessionEnd - sessionStart) ~/ 1000);
      }
    }

    return totalSeconds;
  }

  /// Returns list of all closed sessions within a time range.
  Future<List<Map<String, dynamic>>> getUsageSessions(DateTime from, DateTime to) async {
    final rows = await customSelect(
      '''
      SELECT id, start_time, end_time FROM usage_sessions 
      WHERE start_time >= ? AND start_time <= ?
      ORDER BY start_time DESC
      ''',
      variables: [
        Variable.withInt(from.millisecondsSinceEpoch),
        Variable.withInt(to.millisecondsSinceEpoch),
      ],
    ).get();

    return rows.map((r) {
      return {
        'id': r.read<int>('id'),
        'startTime': r.read<int>('start_time'),
        'endTime': r.readNullable<int>('end_time'),
      };
    }).toList();
  }

  // ==========================================
  // REEL EVENTS
  // ==========================================

  /// Records a new reel opened event.
  Future<int> recordReelEvent(DateTime timestamp, [String? reelId]) async {
    return customInsert(
      'INSERT INTO reel_events (timestamp, reel_id) VALUES (?, ?)',
      variables: [
        Variable.withInt(timestamp.millisecondsSinceEpoch),
        Variable.withString(reelId ?? ''),
      ],
    );
  }

  /// Returns the count of reels opened between [from] and [to].
  Future<int> getReelsCount(DateTime from, DateTime to) async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS total FROM reel_events 
      WHERE timestamp >= ? AND timestamp <= ?
      ''',
      variables: [
        Variable.withInt(from.millisecondsSinceEpoch),
        Variable.withInt(to.millisecondsSinceEpoch),
      ],
    ).getSingle();

    return row.read<int>('total');
  }

  /// Returns list of all reel events between [from] and [to].
  Future<List<Map<String, dynamic>>> getReelEvents(DateTime from, DateTime to) async {
    final rows = await customSelect(
      '''
      SELECT id, timestamp, reel_id FROM reel_events 
      WHERE timestamp >= ? AND timestamp <= ?
      ORDER BY timestamp DESC
      ''',
      variables: [
        Variable.withInt(from.millisecondsSinceEpoch),
        Variable.withInt(to.millisecondsSinceEpoch),
      ],
    ).get();

    return rows.map((r) {
      return {
        'id': r.read<int>('id'),
        'timestamp': r.read<int>('timestamp'),
        'reelId': r.readNullable<String>('reel_id'),
      };
    }).toList();
  }

  // ==========================================
  // STORY EVENTS
  // ==========================================

  /// Records a new story viewed event.
  Future<int> recordStoryEvent(DateTime timestamp, [String? username, String? storyId]) async {
    return customInsert(
      'INSERT INTO story_events (timestamp, username, story_id) VALUES (?, ?, ?)',
      variables: [
        Variable.withInt(timestamp.millisecondsSinceEpoch),
        Variable.withString(username ?? ''),
        Variable.withString(storyId ?? ''),
      ],
    );
  }

  /// Returns the count of stories viewed between [from] and [to], optionally filtered by [username].
  Future<int> getStoryCount(DateTime from, DateTime to, [String? username]) async {
    final hasUser = username != null && username.isNotEmpty;
    final sql = hasUser
        ? 'SELECT COUNT(*) AS total FROM story_events WHERE timestamp >= ? AND timestamp <= ? AND username = ?'
        : 'SELECT COUNT(*) AS total FROM story_events WHERE timestamp >= ? AND timestamp <= ?';
    final vars = [
      Variable.withInt(from.millisecondsSinceEpoch),
      Variable.withInt(to.millisecondsSinceEpoch),
      if (hasUser) Variable.withString(username),
    ];

    final row = await customSelect(sql, variables: vars).getSingle();
    return row.read<int>('total');
  }

  /// Returns list of all story events between [from] and [to].
  Future<List<Map<String, dynamic>>> getStoryEvents(DateTime from, DateTime to) async {
    final rows = await customSelect(
      '''
      SELECT id, timestamp, username, story_id FROM story_events 
      WHERE timestamp >= ? AND timestamp <= ?
      ORDER BY timestamp DESC
      ''',
      variables: [
        Variable.withInt(from.millisecondsSinceEpoch),
        Variable.withInt(to.millisecondsSinceEpoch),
      ],
    ).get();

    return rows.map((r) {
      return {
        'id': r.read<int>('id'),
        'timestamp': r.read<int>('timestamp'),
        'username': r.readNullable<String>('username'),
        'storyId': r.readNullable<String>('story_id'),
      };
    }).toList();
  }

  // ==========================================
  // SETTINGS KEY-VALUE
  // ==========================================

  /// Retrieves a string setting by [key].
  Future<String?> getSetting(String key) async {
    final row = await customSelect(
      'SELECT value FROM settings WHERE key = ?',
      variables: [Variable.withString(key)],
    ).getSingleOrNull();

    return row?.read<String>('value');
  }

  /// Sets or updates a setting [key] to [value].
  Future<void> setSetting(String key, String value) async {
    await customInsert(
      'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      variables: [Variable.withString(key), Variable.withString(value)],
    );
  }

  /// Deletes a setting by [key].
  Future<void> deleteSetting(String key) async {
    await customUpdate(
      'DELETE FROM settings WHERE key = ?',
      variables: [Variable.withString(key)],
      updates: {},
    );
  }

  /// Returns all settings as a key-value Map.
  Future<Map<String, String>> getAllSettings() async {
    final rows = await customSelect('SELECT key, value FROM settings').get();
    return {
      for (final r in rows) r.read<String>('key'): r.read<String>('value'),
    };
  }

  // ==========================================
  // DATA MANAGEMENT & EXPORT
  // ==========================================

  /// Exports all database tables to a structured JSON Map.
  Future<Map<String, dynamic>> exportAllData() async {
    final sessions = await customSelect(
      'SELECT id, start_time, end_time FROM usage_sessions ORDER BY start_time ASC',
    ).get();

    final reels = await customSelect(
      'SELECT id, timestamp, reel_id FROM reel_events ORDER BY timestamp ASC',
    ).get();

    final stories = await customSelect(
      'SELECT id, timestamp, username, story_id FROM story_events ORDER BY timestamp ASC',
    ).get();

    final settings = await customSelect('SELECT key, value FROM settings').get();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'usageSessions': sessions.map((r) => {
        'id': r.read<int>('id'),
        'startTime': DateTime.fromMillisecondsSinceEpoch(r.read<int>('start_time')).toIso8601String(),
        'endTime': r.readNullable<int>('end_time') != null
            ? DateTime.fromMillisecondsSinceEpoch(r.read<int>('end_time')).toIso8601String()
            : null,
      }).toList(),
      'reelEvents': reels.map((r) => {
        'id': r.read<int>('id'),
        'timestamp': DateTime.fromMillisecondsSinceEpoch(r.read<int>('timestamp')).toIso8601String(),
        'reelId': r.readNullable<String>('reel_id'),
      }).toList(),
      'storyEvents': stories.map((r) => {
        'id': r.read<int>('id'),
        'timestamp': DateTime.fromMillisecondsSinceEpoch(r.read<int>('timestamp')).toIso8601String(),
        'username': r.readNullable<String>('username'),
        'storyId': r.readNullable<String>('story_id'),
      }).toList(),
      'settings': {
        for (final r in settings) r.read<String>('key'): r.read<String>('value'),
      },
    };
  }

  /// Completely deletes all user usage data and resets settings.
  Future<void> deleteAllData() async {
    await customStatement('DELETE FROM usage_sessions;');
    await customStatement('DELETE FROM reel_events;');
    await customStatement('DELETE FROM story_events;');
    await customStatement('DELETE FROM settings;');
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File('${dbFolder.path}/zeroscroll_limits.db');
      return NativeDatabase.createInBackground(file);
    });
  }
}
