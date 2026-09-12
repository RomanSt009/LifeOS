# Notes Vertical Slice + Schema Migration Foundation

Статус: completed

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

Статус: done

Результат: добавлены `LifeOsEntityType.note`, `LifeOsNote`, typed repository, Drift mapper/repository и atomic Entity + Note + Outbox persistence. Проверены invariants, immutable edit/no-op, deterministic reads, reopen, diagnostics, ID collision и rollback.

Focused validation: 10 Domain/Infrastructure tests passed.

### NS-06 — Note Application + minimal Presentation

Статус: done

Результат: добавлены list/get/create/edit use cases, production composition и localized Notes destination с explicit-save plain-text editor. No-op edit не вызывает repository save; shell сохраняет editor state через существующий `IndexedStack`.

Focused validation: 16 Application/Presentation/shell/lifecycle tests passed.

### NS-07 — Backup compatibility gate/integration

Статус: done

Architecture gate снят: принят ADR-0031. Backup/Export v1 остаётся историческим Task-only contract; текущая запись использует v2 с Notes, а Restore поддерживает v1 и v2.

Результат: добавлены отдельные DTO/codec v2 и version-aware reader; production composition пишет Backup/Export v2 с Tasks и Notes. Исторический v1 остаётся неизменным и читается как Task-only snapshot. Restore v1/v2 полностью декодирует и проверяет файл до mutation, затем одной SQLite transaction очищает Outbox и заменяет Tasks/Notes/Entities в FK-safe порядке; repository `save()` не используется.

Focused validation: 47 Application/Backup/Restore tests passed. Проверены v1 restore, v2 Task-only, v2 Task+Note, точные metadata и whitespace content, Export v2, пустой Outbox, rollback, сохранение installation device identity, malformed/checksum/future-version rejection до mutation и регрессия Task v1.

### NS-08 — Search decision/integration

Статус: done

Результат: согласно ADR-0030 текущий Task-specific Search не обобщён и Note Search не добавлен. Первая Note vertical slice остаётся законченной без Search; выбор Note-specific или unified Search отложен до отдельного architecture gate. Schema, FTS, dependencies и generic Search abstractions не изменялись.

Focused validation: 23 Application/Task repository/Search Presentation tests passed; существующие Task Search semantics и UI остаются без изменений.

Validation запуска NS-07/NS-08:

- handwritten Dart отформатирован; `flutter gen-l10n` выполнен штатно;
- `flutter analyze`: no issues found;
- полный `flutter test`: 154 tests passed;
- import-boundary scan: PASS для Domain/Application/Presentation;
- `LifeOsDatabase.schemaVersion = 2`, schema v3 отсутствует;
- `pubspec.yaml` и `pubspec.lock` не изменены;
- `git diff --check`: PASS.

### NS-09 — Final audit

Статус: done

Результат: финальный Domain/Application/Infrastructure/Presentation audit пройден. Note соответствует ADR-0030; schema v2 и migration соответствуют ADR-0029; Backup/Export v2 и Restore v1/v2 соответствуют ADR-0028/ADR-0031; Task Search остаётся Task-specific, Note/unified Search явно отложен.

Во время аудита исправлены два конкретных дефекта без расширения scope:

- hydration `LifeOsNote` теперь проверяет typed identity, UTC/monotonic timestamps, положительную version, normalized title и empty-state invariant; mapper преобразует invalid persisted state в typed mapping failure;
- reopen-тест Note repository больше не держит лишний открытый `LifeOsDatabase`; Drift warning классифицирован как test lifecycle issue и устранён без подавления diagnostics.

Добавлено минимальное acceptance evidence: production-composed Backup/Restore round-trip теперь включает Note с точными metadata/content и reopen, а production Export v2 проверяет Notes.

Final validation:

- focused audit suite: 95 tests passed;
- `flutter gen-l10n`: PASS;
- `flutter analyze`: no issues found;
- полный `flutter test`: 156 tests passed без Drift lifecycle warning;
- import-boundary, Search scope и routing dependency scans: PASS;
- `git diff --check`: PASS;
- `LifeOsDatabase.schemaVersion = 2`; schema v3 отсутствует;
- dependencies и Drift-generated/schema artifacts не изменялись.

Documentation reconciliation: актуализированы текущие capability annotations в README, Vision, Product, Architecture, Database и UI/UX docs. Целевые future sections не переписывались.

Deferred scope: Note/unified Search, FTS/embeddings, autosave/drafts, Markdown/rich text, archive/delete, Relationships, attachments, Sync, AI и encryption implementation.

## Resume point

Milestone completed. Новый execution plan автоматически не создаётся.
