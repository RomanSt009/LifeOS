# Notes Vertical Slice + Schema Migration Foundation

Статус: active

## Контекст

Milestone добавляет первую production Note Entity и одновременно проверяет безопасное развитие Drift/SQLite schema. Принятые архитектурные решения: ADR-0029 и ADR-0030.

## История checkpoint

### NS-01 — Migration architecture

Статус: done

Результат: принят ADR-0029, определяющий version-specific migrations, schema snapshots, validation, rollback и downgrade policy.

### NS-02 — Note Domain contract

Статус: done

Результат: принят ADR-0030, определяющий Note identity, `title`/`content`, creation и immutable atomic edit semantics.

### NS-03 — Note persistence + schema v2 design gate

Статус: done

Результат: architecture-ready; ADR-0031 не требуется. Schema v2 равна schema v1 плюс typed `notes` table; переход `v1 -> v2` создаёт только эту таблицу.

## Текущий checkpoint

### NS-04 — Schema migration foundation + schema v2

Статус: done

Цель: реализовать и доказать production-safe upgrade `v1 -> v2`, frozen schemas, migration orchestration/validation, `notes` table и production startup barrier.

Relevant ADRs: ADR-0023, ADR-0024, ADR-0029, ADR-0030.

Allowed scope:

- frozen Drift schema v1/v2;
- Infrastructure migration orchestration и validation;
- `v1 -> v2` migration;
- physical `notes` table;
- `schemaVersion = 2`;
- production startup migration barrier;
- generated Drift/test artifacts;
- focused migration и persistence regression tests.

Explicit non-goals:

- `LifeOsNote` и `LifeOsNoteRepository`;
- Note mapper, Outbox payload, Application и Presentation;
- Backup/Restore/Search/localization changes;
- новые dependencies.

Definition of Done:

- schema v1 frozen до изменения production schema;
- schema v2 содержит только новую `notes` table;
- migration последовательна, транзакционна, валидируется и сохраняет v1 data;
- downgrade/future schema отклоняется без mutation;
- production dependencies не публикуются до успешного open/migration;
- required focused и regression validation проходит.

Validation:

- formatting handwritten Dart;
- focused migration tests;
- existing persistence/repository tests;
- `flutter analyze`;
- full `flutter test`;
- `git diff --check`.

Result / evidence:

- До изменения production schema штатным Drift tooling сохранён `drift_schemas/lifeos/drift_schema_v1.json`; после изменения сохранён `drift_schema_v2.json`.
- Schema v2 сохраняет `entities`, `tasks` и `outbox` без изменений и добавляет только typed `notes(entity_id, title, content)` с primary/foreign key по Entity ID.
- `LifeOsDatabase.schemaVersion` увеличен до `2`; fresh-create продолжает использовать `createAll()`.
- Добавлены последовательный migration orchestrator, единая transaction boundary, `v1 -> v2` step и bounded `foreign_key_check`/`quick_check` validation. Migration не изменяет Domain data и не создаёт Outbox records.
- Production open теперь принудительно выполняет фактическое открытие database до возврата экземпляра; при initialization/migration failure database закрывается и не публикуется composition root.
- Drift-generated database code, frozen schemas и versioned migration-test helpers созданы tooling и вручную не редактировались.
- Focused migration suite: 5 tests passed. Доказаны сохранность Entity/Task/Outbox и metadata, schema equivalence, fresh v2, FK enforcement, reopen, полный rollback при controlled failure, отказ для future schema без mutation и production startup barrier.
- Existing Task/production/Backup persistence regression suite: 21 tests passed.
- `flutter analyze`: no issues found.
- Full `flutter test`: 132 tests passed.
- Handwritten Dart отформатирован; `git diff --check` прошёл без ошибок.
- Dependencies, Domain, Application, Presentation, Backup, Search и localization не изменялись.

## Следующие checkpoints

### NS-05 — Note Domain + persistence implementation

Статус: pending

### NS-06 — Note Application + minimal Presentation

Статус: pending

### NS-07 — Backup compatibility gate/integration

Статус: pending

### NS-08 — Search decision/integration

Статус: pending

### NS-09 — Final audit

Статус: pending

## Resume point

NS-05 — Note Domain + persistence implementation. NS-05 не начат.
