# ADR-0033: Task and Note Lifecycle and User Mutation Semantics

**Статус:** Принято

**Дата:** 2026-09-13

**Версия:** 0.1

## Контекст

LifeOS уже имеет production Entity типов Task, Note и Relationship. Общий `LifeOsEntity` contract содержит lifecycle states:

- `active`;
- `archived`;
- `deleted`.

ADR-0016 различает Archive и Delete, предпочитает logical soft delete и исключает deleted Entity из обычного Search, но намеренно не определяет точные lifecycle state machines. ADR-0030 определяет Note creation и atomic title/content edit, однако откладывает Note archive/delete/restore до отдельного lifecycle gate. Task поддерживает creation и отдельную completion mutation, но не имеет принятой title-edit mutation.

Desktop Usability & Dogfooding Alpha требует безопасных и однозначных Task edit, Task/Note delete и Entity restore flows. Эти операции затрагивают Domain invariants, Application use cases, repository reads, Outbox, Relationship visibility, Backup и будущий Sync, поэтому не могут быть определены только Presentation-кодом.

ADR-0032 запрещает automatic cascade mutation Relationship при lifecycle change endpoint Entity. ADR-0023 требует, чтобы normal local material mutation атомарно сохраняла resulting Domain state и соответствующий Outbox Change. Будущий Sync требует сохранять stable identity и versioned deleted state как основу tombstone semantics, но сам Sync protocol в этом решении не определяется.

## Решение

### 1. Scope решения

ADR-0033 определяет:

- Task title edit semantics;
- ограничения existing Task completion mutation по lifecycle;
- Task и Note archive/delete/restore state machine;
- default lifecycle visibility;
- поведение Relationship при изменении lifecycle endpoint;
- Outbox representation normal local mutations;
- минимальные typed repository и Application boundaries;
- минимальный user-facing lifecycle scope Desktop Alpha.

ADR не является подробной UI specification и не меняет Note title/content semantics ADR-0030.

### 2. Task title edit

В Alpha пользователь может отдельно изменять только Task `title`.

Completion остаётся отдельной существующей Domain mutation и не включается в общий edit payload. Domain предоставляет узкую mutation концептуальной формы:

```text
editTitle(
  title,
  updatedAt
)
```

Generic Task `edit(...)`, объединяющий title и completion, не вводится.

### 3. Task title invariants и normalization

- `title` сохраняется после `trim()`;
- empty и whitespace-only title недопустимы;
- произвольный maximum length не вводится без подтверждённого product или technical requirement;
- title edit разрешён только для Task с lifecycle `active`;
- archived или deleted Task является read-only до явного возврата в `active`.

Hydrated Task должна сохранять общий валидный typed Entity contract:

- non-empty Task Entity ID с `entityType = task`;
- normalized non-empty title;
- UTC `createdAt` и `updatedAt`;
- `updatedAt >= createdAt`;
- positive version.

### 4. Task material edit и no-op

Material title edit:

- создаёт новую immutable Task value;
- сохраняет ID, `createdAt`, lifecycle, source и completion state;
- увеличивает version на `1`;
- устанавливает `updatedAt` равным supplied UTC timestamp;
- отклоняет timestamp раньше текущего `updatedAt`.

Monotonic convention соответствует ADR-0030 и ADR-0032:

```text
new updatedAt >= previous updatedAt
```

Строгое `>` не требуется. Равный timestamp допустим для material mutation при coarse или deterministic clock; version остаётся источником последовательности material changes.

Если normalized title совпадает с текущим title, edit является no-op:

- возвращается та же Entity value/instance;
- version и `updatedAt` не меняются;
- repository save не выполняется;
- Outbox Change не создаётся.

Supplied timestamp всё равно должен быть UTC и не раньше current `updatedAt`; timestamp validation выполняется до no-op result. Domain не читает system clock самостоятельно.

### 5. Completion mutation boundary

Task completion toggle остаётся отдельной mutation.

- Toggle разрешён только для active Task.
- Completed Task продолжает иметь lifecycle `active`.
- Archived/deleted Task нельзя complete или reopen через completion mutation; сначала требуется соответствующая lifecycle operation до `active`.
- Material toggle следует той же external UTC и monotonic `updatedAt >= previous.updatedAt` convention и увеличивает version на `1`.

### 6. Task и Note lifecycle state machine

Для Task и Note принимаются следующие transitions:

| Transition | Решение | Domain action |
|---|---|---|
| `active -> archived` | ALLOW | `archive()` |
| `active -> deleted` | ALLOW | `delete()` |
| `archived -> active` | ALLOW | `unarchive()` |
| `archived -> deleted` | ALLOW | `delete()` |
| `deleted -> active` | ALLOW | `restore()` |
| `deleted -> archived` | FORBID | отсутствует |

Повтор action для уже достигнутого целевого состояния является no-op:

- archive archived Entity;
- delete deleted Entity;
- restore active Entity;
- unarchive active Entity.

No-op не меняет Entity state, version или timestamps и не вызывает persistence/Outbox mutation. Supplied timestamp, если он является параметром action, должен пройти UTC и non-decreasing validation до no-op.

Forbidden transition не преобразуется автоматически в compound transition. Например, deleted Entity нельзя сразу перевести в archived: сначала выполняется explicit restore в active, затем отдельный archive.

### 7. Lifecycle material mutation

Каждая material lifecycle mutation:

- возвращает новую immutable typed Entity value;
- сохраняет ID, `createdAt`, source и Entity-specific state;
- увеличивает version на `1`;
- получает `updatedAt` извне;
- требует UTC `updatedAt >= previous.updatedAt`;
- изменяет только lifecycle, `updatedAt` и version.

Task completion state сохраняется при archive/delete/restore. Note title и content сохраняются exactly. Physical delete не выполняется.

### 8. Note mutation boundary

ADR-0030 остаётся authoritative для Note title/content, empty-state, normalization и atomic edit semantics.

ADR-0033 добавляет только lifecycle boundary:

- normal Note edit разрешён только для active Note;
- archived/deleted Note read-only;
- lifecycle actions не изменяют Note title/content;
- Note content whitespace сохраняется exactly.

### 9. Archive и Delete

Archive и Delete имеют разный Domain смысл.

Archive:

- устанавливает lifecycle `archived`;
- сохраняет Entity и typed state;
- исключает Entity из ordinary active context;
- допускает explicit `unarchive()` обратно в active.

Delete:

- устанавливает lifecycle `deleted`;
- является logical soft delete;
- сохраняет Entity row, typed state, identity и metadata;
- допускает explicit `restore()` обратно в active.

Hard delete, purge и physical row removal не являются normal user lifecycle operations.

### 10. Desktop Alpha lifecycle exposure

Desktop Alpha предоставляет минимальный безопасный user-facing scope:

- Delete;
- per-feature Trash;
- Restore deleted Task/Note.

Trash находится внутри Task и Note feature surfaces. Отдельный top-level Trash destination в `NavigationRail` не требуется.

Archive semantics определены архитектурно, но Archive/Unarchive UI и соответствующие Application user actions откладываются. Наличие `archived` в common enum само по себе не требует одновременно exposing Archive и Delete в Alpha.

### 11. Default visibility policy

| Consumer | `active` | `archived` | `deleted` |
|---|---:|---:|---:|
| Ordinary Task list | include, включая completed Tasks | exclude | exclude |
| Ordinary Note list | include | exclude | exclude |
| Task Search | include | exclude | exclude |
| Future Note/Unified Search default | include | exclude | exclude |
| Relationship picker endpoints | selectable | exclude | exclude |
| Normal contextual Related section | conditional include | exclude | exclude |
| Per-feature Trash | exclude | exclude | include |
| Backup | include | include | include |
| Human-readable Export | include | include | include |
| Backup Restore | preserve exactly | preserve exactly | preserve exactly |

Normal contextual Related section показывает Relationship только когда:

- сама Relationship имеет lifecycle `active`;
- оба endpoint Entity имеют lifecycle `active`.

Inactive Entity не становится logically missing. All-state internal reads и Backup/Export продолжают сохранять её identity/state.

### 12. Relationship policy при lifecycle change endpoint

Lifecycle mutation Task или Note не должна автоматически:

- удалять или архивировать Relationship;
- менять Relationship lifecycle;
- менять Relationship version или timestamps;
- создавать Relationship Outbox Change;
- выполнять cascade unlink.

Relationship остаётся persisted с теми же stable ID, endpoints и metadata. Если любой endpoint archived/deleted, Relationship скрывается из normal contextual UI. После Restore или Unarchive endpoint существующая active Relationship снова может отображаться.

Relationship picker показывает только active Task/Note endpoints. Создание новой Relationship к archived/deleted endpoint запрещено на Application boundary; Infrastructure должна сохранять referential/data-integrity protection.

Скрытая из-за inactive endpoint Relationship продолжает существовать и учитываться duplicate protection. Restore endpoint не создаёт новую Relationship identity.

Explicitly unlinked Relationship сохраняет собственную `deleted` semantics ADR-0032. Re-link/undo такой Relationship не определяется настоящим ADR и остаётся отдельным будущим lifecycle UX gate.

### 13. Entity Restore terminology

Не смешиваются два разных действия:

- Backup Restore — replace-style восстановление dataset из Backup;
- Entity lifecycle restore — возврат deleted Task/Note в active.

Domain names:

```text
restore()   = deleted -> active
unarchive() = archived -> active
```

Generic `reactivate()` не используется, потому что скрывает исходное lifecycle state и user intent.

Presentation должна применять контекстные labels, например `Restore task`, `Restore note` и отдельно `Restore backup`. Неоднозначный unlabeled `Restore` не используется вне очевидного feature context.

### 14. Outbox policy

Каждая normal local material mutation из списка:

- Task title edit;
- Task archive/delete/restore/unarchive;
- Note archive/delete/restore/unarchive;

сохраняется как:

```text
operation = UPDATE
baseVersion = previous Entity version
newVersion = previous version + 1
payload = full resulting Entity snapshot
```

Full snapshot включает lifecycle и все Entity-specific fields. Domain state и Outbox Change записываются в одной atomic persistence transaction.

Повторная/no-op operation:

- не увеличивает version;
- не меняет timestamp;
- не вызывает repository mutation;
- не создаёт Outbox.

Outbox `DELETE` не используется для soft lifecycle delete. Physical Entity row сохраняется, а resulting full snapshot явно содержит `lifecycle = deleted`.

### 15. Repository boundaries

Task и Note сохраняют отдельные typed repositories. Generic `EntityRepository`, generic lifecycle repository и query language не вводятся.

Для обоих typed repositories:

- `getAll()` сохраняет all-state snapshot semantics, необходимые Backup/Export и bounded internal workflows;
- `getById()` может возвращать Entity независимо от lifecycle;
- добавляется typed lifecycle-aware read `getByLifecycle(LifeOsEntityLifecycle lifecycle)`;
- `save()` остаётся normal mutation persistence boundary;
- physical `delete()` method не добавляется.

Ordinary list use cases запрашивают `active`; per-feature Trash use cases запрашивают `deleted`. `archived` остаётся доступным explicit typed read для будущего Archive UI без изменения contract.

Relationship `getForEntity()` для normal contextual UI возвращает только active Relationships с двумя active endpoints.

### 16. Application boundaries

Presentation не координирует Domain/repository mutation напрямую. Application предоставляет explicit typed use cases для Alpha user actions, как минимум:

- edit Task title;
- delete Task;
- restore Task;
- delete Note;
- restore Note;
- active и deleted Task/Note reads.

Use case загружает Entity, вызывает Domain mutation, пропускает save при no-op и сохраняет material result через typed repository. UTC clock предоставляется существующей Application/composition boundary.

Archive/Unarchive Application use cases могут быть добавлены позднее вместе с user-facing Archive scope. Domain capability и Alpha UI exposure являются разными решениями.

### 17. Backup, Export и Backup Restore

Текущий Backup/Export format v3 уже сохраняет lifecycle metadata Task, Note и Relationship. Новый Entity type или новое persistent field этим ADR не вводится.

- Active, archived и deleted Task/Note включаются в Backup.
- Human-readable Export также включает все lifecycle states согласно текущему all-state snapshot contract.
- Relationships к inactive, но существующим endpoints допустимы и сохраняются.
- Backup Restore сохраняет lifecycle exactly.
- Active Outbox не восстанавливается и после Restore остаётся очищенным согласно ADR-0028/ADR-0031.

Backup/Export format v4 не требуется. Исторические v1/v2 contracts и текущий v3 contract не изменяются.

### 18. Schema и dependencies

SQLite `schemaVersion` остаётся `3`.

- Schema v4 и migration не требуются.
- Lifecycle уже хранится в `entities.lifecycle`.
- Existing `updated_at`, version и typed tables достаточны.
- Relationship FK `NO ACTION` совместимы с soft lifecycle, потому что endpoint rows физически сохраняются.
- Lifecycle filtering является query change, а не schema change.
- Новые indexes не добавляются без измеренной query problem.
- Новые package dependencies не требуются.

### 19. Future Sync compatibility

Deleted Entity сохраняется как stable-ID full snapshot с lifecycle, version и timestamp. Вместе с atomic versioned Outbox `UPDATE` это предоставляет локальную tombstone foundation без физического удаления данных.

Entity Restore является новой последующей versioned `UPDATE`, а не созданием новой identity.

Настоящий ADR не определяет:

- remote tombstone retention;
- server delete protocol;
- purge;
- conflict resolution;
- merge semantics;
- deleted-vs-edited concurrency;
- remote Restore conflicts.

Эти вопросы относятся к будущему Sync architecture gate.

## Non-goals

- Physical delete, purge и retention policy.
- Automatic Relationship cascade или cleanup.
- Dedicated global Trash destination.
- Archive UI в Desktop Alpha.
- Relationship re-link/undo semantics.
- Workspace/Projects и graph behavior.
- Sync transport и remote conflict handling.
- Generic repository/lifecycle abstraction.
- Schema v4 или новая migration.
- Backup/Export format v4.
- Новые dependencies.
- Unified Search implementation.
- Изменение Note content/title semantics ADR-0030.

## Отклонённые альтернативы

### Hard SQL delete

Отклонено: уничтожает recoverable user state, конфликтует с soft-delete direction и ухудшает future Sync tombstone foundation.

### Cascade Relationship unlink

Отклонено: lifecycle endpoint не является mutation Relationship; cascade создаёт скрытые дополнительные version/Outbox changes и противоречит ADR-0032.

### Outbox DELETE для lifecycle delete

Отклонено для текущего local contract: Entity row и full snapshot сохраняются. Единый `UPDATE` соответствует Relationship unlink precedent и явно передаёт resulting lifecycle state.

### Одновременный Archive + Delete + Trash UI в Alpha

Отклонено как избыточный initial scope. Delete + discoverable Trash + Restore закрывают безопасный CRUD loop; Archive UI может появиться по результатам dogfooding.

### Delete/Restore без discoverable Trash

Отклонено: пользователь не имеет понятного пути найти и восстановить удалённую Entity.

### Top-level Trash destination

Отклонено: per-feature Trash сохраняет контекст Task/Note и не расширяет shell navigation раньше необходимости.

### Generic repository или LifecycleService

Отклонено: два typed Entity repository и конкретные user actions не оправдывают generic abstraction. Typed lifecycle query является достаточным минимальным contract.

### Schema migration только ради soft delete

Отклонено: все необходимые lifecycle/version/timestamp fields уже существуют; query filtering не требует schema change.

## Последствия

### Положительные

- Task title edit и lifecycle mutations получают детерминированные Domain semantics.
- Delete становится безопасным recoverable soft delete.
- Ordinary views не смешивают active и inactive state.
- Relationships сохраняют identity и не получают неявных cascade mutations.
- Outbox сохраняет единый atomic full-snapshot pattern.
- Backup/Export v3 и schema v3 остаются достаточными.
- Future Sync получает versioned deleted-state foundation без преждевременного protocol design.

### Ограничения

- Deleted rows сохраняются до будущей retention/purge policy.
- Archive state архитектурно поддерживается, но не имеет user-facing Alpha UI.
- Typed repositories получают явный lifecycle-filtered read наряду с all-state snapshot read.
- Related Relationship временно скрывается, пока любой endpoint inactive.
- Relationship re-link после explicit unlink остаётся отдельным будущим решением.

## Приоритет и связь с существующими ADR

ADR-0033 конкретизирует точные Task/Note lifecycle state machines, Task title edit и endpoint visibility, намеренно оставленные будущими gates в ADR-0016, ADR-0026, ADR-0030 и ADR-0032.

ADR-0030 остаётся authoritative для Note title/content edit semantics. ADR-0032 остаётся authoritative для Relationship identity и unlink. ADR-0023 остаётся authoritative для atomic Domain state + Outbox persistence. ADR-0028 и ADR-0031 продолжают регулировать Backup/Export/Restore compatibility.

Если preliminary ADR-0019 концептуально описывает DELETE/tombstone operation шире текущего local persistence contract, для normal local soft lifecycle mutations Task/Note применяется конкретное решение ADR-0033: Outbox `UPDATE` с full resulting deleted snapshot. Future remote Sync operation mapping требует отдельного ADR.
