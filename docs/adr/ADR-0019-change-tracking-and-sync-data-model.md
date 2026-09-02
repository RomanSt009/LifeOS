# ADR-0019: Change Tracking and Sync Data Model

**Статус:** Предварительно принято  
**Дата:** 2026-08-21  
**Версия:** 0.1
## 1. Контекст

В ADR-0018 была определена общая архитектура синхронизации LifeOS:

- local-first;
- asynchronous synchronization;
- локальный SQLite;
- Outbox;
- Push / Pull;
- Sync Cursor;
- Stable Entity IDs;
- Entity Versions;
- Change Tracking;
- Tombstones;
- Conflict Detection;
- Retry;
- поддержка нескольких устройств.

Следующим шагом необходимо определить структуру данных, которая позволит реализовать эти механизмы.

Основной вопрос:

> Как LifeOS будет представлять, хранить и передавать изменения между локальной базой данных и Sync Service?

---
# 2. Основное решение

LifeOS использует **Change-Based Synchronization Model**.

Синхронизация выполняется не путём постоянной передачи полной базы данных, а через набор изменений.

Концептуально:
```text

Domain State
     ↓
Change
     ↓
Outbox
     ↓
Sync
     ↓
Remote Change Log
     ↓
Other Device
```

---
# 3. Domain State

Domain State представляет текущее состояние пользовательских данных.

Например:
```
Task
├── id
├── title
├── status
├── lifecycle_state
├── version
└── updated_at
```

Domain State хранится локально в SQLite.

---

# 4. Change

Change представляет изменение Domain State.

Например:

Change

├── change_id

├── entity_id

├── device_id

├── operation

├── base_version

├── new_version

├── timestamp

└── payload

Change не является отдельной Domain Entity.

Это техническое представление изменения Domain State.

---

# 5. Change ID

Каждый Change должен иметь уникальный `change_id`.

change_id = globally_unique_identifier

Change ID используется для:

- идентификации изменения;
- предотвращения повторной обработки;
- idempotency;
- диагностики;
- Sync acknowledgement.

---

# 6. Entity ID

Каждая Domain Entity должна иметь стабильный `entity_id`.

Например:

entity_id = task_123

Entity ID создаётся локально и не требует подключения к серверу.

---

# 7. Device ID

Каждое устройство получает уникальный `device_id`.

Например:

User

```
├── Desktop
│   └── device_A
│
└── Phone
    └── device_B
```

Device ID используется для идентификации источника изменения.

---

# 8. User ID

User ID и Device ID являются разными понятиями.
```
User
   │
   ├── Device A
   │
   └── Device B
```
Несколько устройств могут принадлежать одному пользователю.

---

# 9. Operation

Change должен определять тип операции.

Минимально:
```
CREATE
UPDATE
DELETE
```

В дальнейшем могут появиться дополнительные операции, если они потребуются Domain Model.

---

# 10. CREATE

CREATE означает создание новой Entity.

CREATE

entity_id = X

Пример:

Offline

   ↓

Create Task

   ↓

Generate Entity ID

   ↓

Create Change

---

# 11. UPDATE

UPDATE означает изменение существующей Entity.

UPDATE

entity_id = X

Update Change должен содержать информацию о версии, на основе которой было выполнено изменение.

---

# 12. DELETE

DELETE означает удаление Entity из активного Domain State.

Физическое удаление данных из локальной database не обязательно происходит сразу.

Для Sync Model используется Tombstone.

---

# 13. Entity Version

Каждая синхронизируемая Entity имеет version.

Например:

version = 10

После изменения:

version = 11

Version используется для определения последовательности изменений и обнаружения конкурентных изменений.

---

# 14. Base Version

Каждый Update Change должен содержать `base_version`.

Например:

Current Entity:

version = 10

Пользователь изменяет Entity:

base_version = 10

new_version  = 11

Это означает:

> изменение было выполнено на основе версии 10.

---

# 15. Concurrent Change Detection

Если удалённое устройство уже изменило Entity:

Remote:

version = 11

а локальное изменение было создано:

base_version = 10

то система должна определить, являются ли изменения последовательными или конкурентными.

Remote version = 11

Local base     = 10

  

        ↓

  

Potential Conflict

---

# 16. New Version

`new_version` представляет версию Entity после применения Change.

Например:
```
base_version = 10
new_version  = 11
```
Для последовательного изменения версия обычно увеличивается относительно текущего состояния Entity.

Однако LifeOS не фиксирует на уровне этого ADR конкретный алгоритм вычисления `new_version`.

Несколько устройств могут независимо создать Changes на основе одной версии:
```
Initial:
version = 10

PC:

base_version = 10
new_version  = 11

Phone:

base_version = 10
new_version  = 11
```
Это допустимо и является основанием для последующего Conflict Detection.

Окончательная стратегия Versioning будет определена на этапе реализации Sync Protocol.

---

# 17. Timestamp

Change должен иметь timestamp.

Например:

created_at

Timestamp используется для:

- диагностики;
- сортировки;
- observability;
- анализа конфликтов.

Timestamp не должен быть единственным механизмом определения победителя конфликта.

---

# 18. Payload

Change может содержать payload с изменёнными данными.

Например:

Change

├── entity_id

├── operation = UPDATE

├── base_version = 10

├── new_version = 11

└── payload

      └── priority = HIGH

---

# 19. Full Snapshot vs Patch

Change Payload может концептуально представлять:

Full Entity Snapshot

или:

Patch

На текущем этапе не фиксируется окончательный вариант.

---

# 20. Предварительное решение по Payload

Для MVP предпочтительно использовать модель Payload, которая обеспечивает:

- простую реализацию;
- надёжное восстановление состояния Entity;
- понятную диагностику;
- возможность повторного применения Change;
- возможность выполнять Conflict Detection;
- возможность выполнять Conflict Resolution.

Окончательный выбор между Full Snapshot и Patch будет сделан после создания Persistence Prototype и анализа реальных сценариев изменения Domain Entities.

Выбранный формат Payload должен предоставлять достаточно информации для восстановления актуального состояния Entity и корректной обработки конкурентных изменений.

Конкретный формат Payload не фиксируется этим ADR.

---

# 21. Outbox

Outbox хранит локальные изменения, которые ещё не были подтверждены Sync Service.

SQLite

│

├── Domain State

│

└── Outbox

      ├── Change A

      ├── Change B

      └── Change C

---

# 22. Outbox Entry

Outbox Entry содержит Change и техническое состояние доставки.

Концептуально:

Outbox Entry

├── change_id

├── entity_id

├── operation

├── payload

├── status

├── attempt_count

└── created_at

---

# 23. Outbox Status

Минимальные состояния:

PENDING

IN_FLIGHT

ACKNOWLEDGED

FAILED

Конкретный state machine может быть уточнён во время реализации.

---

# 24. PENDING

Change ожидает отправки.

PENDING

   ↓

Sync Worker

---

# 25. IN_FLIGHT

Change находится в процессе передачи.

PENDING

   ↓

IN_FLIGHT

   ↓

Remote Service

---

# 26. ACKNOWLEDGED

Remote Sync Service подтвердил получение и принятие Change.

IN_FLIGHT

   ↓

ACKNOWLEDGED

После этого Outbox Entry может быть удалён или перемещён в историю в соответствии с реализацией.

---

# 27. FAILED

Change не удалось отправить.

Например:

Network Error

     ↓

FAILED

После этого Sync Worker может выполнить Retry.

---

# 28. Retry

Retry должен быть безопасным.

Например:

Change A

   ↓

Attempt 1

   ↓

Network Error

   ↓

Attempt 2

   ↓

Network Error

   ↓

Attempt 3

Change не должен теряться между попытками.

---

# 29. Idempotency

Remote Sync Service должен обрабатывать повторную передачу одного и того же `change_id` идемпотентно.

Например:

Change A

   ↓

Send

   ↓

Timeout

   ↓

Send again

Вторая передача не должна создавать второе логическое изменение.

---

# 30. Change Log

Remote Sync Service должен иметь механизм хранения изменений, доступных для синхронизации устройств.

Концептуально:

Remote Sync Service

        │

        └── Change Log

              ├── Change A

              ├── Change B

              └── Change C

Конкретная серверная database не определяется этим ADR.

---

# 31. Change Log vs Domain State

Change Log и Domain State выполняют разные задачи.

Domain State

→ текущее состояние

  

Change Log

→ изменения, необходимые для Sync

---

# 32. Sync Cursor

Каждое устройство хранит Sync Cursor.

Например:

sync_cursor = 10482

Cursor показывает, до какой позиции Remote Change Log устройство обработало изменения.

---

# 33. Cursor Update

После успешного применения изменений:

Cursor 10482

      ↓

Apply changes

      ↓

Cursor 10491

Cursor должен обновляться только после успешной обработки соответствующего набора изменений.

---

# 34. Cursor и Local State

Cursor и применение Domain Changes должны быть согласованы.

Нельзя считать Change обработанным, если:

Cursor updated

но:

Domain Change not applied

---

# 35. Atomic Apply

Получение Remote Changes должно обрабатываться таким образом, чтобы приложение не потеряло изменения при crash.

Концептуально:

Transaction

├── Apply Change

├── Update Sync State

└── Update Cursor

Конкретные границы transaction определяются реализацией.

---

# 36. Incoming Changes

Полученные изменения могут временно находиться в локальной очереди.

Remote

   ↓

Incoming Changes

   ↓

Validation

   ↓

Conflict Detection

   ↓

Apply

---

# 37. Conflict Detection

Для UPDATE Change система сравнивает:
```
Incoming base_version
```
с:
```
Current local version
```
Например:
```
Local version = 11
Incoming base_version = 10
```
Это означает, что Incoming Change был создан на основе более старой версии Entity.

Однако несовпадение версий само по себе не означает окончательный конфликт.

Система должна определить:
```
base_version mismatch
        ↓
Potential Conflict
        ↓
Compare changed fields / Domain semantics
        ↓
Merge Policy
        ↓
Automatic Merge
        или
Conflict requiring resolution
```
Например, если локальное изменение затронуло:
```
title
```
а Incoming Change затронул:
```
priority
```
изменения могут быть совместимыми и автоматически объединены.

Если изменения затрагивают одно и то же поле или семантически несовместимые части Domain Model, требуется применение соответствующей Conflict Resolution Policy.

Таким образом:

> `base_version mismatch` обнаруживает потенциально конкурентное изменение, но не определяет автоматически наличие неразрешимого конфликта.
---

# 38. Sequential Change

Если:

Local version = 10

Incoming base_version = 10

изменение может быть последовательным и применяться согласно обычной Sync Policy.

---

# 39. Concurrent Change

Если:

Local version = 11

Incoming base_version = 10

изменение потенциально является конкурентным.

Система должна проверить:

- какие поля были изменены;
- совместимы ли изменения;
- существует ли автоматическая Merge Policy.

---

# 40. Field-Level Change

Для поддержки field-level merge система должна иметь возможность определить, какие поля были изменены.

Например:

Change A

title = changed

  

Change B

priority = changed

Можно рассмотреть:

title + priority

как совместимые изменения.

---

# 41. Field-Level Merge Policy

Не каждое поле должно иметь одинаковое правило merge.

Концептуально:

Field

   ↓

Merge Policy

Например:

title

→ possible conflict

  

priority

→ possible automatic merge

  

lifecycle_state

→ specialized policy

  

parent_id

→ conflict

Конкретная Conflict Matrix будет определена отдельно.

---

# 42. Tombstone

После DELETE создаётся Tombstone.

Entity

   ↓

DELETE

   ↓

Tombstone

---

# 43. Tombstone Data

Концептуально:

Tombstone

├── entity_id

├── version

├── deleted_at

└── device_id

---

# 44. Tombstone Purpose

Tombstone позволяет другим устройствам узнать:

> Entity была удалена.

Без Tombstone удалённая Entity может снова появиться при старом Sync.

---

# 45. Tombstone и Restore

Если система поддерживает Restore:

DELETE

   ↓

Tombstone

   ↓

RESTORE

Restore должен быть отдельным Domain Change.

Конкретная lifecycle policy определяется отдельно.

---

# 46. Relationship Changes

Relationships также должны иметь собственные стабильные IDs.

Например:

Relationship

├── id

├── source_entity_id

├── target_entity_id

└── relationship_type

---

# 47. Relationship Change

Relationship может иметь собственные Changes:

CREATE_RELATIONSHIP

UPDATE_RELATIONSHIP

DELETE_RELATIONSHIP

Если Domain Model потребует отдельного Relationship Entity.

---

# 48. Referential Integrity

Relationship нельзя окончательно применить, если необходимые Entity отсутствуют.

Например:

Relationship

   ↓

Entity B missing

   ↓

Pending

После появления Entity:

Entity B arrives

   ↓

Apply Relationship

---

# 49. Change Ordering

Некоторые Changes имеют зависимости.

Например:

CREATE Entity A

       ↓

CREATE Entity B

       ↓

CREATE Relationship A → B

Sync implementation должна учитывать зависимости между Changes.

---

# 50. Duplicate Changes

Если Remote Service получает Change с уже известным `change_id`:

change_id = X

повторное применение не должно создавать новый Domain Change.

---

# 51. Change Validation

Перед применением Change система должна проверить:

- корректность Change ID;
- существование Entity или допустимость CREATE;
- operation;
- version;
- payload;
- schema version;
- authorization context.

---

# 52. Invalid Change

Если Change невозможно применить:

Incoming Change

      ↓

Validation Failed

      ↓

Rejected / Quarantined

Такой Change не должен молча изменять Domain State.

---

# 53. Quarantine

Для технически повреждённых или неподдерживаемых Changes может использоваться отдельное состояние:

QUARANTINED

Это позволяет сохранить информацию для диагностики.

---

# 54. Schema Version

Change Payload должен иметь schema version.

Например:

schema_version = 1

Это позволяет изменять формат Change в будущих версиях LifeOS.

---

# 55. Protocol Version vs Schema Version

Необходимо различать:

Protocol Version

и:

Change Schema Version

Protocol Version описывает правила взаимодействия Sync.

Schema Version описывает формат самого Change.

---

# 56. Change Immutability

После создания Change его содержимое не должно изменяться.

Change

   ↓

Immutable

Если требуется новое изменение:

Change A

   ↓

Change B

создаётся новый Change.

---

# 57. Why Immutable Changes

Immutable Changes упрощают:

- retry;
- debugging;
- auditing;
- conflict analysis;
- idempotency.

---

# 58. Change Ordering

Timestamp не является гарантированным глобальным порядком Changes.

Для определения порядка необходимо использовать:

- version;
- dependency;
- Sync Cursor;
- другие механизмы протокола.

---

# 59. Device Clock

Локальные часы устройства не считаются полностью доверенным источником порядка.

Например:

Device A

10:00

  

Device B

09:59

Это не означает автоматически, что изменение A произошло позже изменения B.

---

# 60. Server Timestamp

Remote Service может добавлять server-side timestamp для технических целей.

Но server timestamp не должен автоматически определять победителя Domain Conflict.

---

# 61. Change Retention

Remote Change Log не обязательно хранить бесконечно.

Retention Policy определяется инфраструктурой Sync.

Однако система должна обеспечивать возможность:

Device

   ↓

Reconnect after long offline period

   ↓

Catch up

Если Change Log больше недоступен:

Initial / Partial Resync

может быть необходим.

---

# 62. Snapshot

Remote Sync Service может периодически создавать Snapshot Domain State.

Snapshot

   ↓

Change Log

   ├── Change A

   ├── Change B

   └── Change C

Это может уменьшить стоимость Initial Sync.

Snapshot не является обязательной частью MVP.

---

# 63. Change Compaction

В будущем несколько Changes могут быть объединены.

Например:

A:

title = A

  

B:

title = AB

  

C:

title = ABC

может быть возможно заменить одним актуальным состоянием для определённых сценариев.

Однако Compaction не должна нарушать требования Sync и Conflict Resolution.

---

# 64. Compaction не должна ломать Offline Devices

Если устройство было offline:

Device B

version = 10

а сервер уже compacted старые Changes:

version 10 → 20

устройство всё равно должно иметь возможность восстановить актуальное состояние.

---

# 65. Local Change History

Полную историю всех локальных Changes необязательно хранить бесконечно.

Минимально необходимо сохранять:

- pending Outbox Changes;
- необходимую информацию для Conflict Resolution;
- Sync State.

---

# 66. Domain State vs Change History

Важно различать:

Current Domain State

и:

Change History

LifeOS не обязан становиться полноценной Event Sourcing системой.

---

# 67. Event Sourcing

Change Tracking не означает Event Sourcing.

В LifeOS:

SQLite

→ Current Domain State

является основной моделью хранения.

Changes используются прежде всего для:

Synchronization

---

# 68. Sync and Derived Data

Changes должны относиться к Domain State.

Например:

Entity Updated

может после применения вызвать:

Search Index Update

Embedding Update

AI Context Update

Но эти операции не являются отдельными Sync Changes.

---

# 69. AI-generated Changes

AI может создавать Domain Changes.

Например:

AI

 ↓

Suggest Relationship

 ↓

User confirms

 ↓

CREATE_RELATIONSHIP Change

После подтверждения пользователя изменение становится обычным Domain Change.

---

# 70. Unconfirmed AI Suggestions

Неподтверждённые AI Suggestions не должны автоматически становиться Syncable Domain State.

AI Suggestion

    ↓

PROPOSED

не равно:

CONFIRMED

---

# 71. User Override

Если пользователь изменил результат AI:

AI Suggestion

     ↓

User Override

     ↓

Domain Change

пользовательское изменение должно иметь приоритет в соответствии с Domain Policy.

---

# 72. Sync Security

Change не должен доверенно применяться только потому, что он пришёл от Sync Service.

Необходимо проверить:

- authentication;
- authorization;
- schema;
- integrity;
- ownership.

---

# 73. Change Integrity

В будущем Change может иметь cryptographic integrity mechanism.

Например:

Change

   ↓

Integrity Metadata

Конкретный механизм не фиксируется этим ADR.

---

# 74. Sensitive Payload

Change Payload может содержать пользовательские данные.

Поэтому:

- payload должен передаваться через защищённый канал;
- логи не должны содержать полный payload без необходимости;
- debugging tools должны учитывать privacy.

---

# 75. Local Storage

Outbox и Sync State хранятся локально.

Например:

SQLite

├── Domain Tables

├── Outbox

├── Sync State

└── Tombstones

Конкретная схема SQLite будет определена на этапе Persistence implementation.

---

# 76. Sync State

Минимально локально необходимо хранить:

Sync State

├── device_id

├── sync_cursor

├── last_sync_at

└── sync_status

---

# 77. Multiple Sync Cursors

Если Sync Service использует несколько независимых потоков данных, может потребоваться несколько Cursor.

Например:

cursor

├── domain

├── relationships

└── metadata

На текущем этапе используется концепция единого логического Cursor.

---

# 78. Sync Cursor Scope

Cursor относится к Remote Change Stream, а не к отдельной Entity.

Remote Change Stream

        ↓

     Cursor

---

# 79. Initial Sync

Новое устройство:

Install

   ↓

Authenticate

   ↓

Register Device

   ↓

Download Snapshot / Changes

   ↓

Apply

   ↓

Build Local State

---

# 80. Resume Initial Sync

Initial Sync должен быть resumable.

Если процесс прерван:

70%

 ↓

Connection Lost

 ↓

Resume

не требуется начинать весь процесс заново.

---

# 81. Batching

Changes должны передаваться пакетами.

Batch 1

Batch 2

Batch 3

...

Размер batch определяется реализацией.

---

# 82. Sync Transaction

Применение batch должно быть безопасным при crash.

Например:

Transaction

├── Apply Changes

├── Update Local Sync State

└── Update Cursor

---

# 83. Partial Failure

Если:

Batch

├── Change A ✓

├── Change B ✓

└── Change C ✗

система не должна считать весь batch успешно обработанным без соответствующей стратегии восстановления.

---

# 84. Retry After Crash

После restart:

SQLite

   ↓

Read Sync State

   ↓

Read Outbox

   ↓

Resume

---

# 85. Outbox Cleanup

После успешного acknowledgement:

PENDING

   ↓

IN_FLIGHT

   ↓

ACKNOWLEDGED

   ↓

Cleanup

Outbox Entry может быть удалён после того, как система больше не нуждается в нём для retry или diagnostics.

---

# 86. Conflict Record

Неразрешённый конфликт может сохраняться отдельно.

Концептуально:

Conflict

├── conflict_id

├── entity_id

├── local_change

├── remote_change

├── detected_at

└── status

---

# 87. Conflict Status

Например:

PENDING

RESOLVED

DISMISSED

---

# 88. Conflict Resolution Result

После разрешения конфликта создаётся новый Domain Change.

Например:

Conflict

   ↓

User chooses Merge

   ↓

New Change

   ↓

Sync

Старые conflicting Changes не изменяются.

---

# 89. Why Resolution Creates New Change

Это сохраняет принцип:

Changes are immutable

и делает Resolution отдельным действием.

---

# 90. Sync Observability

Система должна иметь технические метрики:

sync_duration

uploaded_changes

downloaded_changes

conflicts

failed_changes

retry_count

---

# 91. Logging

Логи должны позволять определить:

Change ID

Entity ID

Device ID

Operation

Sync State

Error

Но не должны без необходимости содержать полный пользовательский payload.

---

# 92. Error Categories

Ошибки Sync должны разделяться:

Network Error

Authentication Error

Authorization Error

Validation Error

Conflict

Server Error

Database Error

Protocol Error

---

# 93. Determinism

Применение одинакового набора валидных Changes при одинаковом исходном состоянии должно приводить к одинаковому Domain State.

---

# 94. Recoverability

После сбоя система должна иметь возможность продолжить Sync без потери подтверждённых или pending Changes.

---

# 95. Auditability

Для важных конфликтов и Sync Errors система должна иметь возможность определить:

What changed?

Who changed it?

On which device?

Based on which version?

When?

How was conflict resolved?

---

# 96. MVP Data Model

Для MVP необходимо предусмотреть следующие концептуальные структуры:

Entity

Change

Outbox Entry

Tombstone

Sync State

Conflict Record

---
# 97. MVP Change

Минимальный Change:
```
Change
├── change_id
├── entity_id
├── device_id
├── operation
├── base_version
├── new_version
├── timestamp
├── schema_version
└── payload
```
Для разных операций version semantics могут отличаться.

### CREATE

Для создания новой Entity:

```
operation    = CREATE
base_version = null
new_version  = 1
```
### UPDATE

Для изменения существующей Entity:
```
operation    = UPDATE
base_version = current_entity_version
new_version  = next_entity_version
```
### DELETE

Для удаления Entity:
```
operation    = DELETE
base_version = current_entity_version
new_version  = next_entity_version
```
`base_version` является обязательным для операций, изменяющих существующую Entity.

Конкретный алгоритм вычисления `new_version` определяется реализацией Sync Protocol.

---
# 98. MVP Outbox

Минимальный Outbox Entry:

Outbox Entry

├── change_id

├── status

├── attempt_count

└── created_at

---

# 99. MVP Sync State

Sync State

├── device_id

├── sync_cursor

├── last_sync_at

└── sync_status

---

# 100. MVP Tombstone

Tombstone

├── entity_id

├── version

├── deleted_at

└── device_id

---

# 101. MVP Conflict Record

Conflict

├── conflict_id

├── entity_id

├── local_change

├── remote_change

├── detected_at

└── status

---

# 102. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную SQLite schema;
- конкретный Sync Backend;
- конкретный Cloud Provider;
- REST / GraphQL / WebSocket;
- конкретный API format;
- окончательную Snapshot vs Patch strategy;
- окончательную Conflict Matrix;
- конкретную Retry Algorithm;
- конкретный ID generation algorithm;
- конкретную cryptographic integrity mechanism;
- окончательную Tombstone Retention Policy;
- конкретный server-side database;
- CRDT;
- Event Sourcing.

---

# 103. Последствия решения

## Положительные

- Sync становится основанным на явных Changes;
- изменения можно повторять безопасным образом;
- появляется основа для idempotency;
- можно поддерживать несколько устройств;
- Outbox обеспечивает надёжную доставку локальных изменений;
- Cursor позволяет отслеживать прогресс Sync;
- Version + base_version позволяют обнаруживать конкурентные изменения;
- Tombstones позволяют синхронизировать удаления;
- Immutable Changes упрощают диагностику;
- Domain State остаётся основной моделью хранения;
- Change Tracking не превращает LifeOS в Event Sourcing систему;
- AI остаётся независимым от базового Sync;
- архитектура допускает дальнейшее развитие.

## Отрицательные

- появляется дополнительная сложность Persistence Layer;
- необходимо поддерживать Outbox;
- необходимо хранить Sync State;
- требуется Change Log на стороне Sync Service;
- необходимо реализовать Idempotency;
- необходимо обрабатывать повреждённые и неподдерживаемые Changes;
- требуется Conflict Resolution;
- необходимо поддерживать Tombstones;
- потребуется дополнительное тестирование crash/retry scenarios;
- потребуется тестирование нескольких устройств;
- потребуется определить окончательный Payload Format;
- потребуется определить конкретную Conflict Matrix.

---

# 104. Следующий шаг

После ADR-0019 необходимо перейти к проектированию конкретной Persistence Schema.

Следующим логичным документом является:

**ADR-0020: SQLite Persistence Schema**

В нём необходимо определить:

SQLite

│

├── entities

├── relationships

├── outbox

├── tombstones

├── sync_state

└── conflicts

После этого мы уже сможем перейти от архитектурных решений к проектированию реальных таблиц и Repository Layer.

Конкретный Dart/Flutter код пока не пишем.

Сначала необходимо зафиксировать Persistence Schema.