# ADR-0034: Workspace and Context Architecture

**Статус:** Принято

**Дата:** 2026-09-19

**Версия:** 0.1

## 1. Контекст

Текущая production-версия LifeOS поддерживает Task, Note и ненаправленную
Relationship типа `related`. Все эти объекты используют общий Entity contract,
local-first persistence, versioned Outbox и logical Backup/Restore.

При этом долгосрочная концепция LifeOS организует пользовательские данные вокруг
жизненного контекста, а не только вокруг типов данных. Пользователь работает не
просто с Task или Note, а с такими областями, как работа, ремонт квартиры,
путешествие или развитие продукта.

До настоящего ADR Workspace не имел принятой Domain-семантики. Не были определены:

- identity и минимальное состояние Workspace;
- отличие Workspace от runtime Context;
- способ принадлежности Entity к Workspace;
- cardinality и допустимость Entity без Workspace;
- lifecycle Workspace и membership;
- граница structural membership и semantic Relationship;
- направление persistence, migration, Outbox и Backup evolution;
- требования, необходимые будущим Search и AI context.

Решение основано на отдельном read-only Workspace & Context Architecture
Investigation и конкретизирует общие принципы существующих ADR, не реализуя
Workspace в этом документе.

## 2. Решение

LifeOS принимает гибридную Workspace-модель:

- `LifeOsWorkspace` является полноценной typed `LifeOsEntity`;
- принадлежность Entity к Workspace представляется отдельной structural Entity
  `LifeOsWorkspaceMembership`;
- membership не является ownership и не кодируется через
  `LifeOsRelationship`;
- одна поддерживаемая Entity может принадлежать нулю, одному или нескольким
  Workspace;
- Workspace и persisted membership являются Domain state, а Context является
  вычисляемой Application-level projection.

## 3. Workspace identity и состояние

`LifeOsWorkspace` использует общий Entity contract:

- typed Entity identity;
- Entity type `workspace`;
- UTC `createdAt` и `updatedAt`;
- lifecycle;
- version;
- source;
- atomic persistence и Outbox semantics;
- Backup/Restore semantics.

Минимальное Workspace-specific state v1:

```text
title: String
description: String?
```

`title` сохраняется после `trim()` и не может быть пустым. `description`
является optional plain text. Workspace v1 не вводит Domain-поля для icon,
color, layout configuration, favorites, pinning, permissions или collaboration
settings.

Workspace не имеет отдельного ID помимо typed Entity ID:

```text
Workspace identity == Entity identity
```

Creation использует принятые ADR-0026 defaults: UUID v4 через существующую
identity boundary, одну предоставленную извне UTC timestamp,
`createdAt == updatedAt`, lifecycle `active`, version `1`, source `user` для
обычного пользовательского создания.

## 4. Workspace и Context

Workspace и Context являются разными понятиями.

Workspace — долговременная пользовательская Entity, представляющая область или
контекст жизни.

Context — runtime/Application-level projection, которая в зависимости от use
case может включать:

- текущий Workspace и его metadata;
- Workspace memberships;
- member Entities;
- semantic Relationships;
- Search results;
- lifecycle visibility;
- текущее намерение пользователя.

Context не является persisted Entity в Workspace v1. Настоящий ADR не вводит
`Context` table, persistent Context model или Context repository.

## 5. Workspace membership

`LifeOsWorkspaceMembership` является отдельной typed `LifeOsEntity` и содержит:

- собственную typed Entity identity;
- `workspaceId`;
- `memberEntityId`;
- общий Entity metadata contract.

Membership является structural graph edge. Она отделена от semantic
`LifeOsRelationship` и не означает владение member Entity.

Workspace v1 поддерживает member Entity types:

- Task;
- Note.

Добавление будущих Entity types требует отдельного architecture gate.

Membership не представляется:

- полем `workspaceId` внутри member Entity;
- kind текущей `LifeOsRelationship`;
- container ownership relation.

## 6. Cardinality и Unassigned

Для поддерживаемой Entity принимается cardinality:

```text
Entity -> zero-to-many Workspaces
```

Task или Note может:

- не принадлежать ни одному Workspace;
- принадлежать одному Workspace;
- принадлежать нескольким Workspace.

Unassigned Entity является валидным Domain state. LifeOS не создаёт
автоматически `Personal`, `Inbox` или иной default Workspace.

`Unassigned` является вычисляемым UI/Application representation, а не persisted
Workspace.

При migration существующие Tasks и Notes сохраняются без Domain mutation,
получают zero memberships и не порождают migration Outbox records.

## 7. Workspace lifecycle

Workspace использует общий lifecycle:

```text
active
archived
deleted
```

Для Workspace концептуально поддерживаются:

- create;
- rename/edit;
- archive;
- unarchive;
- soft delete;
- restore.

Workspace lifecycle никогда автоматически не изменяет lifecycle:

- Task;
- Note;
- future member Entity;
- semantic Relationship.

Lifecycle cascade запрещён. Membership records сохраняются при archive или
soft delete Workspace.

Inactive Workspace исключается из ordinary context navigation,
Workspace-scoped Search и будущего AI context. После restore существующие
memberships снова становятся доступны. Hard delete и purge находятся вне scope.

## 8. Membership lifecycle

Membership является versioned Entity.

- Первый attach создаёт membership через `CREATE` mutation.
- Remove выполняется как soft lifecycle transition, а не physical delete.
- Reattach той же пары восстанавливает существующую membership identity, а не
  создаёт duplicate membership.
- Material lifecycle mutation увеличивает version, обновляет timestamp и
  создаёт Outbox `UPDATE`.
- No-op не меняет state и не создаёт Outbox.

Пара:

```text
workspaceId + memberEntityId
```

логически уникальна, включая inactive membership. Это сохраняет стабильную
identity при remove и последующем reattach.

Domain state membership, typed persistence row и соответствующая Outbox mutation
должны сохраняться атомарно по существующей ADR-0023 модели.

## 9. Взаимодействие с Relationship

`LifeOsRelationship` остаётся отдельным semantic edge. Workspace v1 не меняет
её базовую модель:

- Relationship остаётся ненаправленной;
- текущий kind остаётся `related`;
- текущая semantic purpose сохраняется.

Membership не кодируется через `related`. Workspace v1 не добавляет kinds:

- `contains`;
- `belongsTo`;
- `partOf`;
- `dependsOn`;
- `assignedTo`;
- `about`.

Workspace как semantic Relationship endpoint и directed Relationships отложены
до Knowledge Graph Foundation #2.

## 10. Knowledge graph semantics

На концептуальном уровне LifeOS различает:

```text
Nodes:
  Workspace, Task, Note, future Entity types

Structural edges:
  WorkspaceMembership

Semantic edges:
  LifeOsRelationship
```

SQLite/Drift остаётся persistence foundation. Graph является логической моделью,
а не требованием graph database.

Настоящий ADR не определяет traversal depth, ranking, transitive context, graph
visualization или directed semantic edges.

## 11. Workspace hierarchy

Workspace hierarchy не входит в Workspace v1.

Не вводятся:

- `parentWorkspaceId`;
- Workspace membership внутри Workspace;
- inherited context;
- lifecycle propagation;
- recursive hierarchy.

Hierarchy требует отдельного architecture gate с правилами циклов, наследования,
visibility и lifecycle.

## 12. Persistence direction и schema v4

Workspace introduction требует SQLite/Drift schema version 4.

Ожидаемые новые typed structures:

```text
workspaces
workspace_memberships
```

Существующие `entities`, `tasks`, `notes`, `relationships` и `outbox`
сохраняются. Таблица `relationships` не изменяется только ради Workspace.

Persistence должна обеспечивать:

- Workspace typed row, связанный с Workspace Entity;
- Membership typed row, связанный с Membership Entity;
- ссылку `workspaceId` на существующую Workspace Entity;
- ссылку `memberEntityId` на существующую поддерживаемую Entity;
- logical uniqueness `workspaceId + memberEntityId`;
- отсутствие lifecycle cascade.

Точные SQL definitions, indexes и bounded integrity checks определяются schema
migration checkpoint, если они не меняют semantics настоящего ADR.

## 13. Migration v3 -> v4

Migration должна следовать ADR-0029 и:

- создать Workspace persistence structures;
- сохранить Tasks, Notes, Relationships и Outbox;
- не создавать Workspace или membership автоматически;
- не создавать Outbox из технической migration;
- оставить существующие Tasks и Notes unassigned;
- выполняться атомарно;
- поддерживать rollback при failure;
- иметь frozen schema snapshot, fresh-schema tests и migration tests.

Database schema version, Backup format version, Entity version и Outbox payload
schema version остаются независимыми понятиями.

## 14. Outbox и future Sync

Normal local Workspace mutations используют:

```text
CREATE  для создания Workspace
UPDATE  для edit и lifecycle mutations
```

Membership mutations используют:

```text
CREATE  для первого attach
UPDATE  для remove и reattach
```

Используется существующая full-resulting-snapshot philosophy. Domain state и
Outbox Change записываются в одной persistence transaction. No-op не создаёт
Outbox.

Workspace и Membership становятся самостоятельными syncable records. Future
Sync должен учитывать dependency ordering: Workspace и member Entity должны быть
доступны до применения membership. Backend transport, delivery protocol и
conflict resolution этим ADR не определяются.

## 15. Backup, Export и Restore

Workspace introduction требует Backup/Export format v4.

Format v4 должен сохранять:

- Tasks;
- Notes;
- Relationships;
- Workspaces;
- Workspace memberships;
- common Entity metadata;
- lifecycle, version и source.

Current application после реализации v4 должна продолжать читать и
восстанавливать поддерживаемые Backup v1, v2 и v3, а новые Backup/Export создавать
как v4.

Restore должен:

- полностью декодировать и валидировать format до mutation;
- проверить reference integrity и logical uniqueness;
- выполнять replace-style mutation атомарно;
- сохранять installation `device_id`;
- очищать active Outbox согласно существующему contract;
- не создавать новые Outbox Changes.

Точный FK-safe ordering определяется implementation checkpoint. Unsupported
future versions отклоняются до mutation.

## 16. Search implications

Workspace architecture должна позволять будущие:

- Global Search;
- Workspace-scoped Search.

Начальная Workspace scope semantics включает active direct members.

Автоматически не включаются:

- graph traversal;
- related neighbors;
- fuzzy Search;
- semantic или vector Search.

Unified Local Search остаётся отдельным milestone. Current Task Search этим ADR
не изменяется.

## 17. AI context implications

AI не должен напрямую получать arbitrary database dump или обращаться к
persistence implementation.

Будущий Application-level Context Assembler должен иметь возможность построить
bounded context из:

- current Workspace;
- Workspace metadata;
- active direct members;
- selected semantic Relationships;
- relevant Search results;
- lifecycle и privacy filters.

AI provider, model, dependency, token-ranking policy и Context Assembler
implementation настоящим ADR не определяются.

## 18. UX и navigation direction

LifeOS постепенно переходит от type-centric UX к context-centric UX.

Целевое направление:

```text
Home
  -> Workspaces, Unassigned и contextual entry points

Workspace
  -> mixed Tasks, Notes и membership actions

Tasks / Notes
  -> secondary global views

Search / Settings
  -> global destinations
```

Настоящий ADR не фиксирует exact layout и не требует нового routing package.
Navigation implementation остаётся отдельным checkpoint.

## 19. Quick-create transaction boundary

Атомарность compound workflow:

```text
Create Entity + attach Entity to Workspace
```

не определяется молча этим ADR.

Поскольку unassigned Entity является валидной, failure membership после
успешного Entity creation не нарушает Domain integrity. Однако UX может требовать
all-or-nothing semantics.

Перед реализацией Workspace quick create execution plan должен пройти отдельный
implementation architecture gate и явно определить transaction boundary.
Отдельный ADR не обязателен, если решение не меняет общие архитектурные принципы.

## 20. Security и privacy

Workspace membership сама по себе не является permission boundary. Workspace v1
не вводит ACL или authorization semantics.

Workspace metadata и member content рассматриваются как sensitive user data по
существующим правилам. Future AI context должен учитывать user-controlled scope
и privacy, но exact policy определяется AI Foundation milestone.

## 21. Non-goals

- Workspace hierarchy.
- Graph visualization.
- Directed Relationships.
- Новые semantic Relationship kinds.
- Workspace semantic Relationship endpoints.
- Unified Search implementation.
- Semantic или vector Search.
- AI provider, model или AI implementation.
- Context Engine persistence.
- Sync backend и conflict protocol.
- Collaboration.
- Permissions и ACL.
- Document, Person или Event Entity.
- Hard delete и purge.
- Icon, color, layout configuration и pinning.
- System Tray.
- Spellcheck.
- Notifications и reminders.
- Notification-driven Task time fields.

## 22. Последствия

### Положительные

- LifeOS получает первый context-centric Domain primitive.
- Workspace не становится owner или container пользовательских Entity.
- Entity может участвовать в нескольких жизненных контекстах.
- Structural membership не смешивается с semantic Relationship.
- Existing data мигрируют без synthetic context и Domain mutation.
- Search, AI и future Sync получают устойчивую foundation.
- Runtime Context можно развивать независимо от persistence model.

### Costs и ограничения

- Появляются две новые Entity models.
- Требуются schema v4 и migration v3 -> v4.
- Требуется Backup/Export format v4.
- Нужны membership repository и Application use cases.
- Membership создаёт дополнительные Outbox records.
- Queries и validation reference integrity становятся сложнее.
- Workspace UI должен работать с mixed Entity types.
- Future Sync должен учитывать dependency ordering.
- Quick-create transaction boundary требует отдельного implementation gate.

## 23. Отклонённые альтернативы

### Separate Workspace aggregate

Отклонено, поскольку создаёт вторую систему identity, lifecycle, versioning,
Outbox и Backup вне существующего Entity contract.

### Graph-only Workspace

Отклонено, поскольку не предоставляет устойчивой пользовательской Entity для
title, description, lifecycle и navigation.

### `workspaceId` на member Entity

Отклонено, поскольку вводит single-owner semantics, не поддерживает
zero-to-many membership и связывает Entity state с одним контекстом.

### Exactly-one или zero-or-one Workspace

Отклонено, поскольку одна Entity может быть релевантна нескольким жизненным
контекстам.

### Membership через `LifeOsRelationship.related`

Отклонено, поскольку смешивает structural и semantic edges и не соответствует
ненаправленной семантике `related`.

### Automatic Personal или Inbox migration

Отклонено, поскольку создаёт synthetic пользовательский контекст и неожиданные
данные. Existing Entity остаются unassigned.

### Lifecycle cascade

Отклонено, поскольку Workspace не владеет member Entity. Изменение контекста не
является mutation содержимого или lifecycle members.

### Hierarchy в Workspace v1

Отклонено как преждевременное расширение, требующее правил циклов, наследования,
visibility и lifecycle propagation.

## 24. Соответствие существующим ADR

ADR-0034:

- конкретизирует Entity, Context и graph principles preliminary ADR-0016;
- применяет atomic Domain State + Outbox pattern ADR-0023;
- применяет creation identity, UTC clock и defaults ADR-0026;
- сохраняет logical Backup/Restore boundary ADR-0028;
- требует последовательную atomic schema migration по ADR-0029;
- не изменяет Note content и mutation semantics ADR-0030;
- продолжает versioned Backup compatibility policy ADR-0031;
- отделяет membership от semantic Relationship ADR-0032;
- применяет no-cascade lifecycle philosophy ADR-0033.

Если preliminary ADR-0016 описывает generic directed или typed Relationships
шире текущей production-модели, для Workspace v1 применяется более конкретное
решение настоящего ADR: structural membership отделена от остающейся
ненаправленной `related` Relationship.

## 25. Приоритет

ADR-0034 является источником истины для Workspace identity, membership,
cardinality, Unassigned, lifecycle interaction, Context boundary и направления
schema/Backup evolution.

Implementation details должны определяться будущим execution plan Workspace
Vertical Slice в пределах настоящего решения. Изменение зафиксированной
семантики требует нового architecture gate и ADR amendment либо нового ADR.
