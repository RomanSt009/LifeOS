# ADR-0030: Domain-модель Note и семантика мутаций

**Статус:** Принято

**Дата:** 2026-09-11

**Версия:** 0.1

## 1. Контекст

LifeOS рассматривает Note как один из основных типов Entity, но существующие ADR пока не фиксируют минимальный устойчивый Domain contract первой production-версии Note.

Перед проектированием persistence table, schema v2, migration `v1 -> v2`, repository implementation, Backup extension и Presentation необходимо определить:

- identity и общие metadata Note;
- минимальное Note-specific state;
- допустимое пустое состояние;
- normalization и content semantics;
- creation и edit semantics;
- границы lifecycle, Search и Backup;
- функции, которые намеренно не входят в Note v1.

Решение должно сохранить Domain независимым от editor formats, Flutter, Drift, SQLite, filesystem и внешних сервисов и не создавать преждевременный knowledge-management stack.

## 2. Решение

### 2.1. Note как typed Entity

Note является самостоятельной typed LifeOS Entity.

Note использует общий `LifeOsEntity` contract:

- `LifeOsEntityId`;
- `entityType = note`;
- `createdAt`;
- `updatedAt`;
- `lifecycle`;
- `version`;
- `source`.

Note-specific state не дублирует эти общие поля.

### 2.2. Identity

Note не имеет отдельного Note ID.

Identity Note совпадает с identity Entity:

```text
Note identity == Entity identity
```

Типизированный `LifeOsEntityId` использует Entity type `note`. Изменение содержимого Note не меняет её ID.

### 2.3. Минимальное Note-specific state v1

Note v1 содержит только:

```text
title: String
content: String
```

Дополнительные knowledge-management, editor и organization fields не входят в начальный contract.

### 2.4. Content semantics

На уровне Domain `content` является opaque plain `String`.

Domain не интерпретирует:

- Markdown;
- HTML;
- rich text;
- WYSIWYG;
- editor document formats.

Domain хранит текстовое значение, но не связывает его смысл или структуру с конкретным editor либо serialization format.

### 2.5. Empty-state invariant

Note v1 допускает:

- пустой `title`, если `content` содержит значимый текст;
- пустой `content`, если `title` содержит значимый текст.

`title` и `content` не могут быть одновременно semantically empty.

Для проверки этого invariant semantic emptiness обоих значений определяется через `trim()`. Полностью пустая persisted Note в Note v1 не поддерживается.

Если в будущем потребуется empty autosave draft, это будет отдельным изменением Domain/UX semantics и потребует отдельного architecture gate.

### 2.6. Normalization

- `title` сохраняется после `trim()`;
- `content` сохраняется буквально;
- Domain не применяет `trim()` к `content`;
- whitespace внутри `content` не схлопывается;
- line endings автоматически не нормализуются;
- maximum length для `title` или `content` сейчас не вводится.

Произвольные ограничения длины не являются частью Domain без подтверждённого product или technical requirement.

### 2.7. User creation defaults

ADR-0030 распространяет доказанные creation conventions ADR-0026 на Note, непосредственно созданную пользователем:

- UUID v4 создаётся через существующую identity boundary;
- создаётся типизированный Entity ID с `type = note`;
- используется одна предоставленная извне UTC timestamp;
- `createdAt == updatedAt`;
- `lifecycle = active`;
- `version = 1`;
- `source = user`.

Domain не генерирует UUID и не читает системное время.

### 2.8. Creation responsibility и persistence

Создание Note является Domain/Application operation.

Application координирует получение identity, времени и пользовательского ввода. Domain проверяет invariants и создаёт валидную Note. Успешно созданная Note впоследствии сохраняется через typed Note repository.

Normal local persisted creation должна участвовать в существующем atomic Domain State + Outbox `CREATE` pattern ADR-0023. Persisted Note и соответствующий Outbox Change должны фиксироваться атомарно.

Migration и Restore не являются normal user mutations и не создают такой `CREATE` автоматически.

### 2.9. Update model

Note v1 использует единую immutable atomic edit mutation для `title` и `content`.

Концептуальная форма:

```text
edit(
  title,
  content,
  updatedAt
)
```

Передача обоих полей одной операции позволяет проверять общий empty-state invariant и сохранять согласованное состояние атомарно.

### 2.10. Material edit

Material edit:

- применяет normalization `title`;
- сохраняет `content` буквально;
- проверяет empty-state invariant;
- увеличивает `version` на `1`;
- устанавливает `updatedAt` равным предоставленной UTC timestamp;
- сохраняет `id`, `createdAt`, `lifecycle` и `source`;
- отклоняет `updatedAt`, который раньше предыдущего `updatedAt`.

Результатом является новая immutable Note value. Исходный экземпляр не изменяется.

Normal local persisted material edit должен следовать atomic Domain State + Outbox update pattern ADR-0023.

### 2.11. No-op edit

Edit является no-op, если normalized `title` и exact `content` совпадают с текущим состоянием.

При no-op:

- Entity state не изменяется;
- `version` не увеличивается;
- `updatedAt` не меняется;
- persistence save не требуется;
- Outbox Change не создаётся.

### 2.12. Clock boundary

Domain не читает системное время самостоятельно.

UTC timestamp для creation и edit предоставляется извне через существующую Application/composition clock boundary. Это сохраняет Domain детерминированным и тестируемым.

### 2.13. Lifecycle

Note использует общий `LifeOsEntityLifecycle`.

Note v1 не добавляет:

- archive use case;
- delete use case;
- restore use case;
- `DELETE` Outbox semantics.

Эти операции отложены до отдельного lifecycle gate. Настоящий ADR не вводит Note-specific archive/delete system.

### 2.14. Repository boundary

Будущий `LifeOsNoteRepository` является отдельным typed Domain repository.

Минимально ожидаемые операции первой vertical slice:

- `getAll()`;
- `getById()`;
- `save()`.

Настоящий ADR не вводит:

- generic `EntityRepository`;
- search method;
- Relationships API;
- archive/delete API.

Появление второго Entity type само по себе не является достаточной причиной для generic repository abstraction.

### 2.15. Search impact

Note концептуально является searchable Entity. Естественные searchable data:

- `title`;
- `content`.

Текущий Task Search этим ADR не обобщается. Note Search и Unified Search требуют отдельного будущего architecture gate после появления production Note persistence.

Первая Note vertical slice может быть реализована без интеграции в текущий Search.

### 2.16. Backup и Export impact

Production Note является пользовательским Domain state и в итоге должна участвовать в Backup и human-readable Export.

Для Note должны сохраняться:

- Entity identity и type;
- общие Entity metadata;
- `title`;
- `content`.

ADR-0030 не решает, следует ли backward-compatible расширить Backup format v1 или ввести Backup format v2. Это отдельный compatibility gate, который должен быть пройден до завершения production Note milestone.

Database schema migration и Backup format evolution остаются разными механизмами согласно ADR-0028 и ADR-0029.

### 2.17. Security и privacy

Note content считается потенциально sensitive user data.

- Note content не должен логироваться без явной необходимости;
- content не должен автоматически отправляться внешним сервисам;
- basic local Note functionality не должна требовать сети.

Encryption остаётся Infrastructure/storage concern и не является blocker для local Note v1 согласно текущим ADR. Конкретная encryption architecture этим ADR не определяется.

## 3. Explicit non-goals Note v1

Следующее не входит в Note v1 и требует будущего gate при появлении подтверждённого use case:

- Markdown semantics;
- rich text;
- WYSIWYG;
- tags;
- folders и notebooks;
- attachments, files и images;
- backlinks;
- Relationships;
- Projects и Workspace membership;
- templates;
- checklists;
- embedded Tasks;
- revision history;
- collaborative editing;
- autosave и draft policy;
- semantic embeddings;
- AI content semantics;
- encryption implementation;
- Sync conflict UI.

Presentation может выбирать способ редактирования opaque text только в пределах этого contract. Такой выбор не должен незаметно превращаться в новую Domain semantics.

## 4. Отклонённые варианты

### Только content с производным title

Отклонено для Note v1. Вычисление title из content добавляет незафиксированные parsing и update rules, усложняет Search и Presentation и делает identity отображения зависимой от editor semantics.

### Title, content и расширенный knowledge-management state

Отклонено как преждевременное расширение. Tags, folders, formats, Relationships и другие поля требуют собственных product и architecture decisions.

### Полностью пустая persisted Note

Отклонено для Note v1. Поддержка empty draft требует определения autosave, draft lifecycle, cleanup и UX semantics.

### Отдельный Note ID

Отклонено. Общий typed Entity ID уже предоставляет устойчивую identity; второй ID создал бы лишнее сопоставление во всех слоях.

### Несколько независимых field mutations

Отклонено для начального contract. Единая atomic edit mutation обеспечивает одну проверку общего invariant и одну material version transition.

### Generic repository и немедленный Unified Search

Отклонено как speculative abstraction. Их необходимость оценивается после появления production Note persistence и конкретного multi-entity use case.

## 5. Последствия

### Положительные

- Note получает минимальный, ясный и тестируемый Domain contract.
- Identity и metadata согласованы с общей Entity architecture.
- Одна atomic edit mutation однозначно задаёт version и timestamp semantics.
- No-op не создаёт ложных persistence и Outbox mutations.
- Content остаётся независимым от конкретного editor format.
- Persistence, Search, Backup и Presentation могут развиваться через отдельные gates без утечки их деталей в Domain.
- Модель допускает дальнейшее расширение без преждевременных полей и abstractions.

### Ограничения

- Note v1 не поддерживает полностью пустой persisted draft.
- Domain не предоставляет Markdown/rich-text semantics.
- Archive, delete, restore и revision history отсутствуют в первой vertical slice.
- Search и Backup integration требуют последующих решений.
- Единая edit mutation обновляет `title` и `content` как одно согласованное состояние.

### Future gates

До реализации соответствующего scope отдельно решаются:

- physical Note persistence schema и migration `v1 -> v2` по ADR-0029;
- atomic Note repository persistence и Outbox payload;
- Backup/Export format compatibility по ADR-0028;
- Note Search и Unified Search;
- lifecycle operations;
- autosave/empty draft semantics;
- editor format semantics;
- Relationships и organization model;
- encryption implementation;
- Sync conflict behavior.

## 6. Соответствие существующим ADR

ADR-0030:

- конкретизирует для Note общий Domain Entity contract ADR-0016;
- применяет atomic Domain State + Outbox persistence pattern ADR-0023 к normal local Note mutations;
- распространяет доказанные user-creation conventions ADR-0026 на Note;
- сохраняет разделение logical Backup format и physical database schema, установленное ADR-0028;
- оставляет schema version, migration orchestration и migration tests в Infrastructure согласно ADR-0029.

Настоящий ADR не изменяет существующие ADR и не определяет production Dart API, Drift schema, migration implementation, Backup format revision, Search integration или Presentation.

## 7. Приоритет

Для Domain-модели Note и семантики её creation/edit решений применяется ADR-0030.

Общие правила Entity identity, persistence atomicity, user-creation defaults, Backup/Export boundary и schema migrations продолжают регулироваться ADR-0016, ADR-0023, ADR-0026, ADR-0028 и ADR-0029 соответственно.
