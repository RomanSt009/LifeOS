# Relationships Vertical Slice + Schema v3

Статус: active

## Контекст

Milestone добавляет первую production Relationship Entity поверх существующих Task и Note. Domain-семантика принята в ADR-0032; SQLite/Drift migration discipline определяется ADR-0029. Текущая production schema имеет версию `2`, а текущий Backup/Export writer использует format v2.

## История checkpoint

### RL-01 — Domain Model ADR

Статус: done

Результат: принят ADR-0032. Relationship является first-class typed Entity с одним kind `related`, ненаправленными canonical endpoints, запретом self-link и duplicate active link, общими metadata/lifecycle/version semantics, atomic Outbox и обязательным будущим Backup/Export representation.

## Текущий checkpoint

### RL-02 — Persistence + Schema v3 Design Gate

Статус: done

Цель: определить architecture-ready physical persistence design Relationship и migration `v2 -> v3`, не изменяя production schema или код.

Relevant ADRs: ADR-0016, ADR-0023, ADR-0025, ADR-0029, ADR-0030, ADR-0031, ADR-0032.

Allowed scope:

- audit фактической schema v2, lifecycle, repositories, mappers, Outbox и migration tooling;
- physical design таблицы `relationships`, constraints, indexes и FK policy;
- repository/mapper/Outbox design;
- design migration `v2 -> v3` и test matrix;
- анализ будущего Backup/Search impact;
- обновление только этого execution plan.

Explicit non-goals:

- production Relationship Domain/Application/Infrastructure/Presentation code;
- изменение Drift schema, `schemaVersion`, generated code или dependencies;
- migration implementation/codegen;
- Backup v3, Search или UI implementation.

Definition of Done:

- lifecycle gate разрешён или зафиксирован точный blocker;
- exact schema v2 и minimal schema v3 delta зафиксированы;
- определены table, constraints, indexes, FK, repository, mapper и Outbox contracts;
- определены migration algorithm, frozen-schema artifacts и test matrix;
- Backup/Search consequences и ADR gate зафиксированы;
- указан точный resume point.

Validation:

- read-only inspection accepted ADR и фактического кода;
- `git diff --check`;
- Git status/revision reconciliation.

Result / evidence:

#### Lifecycle gate

- Фактический `LifeOsEntityLifecycle`: `active`, `archived`, `deleted`.
- ADR-0016 определяет `ACTIVE -> DELETED` как common soft-delete semantics; физическое удаление является отдельной операцией. Поэтому `deleted` является уже принятым terminal/removal state для Relationship unlink. `archived` не переиспользуется с новым смыслом.
- Обычные production create/edit paths Task и Note создают/сохраняют `active` state и не имеют lifecycle mutation API. `archived` и `deleted` уже сериализуются и восстанавливаются Backup/Restore tests, но user-facing Task/Note lifecycle mutations пока не реализованы.
- Domain mutation pattern является immutable copy с предоставленным извне UTC timestamp, увеличением version только при material mutation и возвратом того же объекта для no-op там, где это определено Note.
- Текущий repository save path определяет Outbox operation как `CREATE` при отсутствии Entity row и `UPDATE` при её наличии. Отдельного production `DELETE` operation/API нет.
- Relationship `remove(updatedAt)` должен переводить `active -> deleted`, устанавливать `version + 1`, принимать UTC `updatedAt >= current updatedAt` и возвращать тот же instance для уже non-active Relationship. Material removal сохраняется через обычный `save()` и создаёт Outbox `UPDATE`; hard delete не вводится.
- Architecture gate пройден: новый lifecycle state, новый DELETE contract и отдельный ADR для unlink не требуются.

#### Exact current physical schema v2

`entities`:

- `id TEXT NOT NULL PRIMARY KEY`;
- `entity_type TEXT NOT NULL`;
- `created_at INTEGER NOT NULL`;
- `updated_at INTEGER NOT NULL`;
- `lifecycle TEXT NOT NULL`;
- `version INTEGER NOT NULL`;
- `source TEXT NOT NULL`;
- дополнительных CHECK/UNIQUE/indexes нет.

`tasks`:

- `entity_id TEXT NOT NULL PRIMARY KEY REFERENCES entities(id)`;
- `title TEXT NOT NULL`;
- `is_completed INTEGER NOT NULL CHECK (is_completed IN (0, 1))`;
- отдельных indexes нет.

`notes`:

- `entity_id TEXT NOT NULL PRIMARY KEY REFERENCES entities(id)`;
- `title TEXT NOT NULL`;
- `content TEXT NOT NULL`;
- дополнительных CHECK/indexes нет.

`outbox`:

- `change_id TEXT NOT NULL PRIMARY KEY`;
- `entity_id TEXT NOT NULL REFERENCES entities(id)`;
- `device_id TEXT NOT NULL`;
- `operation TEXT NOT NULL`;
- `base_version INTEGER NULL`;
- `new_version INTEGER NOT NULL`;
- `payload TEXT NOT NULL`;
- `schema_version INTEGER NOT NULL`;
- `status TEXT NOT NULL`;
- `attempt_count INTEGER NOT NULL`;
- `created_at INTEGER NOT NULL`;
- `last_attempt_at INTEGER NULL`;
- дополнительных CHECK/indexes нет.

Все существующие FK используют SQLite default `NO ACTION` для update/delete. `PRAGMA foreign_keys = ON` устанавливается migration strategy `beforeOpen` и перед migration chain. Latest version принадлежит только `LifeOsDatabase.schemaVersion = 2`. Fresh database использует `createAll()`. Upgrade выполняется одной transaction через sequential step map; `v1 -> v2` создаёт только `notes`; затем запускаются `foreign_key_check` и `quick_check`. Frozen tooling artifacts: `drift_schema_v1.json`, `drift_schema_v2.json` и generated versioned test helpers.

#### Proposed `relationships` table

```sql
CREATE TABLE relationships (
  entity_id TEXT NOT NULL
    PRIMARY KEY
    REFERENCES entities(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  first_entity_id TEXT NOT NULL
    REFERENCES entities(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  second_entity_id TEXT NOT NULL
    REFERENCES entities(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  kind TEXT NOT NULL,
  CHECK (first_entity_id <> second_entity_id),
  CHECK (first_entity_id < second_entity_id),
  UNIQUE (first_entity_id, second_entity_id, kind)
);

CREATE INDEX relationships_second_entity_id_idx
  ON relationships(second_entity_id);
```

- Все columns non-null; SQL defaults отсутствуют. Domain/Application предоставляют identity, canonical endpoints и kind.
- `entity_id` является одновременно PK typed row и FK на common Entity identity, как в `tasks`/`notes`.
- `first_entity_id` и `second_entity_id` ссылаются на существующие Entity rows.
- `kind` хранится как canonical enum name `related`. Отдельный SQL CHECK на конкретный kind не предлагается: текущая стратегия enum/type integrity для common Entity metadata основана на Domain/mapper/repository validation, а расширение kind всё равно требует отдельного Domain gate.
- `CHECK first <> second` дублирует критичный structural invariant на storage boundary.
- `CHECK first < second` закрепляет canonical orientation и делает UNIQUE устойчивым к обратной записи. Для production UUID v4 canonical strings Dart lexical order и SQLite default binary text order совпадают. Restore обязан применить тот же Domain canonical validation до mutation.
- `UNIQUE(first, second, kind)` намеренно не зависит от lifecycle из `entities`: SQLite index не может безопасно сделать cross-table partial uniqueness. Это задаёт не более одной persisted identity для pair+kind, что сильнее минимального «одна active». Повторное связывание удалённой пары должно в будущем восстанавливать ту же Relationship identity либо пройти отдельный lifecycle UX gate; RL-03 не должен изобретать re-link semantics.

#### Entity-type integrity

- Сохраняется единая стратегия typed tables: SQL FK гарантирует наличие общего Entity row, а mapper/repository проверяют `entity_type == relationship` и matching `entity_id`.
- Trigger или composite FK только для Relationship не вводятся: это сделало бы integrity strategy сильнее Task/Note и было бы отдельным architecture change.
- Endpoint FK гарантируют existence, а Application/repository перед записью проверяют, что оба endpoints имеют разрешённые ADR-0032 типы `task`/`note`. Relationship Entity как endpoint недопустима.
- Wrong type, missing typed row и inconsistent pair являются typed persistence/mapping failures, а не молчаливым `null`.

#### FK policy

- Для всех трёх FK применяется `NO ACTION`, согласованное с существующей schema.
- `CASCADE` запрещён: ADR-0032 не принимает автоматические Domain mutations при lifecycle/delete endpoint.
- `SET NULL` несовместим с обязательными endpoints.
- `RESTRICT` не даёт полезного отличия от deferred `NO ACTION` в текущих immediate statements и нарушил бы единообразие без необходимости.
- Физическое удаление endpoint/Relationship Entity возможно только через явно упорядоченный maintenance/Restore path; обычная Domain removal остаётся soft delete.

#### Index design

- PK автоматически индексирует `entity_id`.
- UNIQUE index `(first_entity_id, second_entity_id, kind)` одновременно обеспечивает duplicate collision atomicity и является usable prefix index для `first_entity_id = ?`; отдельный first-endpoint index избыточен.
- Отдельный non-unique index на `second_entity_id` покрывает вторую ветвь `OR`.
- SQLite может выполнить `getForEntity` как multi-index OR по composite UNIQUE prefix и second-endpoint index, затем join к `entities` и bounded sort.
- Index по `updated_at` не добавляется: поле находится в `entities`, а основной endpoint-filter уже существенно сужает набор. Добавлять speculative cross-table/order index без измерения не требуется.

#### Repository contract

```dart
abstract interface class LifeOsRelationshipRepository {
  Future<LifeOsRelationship?> getById(LifeOsEntityId id);
  Future<List<LifeOsRelationship>> getForEntity(LifeOsEntityId entityId);
  Future<void> save(LifeOsRelationship relationship);
}
```

- `getById` возвращает `null` для missing ID и wrong requested ID type; inconsistent existing Entity/typed state вызывает typed persistence/mapping exception.
- `getForEntity` принимает существующий supported Task/Note ID, ищет обе стороны, возвращает только `active` Relationships и сортирует `updatedAt DESC`, затем `id ASC`.
- `save` является единственной create/update/removal persistence boundary. Create и update выполняются одной SQLite transaction с Outbox.
- Existing ID другого Entity type, missing/inconsistent typed pair, missing/unsupported endpoint, non-canonical state и duplicate pair дают typed failure до commit. FK/UNIQUE остаются последней atomic protection.
- Для material update existing version является `base_version`; no-op removal не вызывает `save()` на Application path.
- Generic `EntityRepository`, `GraphRepository`, query language и physical delete API не вводятся.

#### Mapper contract

Conceptual mapping остаётся `EntityRecord + RelationshipRecord <-> LifeOsRelationship`, но фактический `toDomain` также должен получить resolved endpoint Entity metadata (либо эквивалентные проверенные typed endpoint IDs). Причина: существующий `LifeOsEntityId` содержит не только string value, но и `entityType`, тогда как normalized `relationships` row намеренно хранит только endpoint IDs. Дублировать endpoint types в typed row нельзя; repository загружает endpoint Entity rows и передаёт mapper достаточные данные.

Mapper проверяет:

- одинаковые `entity.id` и `relationship.entity_id`;
- `entity_type == relationship`;
- non-empty typed ID;
- UTC `createdAt`/`updatedAt`, `updatedAt >= createdAt` и `version >= 1` через Domain hydration contract;
- valid lifecycle/source enum names;
- valid `kind` (`related`);
- соответствие resolved endpoint IDs persisted values;
- supported endpoint Entity ID types, distinct endpoints и canonical order.

По аналогии с Note вводится typed `LifeOsRelationshipMappingException`: corrupted/invalid persisted state не выдаётся как Domain Entity. Mapping не обращается к Presentation/Application. Endpoint existence/type verification, требующая database access, остаётся repository responsibility.

#### Outbox design

- Текущая physical representation operation — строка; production writers используют только `CREATE`/`UPDATE`. Новый enum/`DELETE` не нужен.
- Create: `operation = CREATE`, `base_version = null`, `new_version = 1`.
- Material lifecycle removal: `operation = UPDATE`, `base_version = persisted previous version`, `new_version = previous + 1`.
- `payload` является full JSON snapshot с existing camelCase conventions: `id`, `entityType`, `firstEntityId`, `secondEntityId`, `kind`, `createdAt`, `updatedAt`, `lifecycle`, `version`, `source`.
- `schema_version` Outbox остаётся текущим payload-contract value `1`; он не равен SQLite schema v3 или Backup format v3.
- `status = PENDING`, `attempt_count = 0`, `created_at = relationship.updatedAt`, `device_id` и `change_id` приходят из существующей Infrastructure composition.
- Entity row, typed Relationship row и Outbox row атомарны. No-op не меняет persistence и не создаёт Outbox.

#### Exact schema `v2 -> v3` delta

- Добавляется только `relationships` table с указанными FK/CHECK/UNIQUE constraints и `relationships_second_entity_id_idx`.
- `entities`, `tasks`, `notes` и `outbox` физически не изменяются.
- `LifeOsEntityType.relationship` является будущим Domain/code delta RL-04, но не требует изменения columns существующей `entities` table, поскольку `entity_type` хранится как text и валидируется mapper/repository.
- `schemaVersion` должен стать `3` только в RL-03 после добавления table declaration и migration step.
- Data backfill отсутствует: schema v2 не содержит Relationship state.

#### Migration `v2 -> v3`

RL-03 должен:

1. до изменения latest schema сохранить/проверить frozen v2 snapshot;
2. добавить Drift declaration table/indexes и `schemaVersion = 3`;
3. добавить отдельный `v2_to_v3.dart` step;
4. в существующей общей migration transaction создать `relationships` и required index;
5. не изменять и не пересохранять Tasks, Notes, Entities или Outbox;
6. выполнить существующие bounded `PRAGMA foreign_key_check` и `PRAGMA quick_check` до commit;
7. rollback всей цепочки при любой ошибке;
8. сгенерировать tooling-ом latest Drift code, frozen schema v3 и versioned migration helpers;
9. оставить production `device_id` нетронутым;
10. использовать `createAll()` для fresh v3.

#### RL-03 test matrix

1. fresh v3 creation;
2. file-backed `v2 -> v3` migration;
3. сохранение существующих Tasks и Entity metadata;
4. сохранение существующих Notes и Entity metadata/content;
5. сохранение существующего Outbox без новых records;
6. наличие `relationships` table;
7. наличие PK/FK/CHECK/UNIQUE и second-endpoint index;
8. FK enforcement и `foreign_key_check` PASS;
9. `quick_check` PASS;
10. rollback полной migration transaction при injected failure;
11. future schema version rejection без mutation;
12. migrated v3 логически эквивалентна fresh/frozen v3 через Drift schema verifier;
13. reopen migrated file сохраняет schema/data;
14. migration не меняет installation `device_id` (проверяется production-open integration либо фиксируется как неизменяемый внешний file state).

#### Backup/Export consequence

- ADR-0031 не связывает Backup version с SQLite schema version, но требует новый format number, когда старый reader не может безопасно и полно интерпретировать новое production user state.
- Relationship является обязательным production user state по ADR-0032. Старый v2 reader знает только Tasks/Notes и потерял бы Relationships при replace-style Restore. Поэтому release-ready Relationship требует **Backup/Export format v3** в RL-06; новый ADR не нужен.
- Future v3 record сохраняет common metadata (`id`, `entityType`, timestamps, lifecycle, version, source), `firstEntityId`, `secondEntityId`, `kind`.
- Reader сохраняет поддержку v1/v2, dispatch/reject происходит до mutation. Restore v3 заранее валидирует unique canonical pairs, distinct/supported/existing endpoints и typed/common cross-references.
- FK-safe deletion: `outbox -> relationships -> tasks + notes -> entities`. Insertion: все `entities` metadata, затем `tasks`/`notes`, затем `relationships`, чтобы endpoints существовали. Restore остаётся atomic, не использует normal `save()`, не создаёт Outbox и не меняет installation `device_id`.

#### Search/Presentation consequence

- Schema v3 сама по себе не требует Search changes, FTS или indexes для text search.
- Relationship picker не разрешает автоматически generic/unified Search; он может использовать bounded Task/Note reads. Если usable picker потребует unified Search, RL-07 должен остановиться на отдельном architecture gate.
- Physical schema design не определяет UI. Relationship остаётся contextual Task/Note presentation без нового NavigationRail destination.

#### ADR gate

`ADR-0033 not required`.

Lifecycle/remove уже покрыты ADR-0016 и ADR-0032; migration discipline — ADR-0029; Backup version consequence — однозначный результат ADR-0031. Предложенные FK, indexes, constraints и typed repository/mapper являются bounded physical design в рамках принятых решений, а не новым graph architecture.

Validation evidence:

- Git/plan reconciliation: до RL-02 active plan отсутствовал; production Relationship implementation отсутствует; `LifeOsDatabase.schemaVersion = 2`; HEAD `e65351f1265afe0b674d865d86d0363b2b998fc1` содержит accepted ADR-0032; branch `main` совпадает с upstream (`0/0`).
- Read-only audit выполнен по перечисленным ADR, Domain entities/repositories, Drift schema/snapshots/migrations, Task/Note mapper/repository, Outbox и Backup v2/Restore paths.
- Production code, schema, generated files, dependencies и `.obsidian/workspace.json` не изменялись.
- `git diff --check`: PASS; отдельная whitespace-проверка нового untracked plan: PASS.
- Итоговый `git status --short`: pre-existing `M .obsidian/workspace.json`; новый `?? docs/exec-plans/active/relationships-vertical-slice.md` (Git сокращает его до untracked directory при обычном status).

## Следующие checkpoints

### RL-03 — Schema v3 Migration

Статус: pending

Цель: реализовать только schema v3 table/indexes, `v2 -> v3` migration, generated artifacts и migration validation согласно RL-02.

### RL-04 — Domain + Persistence

Статус: pending

Цель: реализовать `LifeOsRelationship`, typed repository, mapper и atomic Outbox persistence поверх schema v3.

### RL-05 — Application + Presentation

Статус: pending

Цель: реализовать минимальные use cases и contextual Task/Note Relationship UX без нового top-level destination.

### RL-06 — Backup/Export/Restore

Статус: pending

Цель: добавить Backup/Export format v3 и atomic Relationship-aware Restore с сохранением v1/v2 compatibility.

### RL-07 — Cross-Entity UX/Search Gate

Статус: pending

Цель: проверить usable endpoint selection и необходимость Search changes без автоматического введения unified Search.

### RL-08 — Final Audit

Статус: pending

Цель: провести финальный архитектурный, migration, persistence, Backup/Restore и UX audit milestone.

## Resume point

RL-03 — Schema v3 Migration. Не начинать без отдельного запроса.
