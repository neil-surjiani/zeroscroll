// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUsageLogsTable extends LocalUsageLogs
    with TableInfo<$LocalUsageLogsTable, LocalUsageLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsageLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recordedAt, durationSeconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_usage_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUsageLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUsageLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUsageLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
    );
  }

  @override
  $LocalUsageLogsTable createAlias(String alias) {
    return $LocalUsageLogsTable(attachedDatabase, alias);
  }
}

class LocalUsageLog extends DataClass implements Insertable<LocalUsageLog> {
  final int id;
  final DateTime recordedAt;
  final int durationSeconds;
  const LocalUsageLog({
    required this.id,
    required this.recordedAt,
    required this.durationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    return map;
  }

  LocalUsageLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalUsageLogsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      durationSeconds: Value(durationSeconds),
    );
  }

  factory LocalUsageLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUsageLog(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
    };
  }

  LocalUsageLog copyWith({
    int? id,
    DateTime? recordedAt,
    int? durationSeconds,
  }) => LocalUsageLog(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
  );
  LocalUsageLog copyWithCompanion(LocalUsageLogsCompanion data) {
    return LocalUsageLog(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsageLog(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, durationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUsageLog &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.durationSeconds == this.durationSeconds);
}

class LocalUsageLogsCompanion extends UpdateCompanion<LocalUsageLog> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<int> durationSeconds;
  const LocalUsageLogsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  });
  LocalUsageLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required int durationSeconds,
  }) : recordedAt = Value(recordedAt),
       durationSeconds = Value(durationSeconds);
  static Insertable<LocalUsageLog> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<int>? durationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
  }

  LocalUsageLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? recordedAt,
    Value<int>? durationSeconds,
  }) {
    return LocalUsageLogsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsageLogsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUsageLogsTable localUsageLogs = $LocalUsageLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localUsageLogs];
}

typedef $$LocalUsageLogsTableCreateCompanionBuilder =
    LocalUsageLogsCompanion Function({
      Value<int> id,
      required DateTime recordedAt,
      required int durationSeconds,
    });
typedef $$LocalUsageLogsTableUpdateCompanionBuilder =
    LocalUsageLogsCompanion Function({
      Value<int> id,
      Value<DateTime> recordedAt,
      Value<int> durationSeconds,
    });

class $$LocalUsageLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsageLogsTable> {
  $$LocalUsageLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsageLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsageLogsTable> {
  $$LocalUsageLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsageLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsageLogsTable> {
  $$LocalUsageLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );
}

class $$LocalUsageLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUsageLogsTable,
          LocalUsageLog,
          $$LocalUsageLogsTableFilterComposer,
          $$LocalUsageLogsTableOrderingComposer,
          $$LocalUsageLogsTableAnnotationComposer,
          $$LocalUsageLogsTableCreateCompanionBuilder,
          $$LocalUsageLogsTableUpdateCompanionBuilder,
          (
            LocalUsageLog,
            BaseReferences<_$AppDatabase, $LocalUsageLogsTable, LocalUsageLog>,
          ),
          LocalUsageLog,
          PrefetchHooks Function()
        > {
  $$LocalUsageLogsTableTableManager(
    _$AppDatabase db,
    $LocalUsageLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsageLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsageLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsageLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
              }) => LocalUsageLogsCompanion(
                id: id,
                recordedAt: recordedAt,
                durationSeconds: durationSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime recordedAt,
                required int durationSeconds,
              }) => LocalUsageLogsCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                durationSeconds: durationSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsageLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUsageLogsTable,
      LocalUsageLog,
      $$LocalUsageLogsTableFilterComposer,
      $$LocalUsageLogsTableOrderingComposer,
      $$LocalUsageLogsTableAnnotationComposer,
      $$LocalUsageLogsTableCreateCompanionBuilder,
      $$LocalUsageLogsTableUpdateCompanionBuilder,
      (
        LocalUsageLog,
        BaseReferences<_$AppDatabase, $LocalUsageLogsTable, LocalUsageLog>,
      ),
      LocalUsageLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUsageLogsTableTableManager get localUsageLogs =>
      $$LocalUsageLogsTableTableManager(_db, _db.localUsageLogs);
}
