# Workspace Vertical Slice

Статус плана: active

Текущий checkpoint: WS-04 — Application + production composition (pending)

Точная точка возобновления: начать WS-04 с повторной сверки Git, ADR-0022,
ADR-0023, ADR-0024, ADR-0026, ADR-0033, ADR-0034 и готовых WS-03 contracts;
до implementation отметить WS-04 active. WS-05 не начинать.

## Goal

Реализовать первый production context-centric primitive LifeOS. После milestone
пользователь может создавать, редактировать, удалять и восстанавливать Workspace,
работать с mixed direct Task/Note members, создавать Entity внутри Workspace,
attach/detach/reattach существующие Entity, использовать zero-to-many membership
и Unassigned и сохранять весь контекст через restart и Backup/Restore.

## Architecture baseline

- ADR-0034 принят и является source of truth для Workspace и Context.
- `LifeOsWorkspace` и `LifeOsWorkspaceMembership` являются отдельными typed
  `LifeOsEntity`.
- Membership является structural edge, а не `LifeOsRelationship` и не ownership.
- Cardinality — zero-to-many; Unassigned является вычисляемым состоянием.
- Workspace lifecycle не каскадирует на members, memberships или Relationships.
- Workspace hierarchy и Workspace semantic Relationship endpoints отсутствуют.
- Current production schema — v3; current writer — Backup/Export v3; Restore
  читает v1/v2/v3.
- Composition root владеет единственной production database и всеми concrete
  persistence implementations.
- Shell использует `NavigationRail`, `IndexedStack` и shell-local destination
  state без routing dependency.
- Единственное исходное working-tree изменение при создании плана — user-owned
  `.obsidian/workspace.json`; оно не относится к milestone и не изменяется.

## Milestone scope

- Workspace и WorkspaceMembership Domain contracts.
- SQLite/Drift schema v4 и migration v3 -> v4.
- Typed repositories, mappers, Outbox и atomic persistence.
- Application use cases, mixed Workspace read model и production composition.
- Atomic Task/Note quick create внутри Workspace.
- Backup/Export/Restore format v4 с чтением v1/v2/v3/v4.
- Localized Workspace Presentation, Unassigned и context-centric shell entry.
- Focused и full validation.

## Explicit non-goals

- Unified Search или изменение current Task Search.
- AI, Context Engine implementation или AI dependency.
- Knowledge Graph Foundation #2, graph traversal или visualization.
- Directed/new semantic Relationship kinds или Workspace Relationship endpoints.
- Workspace hierarchy.
- Document, Person, Event или другие новые member types.
- Sync backend, conflict resolution, collaboration, permissions или ACL.
- Generic Entity repository, generic Unit of Work или routing package.
- Hard purge, System Tray, Spellcheck, Notifications/reminders и
  notification-driven Task time fields.

## Roadmap direction

```text
Workspace Vertical Slice
  -> Context-centric UX
  -> Knowledge Graph Foundation #2
  -> Unified Local Search
  -> AI Foundation
  -> Context-aware AI #1
  -> LifeOS 1.0 Dogfooding & Stabilization
  -> LifeOS 1.0
```

System Tray, Spellcheck и Notifications/reminders остаются post-1.0 scope.

## Accepted implementation contracts from WS-01

### Workspace Domain shape

Предлагаемая production форма:

```text
LifeOsWorkspace implements LifeOsEntity
  id: LifeOsEntityId(type: workspace)
  title: String
  description: String?
  createdAt: DateTime UTC
  updatedAt: DateTime UTC
  lifecycle: LifeOsEntityLifecycle
  version: int
  source: LifeOsEntitySource
```

Creation factory:

```text
LifeOsWorkspace.createUserWorkspace(
  id,
  title,
  description,
  timestamp,
)
```

Rules:

- ID non-empty и имеет type `workspace`.
- `title` нормализуется через `trim()` и после normalization не пуст.
- Hydrated title уже должен быть normalized.
- `description == null` означает отсутствие description.
- Non-null description является opaque plain String и сохраняется exactly: без
  trim, line-ending normalization или произвольного maximum length.
- `createdAt` и `updatedAt` — UTC; `updatedAt >= createdAt`; version positive.
- User creation: active, version 1, source user, `createdAt == updatedAt`.
- Atomic `edit(title, description, updatedAt)` разрешён только active Workspace.
- Edit сравнивает normalized title и exact nullable description. No-op возвращает
  тот же instance, не меняет timestamp/version и не создаёт persistence/Outbox.
- Material edit требует UTC non-decreasing timestamp и увеличивает version на 1.
- Domain поддерживает `archive`, `unarchive`, `delete`, `restore` с теми же
  state-machine, timestamp и no-op conventions, что Task/Note в ADR-0033.
- Lifecycle mutations не меняют title/description и не каскадируют.

Workspace v1 Application/UI реализует `CreateWorkspace`, `EditWorkspace`,
`DeleteWorkspace`, `RestoreWorkspace`. Archive/Unarchive сохраняются в Domain и
repository contract, но их user-facing actions отложены до отдельного UX gate.

### WorkspaceMembership Domain shape

Предлагаемая production форма:

```text
LifeOsWorkspaceMembership implements LifeOsEntity
  id: LifeOsEntityId(type: workspaceMembership)
  workspaceId: LifeOsEntityId(type: workspace)
  memberEntityId: LifeOsEntityId(type: task | note)
  createdAt: DateTime UTC
  updatedAt: DateTime UTC
  lifecycle: LifeOsEntityLifecycle(active | deleted)
  version: int
  source: LifeOsEntitySource
```

Creation factory и mutations:

```text
LifeOsWorkspaceMembership.createUserMembership(...)
membership.remove(updatedAt)
membership.reattach(updatedAt)
```

Rules:

- Membership ID non-empty и имеет type `workspaceMembership`.
- `workspaceId` non-empty и имеет type `workspace`.
- `memberEntityId` non-empty и имеет type Task или Note.
- Workspace/member raw ID values должны быть различны; endpoint types и
  существование дополнительно проверяются persistence boundary.
- Endpoints immutable; membership не имеет edit для их замены.
- Hydration требует UTC timestamps, monotonic creation/update и positive version.
- Membership v1 допускает lifecycle active или deleted; archived rejected как
  unsupported state.
- User creation: active, version 1, source user, `createdAt == updatedAt`.
- `remove`: active -> deleted; repeated remove is no-op.
- `reattach`: deleted -> active; active reattach is no-op.
- Timestamp validation выполняется до no-op result; material transition повышает
  version на 1 и сохраняет identity/endpoints/source/createdAt.
- Пара `workspaceId + memberEntityId` уникальна среди всех lifecycle states.

### Repository boundaries

`LifeOsWorkspaceRepository` остаётся typed Domain abstraction:

```text
getAll()
getById(id)
getByLifecycle(lifecycle)
save(workspace)
```

`getAll()` имеет all-state snapshot semantics для Backup. Normal UI читает
active; Workspace Trash читает deleted. `save()` атомарно сохраняет Entity,
typed row и один Outbox CREATE/UPDATE, пропуская no-op на Application boundary.

`LifeOsWorkspaceMembershipRepository` является typed Domain abstraction с
atomic pair-invariant commands:

```text
getAll()
getById(id)
getByPair(workspaceId, memberEntityId)
attach(
  workspaceId,
  memberEntityId,
  newMembershipId,
  timestamp,
)
remove(membershipId, timestamp)
```

`attach` внутри одной repository transaction:

1. проверяет существование и active lifecycle Workspace/member;
2. ищет pair с учётом inactive membership;
3. возвращает active existing membership без write/Outbox;
4. восстанавливает deleted membership с прежней identity и Outbox UPDATE;
5. либо создаёт новую membership с переданным candidate ID и Outbox CREATE.

Так unique-pair invariant не зависит от Presentation или race-prone
`get -> maybe create`. Candidate ID может остаться неиспользованным при no-op или
reattach; это допустимо для UUID boundary. `remove` атомарно выполняет Domain
soft-delete и Outbox UPDATE, а repeated remove не пишет Outbox.

### Quick-create transaction decision

Принят OPTION B: Create Task/Note внутри Workspace является atomic Application
operation.

Сравнение:

| Option | UX/data integrity | Boundaries/Outbox | Решение |
|---|---|---|---|
| A: two-step | Может оставить неожиданную Unassigned Entity | Каждая repository transaction корректна, но user intent частично выполнен | Отклонено для Workspace quick create; global create остаётся отдельным |
| B: atomic | All-or-nothing соответствует одной user action | Требует узкий cross-entity persistence port, два Outbox CREATE в одной transaction | Принято |
| C: compensation | Временно создаёт лишнее state и Outbox; compensation также может fail | Усложняет lifecycle/Sync и не гарантирует rollback | Отклонено |

Обычные global `CreateLifeOsTask` и `CreateLifeOsNote` не меняются.

### Atomic quick-create boundary

Application получает узкий, use-case-specific port, а не generic Unit of Work:

```text
LifeOsWorkspaceMemberCreationStore
  createTaskInWorkspace(task, membership)
  createNoteInWorkspace(note, membership)
```

Port располагается в Application boundary и использует только Domain types.
Infrastructure Drift implementation владеет одной transaction и сохраняет:

```text
Task path:
  Entity(Task) + Task row + Task Outbox CREATE
  Entity(Membership) + Membership row + Membership Outbox CREATE

Note path:
  Entity(Note) + Note row + Note Outbox CREATE
  Entity(Membership) + Membership row + Membership Outbox CREATE
```

При любой ошибке вся transaction откатывается. Application use cases
`CreateLifeOsTaskInWorkspace` и `CreateLifeOsNoteInWorkspace`:

- проверяют active Workspace;
- получают два UUID и одну UTC timestamp;
- создают обе валидные Domain Entity;
- передают их store;
- не импортируют Drift/SQLite/Infrastructure.

Store повторно проверяет persisted active Workspace и отсутствие conflicting
member/membership state внутри transaction. Реализация переиспользует private
Infrastructure persistence helpers, а concrete repositories не вызывают друг
друга.

Это bounded implementation decision, явно разрешённое gate ADR-0034. Новый ADR
не требуется.

### Attach/detach/reattach

- `AttachWorkspaceMember` зависит от membership repository, clock и ID generator.
- Presentation передаёт только Workspace ID и existing Task/Note ID.
- Attach active pair — успешный no-op без version/timestamp/Outbox.
- Attach deleted pair — restore той же membership ID, UPDATE full snapshot.
- Attach absent pair — новая membership ID, CREATE full snapshot.
- Attach требует active Workspace и active Task/Note.
- `DetachWorkspaceMember` принимает membership ID; Task/Note не мутируется.
- Detach active membership — deleted + UPDATE; repeated detach — no-op.
- Workspace lifecycle не меняет membership state.

### Unassigned query semantics

Unassigned — Application read, а не persisted Workspace. Результат содержит
active Tasks/Notes, для которых не существует одновременно:

- active Membership;
- ссылающейся на active Workspace;
- для этой member Entity.

Deleted membership не делает Entity assigned. Active membership в archived или
deleted Workspace также не делает Entity assigned для ordinary active UX.
Archived/deleted Task или Note никогда не попадает в ordinary Unassigned.

Ordering: member Entity `updatedAt DESC`, затем member Entity ID `ASC`.

### Workspace direct-member query semantics

Direct-member read требует:

- requested Workspace существует и active;
- Membership active;
- member Entity active;
- member type Task или Note;
- exact direct membership без Relationship traversal.

Ordering: member Entity `updatedAt DESC`, затем member Entity ID `ASC`.

Application определяет sealed mixed read model, например
`LifeOsWorkspaceMemberView` с typed Task/Note variants, содержащими Membership ID
и соответствующую Domain Task/Note. Application query port реализуется
Infrastructure SQL join. Presentation получает один context-centric result и при
необходимости группирует его в Task/Note sections; generic Entity repository не
вводится.

### Relationship interaction

- Membership не создаёт `LifeOsRelationship`.
- Existing Task<->Note Relationships не меняются.
- Workspace не является Relationship endpoint в этом milestone.
- Detach не unlink semantic Relationships.
- Workspace lifecycle не мутирует Relationships.
- Workspace screen не показывает graph/Relationship projection между direct
  members; это deferred до Knowledge Graph Foundation #2.

### Minimum Presentation contract

- Добавляется один static `Workspaces` destination после Home; dynamic Workspace
  destinations в `NavigationRail` не создаются.
- Shell сохраняет `NavigationRail`, `IndexedStack` и shell-local destination
  state; default entry становится Home как context-centric landing.
- Home показывает deterministic active Workspace entry points, `New Workspace`
  и `Unassigned`; `recent` tracking без persisted/user-state contract не вводится.
- Workspaces surface содержит active list, Workspace Trash и selected Workspace
  detail. Selection остаётся Presentation-local.
- Workspace detail показывает title, optional description, Task section, Note
  section, quick create, attach existing и detach actions.
- Quick create вызывает atomic Application use cases.
- Unassigned screen использует mixed Application read model.
- Tasks и Notes остаются global secondary destinations; Search и Settings
  сохраняются global destinations.
- Home -> Workspace targeting может расширить существующий typed one-shot feature
  command payload; router/event bus/global navigation state не вводятся.
- Весь новый пользовательский текст добавляется в EN/RU ARB и генерируется через
  `flutter gen-l10n`.

### Expected schema v4 delta

`LifeOsEntityType` позднее получает `workspace` и `workspaceMembership`.

```text
workspaces
  entity_id TEXT PRIMARY KEY REFERENCES entities(id) NO ACTION
  title TEXT NOT NULL
  description TEXT NULL

workspace_memberships
  entity_id TEXT PRIMARY KEY REFERENCES entities(id) NO ACTION
  workspace_id TEXT NOT NULL REFERENCES entities(id) NO ACTION
  member_entity_id TEXT NOT NULL REFERENCES entities(id) NO ACTION
  CHECK (workspace_id <> member_entity_id)
  UNIQUE (workspace_id, member_entity_id)
```

Indexes:

- unique `(workspace_id, member_entity_id)` обеспечивает pair invariant и
  workspace-prefix lookup;
- отдельный index на `member_entity_id` поддерживает Unassigned/member queries;
- redundant workspace-only index не добавляется без query-plan evidence.

SQL FK не может проверить Entity type/lifecycle другой таблицы. Task/Note
allowlist, Workspace type и lifecycle проверяются repository mapper/commands и
Backup Restore validation; FK, CHECK и UNIQUE остаются database integrity layer.
Typed tables хранят только Workspace-specific или Membership-specific state.
`relationships` не меняется.

WS-02 создаёт `v3_to_v4.dart`, schema v4, generated Drift output и frozen v4
snapshot по принятому tooling workflow. Existing Tasks/Notes/Relationships и
Outbox остаются exact; synthetic rows и migration Outbox запрещены.

### Expected Backup/Export v4

Logical v4 сохраняет sections:

```text
tasks
notes
relationships
workspaces
workspaceMemberships
```

Validation до mutation проверяет:

- global Entity ID uniqueness;
- Workspace Domain invariants;
- Membership Domain invariants;
- Workspace/member references и Task/Note allowlist;
- pair uniqueness независимо от lifecycle;
- Relationship v3 invariants;
- preservation active/deleted Membership и всех Workspace lifecycle states.

Reader поддерживает v1/v2/v3/v4; writer создаёт v4. Restore clear order:

```text
outbox
-> workspace_memberships + relationships
-> tasks + notes + workspaces
-> entities
```

Restore insert order:

```text
all Entity rows
-> tasks + notes + workspaces typed rows
-> relationships + workspace_memberships edge rows
```

Restore остаётся atomic, сохраняет installation `device_id`, не восстанавливает и
не создаёт Outbox. Human-readable Export v4 включает Workspace и memberships.

### Expected Outbox payloads

Workspace full snapshot:

```text
id, entityType=workspace, title, description,
createdAt, updatedAt, lifecycle, version, source
```

Membership full snapshot:

```text
id, entityType=workspaceMembership, workspaceId, memberEntityId,
createdAt, updatedAt, lifecycle, version, source
```

Workspace create — CREATE; edit/lifecycle — UPDATE. Membership first attach —
CREATE; remove/reattach — UPDATE. No-op не создаёт Outbox.

Текущий `outbox.schema_version` описывает payload schema и имеет значение `1` в
Task/Note/Relationship repositories. Он не равен SQLite schemaVersion. Для новых
Workspace/Membership full snapshots используется payload schema version `1`;
database migration к v4 сама по себе не меняет существующие Outbox versions.

## WS-01 — Contract reconciliation + quick-create transaction gate

Статус: done

### Goal

Сверить ADR-0034 с production contracts, принять bounded quick-create transaction
boundary и превратить milestone в проверяемые checkpoint contracts.

### Relevant ADRs

ADR-0016, ADR-0023, ADR-0026, ADR-0028, ADR-0029, ADR-0030, ADR-0031,
ADR-0032, ADR-0033, ADR-0034.

### Allowed scope

Read-only code/architecture audit и documentation changes только в этом active
plan и execution guide.

### Explicit non-goals

Production/test/schema/Backup/generated/dependency changes и начало WS-02.

### Definition of Done

- Current Domain/Application/Infrastructure/Presentation/Backup contracts
  reconciled.
- Exact Workspace/Membership contracts, reads и lifecycle определены.
- Membership attach/reattach identity защищена atomic repository command.
- Quick-create options сравнены и transaction boundary принят.
- WS-02…WS-08 имеют scope, tests, gates, non-goals и stop conditions.

### Validation

- Git/repository reconciliation.
- `git diff --check`.
- Scope/status inspection.

### Result / evidence

Pre-flight: `main`, HEAD `a127946458e22b90141c6cd18c957276f88cdc34`,
upstream divergence `0 0`; ADR-0034 присутствует в HEAD; staged files и active
plans отсутствовали; единственное исходное изменение — user-owned
`.obsidian/workspace.json`. Production `schemaVersion == 3`; composition использует
`V3BackupExportEncoder`, Backup format 3 и reader v1/v2/v3.

Reconciliation подтвердил typed Entity/repository pattern, external UUID/UTC
boundaries, per-repository Drift transactions с atomic full-snapshot Outbox,
Application use cases, single production composition root, shell-local
`NavigationRail`/`IndexedStack`, one-shot feature commands и current Restore
replace transaction.

Current limitations зафиксированы: Entity enum и exhaustive switches знают только
Task/Note/Relationship; cross-repository transaction abstraction отсутствует;
Backup snapshot ограничен тремя types; Relationship endpoints намеренно только
Task/Note; Search Task-specific; Home/shell type-centric.

Architecture gate: **PASS**. Принят atomic quick create через узкий Application
port `LifeOsWorkspaceMemberCreationStore`; generic Unit of Work и новый ADR не
требуются. Attach/detach/reattach принадлежат atomic membership repository
commands, а не Presentation orchestration.

### Blocker

Отсутствует.

## WS-02 — Schema v4 migration foundation

Статус: done

### Goal

Добавить только physical schema v4 и безопасную migration v3 -> v4 без Domain,
repositories, Outbox mutations или feature behavior.

### Relevant ADRs

ADR-0023, ADR-0029, ADR-0034.

### Allowed scope / expected areas

- `lib/infrastructure/persistence/drift/lifeos_database.dart`.
- `lib/infrastructure/persistence/drift/migrations/` включая `v3_to_v4.dart`.
- generated Drift database API штатным generator.
- `drift_schemas/` и generated migration-test schema v4 штатным tooling.
- migration/fresh-schema tests.
- Этот execution plan.

### Definition of Done

- `schemaVersion == 4`; fresh schema содержит `workspaces` и
  `workspace_memberships` с принятыми keys/constraints/index.
- v3 -> v4 и full v1 -> v4/v2 -> v4 chains сохраняют все existing data/Outbox.
- Existing Task/Note остаются unassigned; migration не создаёт Domain/Outbox rows.
- FK/quick checks, rollback, close/reopen и schema equivalence проходят.
- Relationships table не изменена.

### Tests / validation

- Focused migration/fresh schema/constraint tests.
- Drift generation and schema verification.
- `dart format` handwritten Dart.
- `flutter analyze`; full `flutter test`; import scan; `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если принятые constraints нельзя выразить без triggers, table
redesign, relationship changes или нового dependency/ADR decision.

### Explicit non-goals

Domain Entity types, mappers, repositories, Outbox writes, Application,
Presentation, Backup v4 и WS-03.

### Result / evidence

Pre-flight: `main`, HEAD `09560737ec08af422327b90d461dfa6d87056fba`,
upstream divergence `0 0`; WS-01 и ADR-0034 присутствуют в HEAD; staged files
отсутствовали; единственное исходное working-tree изменение — user-owned
`.obsidian/workspace.json`.

Schema v4 добавляет только typed tables `workspaces` и
`workspace_memberships`. `workspaces` содержит PK/FK `entity_id`, required
`title` и nullable `description`. `workspace_memberships` содержит PK/FK
`entity_id`, FK `workspace_id`, FK `member_entity_id`, CHECK против self-reference
и UNIQUE pair; отдельный index создан только для `member_entity_id`. Все FK имеют
SQLite `NO ACTION`; Entity metadata остаётся в `entities`; `relationships` не
изменена.

`LifeOsDatabase.schemaVersion` повышен с 3 до 4. Отдельный `v3_to_v4.dart`
создаёт две tables и member index без собственной transaction; step подключён к
существующей последовательной orchestration после неизменённых v1 -> v2 и
v2 -> v3. Backfill, synthetic Workspace/membership и migration Outbox
отсутствуют.

Штатными Drift tools обновлён generated database API, создан
`drift_schema_v4.json`, generated `schema_v4.dart` и version dispatcher
`[1, 2, 3, 4]`. Frozen JSON v1/v2/v3 byte-identical. Tooling механически
переформатировал старые generated Dart helpers, поэтому они были возвращены к
HEAD; generated v1/v2/v3 helpers имеют zero diff. Schema v5 отсутствует.

Migration tests расширены: sequential v1 -> v4 и v2 -> v4; file-backed v3 -> v4
с точным сохранением Task, Note, Relationship и Outbox; fresh-v4 equivalence;
empty Workspace tables; FK/PK/nullability/CHECK/UNIQUE/index/no-extra-workspace-
index contract; rollback controlled v3 -> v4 failure; future v5 rejection и
production-open refusal. Close/reopen и foreign-key/quick checks проходят.

Validation:

- direct SDK `dart format` PASS для changed handwritten Dart/test files;
- `dart run build_runner build` PASS; generated Drift API выпущен tooling;
- `drift_dev schema dump/generate` PASS для frozen v4/helper;
- focused migration suite PASS: 9 tests;
- full Drift persistence regression directory PASS: 53 tests;
- `flutter analyze` PASS (`No issues found`);
- full `flutter test --reporter compact` PASS: 263 tests;
- Domain/Application/Presentation import-boundary scans PASS;
- `pubspec.yaml`/`pubspec.lock` unchanged; Backup composition остаётся
  `V3BackupExportEncoder` и logical Backup v3 не менялся;
- ADR-0034 и frozen v1/v2/v3 artifacts unchanged;
- final `git diff --check` PASS.

### Blocker

Отсутствует.

## WS-03 — Workspace/Membership Domain + Persistence

Статус: done

### Goal

Реализовать Workspace/Membership Domain contracts, typed repositories, mappers,
atomic single-Entity persistence и membership pair commands.

### Relevant ADRs

ADR-0016, ADR-0023, ADR-0026, ADR-0032, ADR-0033, ADR-0034.

### Allowed scope / expected areas

- `LifeOsEntityType` additions.
- Workspace/Membership Domain files и typed repository abstractions.
- Drift mappers/repositories и bounded shared private persistence helpers.
- Domain, mapper, repository, Outbox, lifecycle and reopen tests.
- Этот execution plan.

### Definition of Done

- Exact WS-01 Domain invariants/no-op/lifecycle pass focused tests.
- Workspace save atomically writes Entity + typed row + Outbox.
- Membership attach is race-safe under DB uniqueness, restores same identity,
  validates active refs and emits correct CREATE/UPDATE/no-op.
- Detach soft-deletes only membership and emits atomic UPDATE.
- Multi-workspace cardinality and all-state reads work after reopen.
- Task/Note/Relationship behavior remains unchanged.

### Tests / validation

- Focused Domain/mapping/repository/Outbox/concurrency/persistence tests.
- Existing Task/Note/Relationship persistence regressions.
- `dart format`, `flutter analyze`, full `flutter test`, import scan,
  schemaVersion/Backup guards, `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если pair identity требует weakening ADR-0034, physical deletes,
generic Entity repository или change to current Relationship semantics.

### Explicit non-goals

Application use cases/composition, cross-entity quick-create store, Backup v4,
Presentation, Search и WS-04.

### Result / evidence

Pre-flight: `main`, HEAD `386cd49`, upstream divergence `0 0`; WS-01/WS-02,
ADR-0034, schema v4 и migration v3 -> v4 присутствовали в HEAD.
Единственным исходным working-tree change оставался user-owned
`.obsidian/workspace.json`; он не изменялся.

`LifeOsEntityType` дополнен `workspace` и `workspaceMembership`.
`LifeOsWorkspace` реализует typed identity, normalized non-empty title,
literal nullable description, ADR-0026 creation defaults, immutable atomic edit,
true no-op и полную ADR-0033 lifecycle state machine без cascade.
`LifeOsWorkspaceMembership` имеет immutable Workspace/Task-or-Note endpoints,
active/deleted-only lifecycle, identity-preserving remove/reattach, versioned UTC
mutations и no-op semantics; archived membership отклоняется.

Добавлены отдельные typed `LifeOsWorkspaceRepository` и
`LifeOsWorkspaceMembershipRepository`; generic Entity repository не вводился.
Workspace reads и membership all-state/pair/active Workspace/member reads имеют
deterministic `updatedAt DESC`, затем `id ASC` ordering.

Drift mappers объединяют common Entity metadata с typed rows, проверяют
endpoint records/types и преобразуют corrupt persisted state в typed mapping
exceptions. Workspace `save` атомарно записывает Entity + typed row +
full-snapshot Outbox CREATE/UPDATE; direct identical save является no-op.

Membership `attach` в одной transaction проверяет complete active
Workspace и active Task/Note, ищет unique pair независимо от
lifecycle, затем выполняет CREATE, active no-op или identity-preserving
reattach UPDATE. Concurrent duplicate attach образует одну pair и один
Outbox record. `remove` soft-deletes только membership; repeated remove не
пишет state/Outbox. CREATE/UPDATE payload содержит full camelCase snapshot,
`schema_version == 1`; injected Outbox failures откатывают Entity и typed row.
Task/Note и Workspace не мутируются attach/detach operations.

Exhaustive enum consumers обновлены только для явного rejection:
Workspace/Membership не стали Relationship endpoints, и historical Backup v1
их не принимает. Application use cases, production composition, quick-create
store, mixed queries, Backup v4 и Presentation не реализовывались.

Validation:

- focused Workspace/Membership Domain + persistence/Outbox suite PASS: 26 tests;
- Task/Note/Relationship repository + migration/schema regression PASS: 40 tests;
- `flutter analyze` PASS (`No issues found`);
- full `flutter test --reporter compact` PASS: 289 tests;
- Domain/Application import-boundary scans PASS;
- Relationship Task/Note endpoint allowlist preserved;
- `schemaVersion == 4`, schema v5 absent, v3 -> v4 migration и frozen schemas
  v1-v4 unchanged;
- production writer остался `V3BackupExportEncoder`; Backup format v4 не
  реализован;
- `pubspec.yaml`/`pubspec.lock` unchanged; new dependencies absent;
- `git diff --check` PASS.

### Blocker

Отсутствует.

## WS-04 — Application + production composition

Статус: pending

### Goal

Добавить Workspace/member use cases, mixed reads, atomic quick-create port и
единственное production composition wiring.

### Relevant ADRs

ADR-0022, ADR-0023, ADR-0024, ADR-0026, ADR-0033, ADR-0034.

### Allowed scope / expected areas

- Workspace create/edit/delete/restore/list/Trash use cases.
- Attach/detach and Workspace Task/Note quick-create use cases.
- `LifeOsWorkspaceMemberCreationStore` Application port и Drift implementation.
- Mixed direct-member/Unassigned Application read models and query port.
- `lib/app/dependencies.dart`, Provider boundaries needed by later Presentation.
- Focused Application/composition/integration tests.

### Definition of Done

- Normal global Task/Note create remains unchanged.
- Quick create writes Task/Note + Membership + two Outbox records in one
  transaction and fully rolls back injected failure.
- Application has no Drift/SQLite/Infrastructure imports.
- Attach/detach/reattach semantics use atomic repository commands.
- Direct-member and Unassigned reads satisfy exact WS-01 visibility/order.
- Composition creates one database and one set of infrastructure owners.

### Tests / validation

- Deterministic fake Application tests.
- File/in-memory Drift atomic rollback and composition lifecycle tests.
- Existing Task/Note/Relationship/composition regressions.
- `dart format`, `flutter analyze`, full `flutter test`, import scan,
  dependency/schema/Backup guards, `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если atomic quick create требует generic Unit of Work, Application
Drift knowledge, repository concrete coupling или changes to global create.

### Explicit non-goals

Presentation, Backup v4, Search, Relationship expansion и WS-05.

### Result / evidence

Pending.

### Blocker

Отсутствует до architecture gate.

## WS-05 — Backup/Export/Restore v4

Статус: pending

### Goal

Версионировать logical format для Workspace context и сохранить safe Restore
compatibility v1/v2/v3/v4.

### Relevant ADRs

ADR-0028, ADR-0029, ADR-0031, ADR-0034.

### Allowed scope / expected areas

- Backup/Application snapshot contracts.
- v4 DTO/codec/encoder, reader dispatch and file writer validation.
- Restore store FK-safe clear/insert ordering.
- Backup/export/reader/restore/use-case tests.
- Composition switch to v4 writer.

### Definition of Done

- Writer creates Backup/Export v4 with all Tasks, Notes, Relationships,
  Workspaces and memberships including inactive state.
- Reader/Restore v1/v2/v3 regressions remain supported.
- Malformed refs, duplicate pairs, checksum/version errors reject before mutation.
- Restore is atomic, preserves `device_id`, clears Outbox and creates none.
- Deleted memberships and Workspace lifecycle round-trip exactly.

### Tests / validation

- Focused v4 codec/file/restore/backward-compatibility/rollback tests.
- Existing v1/v2/v3 Backup/Export/Restore tests.
- `dart format`, `flutter analyze`, full `flutter test`, import/dependency scan,
  `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если v4 требует changing frozen v1/v2/v3 semantics, partial restore,
raw SQLite backup или a compatibility policy beyond ADR-0034.

### Explicit non-goals

Import from Export, merge Restore, encryption, cloud/scheduled backup,
Presentation и WS-06.

### Result / evidence

Pending.

### Blocker

Отсутствует до architecture gate.

## WS-06 — Workspace Presentation

Статус: pending

### Goal

Реализовать localized Workspace feature surface поверх готовых Application
boundaries без shell/navigation integration.

### Relevant ADRs

ADR-0022, ADR-0027, ADR-0033, ADR-0034.

### Allowed scope / expected areas

- `lib/presentation/workspaces/` widgets/controllers/providers.
- EN/RU ARB и штатный `gen_l10n` output.
- Focused Workspace widget/provider/localization tests.

### Definition of Done

- Active list, selection/detail, create/edit/delete, Trash/restore work.
- Mixed Task/Note sections, atomic quick create, attach existing and detach work.
- Multi-workspace membership and identity-preserving reattach reflected after
  refresh; errors are recoverable.
- Presentation не импортирует Infrastructure и не оркестрирует membership lookup.
- Desktop `1280x800` и `640x600`, keyboard/focus/EN/RU have coverage.

### Tests / validation

- Focused Presentation/provider/widget/localization/layout tests with overrides.
- Existing Task/Note/Relationship Presentation regressions.
- `flutter gen-l10n`, `dart format`, `flutter analyze`, full `flutter test`,
  import/localization/routing scans, `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если UI требует new global state/navigation architecture,
direct Infrastructure dependency или changes to Domain semantics.

### Explicit non-goals

Shell destination, Home/Unassigned integration, graph visualization, Search,
Dashboard, routing package и WS-07.

### Result / evidence

Pending.

### Blocker

Отсутствует до architecture gate.

## WS-07 — Context-centric shell + Unassigned

Статус: pending

### Goal

Интегрировать Workspaces и Unassigned в существующий desktop shell, сохранив
global Task/Note/Search/Settings behavior.

### Relevant ADRs

ADR-0022, ADR-0027, ADR-0034 и completed Desktop Shell/Dogfooding plans.

### Allowed scope / expected areas

- Static `Workspaces` destination, shell `IndexedStack`, Home entry points and
  typed one-shot command extension.
- Default Home landing and Workspaces-local selection.
- Unassigned Presentation over Application mixed read model.
- Shell/Home/Workspace/Task/Note navigation and lifecycle tests.

### Definition of Done

- Static destinations are Home, Workspaces, Tasks, Notes, Search, Settings.
- Home opens Workspace/Unassigned and creates Workspace without dynamic rail.
- Home -> Workspace -> Tasks/Notes -> Workspace сохраняет intended local state.
- Unassigned exact visibility semantics pass integration tests.
- Task/Note global views, Search state, Settings and single DB lifecycle survive.
- No routing package/history/deep links introduced.

### Tests / validation

- Focused shell/Workspace/Unassigned/Task/Note navigation tests.
- EN/RU and desktop responsive/accessibility regressions.
- `flutter gen-l10n` if ARB changed; `dart format`; `flutter analyze`; full
  `flutter test`; import/localization/routing/dependency scans; `git diff --check`.

### Stop conditions / architecture gate

Остановиться, если context entry requires dynamic routes, persistent navigation
history, URL/deep links или global navigation state.

### Explicit non-goals

Unified Search, graph integration, AI, dynamic Workspace rail entries и WS-08.

### Result / evidence

Pending.

### Blocker

Отсутствует до architecture gate.

## WS-08 — Integration + final audit

Статус: pending

### Goal

Доказать end-to-end Workspace vertical slice, architecture boundaries, migration,
restart persistence, Backup v4 и absence of scope creep.

### Relevant ADRs

Все ADR milestone, прежде всего ADR-0023, ADR-0024, ADR-0028, ADR-0029,
ADR-0032, ADR-0033 и ADR-0034.

### Allowed scope

Audit, final evidence и только минимальные fixes конкретных defects внутри
принятой architecture.

### Definition of Done

- Create/edit/delete/restore Workspace works through Presentation -> Application
  -> Domain -> Infrastructure.
- Mixed direct members, quick create, attach/detach/reattach, zero-to-many and
  Unassigned work after close/reopen.
- Workspace/member state and Outbox are atomic; no lifecycle/Relationship cascade.
- v3 -> v4 migration preserves data; fresh v4 and rollback pass.
- Backup/Export v4 and Restore v1-v4 pass without Outbox/device loss.
- Shell/localization/layout stable; Search and Relationship behavior unchanged.
- Plan final validation passes and plan is moved to completed.

### Validation

- All focused Domain/Application/persistence/migration/Backup/Presentation suites.
- `dart format` changed handwritten Dart.
- `flutter gen-l10n` check.
- `flutter analyze`.
- Full `flutter test --reporter compact`.
- Import/localization/routing/dependency/schema/generated-file scans.
- `git diff --check` and exact Git status.

### Stop conditions / architecture gate

Остановиться и зафиксировать blocker при unresolved architecture decision,
compatibility loss, data-loss risk или requirement beyond ADR-0034.

### Explicit non-goals

Следующий milestone или execution plan; Unified Search, graph #2, AI и Sync.

### Result / evidence

Pending.

### Blocker

Отсутствует до architecture gate.

## Run grouping / token optimization

Рекомендуемые runs:

1. WS-01 — отдельный completed documentation/reconciliation run.
2. WS-02 — отдельный schema/migration run и отдельный review/commit владельца.
3. WS-03 — Domain + typed persistence.
4. WS-04 — Application/composition + atomic cross-entity store.
5. WS-05 — Backup/Export/Restore v4.
6. WS-06 + WS-07 — допускается объединить только если WS-06 focused tests зелёные
   и shell integration не требует architecture change.
7. WS-08 — отдельный final audit.

WS-03 и WS-04 лучше разделить, несмотря на исходное предложение grouping:
WS-03 устанавливает pair identity и single-Entity Outbox correctness, тогда как
WS-04 добавляет новый cross-entity transaction port. Раздельная validation делает
rollback и layer-boundary regressions локализуемыми и снижает риск большого
непроверяемого diff. Если WS-03 отдельно cleanly committed и contract полностью
стабилен, владелец может явно разрешить их объединение позднее.

## Plan-level validation strategy

1. Каждый checkpoint начинает с Git/plan/ADR reconciliation и помечается active.
2. Сначала запускаются smallest relevant tests, затем full suite.
3. Generated Drift/localization files меняются только штатным tooling.
4. Schema version, Backup writer и compatibility проверяются явно на каждом
   затрагивающем checkpoint.
5. Import boundaries гарантируют отсутствие Drift/SQLite в Application/Domain и
   Infrastructure construction в Presentation.
6. `.obsidian/workspace.json` всегда сохраняется как отдельное user-owned change.

## Current risks / open implementation details

- SQLite не проверяет cross-table Entity type через обычный FK; repository и
  Restore validation обязательны.
- Candidate membership UUID может не использоваться при reattach/no-op; это
  намеренно и безопасно.
- Cross-entity quick-create transaction должна переиспользовать persistence
  helpers без concrete repository coupling и duplicate Outbox logic drift.
- Provider invalidation после quick create/attach/detach должна обновлять
  Workspace, global Task/Note и Unassigned views без случайного stale state.
- Home не имеет принятого recency model; initial Workspace list deterministic,
  но не называется recent.
- Exact widget layout остаётся WS-06 concern в пределах fixed UX contract.

Неразрешённых архитектурных blocker после WS-01 нет. Новый ADR помимо ADR-0034
не требуется.

## Exact resume point

WS-03 завершён. Возобновить с WS-04 — Application, mixed queries,
atomic quick-create store and production composition. Перед implementation
отметить WS-04 active, перечитать ADR-0022, ADR-0023, ADR-0024, ADR-0026,
ADR-0033 и ADR-0034, сверить HEAD/Git и WS-03 repository contracts. WS-05 не
начинать.
