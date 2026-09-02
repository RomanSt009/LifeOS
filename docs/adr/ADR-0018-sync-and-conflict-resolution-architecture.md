# ADR-0018: Sync and Conflict Resolution Architecture

  

**Статус:** Предварительно принято  

**Дата:** 2026-08-20  

**Версия:** 0.1

  

## 1. Контекст

  

LifeOS проектируется как local-first приложение.

  

Каждое устройство должно иметь возможность:

  

- работать без подключения к интернету;

- создавать и изменять данные локально;

- сохранять данные в локальной SQLite database;

- продолжать работу при отсутствии сети;

- синхронизировать изменения после восстановления соединения.

  

В ADR-0017 была определена локальная Persistence Architecture:

  

```text

Flutter

   ↓

Application

   ↓

Repository

   ↓

SQLite
```
Теперь необходимо определить, каким образом изменения между несколькими устройствами будут синхронизироваться.

---

# 2. Основное решение

LifeOS использует архитектуру:

**Local-first + asynchronous synchronization**

Каждое устройство имеет собственную локальную копию Domain State.

        Device A

      Local SQLite

           |

           | Sync

           ↓

      Remote Sync

        Service

           ↑

           | Sync

           |

        Device B

      Local SQLite

Сеть не является обязательной для основной работы приложения.

---

# 3. Local-first

Основной принцип:

User Action

    ↓

Local Domain State

    ↓

UI Update

    ↓

Sync Later

Пользователь не должен ждать удалённый сервер для выполнения обычной операции.

---

# 4. Offline-first

LifeOS должен поддерживать:

Offline

   ↓

Create / Update / Archive

   ↓

Save locally

   ↓

Continue working

   ↓

Online

   ↓

Synchronize

---

# 5. Sync не является Source of Truth

Remote Sync Service не должен автоматически считаться главным источником истины.

На устройстве:

SQLite

   ↓

Local Source of Truth

Remote storage используется для обмена изменениями и хранения синхронизируемого состояния.

---

# 6. Что синхронизируется

Основным объектом Sync являются Domain Changes.

Синхронизироваться могут:

- Entities;
- Relationships;
- Lifecycle State;
- необходимые metadata;
- версии;
- изменения, необходимые для восстановления Domain State.

---

# 7. Что не синхронизируется напрямую

По умолчанию не требуется синхронизировать:

- Search Index;
- Embedding Index;
- AI Cache;
- Temporary AI Context;
- UI Cache;
- локальные performance caches.

---

# 8. Производные данные

Производные данные могут быть пересозданы:

Domain State

      ↓

Search Index

      ↓

Embedding Index

      ↓

AI Cache

Если устройство потеряло эти данные:

Rebuild

   ↓

Derived State restored

---

# 9. Syncable State

Концептуально:

Syncable State

├── Entity

├── Relationship

├── Lifecycle

├── Version

└── Metadata

---

# # 10. Stable Entity ID

Каждая Entity должна иметь стабильный ID.

ID создаётся локально.

Device A

   ↓

Generate Entity ID

   ↓

Save locally

Сервер не должен быть необходим для получения ID.

---

# 11. Offline Entity Creation

Пользователь может создать Entity без сети:

Offline

   ↓

Create Task

   ↓

Generate ID

   ↓

Save SQLite

Позже:

Sync

   ↓

Upload Entity

---

# 12. Change Tracking

Для Sync необходимо определить изменения, произошедшие после последней синхронизации.

Возможные механизмы:

- Entity version;
- updated_at;
- change log;
- sync cursor;
- outbox;
- tombstones.

Конкретная реализация может использовать комбинацию этих механизмов.

---

# 13. Sync Metadata

Каждая синхронизируемая Entity должна иметь достаточно информации для определения её состояния.

Минимально:

Entity

├── id

├── version

├── updated_at

└── lifecycle_state

---

# 14. Change Set

Sync может передавать не всю database, а набор изменений.

Device

   ↓

Changes since cursor X

   ↓

Sync Service

---

# 15. Sync Cursor

Устройство может хранить позицию последней обработанной синхронизации.

Например:

sync_cursor = 10482

После следующей синхронизации:

10482

   ↓

10491

Конкретный формат cursor определяется реализацией Sync Service.

---

# 16. Outbox

Локальная database может использовать Outbox для изменений, ожидающих отправки.

Концептуально:

SQLite

│

├── Domain State

│

└── Outbox

      ├── Change A

      ├── Change B

      └── Change C

---

# 17. Outbox Transaction

Изменение Domain State и создание Outbox Entry должны быть атомарными.

Transaction

├── Update Entity

└── Create Outbox Entry

Если transaction завершена:

Entity saved

Outbox saved

---

# 18. Sync Worker

Отдельный Sync Worker может отправлять Outbox Changes.

Outbox

   ↓

Sync Worker

   ↓

Network

   ↓

Remote Sync Service

---

# 19. Retry

Если отправка не удалась:

Outbox

   ↓

Network Error

   ↓

Retry

Изменение не должно теряться только потому, что сеть временно недоступна.

---

# 20. Retry Policy

Retry должен иметь ограничения.

Например:

Attempt

   ↓

Backoff

   ↓

Retry

   ↓

Backoff

   ↓

Retry

Конкретная стратегия определяется реализацией.

---

# 21. Idempotency

Sync Operations должны быть максимально идемпотентными.

Повторная отправка одного и того же изменения не должна создавать несколько одинаковых Domain Changes.

---

# 22. Change Identity

Sync Change должен иметь собственный идентификатор и информацию о версии, от которой было создано изменение.

Концептуально:
```
Change
├── change_id
├── entity_id
├── device_id
├── operation
├── base_version
├── new_version
└── timestamp
```

Где:

- `change_id` — уникальный идентификатор изменения;
- `entity_id` — идентификатор изменённой Entity;
- `device_id` — устройство, создавшее изменение;
- `operation` — тип операции;
- `base_version` — версия Entity, на основе которой пользователь выполнил изменение;
- `new_version` — версия Entity после применения изменения;
- `timestamp` — время создания изменения.

`base_version` используется для определения конкурентных изменений.

Например:
```
Initial Entity
version = 10

PC:
base_version = 10
new_version  = 11

Phone:
base_version = 10
new_version  = 11
```
Оба изменения произошли независимо от версии `10` и требуют проверки на конфликт.

Конкретный формат Change определяется на этапе реализации Sync Data Model.

---

# 23. Device Identity

Каждое устройство может иметь уникальный Device ID.

Например:

Desktop

device_A

  

Phone

device_B

Device ID помогает:

- отслеживать источник изменения;
- разрешать конфликты;
- диагностировать Sync;
- предотвращать повторную обработку.

---

# 24. Device ID не является User ID

Необходимо различать:

User

Device

Entity

Change

Например:

User A

 ├── Desktop

 └── Phone

---

# 25. Sync Protocol

Sync Protocol должен поддерживать как минимум:

Push Changes

Pull Changes

Acknowledge Changes

Detect Conflicts

Resolve Conflicts

Update Cursor

---

# 26. Push

Устройство отправляет локальные изменения:

Device

   ↓

Push

   ↓

Remote Sync Service

---

# 27. Pull

Устройство получает изменения других устройств:

Remote Sync Service

   ↓

Pull

   ↓

Device

---

# 28. Push + Pull

Полный Sync Cycle:

Local Changes

      ↓

     Push

      ↓

Remote Changes

      ↓

     Pull

      ↓

Apply

      ↓

Update Cursor

Порядок Push/Pull может изменяться в зависимости от конкретного протокола.

---

# 29. Sync Cycle

Концептуально:

Start Sync

     ↓

Authenticate

     ↓

Push Local Changes

     ↓

Receive Remote Changes

     ↓

Detect Conflicts

     ↓

Resolve / Queue Conflicts

     ↓

Apply Changes

     ↓

Update Sync State

     ↓

Finish

---

# 30. Conflict

Conflict возникает, когда несколько устройств изменили одну и ту же Domain State независимо.

Например:

Initial:

Task.status = TODO

version = 5

PC:

version 6

status = IN_PROGRESS

Phone:

version 6

status = COMPLETED

После Sync возникает конфликт.

---

# 31. Почему Last Write Wins недостаточно

Простая стратегия:

Last Write Wins

может привести к потере пользовательских изменений.

Например:

PC:

Priority = HIGH

  

Phone:

Priority = LOW

Одно изменение будет потеряно.

Поэтому Last Write Wins не является универсальной стратегией LifeOS.

---

# 32. Conflict Types

Не все конфликты одинаковы.

Минимально необходимо различать:

Field Conflict

Entity Conflict

Relationship Conflict

Lifecycle Conflict

Delete vs Update Conflict

---

# 33. Field Conflict

Например:

PC:

priority = HIGH

  

Phone:

priority = LOW

---

# 34. Entity Conflict

Несовместимые изменения нескольких важных свойств Entity.

PC:

Task renamed to A

  

Phone:

Task renamed to B

---

# 35. Relationship Conflict

Например:

PC:

Task → belongs_to → Project A

  

Phone:

Task → belongs_to → Project B

---

# 36. Lifecycle Conflict

Например:

PC:

Entity → ARCHIVED

  

Phone:

Entity → ACTIVE

---

# 37. Delete vs Update

Один из наиболее важных конфликтов:

PC:

Delete Entity

  

Phone:

Update Entity

Система не должна молча уничтожать изменение без определения политики.

---

# 38. Conflict Detection

Концептуально:

Incoming Change

      ↓

Compare Version

      ↓

Same lineage?

      ↓

       ├── Yes → Apply

       |

       └── No → Conflict Detection

---

# 39. Version-Based Detection

Если устройство изменяет:

version = 10

а удалённая версия уже:

version = 11

необходимо проверить, совместимы ли изменения.

---

# 40. Concurrent Changes

Конфликт особенно вероятен, если:

Device A

version 10

   ↓

offline

   ↓

change A

  

Device B

version 10

   ↓

offline

   ↓

change B

---

# 41. Sequential Changes

Если изменения происходят последовательно:

A:

version 10 → 11

  

B:

receives 11

   ↓

version 11 → 12

обычный Sync может применить их без конфликта.

---

# 42. Automatic Merge

Если изменения затрагивают разные поля, их можно объединить.

Например:

Initial:

title = "Task"

priority = LOW

  

PC:

title = "Important Task"

  

Phone:

priority = HIGH

Можно получить:

title = "Important Task"

priority = HIGH

---

# 43. Field-Level Merge

Если изменения затрагивают разные поля одной Entity, они могут быть автоматически объединены.

Например:
```
Initial:
title = "Task"
priority = LOW
```
PC:
```
title = "Important Task"
```
Phone:
```
priority = HIGH
```
Результат:
```
title = "Important Task"
priority = HIGH
```
Однако Field-Level Merge разрешён **только для полей, для которых определена совместимая Merge Policy**.

Не все поля могут безопасно объединяться автоматически.

Особое внимание требуется для:

- `lifecycle_state`;
- `status`;
- `parent_id`;
- Relationship fields;
- Delete/Restore operations;
- других полей с семантическими ограничениями.

Для таких полей может потребоваться отдельная Conflict Policy или решение пользователя.
---

# 44. Semantic Merge

В будущем AI может помогать в сложных merge scenarios.

Например:

Conflict

   ↓

Context

   ↓

AI Analysis

   ↓

Suggested Resolution

Но AI не должен автоматически становиться финальным арбитром пользовательских данных.

---

# 45. AI Conflict Resolution

AI может предложить:

Option A

Option B

Merged Option

Пользователь или заранее определённая policy принимает окончательное решение.

---

# 46. Human-in-the-loop

Для неоднозначных конфликтов:

Conflict

   ↓

User

   ├── Keep Local

   ├── Keep Remote

   └── Merge

---

# 47. Conflict Record

Неразрешённый конфликт должен сохраняться.

Концептуально:

Conflict

├── conflict_id

├── entity_id

├── local_change

├── remote_change

├── detected_at

└── status

---

# 48. Conflict Status

Например:

PENDING

RESOLVED

DISMISSED

---

# 49. Conflict UI

Пользователь должен понимать:

Что изменилось локально

Что изменилось удалённо

Почему возник конфликт

Какой вариант будет сохранён

---

# 50. Conflict History

По возможности система должна сохранять достаточно информации, чтобы объяснить происхождение конфликта.

Но полная история каждого изменения не является обязательной частью MVP.

---

# 51. Tombstones

Удалённые Entity не должны сразу исчезать из Sync Model.

Иначе другое устройство может не узнать, что Entity была удалена.

Используются Tombstones.

Entity

   ↓

DELETE

   ↓

Tombstone

---

# 52. Tombstone

Концептуально:

Tombstone

├── entity_id

├── deleted_at

├── version

└── device_id

---

# 53. Tombstone Retention

Tombstones нельзя хранить бесконечно без необходимости.

Но удалять их можно только после того, как система уверена, что необходимые устройства получили информацию об удалении.

Конкретная политика retention определяется Sync implementation.

---

# 54. Delete vs Update Resolution

Если:

Device A:

DELETE version 8

  

Device B:

UPDATE version 8

система должна обнаружить конфликт.

Автоматическая политика должна быть определена отдельно для разных типов Entity.

---

# 55. Relationship Sync

Relationships синхронизируются как Domain State.

Entity A

   ↓

Relationship

   ↓

Entity B

---

# 56. Relationship IDs

Каждая Relationship должна иметь стабильный ID.

Это позволяет синхронизировать:

Create Relationship

Update Relationship

Delete Relationship

---

# 57. AI-generated Relationships

AI-generated Relationships должны синхронизироваться с учётом их статуса.

Например:

PROPOSED

CONFIRMED

REJECTED

---

# 58. User Override

Если пользователь явно изменил Relationship:

AI:

A → related_to → B

  

User:

A → depends_on → B

пользовательское изменение должно иметь приоритет.

---

# 59. Conflict Between AI and User Data

AI-generated изменение не должно автоматически перезаписывать пользовательские данные.

User Data

    ↑

Priority

    ↑

AI Suggestion

---

# 60. Sync and Lifecycle

Lifecycle State также синхронизируется.

Например:

ACTIVE

ARCHIVED

DELETED

---

# 61. Restore Conflict

Возможна ситуация:

PC:

DELETE

  

Phone:

RESTORE

Это является Lifecycle Conflict и требует отдельной политики.

---

# 62. Sync and Derived Data

После получения изменения:

EntityUpdated

      ↓

SQLite

      ↓

Search Update

      ↓

Embedding Update

Derived Data обновляется локально после применения Domain Change.

---

# 63. Rebuild Derived State

Если Sync Index повреждён:

SQLite Domain State

      ↓

Rebuild Search

      ↓

Rebuild Embeddings

Sync не должен зависеть от сохранности derived indexes.

---

# 64. Sync and AI

AI не должен быть обязательной частью Sync.

Sync

  ≠

AI

AI может использоваться для:

- conflict suggestions;
- semantic merge;
- classification.

Но базовый Sync должен работать без AI.

---

# 65. Sync and Network Failure

Если сеть исчезла:

Sync

   ↓

Network Error

   ↓

Keep Local Changes

   ↓

Retry Later

Данные не должны теряться.

---

# 66. Partial Sync Failure

Например:

Change A ✓

Change B ✓

Change C ✗

Система должна понимать состояние каждой операции.

Нельзя считать весь Sync успешно завершённым, если часть критических изменений не обработана.

---

# 67. Sync State

Устройство может хранить:

last_sync_at

sync_cursor

pending_changes

failed_changes

conflicts

---

# 68. Sync Status

UI может отображать:

Synced

Syncing

Offline

Waiting

Conflict

Error

---

# 69. User Experience

Sync не должен мешать обычной работе пользователя.

Пользователь продолжает работать:

User

 ↓

LifeOS

 ↓

Local SQLite

а Sync выполняется в фоне.

---

# 70. Manual Sync

Пользователь может иметь возможность инициировать Sync вручную.

Sync Now

Но обычная работа не должна зависеть от ручного запуска.

---

# 71. Automatic Sync

При наличии сети система может автоматически выполнять Sync.

Триггерами могут быть:

- запуск приложения;
- восстановление соединения;
- изменение данных;
- периодический background job;
- ручной запуск.

---

# 72. Sync Frequency

Конкретный interval не фиксируется этим ADR.

Он зависит от:

- платформы;
- энергопотребления;
- network conditions;
- background execution capabilities.

---

# 73. Authentication

Sync Service должен требовать authentication.

Конкретный механизм authentication определяется Security Architecture и Sync implementation.

---

# 74. Authorization

Пользователь должен иметь доступ только к своим данным и данным, к которым у него есть соответствующие права.

---

# 75. Encryption in Transit

Sync Traffic должен передаваться по защищённому соединению.

Конкретная реализация определяется Security Architecture.

---

# 76. Encryption at Rest

Remote Sync Storage может хранить пользовательские данные.

Требования к encryption at rest определяются Security Architecture и выбранной инфраструктурой.

---

# 77. Server Trust

Remote Sync Service должен рассматриваться как потенциально недоверенный слой относительно Domain Model.

Критические правила Domain не должны зависеть только от server-side validation.

---

# 78. Data Ownership

Пользовательские данные принадлежат пользователю.

Sync Service не должен становиться единственным способом доступа к данным.

---

# 79. Export Compatibility

Пользователь должен иметь возможность экспортировать Domain State независимо от Sync Service.

Local SQLite

      ↓

Export

      ↓

Portable Data

---

# 80. Account Loss

Потеря доступа к Sync Account не должна автоматически означать потерю локальных данных.

Если локальное устройство доступно:

Local SQLite

      ↓

Export

данные должны оставаться доступными согласно Security Policy.

---

# 81. Multiple Devices

Один пользователь может иметь несколько устройств:

User

├── Desktop

├── Laptop

├── Phone

└── Tablet

Все устройства могут иметь собственную локальную database.

---

# 82. Device Registration

Новое устройство должно пройти процесс регистрации:

New Device

   ↓

Authentication

   ↓

Register Device

   ↓

Initial Sync

---

# 83. Initial Sync

При первом подключении:

New Device

    ↓

Authenticate

    ↓

Download Domain State

    ↓

Build Local SQLite

    ↓

Build Derived Indexes

---

# 84. Initial Sync Performance

Initial Sync может быть большим.

Поэтому он должен поддерживать:

- batching;
- progress reporting;
- resumability;
- background execution.

---

# 85. Resumable Sync

Если Initial Sync прерван:

Downloaded 70%

      ↓

Connection Lost

      ↓

Resume

      ↓

Continue from checkpoint

Не следует начинать весь процесс заново без необходимости.

---

# 86. Batching

Большие объёмы данных должны передаваться пакетами.

Batch 1

Batch 2

Batch 3

...

---

# 87. Sync Ordering

Для зависимых изменений порядок может иметь значение.

Например:

Create Project

      ↓

Create Task

      ↓

Create Relationship

Sync Protocol должен учитывать зависимости.

---

# 88. Referential Integrity During Sync

Нельзя применить:

Relationship

если необходимые Entity ещё не существуют локально.

Возможна очередь pending relationships.

Relationship

   ↓

Missing Entity

   ↓

Pending

   ↓

Entity arrives

   ↓

Apply Relationship

---

# 89. Duplicate Detection

Sync должен предотвращать создание дубликатов Entity.

Stable Entity ID является главным механизмом идентификации.

---

# 90. Duplicate Import

Если одна и та же Entity существует на нескольких устройствах:

Same Entity ID

она должна рассматриваться как одна Domain Entity, а не две разные.

---

# 91. Merge Strategy

Merge Strategy должна быть:

Deterministic

Auditable

Recoverable

---

# 92. Deterministic

Одинаковый набор изменений должен приводить к одинаковому результату.

---

# 93. Recoverable

Пользовательские данные не должны необратимо исчезать из-за автоматического merge без возможности восстановления, если система располагает необходимой историей.

---

# 94. Auditable

Для важных конфликтов система должна иметь возможность объяснить:

Local Change

Remote Change

Resolution

---

# 95. Conflict Priority

Общий принцип:

Explicit User Decision

        ↓

User-authored Domain State

        ↓

Deterministic Automatic Merge

        ↓

AI Suggestion

Это не означает, что AI всегда находится ниже всех автоматически применяемых правил. Это означает, что AI Suggestion не должен безусловно переопределять подтверждённые пользовательские данные.

---

# 96. AI as Advisor

AI в Sync Architecture рассматривается как:

Advisor

а не:

Authority

---

### 97. Conflict Resolution Policy

Для каждого типа конфликта должна существовать отдельная policy.

Концептуально:
```
Conflict Type
      ↓
Detection
      ↓
Automatic Resolution?
      ↓
User Resolution?
```
Например:
```
Field Conflict
→ Automatic Merge, если поля независимы и для них существует совместимая Merge Policy

Delete vs Update
→ Conflict

Relationship Conflict
→ Conflict / User Decision

Lifecycle Conflict
→ Conflict / специализированная Policy

AI Suggestion vs User Data
→ User Data wins
```
Конкретная **Conflict Resolution Matrix** будет определена отдельным техническим артефактом после определения Change Tracking и Sync Data Model.

Она должна определить для каждого типа конфликта:

- условия обнаружения;
- возможность автоматического разрешения;
- правила merge;
- необходимость участия пользователя;
- приоритет локального и удалённого изменения;
- возможность восстановления предыдущего состояния.
---

# 98. Sync Protocol Versioning

Sync Protocol должен иметь версию.

Например:

protocol_version = 1

Это позволит развивать Sync без мгновенной несовместимости старых клиентов.

---

# 99. Backward Compatibility

Новые версии LifeOS должны по возможности поддерживать совместимость со старыми Sync clients.

Если совместимость невозможна:

Version negotiation

должна определить допустимый режим работы.

---

# 100. Sync Observability

Система должна собирать технические метрики:

sync_duration

uploaded_changes

downloaded_changes

conflicts

failed_changes

retry_count

---

# 101. Privacy of Sync Logs

Sync Logs не должны содержать полное содержимое пользовательских документов или другие чувствительные данные без необходимости.

---

# 102. Sync Errors

Ошибки должны разделяться:

Network Error

Authentication Error

Authorization Error

Validation Error

Conflict

Server Error

Database Error

---

# 103. Recoverable Errors

Большинство временных ошибок должны позволять:

Retry

---

# 104. Permanent Errors

Некоторые ошибки требуют вмешательства пользователя:

Invalid Authentication

Unresolvable Conflict

Corrupted Local State

Unsupported Protocol

---

# 105. Sync Queue Cleanup

Успешно синхронизированные Outbox entries могут удаляться после подтверждения.

Pending

   ↓

Sent

   ↓

Acknowledged

   ↓

Cleanup

---

# 106. Sync History

Полная история всех Sync операций не является обязательной частью MVP.

Но система должна сохранять достаточно metadata для:

- диагностики;
- conflict resolution;
- retry;
- восстановления Sync state.

---

# 107. Local Changes Before Sync

Если пользователь продолжает изменять Entity во время Sync:

Sync running

      +

User edits Entity

новое изменение не должно потеряться.

---

# 108. Concurrent Local Changes

Persistence и Sync Layer должны корректно обрабатывать ситуацию:

Sync reads version 10

  

User updates

version 11

  

Sync tries to apply version 10

Sync не должен перезаписывать более новое локальное изменение.

---

# 109. Optimistic Concurrency

Local persistence должна проверять version при критических обновлениях.

Expected version = 10

  

Current version = 11

  

      ↓

  

Update rejected

---

# 110. Sync State Machine

Концептуально:

IDLE

  ↓

SYNCING

  ↓

APPLYING

  ↓

COMPLETED

Возможные дополнительные состояния:

OFFLINE

RETRYING

CONFLICT

ERROR

---

# 111. Sync Does Not Block UI

Sync должен быть background operation.

UI

│

├── User Interaction

│

└── Sync Worker

---

# 112. Sync and App Restart

Если приложение закрыто во время Sync:

App closes

   ↓

Pending Changes remain

   ↓

App starts

   ↓

Resume Sync

---

# 113. Crash Safety

Sync State должен сохраняться достаточно надёжно, чтобы crash не приводил к потере pending changes.

---

# 114. Network Independence

Domain Layer не должен знать:

Wi-Fi

5G

Ethernet

Offline

Network state относится к Infrastructure/Application concerns.

---

# 115. Sync Abstraction

Application Layer должен взаимодействовать с Sync через abstraction.

Application

      ↓

Sync Interface

      ↓

Sync Implementation

      ↓

Remote Service

---

# 116. Provider Independence

Sync Architecture не должна зависеть от конкретного:

- cloud provider;
- backend framework;
- database provider;
- hosting platform.

---

# 117. Возможные реализации

В будущем Sync Service может быть реализован через:

Custom Backend

Managed Backend

Self-hosted Service

Конкретный выбор не фиксируется этим ADR.

---

# 118. Не использовать Graph Database только ради Sync

Sync не требует отдельной Graph Database.

Domain Graph может синхронизироваться через обычные Entity и Relationship Changes.

---

# 119. Sync Security Boundary

Sync Service является отдельной security boundary.

Local Application

        |

     Security

        |

     Sync Layer

        |

     Remote Service

---

# 120. MVP Sync

В MVP необходимо предусмотреть архитектуру для:

Local SQLite

Outbox

Change Tracking

Push

Pull

Sync Cursor

Stable IDs

Versions

Basic Conflict Detection

Retry

Tombstones

---

# 121. Не входит в MVP

Не требуется сразу реализовывать:

- AI-powered automatic merge;
- сложный semantic merge;
- distributed CRDT;
- full event sourcing;
- multi-region sync;
- peer-to-peer sync;
- сложную conflict history;
- offline collaboration в реальном времени.

---

# 122. CRDT

CRDT не выбирается как основная Sync Model на текущем этапе.

Причина:

- дополнительная сложность;
- не все Domain Entities естественно моделируются как CRDT;
- LifeOS не является realtime collaborative editor;
- сначала необходимо получить реальные данные о характере конфликтов.

CRDT может быть рассмотрен позднее для отдельных сценариев.

---

# 123. Event Sourcing

Event Sourcing не является основной моделью Sync.

Основным объектом синхронизации является Domain Change.

---

# 124. Real-time Sync

Real-time Sync не является обязательным для MVP.

Первоначально достаточно asynchronous synchronization.

---

# 125. Sync Architecture Principles

Для Sync Architecture принимаются следующие принципы:

1. LifeOS является local-first.
2. Каждое устройство имеет локальный SQLite.
3. Основная работа приложения не требует сети.
4. Sync является asynchronous.
5. Remote Service не является единственным Source of Truth.
6. Domain State синхронизируется.
7. Derived Data не является обязательной частью Sync.
8. Entity IDs создаются offline.
9. Entity IDs стабильны.
10. Relationships имеют стабильные IDs.
11. Entity имеют versions.
12. Изменения должны отслеживаться.
13. Outbox может использоваться для pending changes.
14. Domain Update и Outbox Entry должны быть атомарными.
15. Sync Operations должны быть идемпотентными.
16. Sync поддерживает Push.
17. Sync поддерживает Pull.
18. Sync поддерживает Cursor.
19. Sync поддерживает Retry.
20. Sync должен быть resumable.
21. Sync не должен блокировать UI.
22. Конфликты должны обнаруживаться.
23. Last Write Wins не является универсальной стратегией.
24. Возможен field-level merge.
25. Автоматический merge должен быть детерминированным.
26. Неоднозначные конфликты передаются пользователю.
27. AI может быть советником при разрешении конфликтов.
28. AI не является финальным арбитром пользовательских данных.
29. Пользовательские изменения имеют приоритет над AI Suggestions.
30. Delete vs Update рассматривается как отдельный тип конфликта.
31. Lifecycle Conflicts рассматриваются отдельно.
32. Relationship Conflicts рассматриваются отдельно.
33. Deleted Entities используют Tombstones.
34. Tombstones имеют retention policy.
35. Sync должен поддерживать несколько устройств.
36. Новое устройство проходит Initial Sync.
37. Initial Sync должен быть resumable.
38. Большие Sync операции используют batching.
39. Referential Integrity должна сохраняться во время Sync.
40. Sync не должен создавать дубликаты Entity.
41. Merge должен быть recoverable.
42. Merge должен быть auditable.
43. Sync Protocol должен иметь version.
44. Sync Provider не фиксируется этим ADR.
45. Cloud Provider не фиксируется этим ADR.
46. CRDT не используется в MVP.
47. Event Sourcing не используется как основная Sync Model.
48. Real-time Sync не требуется для MVP.
49. AI не является обязательным для Sync.
50. Пользовательские данные должны оставаться доступными локально при потере Sync Service.

---

# 126. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретный Sync Backend;
- конкретный Cloud Provider;
- API Protocol;
- REST vs GraphQL vs WebSocket;
- конкретную Authentication implementation;
- конкретную database на сервере;
- окончательный формат Change Object;
- окончательный формат Cursor;
- конкретный ID format;
- окончательную Conflict Matrix;
- окончательную Tombstone Retention Policy;
- конкретную Outbox Schema;
- конкретную Retry Algorithm;
- конкретный AI Merge Provider.

Эти решения будут определены после прототипирования.

---

# 127. Последствия решения

## Положительные

- LifeOS полноценно поддерживает local-first;
- пользователь может работать без интернета;
- изменения не должны теряться при временном отсутствии сети;
- несколько устройств могут иметь локальные копии данных;
- Sync не связан напрямую с Flutter UI;
- Sync не связан с конкретным Cloud Provider;
- Derived Data не требуется синхронизировать;
- AI не становится обязательным компонентом Sync;
- архитектура допускает дальнейшее развитие;
- конфликты рассматриваются как нормальная часть multi-device системы;
- пользователь сохраняет контроль над неоднозначными конфликтами;
- Tombstones позволяют корректно синхронизировать удаления;
- архитектура совместима с будущим AI-assisted conflict resolution.

## Отрицательные

- Sync значительно сложнее локального CRUD;
- необходимо поддерживать Outbox;
- необходимо отслеживать изменения;
- необходимо обрабатывать конфликты;
- необходимы Tombstones;
- потребуется дополнительная серверная инфраструктура;
- потребуется тестирование offline scenarios;
- потребуется тестирование crash/retry scenarios;
- потребуется разработка Conflict UI;
- multi-device Sync увеличивает количество edge cases.

---

# 128. Следующий шаг

После ADR-0018 следующим логичным этапом является переход от общей архитектуры Sync к более конкретной технической модели.

Необходимо будет определить:

Entity

   ↓

Change

   ↓

Outbox

   ↓

Sync Protocol

   ↓

Remote Storage

Следующим ADR может стать:

**ADR-0019: Change Tracking and Sync Data Model**

В нём можно будет определить конкретную структуру:

Change

├── change_id

├── entity_id

├── device_id

├── operation

├── base_version

├── new_version

├── timestamp

└── payload

А также более точно определить:

- Outbox;
- Tombstones;
- Sync Cursor;
- Change Log;
- conflict detection;
- ordering;
- idempotency.

После этого архитектурный фундамент LifeOS будет достаточно зрелым для перехода к технической реализации Persistence и Sync слоя.