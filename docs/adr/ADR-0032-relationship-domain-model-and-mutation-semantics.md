# ADR-0032: Relationship Domain Model and Mutation Semantics

**Статус:** Принято
**Дата:** 2026-09-12

## Контекст

LifeOS теперь имеет как минимум два production Entity type:

- Task;
- Note.

Task и Note используют общий `LifeOsEntity` contract и имеют:

- стабильный UUID;
- `entityType`;
- `createdAt`;
- `updatedAt`;
- lifecycle;
- version;
- source.

Persistence использует hybrid model:

```
entities
+
typed tables
```

Локальные изменения syncable Entity атомарно сохраняют:

```
Entity state
+
typed state
+
Outbox Change
```

До появления второго типа Entity отдельная модель Relationships не была необходима.

После появления Tasks и Notes становятся практически значимыми связи:

```
Task ↔ Task
Task ↔ Note
Note ↔ Note
```

До реализации необходимо определить:

- является ли Relationship Entity;
- identity;
- направленность;
- тип связи;
- duplicate semantics;
- self-links;
- versioning;
- timestamps;
- lifecycle;
- mutation semantics;
- допустимые endpoint types;
- связь с Outbox и будущим Sync.

---

# Решение

## 1. Relationship является отдельной LifeOS Entity

`LifeOsRelationship` является typed `LifeOsEntity`.

Она имеет собственный стабильный Entity ID и общий metadata contract.

Концептуально:

```
LifeOsRelationship
├── id
├── type = relationship
├── createdAt
├── updatedAt
├── lifecycle
├── version
├── source
│
├── firstEntityId
├── secondEntityId
└── kind
```

Relationship является Entity **не потому, что она аналогична Task или Note в UX**, а потому что она является самостоятельным persistent user state, которое должно иметь:

- стабильную identity;
- version;
- timestamps;
- lifecycle;
- Backup representation;
- atomic Outbox semantics;
- возможность будущей Sync reconciliation.

Таким образом:

> Relationship — first-class persisted Entity, семантически представляющая edge между двумя другими Entity.

---

## 2. Отдельного Relationship ID вне Entity ID нет

Используется только:

```
LifeOsRelationship.id
```

Никакой дополнительный:

```
relationshipId
edgeId
linkId
```

не вводится.

При пользовательском создании используется тот же UUID v4 identity boundary, что и для других LifeOS Entity.

---

## 3. Relationship v1 является ненаправленной

В первой версии связь не имеет source/target semantics.

Связь:

```
A ↔ B
```

эквивалентна:

```
B ↔ A
```

То есть:

```
Task A ↔ Note B
```

— одна и та же Relationship независимо от того, с какой стороны пользователь её открыл.

Не вводятся понятия:

```
parent → child
blocks → blockedBy
dependsOn → dependencyOf
contains → containedBy
```

Направленные отношения требуют отдельного будущего Domain decision.

---

## 4. Endpoint naming не должно подразумевать направление

Domain API не должен использовать:

```
sourceEntityId
targetEntityId
```

поскольку это создаёт ложную directed semantics.

Предпочтительные имена:

```
firstEntityId
secondEntityId
```

или эквивалентные нейтральные названия.

Порядок полей является техническим представлением и не определяет смысл связи.

---

# 5. Relationship kind

Relationship v1 имеет typed property:

```
kind
```

В первой версии поддерживается только:

```
related
```

Например концептуально:

```
enum LifeOsRelationshipKind {
  related,
}
```

Наличие `kind` сейчас принимается намеренно, несмотря на единственное значение.

Причина — значение связи является частью Domain state, и его лучше сделать явным, чем неявно кодировать самим фактом существования строки.

Это также позволяет в будущем отдельно рассматривать:

```
blocks
dependsOn
references
partOf
...
```

без изменения identity model Relationship.

Однако добавление новых видов отношений **не считается автоматически разрешённым** этим ADR.

Каждый новый semantic relationship kind требует отдельной проверки Domain semantics.

---

# 6. Допустимые endpoint Entity types в v1

Relationship v1 поддерживает связи:

```
Task ↔ Task
Task ↔ Note
Note ↔ Note
```

Порядок не имеет значения.

Например:

```
Task ↔ Note
```

эквивалентно:

```
Note ↔ Task
```

Relationship v1 не вводит generic правило:

> любая будущая Entity автоматически может быть endpoint.

Поддержка нового Entity type должна быть сознательно проверена при его появлении.

---

# 7. Endpoint должен существовать

Нельзя создать Relationship с Entity ID, которого нет в persistent LifeOS state.

Например:

```
Relationship
A ↔ missing UUID
```

недопустима.

Existence check относится к Application/Infrastructure orchestration, поскольку сама Domain Relationship не имеет repository access.

Domain отвечает за локальные invariants ID.

Repository/Application отвечает за referential existence.

---

# 8. Self-relationship запрещена

Relationship:

```
A ↔ A
```

не имеет поддерживаемого смысла в Relationship v1.

Поэтому:

```
firstEntityId == secondEntityId
```

является Domain validation error.

Это проверяется непосредственно Domain model.

---

# 9. Duplicate Relationship запрещена

Для `kind = related` между одной и той же unordered pair Entity может существовать только одна active Relationship.

То есть:

```
A ↔ B
```

и:

```
B ↔ A
```

являются duplicate.

Также:

```
relationship-1:
A ↔ B
kind=related

relationship-2:
A ↔ B
kind=related
```

недопустимы одновременно как active Relationships.

Uniqueness определяется логически как:

```
unordered(endpoint A, endpoint B) + kind
```

а не Relationship ID.

---

# 10. Canonical endpoint ordering

Для обеспечения deterministic persistence и uniqueness пара endpoints должна иметь canonical ordering.

Domain representation нормализует:

```
firstEntityId
secondEntityId
```

в стабильный порядок.

Для UUID/string IDs используется deterministic lexical ordering существующего canonical string representation.

То есть независимо от входа:

```
create(A, B)
create(B, A)
```

результат имеет одинаковый canonical endpoint order.

Это техническая нормализация, а не directed semantics.

---

# 11. Creation semantics

Пользовательская Relationship создаётся со следующими defaults:

```
id = UUID v4 through identity boundary
entityType = relationship

createdAt = supplied UTC timestamp
updatedAt = createdAt

lifecycle = active
version = 1
source = user

kind = related

firstEntityId / secondEntityId =
canonicalized endpoint pair
```

Domain не читает system clock напрямую.

Timestamp предоставляется Application boundary.

---

# 12. Relationship не имеет title/content

Relationship v1 не имеет:

```
title
description
content
notes
label
displayName
```

Пользовательский UI может отображать Relationship через связанные Entity.

Например:

```
Related
• Task: Buy tickets
• Note: Vacation plan
```

Не следует дублировать названия endpoint Entity внутри Relationship state.

---

# 13. Relationship не хранит cached endpoint metadata

Relationship не хранит копии:

```
Task.title
Note.title
entity display name
endpoint entity type display text
```

Её persisted state содержит только стабильные endpoint IDs и Relationship-specific semantics.

UI получает актуальные Entity через соответствующие read models/use cases.

Это предотвращает денормализованный stale state.

---

# 14. Relationship modification в v1 отсутствует

После создания Relationship v1 не имеет редактируемого payload.

Поскольку единственный `kind` — `related`, изменение:

```
endpoint A
endpoint B
kind
```

не считается edit существующей Relationship.

Изменение endpoints концептуально означает:

```
remove old Relationship
+
create new Relationship
```

Поэтому generic:

```
editRelationship(...)
```

в v1 не вводится.

---

# 15. Removal semantics

Relationship должна быть удаляемой пользователем.

Однако physical hard-delete без change representation плохо совместим с существующей Outbox архитектурой.

Поэтому unlink является **Domain mutation Relationship**, а не прямым SQL delete из Presentation/Application.

Для Relationship v1 removal использует common lifecycle semantics.

Relationship переводится из active состояния в неактивное terminal/removal состояние, поддерживаемое общим Entity lifecycle contract.

При removal:

```
version = previousVersion + 1
updatedAt = supplied UTC timestamp
```

и сохраняется обычным atomic persistence path:

```
Entity lifecycle mutation
+
Relationship typed state
+
Outbox UPDATE/change representation
```

### Важное ограничение

ADR-0032 **не должен изобретать новое lifecycle enum value**, если его ещё нет в принятом common Entity contract.

RL-02 обязан проверить фактический `LifeOsEntityLifecycle`.

Если существующий lifecycle не имеет подходящего принятого состояния для unlink, возникает новый architecture gate.

В этом случае нельзя молча:

- hard-delete Relationship;
- придумывать `deleted`;
- использовать `archived` с новым смыслом;
- вводить DELETE Outbox operation.

Это является **stop condition перед persistence implementation**.

---

# 16. No-op removal

Попытка повторно удалить уже неактивную Relationship не создаёт новую mutation.

Не должны изменяться:

```
version
updatedAt
Outbox
```

---

# 17. Timestamp semantics

Все Relationship timestamps являются UTC.

Для material mutation:

```
newUpdatedAt >= previousUpdatedAt
```

Если supplied timestamp раньше текущего `updatedAt`, mutation отклоняется.

Domain не получает system clock самостоятельно.

---

# 18. Version semantics

Creation:

```
version = 1
```

Каждая material mutation:

```
version += 1
```

No-op:

```
version unchanged
```

Relationship version является версией самой Relationship Entity.

Изменение Task или Note endpoint не увеличивает Relationship version автоматически.

---

# 19. Endpoint Entity edits не мутируют Relationship

Например:

```
Note title:
"A" → "B"
```

не является mutation Relationship.

Relationship по-прежнему ссылается на тот же stable Entity ID.

Следовательно:

```
Relationship.version
Relationship.updatedAt
```

не меняются.

---

# 20. Endpoint lifecycle changes

Relationship identity не должна автоматически удаляться только потому, что endpoint Entity изменила lifecycle.

Автоматические cascading Domain mutations запрещены без отдельного решения.

Если в будущем Task/Note получат archive/delete:

- поведение связанных Relationships;
- visibility;
- cleanup;
- cascade policy;

должно быть определено отдельно.

RL v1 не вводит эту семантику заранее.

---

# 21. Repository boundary

Relationship получает отдельный typed repository:

```
LifeOsRelationshipRepository
```

Не вводится generic:

```
EntityRepository
GraphRepository
EdgeRepository
```

Минимальный conceptual API:

```
getById(...)
getForEntity(...)
save(...)
```

Точный signature определяется RL-02 на основе существующих repository conventions.

Если lifecycle-based unlink поддерживается существующим Entity contract, `save()` остаётся mutation boundary.

Отдельный Infrastructure `delete()` не должен вводиться без принятого hard-delete semantics.

---

# 22. getForEntity semantics

Основной read use case:

```
getForEntity(entityId)
```

возвращает Relationships, где Entity находится с любой стороны.

То есть запрос логически:

```
firstEntityId == entityId
OR
secondEntityId == entityId
```

Для active UI по умолчанию возвращаются active Relationships.

Deterministic ordering должен быть определён в RL-02.

Рекомендуемый порядок:

```
updatedAt DESC
id ASC
```

по аналогии с другими read paths.

---

# 23. Outbox semantics

Relationship является syncable Entity state и участвует в существующем Outbox contract.

При normal local creation:

```
Relationship state
+
Outbox CREATE
```

создаются атомарно.

Для material lifecycle mutation:

```
Relationship state
+
Outbox UPDATE
```

создаются атомарно, если именно такая semantics поддерживается принятым общим lifecycle contract.

Outbox payload содержит full Relationship entity snapshot согласно ADR-0023.

Не вводится отдельный Relationship change log.

---

# 24. Outbox payload

Conceptual full snapshot содержит как минимум:

```
id
entityType
createdAt
updatedAt
lifecycle
version
source

firstEntityId
secondEntityId
kind
```

Точные JSON field names должны следовать существующим serialization conventions.

Outbox `schema_version` не следует автоматически путать с:

- SQLite schemaVersion;
- Backup formatVersion.

---

# 25. Atomicity

Любая normal local Relationship mutation должна сохраняться атомарно.

Creation:

```
Entity
+
Relationship typed row
+
Outbox
```

либо сохраняются все, либо ничего.

То же правило применяется к поддерживаемым lifecycle mutations.

---

# 26. Backup / Export

Relationship является production user state и должна участвовать в Backup/Export до того, как milestone может считаться release-ready.

Representation должна сохранять:

- Relationship Entity metadata;
- endpoint IDs;
- kind.

Backup Restore должен проверять, что оба endpoint IDs существуют в восстанавливаемом dataset.

Dangling Relationship делает Backup invalid.

---

# 27. Restore не является user Relationship mutation

Как и для Tasks/Notes:

Restore:

- не использует normal save path;
- не создаёт Outbox;
- восстанавливает version/metadata как сохранены;
- валидирует Relationships до mutation;
- выполняется атомарно.

---

# 28. Search

Relationship v1 сама по себе не расширяет текущий Search contract.

Не вводятся автоматически:

```
graph search
relationship search
unified Entity search
FTS
semantic traversal
```

Relationship picker может использовать существующие Task/Note read APIs либо минимальные специализированные Application queries.

Если usable picker требует generic unified Search architecture — это отдельный architecture gate.

---

# 29. Presentation model

Relationships не получают отдельный top-level NavigationRail destination в v1.

Они представлены в контексте Entity.

Минимальный UX:

```
Task / Note
──────────────
Related
• ...
• ...

[Add relationship]
```

Relationship picker позволяет выбрать существующий поддерживаемый endpoint.

Самостоятельный:

```
Relationships page
Graph page
Knowledge graph
```

не входит в v1.

---

# 30. Не входит в Relationship v1

Явно вне scope:

- directed relationships;
- hierarchy;
- parent/child;
- dependencies;
- blockers;
- relationship weights;
- relationship labels;
- relationship descriptions;
- multiple semantic kinds beyond `related`;
- custom user-defined relationship types;
- graph traversal API;
- graph visualization;
- backlinks engine;
- transitive relations;
- inferred relations;
- AI-generated relations;
- semantic/embedding relations;
- automatic relationship creation;
- relationship suggestions;
- generic GraphRepository;
- unified Search;
- cascade deletion semantics;
- Sync conflict resolution UI.

---

# Consequences

## Положительные

Relationship использует уже существующую architecture:

```
LifeOsEntity
→ typed persistence
→ Outbox
→ Backup
```

Не возникает второго параллельного identity/versioning mechanism.

Stable Relationship ID позволит в будущем:

- Sync;
- conflict handling;
- change tracking;
- references на саму связь при необходимости.

Undirected `related` semantics минимальны и не пытаются преждевременно создать ontology.

Canonical endpoint ordering делает duplicate detection deterministic.

---

## Отрицательные

Для простой связи создаётся полноценная Entity metadata запись.

То есть physical representation будет тяжелее, чем минимальная join table:

```
(a_id, b_id)
```

Но эта стоимость принимается ради:

- stable identity;
- versioning;
- Outbox;
- Backup;
- future Sync consistency.

Также removal обнаруживает зависимость от существующего common lifecycle contract.

Если текущая lifecycle модель не может корректно выразить unlink, потребуется дополнительный architecture decision до RL-04.

---

# Alternatives considered

## A. Relationship как простая join table без Entity identity

Например:

```
relationships(
  first_id,
  second_id
)
```

Не принято.

Хотя это проще SQLite-физически, возникает отдельный путь для:

- change identity;
- versioning;
- Outbox;
- Backup;
- будущего Sync.

---

## B. Relationship как directed edge

Не принято для v1.

Для generic `related` направление не имеет Domain смысла и создаёт ненужную семантику.

---

## C. Relationship type отсутствует

Не принято.

Явный `kind=related` делает Domain contract понятнее и позволяет не кодировать semantic type отсутствием поля.

---

## D. Несколько relationship kinds сразу

Не принято.

LifeOS пока не имеет достаточных product requirements для определения:

```
blocks
dependsOn
contains
references
...
```

Их преждевременное введение создало бы ontology без подтверждённого UX.

---

# Связанные ADR

ADR-0032 дополняет:

- ADR-0016 — common Domain Entity contract;
- ADR-0023 — Entity persistence + Outbox;
- ADR-0025 — production UUID/device identity;
- ADR-0029 — SQLite/Drift Schema Migration Strategy;
- ADR-0030 — Note Domain Model;
- ADR-0031 — Backup/Export versioning.
