# ADR-0029: Стратегия миграций SQLite/Drift schema

**Статус:** Принято  
**Дата:** 2026-09-11  
**Версия:** 0.1

## 1. Контекст

LifeOS использует SQLite через Drift как production persistence layer.

Текущая production schema имеет версию `1` и содержит:

- `entities`;
- `tasks`;
- `outbox`.

До настоящего момента приложение использовало только initial schema creation через `createAll()` и не выполняло реальные production schema upgrades.

Следующий этап развития Domain предполагает появление дополнительных persistent Entity types. Это впервые потребует безопасного перехода существующих пользовательских баз данных с одной schema version на другую.

Существующие ADR требуют:

- сохранения local-first данных;
- отсутствия destructive migration production state;
- Infrastructure ownership persistence concerns;
- сохранения Entity metadata;
- сохранения Outbox;
- стабильного device identity;
- generated Drift code без ручного редактирования.

Однако существующие ADR не определяют:

- orchestration миграций;
- порядок version-specific steps;
- transaction boundary;
- downgrade policy;
- schema snapshots;
- validation после migration;
- repeatable testing strategy.

Этот ADR фиксирует эти правила.

---

## 2. Решение

LifeOS использует последовательные version-specific migrations SQLite/Drift.

Пример:

```text
v1
 ↓ migrateV1ToV2
v2
 ↓ migrateV2ToV3
v3
````

Каждый schema transition имеет отдельный migration step.

Destructive recreation production database запрещена как стандартный migration mechanism.

---

## 3. Schema version ownership

`LifeOsDatabase.schemaVersion` является единственным источником текущей latest production database schema version.

SQLite `user_version` используется Drift для определения текущей версии конкретной database.

Domain, Application и Presentation не должны знать database schema version.

Schema version является Infrastructure concern.

---

## 4. Migration orchestration

`MigrationStrategy.onUpgrade` отвечает только за orchestration.

Он не должен превращаться в длинный список произвольного SQL для всех исторических версий.

Предпочтительная структура:

```
onUpgrade(from, to)
    ↓
validate migration direction
    ↓
run sequential migration steps
    ↓
validate resulting database
```

Version-specific logic размещается отдельно, например:

```
migrations/
├── lifeos_migration_strategy.dart
├── lifeos_migration_validation.dart
└── v1_to_v2.dart
```

При появлении будущей версии добавляется новый реальный step:

```
v2_to_v3.dart
```

Пустые speculative migration files заранее не создаются.

---

## 5. Последовательные переходы

При обновлении через несколько schema versions migrations выполняются строго последовательно.

Например:

```
v1 → v2 → v3
```

Нельзя пропускать промежуточный transition, если для него существует migration logic.

Каждый step должен предполагать только документированное состояние входной версии.

---

## 6. Transaction boundary

Полная цепочка migration одного database open должна выполняться атомарно.

Migration orchestration владеет общей transaction boundary.

Отдельные migration steps не должны открывать независимые вложенные transactions.

Если любой migration step или validation завершается ошибкой:

- вся migration откатывается;
- исходные пользовательские данные остаются неизменными;
- schema version не считается успешно обновлённой;
- database не публикуется repositories/application;
- следующая попытка открытия снова начинает migration с исходной версии.

---

## 7. Сохранность данных

Schema migration не является Domain mutation.

Поэтому migration:

- не создаёт Outbox Changes;
- не меняет Entity version только из-за технического schema upgrade;
- не меняет `createdAt`;
- не меняет `updatedAt`, если это не является необходимой частью явного data transformation;
- не меняет Entity ID;
- не меняет source/provenance;
- не очищает Outbox;
- не меняет `device_id`.

Существующие Tasks, Entity metadata и Outbox должны сохраняться, если конкретная migration явно не определяет допустимую трансформацию.

---

## 8. Device identity

`device_id` хранится вне SQLite production database.

Schema migrations SQLite не должны читать, изменять или регенерировать `device_id`.

Migration failure не влияет на installation identity.

---

## 9. Foreign keys

Foreign keys должны быть включены в normal production operation.

Если конкретная migration требует временного изменения FK enforcement, это должно быть явно ограничено migration orchestration.

Перед успешным завершением migration выполняется проверка:

```
PRAGMA foreign_key_check
```

После migration foreign-key enforcement должен быть восстановлен.

Migration не должна оставлять database с отключёнными foreign keys.

---

## 10. Integrity validation

После выполнения migration chain и до публикации database приложению выполняются bounded integrity checks.

Минимально:

```
PRAGMA foreign_key_check
```

Для migration-run также допускается:

```
PRAGMA quick_check
```

Полный `PRAGMA integrity_check` не требуется на каждом обычном запуске приложения без отдельной причины.

Validation failure приводит к rollback migration.

---

## 11. Production database open lifecycle

Production database должна завершить initialization и обязательную migration до того, как repositories будут доступны остальной части приложения.

Последовательность:

```
composition root
    ↓
construct database
    ↓
force database open
    ↓
inspect schema version
    ↓
run required migration
    ↓
validate database
    ↓
enable normal FK mode
    ↓
publish repositories/use cases
```

Lazy-open behavior Drift не должен приводить к ситуации, когда repositories опубликованы до завершения обязательной migration.

---

## 12. Fresh database

Fresh installation не должна проигрывать всю историческую migration chain.

Для новой пустой database используется current latest schema creation:

```
onCreate → createAll()
```

После создания fresh database её структура должна соответствовать той же latest logical schema, к которой приходит database после всех migrations.

Fresh-create path и upgrade path тестируются отдельно.

---

## 13. Downgrade policy

Downgrade автоматически не поддерживается.

Если существующая database имеет schema version выше, чем поддерживает текущая версия приложения:

```
database user_version > application schemaVersion
```

приложение должно:

- отказаться открывать database для normal operation;
- не выполнять reverse migration;
- не выполнять destructive recreation;
- не менять database;
- вернуть диагностируемую Infrastructure startup error.

Downgrade требует отдельного будущего решения, если когда-либо станет необходим.

---

## 14. Неизвестная будущая schema version

Database из неизвестной более новой schema version рассматривается как unsupported database.

LifeOS не пытается best-effort открыть или модифицировать такую database.

Это защищает данные от запуска более старой версии приложения поверх более новой schema.

---

## 15. Schema snapshots

Перед первым изменением production schema необходимо сохранить versioned schema snapshot текущей версии.

Для initial migration foundation должен существовать snapshot schema v1.

Предлагаемое размещение:

```
drift_schemas/
└── schema_v1.json
```

Snapshots создаются штатными Drift tooling mechanisms и не редактируются вручную.

После появления schema v2 сохраняется соответствующая versioned representation согласно принятому Drift workflow.

Schema snapshots используются для:

- migration tests;
- воспроизводимого old-schema setup;
- проверки исторических schema;
- предотвращения случайной потери migration history.

---

## 16. Generated code

Drift generated files остаются tracked в Git согласно ADR-0023.

Generated code:

- создаётся только configured generator;
- не редактируется вручную;
- обновляется после schema declaration changes;
- проверяется вместе с diff.

Schema snapshots также не редактируются вручную, если они созданы tooling.

---

## 17. Migration tests

Каждый production transition `N → N+1` должен иметь focused migration tests.

Для `v1 → v2` тест должен как минимум:

1. создать file-backed database schema v1;
2. записать реальные v1 данные:
    - Entity metadata;
    - Task;
    - Outbox;
3. закрыть database;
4. открыть тем же production-equivalent path через current database implementation;
5. выполнить migration;
6. проверить сохранность исходных данных;
7. проверить новые schema objects;
8. проверить FK integrity;
9. проверить новую `user_version`;
10. закрыть database;
11. открыть её снова;
12. повторно подтвердить состояние.

Отдельно тестируются:

- fresh latest database;
- migration failure rollback;
- unsupported downgrade;
- multi-step ordering после появления нескольких migrations.

---

## 18. Old-schema test setup

Для migration tests предпочтительно использовать programmatic setup из frozen versioned schema snapshot.

Binary database fixtures не являются обязательными для обычных migrations.

Binary fixture допускается позже для воспроизведения:

- platform-specific дефекта;
- SQLite-version-specific поведения;
- исторического production incident.

Programmatic versioned schema предпочтительнее как прозрачный и cross-platform test mechanism.

---

## 19. Fresh schema и migrated schema

После migration resulting schema должна быть логически эквивалентна fresh latest schema.

Проверка должна использовать подходящие Drift/schema verification mechanisms.

Сравнение случайного порядка raw `sqlite_master` SQL строк не является предпочтительным contract.

---

## 20. Backup / Restore

Database schema migration и Backup format migration являются разными механизмами.

Не смешиваются:

- database schema version;
- Backup format version;
- Entity version;
- Outbox payload schema version.

Backup v1 остаётся logical format.

`sourceDatabaseSchemaVersion`, если присутствует в Backup metadata, является диагностической информацией и не выбирает migration path.

При старте приложения database migration выполняется как часть database-open lifecycle.

Restore работает с текущей supported database schema через logical Restore implementation.

Restore не заменяет database schema migration.

---

## 21. Future Entity migrations

Добавление нового persistent Entity type обычно требует:

1. нового Domain contract;
2. новой typed persistence table;
3. увеличения `schemaVersion`;
4. version-specific migration step;
5. обновления schema snapshot;
6. migration tests;
7. fresh-schema tests;
8. проверки Backup/Restore compatibility.

Конкретные поля новых Entity не определяются этим ADR.

---

## 22. Предлагаемая структура

```
lib/infrastructure/persistence/drift/
├── lifeos_database.dart
├── lifeos_database.g.dart
└── migrations/
    ├── lifeos_migration_strategy.dart
    ├── lifeos_migration_validation.dart
    └── v1_to_v2.dart

drift_schemas/
└── schema_v1.json

test/infrastructure/persistence/drift/migrations/
└── lifeos_database_migration_test.dart
```

Фактические имена могут быть адаптированы к существующим conventions проекта.

---

## 23. Явно запрещённые shortcuts

Без отдельного архитектурного решения запрещены:

- удаление production database при migration failure;
- `drop all → create all`;
- автоматический downgrade;
- best-effort partial migration;
- пропуск version-specific steps;
- ручное изменение `user_version` вместо корректной migration;
- создание sync Outbox Changes из schema migration;
- изменение `device_id`;
- использование Restore как скрытого механизма schema upgrade.

---

## 24. Явно отложено

Этот ADR не определяет:

- конкретную schema v2;
- Note table;
- Note Domain model;
- Relationship schema;
- File schema;
- database encryption;
- downgrade migrations;
- Backup format v2;
- remote Sync migrations;
- server schema migrations.

Они требуют отдельных решений при появлении соответствующего scope.

---

## 25. Последствия

### Положительные

- migration history становится явной и воспроизводимой;
- production user data защищены от destructive upgrades;
- каждый schema transition отдельно тестируется;
- будущие Entity types могут добавляться повторяемым способом;
- fresh install и upgrade имеют разные, понятные paths;
- downgrade не приводит к скрытой порче данных;
- Domain/Application остаются независимыми от SQLite versioning;
- Backup и database migration не смешиваются.

### Отрицательные

- каждый schema change требует отдельного migration step и tests;
- необходимо хранить schema history;
- database-open lifecycle становится немного сложнее;
- migration failures должны корректно обрабатываться на startup boundary.

Эта сложность принимается как необходимая цена безопасного local-first persistence.