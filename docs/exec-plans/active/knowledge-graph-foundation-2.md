# Knowledge Graph Foundation #2

Статус: implementation active

Тип: docs-only architecture investigation и proposed execution plan

Точка возобновления: KG-02 — Drift direct-neighbor reader and composition.
Перед implementation отметить KG-02 active и повторно сверить Git, schema v4,
Relationship indexes и готовый KG-01 Application contract.

## Goal

Определить минимальный Knowledge Graph contract LifeOS 1.0 поверх
существующих Task, Note и `LifeOsRelationship`, не смешивая semantic
edges с Workspace membership и не вводя traversal, graph visualization,
AI Context Engine или новую storage architecture без доказанной необходимости.

## Sources and precedence

Фактически сверены ADR-0016, ADR-0023, ADR-0030, ADR-0032, ADR-0033,
ADR-0034, completed Relationships и Workspace plans, roadmap/vision/architecture/UI
documents и production code. Конкретные accepted ADR-0032…0034 и
production behavior имеют приоритет над preliminary целевыми примерами
ADR-0016 и product vision.

## Current state

### Domain

- `LifeOsRelationship` — отдельная typed `LifeOsEntity` со stable identity,
  UTC timestamps, lifecycle, version и source.
- Endpoints — только Task и Note. Workspace, WorkspaceMembership и Relationship
  endpoint не поддерживаются.
- Relationship ненаправлена. `firstEntityId`/`secondEntityId` имеют
  canonical lexical ordering, но не source/target semantics.
- `LifeOsRelationshipKind` содержит только `related`. Kind не влияет
  на behavior помимо identity/uniqueness и serialization.
- Self-link запрещён. Duplicate определяется unordered endpoint pair + kind.
- Creation создаёт active/user/version-1 Entity. Единственная mutation —
  `unlink()`, переводящая active -> deleted с version increment. Re-link не
  определён.

### Persistence and repository

- `relationships` хранит `entity_id`, canonical `first_entity_id`,
  `second_entity_id`, `kind`.
- PK/FK, self/canonical checks и unique `(first_entity_id, second_entity_id, kind)`
  защищают integrity.
- Composite unique index покрывает lookup по `first_entity_id`; отдельный
  `relationships_second_entity_id_idx` покрывает вторую canonical side.
- `LifeOsRelationshipRepository` предоставляет `getAll`, `getById`,
  `getForEntity` и `save`.
- `getForEntity` читает обе canonical sides, возвращает только active
  Relationship с двумя active endpoints и сортирует `updatedAt DESC,
  id ASC`.
- Current mapper path разрешает endpoint metadata отдельными reads для
  каждой Relationship. Для малых contextual lists это корректно,
  но не является bounded graph projection.
- Save атомарно пишет Entity, typed row и Outbox CREATE/UPDATE. Read-side
  expansion Outbox не требует.

### Application and Presentation

- Application имеет specialised create, get-for-entity и unlink use cases.
- `RelatedEntitiesSection` показывает direct related Task/Note в Task и Note UI,
  позволяет add и unlink.
- Presentation разрешает label endpoint через полные Task/Note lists.
  Это Presentation-side cross-feature lookup, а не graph read model.
- Related row не clickable: Task -> related Note и Note -> related Task не могут
  открыть соседню Entity.
- `LifeOsFeatureCommand` умеет new Task/Note и Workspace actions, но не typed
  open Task/Note. Router/deep links в production нет.

### Backup

- Backup/Export v4 уже сохраняет Relationship с exact metadata, endpoints,
  kind и lifecycle вместе с Task, Note, Workspace и Membership.
- Read/Restore v1–v4, validation-before-mutation, atomicity, no-Outbox Restore и
  `device_id` preservation уже доказаны.

## What the graph is today

Текущий semantic graph:

```text
Nodes: Task, Note
Edges: active LifeOsRelationship(kind: related)
Shape: undirected, direct adjacency only
```

Workspace — structural/context Entity, а WorkspaceMembership — structural edge. Они
не входят в текущий semantic graph, несмотря на более широкую
концептуальную модель ADR-0034.

Сейчас можно получить Relationship rows для одной Entity. Нет:

- Application projection с разрешёнными neighbor Entities;
- traversal больше одного hop;
- cycle protection, visited set и depth policy;
- graph-wide ranking, pagination или visualization;
- graph-specific Context Assembler.

Canonical pair и DB uniqueness предотвращают duplicate edges, но не
дубликаты nodes в произвольном traversal, поскольку traversal нет.

## Relationship kind finding

`kind` сейчас — typed persisted discriminator и часть pair uniqueness. Он
не меняе display, lifecycle, query policy или navigation. Доказанного
user-facing use case для `blocks`, `dependsOn`, `references`, `contains`, `about`
или иного kind нет.

Решение 1.0: оставить только `related`. Новый kind или directionality
потребует отдельного product/Domain gate с конкретным mutation, duplicate,
inverse-label, UI, Backup и future Sync contract.

## Relationship vs Membership boundary

| Concept | Relationship | WorkspaceMembership |
|---|---|---|
| Meaning | user-authored semantic association | structural inclusion in a life context |
| Endpoints | Task/Note unordered pair | Workspace -> Task/Note typed pair |
| Cardinality | unique pair per kind | Entity may belong to zero-to-many Workspaces |
| Lifecycle action | unlink semantic edge | detach/reattach structural membership |
| Context effect | optional semantic neighbor | defines direct Workspace context |
| Storage | `relationships` | `workspace_memberships` |

Граница соблюдается в Domain, repositories, schema, Backup и UI. Опасные
будущие смешения: кодировать membership kind-ом `contains`, считать
Workspace Relationship endpoint, автоматически unlink-ать edge при detach или
расширять Workspace context по graph без explicit policy.

Implementation guards:

- Workspace/Membership не разрешать как Relationship endpoints;
- attach/detach/reattach не создают и не мутируют Relationship;
- graph reads не меняют Workspace membership и не определяют ownership;
- Workspace context не включает semantic neighbors неявно.

## Product capability assessment

| Capability | Current state | Need before 1.0 | Finding |
|---|---|---:|---|
| A. Direct related Task/Note | implemented | yes | Keep and move endpoint resolution below Presentation |
| B. Navigate to direct neighbor | absent | yes | Main proven usability gap |
| C. Show internal Workspace relationships | absent | no evidence | Defer; direct Entity Related UI already exposes semantics |
| D. Show external Workspace neighbors | absent | no | Requires scope/privacy UX decision |
| E. One-hop expansion | partial read capability | yes, only as bounded direct-neighbor primitive | No recursive traversal |
| F. Two-hop traversal | absent | no | No concrete user journey; adds cycles/fan-out |
| G. Full graph visualization | absent | no | Explicitly deferred by ADR-0034/UI docs |
| H. Graph recommendations | absent | no | Belongs to future AI/product policy |
| I. Graph context for AI | absent | future | Reuse bounded direct-neighbor primitive; assembler stays in AI milestone |

## Proposed LifeOS 1.0 graph semantics

1. Semantic nodes are active Task and Note Entities.
2. Semantic edges are active, undirected `LifeOsRelationship(kind: related)` with
   both endpoints active.
3. Ordinary graph read is one-hop adjacency from an explicit root Entity.
4. Result items preserve provenance: Relationship identity/kind and root/neighbor
   identity, plus resolved current Task/Note state needed by the consumer.
5. Ordering is deterministic: Relationship `updatedAt DESC`, then Relationship ID
   `ASC`, matching the existing contextual contract.
6. A read is explicitly bounded by a required positive `limit`. No Domain-wide
   relationship maximum is introduced; callers choose a use-case bound.
7. No implicit Workspace scope, transitive closure, scoring, recommendation,
   directionality or new mutation semantics is added.
8. Read-side projection is local, read-only and produces no Outbox mutation.

`archived`/`deleted` Relationship или endpoint исключаются из ordinary
projection. Endpoint restore/unarchive снова делает существующую active
Relationship видимой. Inactive Workspace не влияет на global semantic
Relationship; Workspace-scoped context остаётся direct-membership-only.

## Direct relations vs traversal

1-hop достаточен для LifeOS 1.0. Arbitrary depth и 2-hop deferred.

Причины: текущий user flow — понять и открыть непосредственную
связь. 2-hop требует visited/deduplication, cycle protection, depth, fan-out,
ranking и relevance policy, но не имеет подтверждённого consumer.

## Workspace graph recommendation

Для 1.0 выбрана модель D: отдельный Workspace graph пока не нужен.

- Model A (edges только между direct members) понятна, но дублирует
  Entity-level Related UI без доказанного Workspace user flow.
- Model B (хотя бы один direct member) смешивает direct context и external
  semantic scope и усложняет lifecycle/stale-state semantics.
- Model C (1-hop наружу) требует privacy, prominence и fan-out policy; это
  будущий AI/Context gate.
- Model D сохраняет accepted direct-member Workspace semantics и позволяет
  сначала закрыть доказанный Entity navigation gap.

## Application boundary

Минимальная abstraction — specialised read-only Application port, например
`LifeOsRelatedEntityReader`, и use case `GetDirectLifeOsRelatedEntities`.

Port принимает typed Task/Note root ID и required positive `limit`, а возвращает
immutable ordered Application projection. Projection содержит Relationship provenance
и resolved current neighbor Task/Note. Точное Dart-имя и sealed shape — bounded
implementation detail KG-01, если не меняет эту semantics.

Почему не alternatives:

- не расширять mutation-oriented Domain repository cross-entity DTO;
- не оставлять Presentation joins/full-list label resolution;
- не вводить generic Graph/Entity repository или query language;
- не вводить Context Assembler до появления AI consumer.

Infrastructure реализует port одним bounded joined query/read workflow поверх
existing schema. Composition создаёт reader/use case на единственной production DB.

## Storage and query implications

- Current schema v4 достаточна.
- Schema v5: NO.
- New kind column/state: NO; column уже есть, Domain остаётся `related`.
- New indexes: NO без измеренной query problem. Existing canonical-pair
  unique index и second-endpoint index покрывают adjacency predicate.
- KG-02 должен зафиксировать `EXPLAIN QUERY PLAN`/index evidence в focused test
  или bounded diagnostic; migration не создавать, если measured defect не найден.
- Backup v4: без изменений. Backup v5: NO.
- Outbox: без изменений; foundation read-only.

## Performance and bounds

- Direct adjacency query должен фильтровать lifecycle и применять order/limit
  в SQLite, а не после full-table materialization.
- Required caller-supplied `limit` делает fan-out explicit. Universal Domain maximum
  и arbitrary fixed product number не вводятся.
- Initial contextual UI использует bounded page/section limit; pagination добавляется
  только при доказанной reachability problem.
- Joined projection должна убрать current per-edge endpoint N+1 и full Task/Note
  list reads.
- Arbitrary traversal, cycle handling и graph-wide deduplication не нужны, пока
  depth равна 1.
- AI Foundation обязана задать свой меньший token/privacy bound;
  UI limit не является AI context policy.

## Context Engine, AI and Search boundaries

### Context Engine

Отдельный Context Assembler сейчас не вводится. ADR-0034 уже фиксирует
Context как computed Application projection. Его consumer-specific assembly,
privacy, ranking, token budget и reason/provenance selection остаются AI Foundation.

### AI

Сейчас стоит реализовать только reusable primitive:

- bounded direct active neighbors;
- deterministic order;
- Relationship provenance explaining why neighbor is present;
- lifecycle filtering;
- no persistence/provider coupling above Infrastructure.

До AI milestone отложены Workspace + member + Relationship + Search assembly,
external-neighbor inclusion, relevance/ranking, token budget, privacy policy, prompt/provider
и user-visible explanation.

### Search

Unified Local Search остаётся отдельным milestone. Search сначала
индексирует/ищет Entity напрямую. Graph expansion не меняет match,
ranking или scope search results. Future `related to result` может быть
post-query Application layer после отдельного product gate.

## UX and navigation recommendation

Минимальный 1.0 UX:

- улучшить existing `RelatedEntitiesSection`, а не создавать Graph page;
- показывать resolved current Task/Note из Application projection;
- сделать row keyboard/click actionable и открывать neighbor;
- переключать existing Tasks/Notes destination через typed one-shot
  `LifeOsFeatureCommand` extension;
- Task/Note feature принимает open-existing command и выбирает Entity;
- Note navigation обязана переиспользовать existing dirty-draft guard; stale/missing/inactive
  target даёт recoverable localized state, а не false selection.

Router, URL routing, deep links, navigation history, dedicated graph destination,
force-directed visualization и context side panel не нужны.

## ADR decision

**ADR NOT REQUIRED.**

ADR-0032 уже определяет current graph identity, endpoint types, undirected
`related`, duplicates, lifecycle и mutation semantics. ADR-0033 определяет
ordinary lifecycle visibility. ADR-0034 разделяет semantic Relationship,
structural Membership и computed Application Context. Предлагаемый scope
добавляет specialised read projection и navigation поверх этих contracts,
но не меняет долгоживущую Domain/storage semantics.

Новый ADR будет нужен только перед new kinds/directionality,
Workspace semantic endpoints/scope, traversal >1 hop или Context Assembler policy.

## Risks and controls

- **Fan-out:** required query limit; no recursive expansion.
- **Cycles/duplicates:** depth 1; DB pair uniqueness; projection returns one item per edge.
- **N+1:** Infrastructure joined projection, verified by focused query tests.
- **Stale labels:** resolve current endpoint state in the same read workflow; provider refresh on
  Task/Note lifecycle/edit and Relationship mutation.
- **Dirty Note loss:** route open command through existing draft guard.
- **Concept mixing:** retain endpoint type guards and separate Membership APIs/tables.
- **Scope creep:** no Workspace graph, Search expansion, AI assembler or visualization.
- **Future scale:** measure query plan and large bounded fixtures before adding indexes.

## Decision answers Q1–Q13

1. Knowledge Graph 1.0 — Task/Note nodes plus active undirected direct `related` edges
   and bounded one-hop neighbor navigation.
2. Semantic nodes — Task и Note. Workspace/Membership сейчас structural/contextual.
3. `Relationship.kind` остаётся только `related`.
4. Directional Relationship до 1.0 не нужна.
5. Schema v5 не нужна.
6. Backup v5 не нужна.
7. Traversal >1 hop не нужен.
8. Dedicated graph visualization не нужна.
9. Workspace не показывает отдельный semantic graph в минимальном 1.0 scope.
10. Global graph может связывать Entity из разных/zero Workspaces, но
    Workspace context не расширяется на external neighbors автоматически.
11. Нужен specialised read-only Application port + direct-neighbor use case.
12. Будущему AI нужны bounded neighbors, lifecycle filtering,
    deterministic order и Relationship provenance; assembly/ranking/privacy позже.
13. Deferred: new kinds/directions, Workspace graph/semantic endpoints, 2+ hops,
    visualization, recommendations, Context Assembler, AI policy, graph-aware Search.

## Recommended 1.0 scope

Included:

- read-only bounded one-hop Task/Note neighbor projection;
- current lifecycle filtering и deterministic ordering;
- removal of Presentation-side full-list endpoint resolution;
- clickable/keyboard-accessible Related rows;
- typed shell command to open an existing Task or Note;
- lifecycle/navigation/invalidation и architecture regression coverage.

Deferred:

- new Relationship kinds и directionality;
- Workspace semantic endpoints и Workspace graph section;
- 2-hop/arbitrary traversal, ranking и recommendations;
- graph visualization/destination;
- Context Assembler, AI provider/context policy;
- graph-expanded Search;
- Relationship re-link/undo.

## Implementation checkpoints

### KG-01 — Direct-neighbor Application contract

Status: done

Goal: ввести specialised immutable related-entity projection, read-only port и
bounded use case.

Scope: Application contracts/use case, deterministic/lifecycle/limit semantics, fakes и
focused tests.

Exclusions: Infrastructure query, UI, navigation, Domain/repository mutation changes.

Depends on: accepted investigation scope.

Validation: Application tests, import-boundary scan, `flutter analyze`, `git diff --check`.

Architecture gate: stop, если projection требует generic Entity/Graph abstraction
или новую lifecycle semantics.

Result / evidence:

- Добавлен sealed Application read model `LifeOsRelatedNeighbor` с typed variants
  `LifeOsRelatedTaskNeighbor` и `LifeOsRelatedNoteNeighbor`. Каждый item сохраняет
  `sourceId`, full `LifeOsRelationship`, resolved typed Task/Note и derived target
  `entityId`; `dynamic`, maps и generic Entity bag не используются.
- Projection constructor защищает Task/Note-only nodes, active Relationship,
  active neighbor, kind `related` и exact opposite-endpoint provenance. Domain не
  изменён.
- Application-facing `LifeOsRelatedEntityReader.getDirectNeighbors` принимает
  required typed `sourceId` и required positive `limit`. Contract возвращает
  at most `limit` items в порядке Relationship `updatedAt DESC`, затем
  Relationship ID `ASC`; optional unbounded API нет.
- `GetDirectLifeOsRelatedNeighbors` следует callable Application convention,
  валидирует source type/limit до port и делегирует read без sorting,
  caching, joins, ranking, traversal или mutation.
- Typed `LifeOsRelatedEntityQueryException` различает
  `unsupportedSourceType`, `invalidLimit`, `sourceNotFound` и `sourceInactive`.
  Invalid type/limit отклоняются use case до reader; KG-02 implementation
  обязана явно бросать missing/inactive source, а не возвращать
  silent empty list.
- Workspace/Membership, navigation, Presentation, Infrastructure, schema, Backup,
  Outbox, dependencies и Relationship kinds не изменялись. KG-02 остаётся
  pending; Drift adapter/composition не начинались.
- Focused KG-01 suite: 7 tests PASS. Existing Relationship Domain/Application
  regression: 9 tests PASS. `dart format` PASS; `flutter analyze` PASS
  (`No issues found`). Application import-boundary, schema/Backup/dependency guards
  и `git diff --check` PASS.

### KG-02 — Drift direct-neighbor reader and composition

Status: pending

Goal: реализовать port bounded joined query на schema v4 и wire его к
single production DB.

Scope: Infrastructure reader, mapping, order/limit, query-plan evidence, composition.

Exclusions: schema migration, indexes without measured defect, Backup/Outbox changes.

Depends on: KG-01.

Validation: direct neighbors, inactive Relationship/endpoint, both canonical sides,
deterministic order, limit, no duplicates, large bounded fixture, read-only/Outbox tests.

Architecture gate: stop before schema v5/new index if existing indexes are demonstrably
insufficient and the durable fix is not unambiguous.

### KG-03 — Typed cross-feature entity navigation

Status: pending

Goal: расширить existing shell-local `LifeOsFeatureCommand` для open-existing
Task/Note без router.

Scope: typed command payload, Task/Note selection handling, stale/inactive target behavior,
Note dirty-draft guard reuse.

Exclusions: router, deep links, history, global navigation state, Graph destination.

Depends on: KG-01 contract; KG-02 may proceed independently until UI wiring.

Validation: Task -> Note, Note -> Task, same-feature open, dirty Note flows, missing target,
IndexedStack state, keyboard navigation.

Architecture gate: stop if reliable selection requires a new routing architecture.

### KG-04 — Related UI over Application projection

Status: pending

Goal: перевести `RelatedEntitiesSection` на direct-neighbor use case и сделать
rows navigable.

Scope: provider overrides, loading/empty/error/retry, clickable/keyboard rows,
localized semantics/tooltips, mutation/lifecycle invalidation.

Exclusions: Workspace graph, visualization, Search, recommendations.

Depends on: KG-02 and KG-03.

Validation: resolved labels, active/inactive lifecycle refresh, add/unlink, stale response,
EN/RU, 1280x800 and 640x600, accessibility and no overflow.

Architecture gate: stop if UI needs graph-wide state or traversal.

### KG-05 — Workspace/Search/Backup non-regression gate

Status: pending

Goal: доказать, что global semantic neighbor navigation не меняет direct
Workspace context, Task-only Search, Backup v4, Outbox и schema v4.

Scope: focused integration/regression tests и documentation evidence; production changes
только для concrete bounded defect.

Exclusions: Workspace graph integration, Unified Search, Backup/schema version bump.

Depends on: KG-04.

Validation: Workspace/Membership, Search, Relationship persistence, Backup v1–v4,
Restore, Outbox, dependency/schema/import scans.

Architecture gate: stop on any need for Workspace scope decision, schema v5 or Backup v5.

### KG-06 — Integration and final audit

Status: pending

Goal: подтвердить complete bounded one-hop vertical slice и absence of scope creep.

Scope: final architecture/data-safety/UX audit, full validation, plan completion.

Exclusions: every deferred capability and next milestone.

Depends on: KG-01…KG-05 done.

Validation: focused matrix, `flutter analyze`, full `flutter test`, localization/import/
routing/dependency/schema/Backup guards, `git diff --check`, exact Git state.

Architecture gate: unresolved durable decision leaves KG-06 blocked and milestone active.

## Milestone Definition of Done

- Task/Note direct neighbors are read through Application, not assembled in Presentation.
- Projection is local, read-only, bounded, lifecycle-aware and deterministically ordered.
- User can navigate Task <-> Task/Note and Note <-> Task/Note from Related UI without
  router or draft/data loss.
- Existing create/unlink, duplicate, Outbox and Backup v4 behavior is unchanged.
- Workspace context remains direct-membership-only; Search remains global Task-only.
- `schemaVersion == 4`, Backup writer v4 and dependency set remain unchanged.
- Focused and full validation pass; no deferred feature is introduced.

## Roadmap interaction

Порядок остаётся логичным:

1. Knowledge Graph Foundation #2 — даёт bounded semantic-neighbor primitive и
   usable cross-entity navigation.
2. Unified Local Search — даёт direct entity retrieval без graph expansion.
3. AI Foundation — определяет provider/privacy/context contracts.
4. Context-aware AI #1 — компонует Workspace, Search и bounded neighbors.
5. LifeOS 1.0 stabilization.

Перестановка не нужна: graph primitive не зависит от Unified Search,
а AI Context получит оба bounded inputs после их отдельной стабилизации.

## Deferred scope

- directional Relationships и new kinds;
- Workspace as semantic endpoint и Workspace graph scope;
- 2-hop/arbitrary traversal, cycle/visited algorithms и graph ranking;
- graph visualization, dedicated destination и force-directed layout;
- recommendations и automatic/AI-created Relationships;
- Context Assembler, token/privacy/ranking policy, AI providers/prompts;
- graph-aware Search и Search result expansion;
- schema v5, Backup v5, graph database и new dependencies;
- Relationship re-link/undo и new mutation semantics.

## Investigation validation

- Pre-flight: branch `main`, HEAD `bbc5c6f` (`docs: complete workspace vertical
  slice`), `origin/main...HEAD = 0 0`.
- Active execution plans до investigation отсутствовали.
- Единственное pre-existing change: user-owned `.obsidian/workspace.json`.
- Production Dart, tests, schema, generated files, dependencies и Backup не менялись.
- Tests не запускались: factual findings подтверждены accepted ADR,
  completed plans, production code и existing test contracts; run docs-only.
