# ADR-0020: SQLite Persistence Schema

  
**Статус:** Предварительно принято  
**Дата:** 2026-08-24  
**Версия:** 0.1
 
## 1. Контекст

В предыдущих ADR была определена архитектура хранения и синхронизации LifeOS.

Основные решения:

- local-first;
- SQLite как локальное хранилище;
- Domain State как основной источник локального состояния;
- Change Tracking;
- Outbox;
- Sync State;
- Tombstones;
- Conflict Records;
- Relationships;

- асинхронная синхронизация;

- независимость AI от базового Sync Layer.

  

ADR-0019 определил концептуальную модель `Change`, но не определил конкретную структуру локального Persistence Layer.

  

Следующий шаг — определить логическую структуру SQLite Database.

  

---

  

# 2. Основное решение

  

LifeOS использует SQLite как основное локальное persistence-хранилище.

  

SQLite должна хранить:

  

```text

SQLite

│

├── Domain State

│

├── Relationships

│

├── Outbox

│

├── Tombstones

│

├── Sync State

│

└── Conflicts
```
SQLite является локальным источником истины для текущего состояния приложения.

Remote Sync Service не заменяет локальную SQLite Database.

---

# 3. Local-First Principle

Приложение должно оставаться функциональным при отсутствии сети.

User

 ↓

Flutter UI

 ↓

Domain / Repository

 ↓

SQLite

Сеть используется для синхронизации:

SQLite

 ↓

Outbox

 ↓

Sync

 ↓

Remote

а не как обязательный посредник между UI и данными.

---

# 4. Domain State

Domain State представляет текущее состояние пользовательских данных.

Например:

Task

├── id

├── title

├── status

├── lifecycle_state

├── version

└── updated_at

Domain State хранится в отдельных таблицах, соответствующих Domain Model.

---

# 5. Domain Tables

На текущем этапе не фиксируется окончательный список всех Domain Tables.

Предварительно предполагаются сущности:

tasks

notes

projects

people

events

...

Конкретный список будет определён после завершения Domain Model.

---

# 6. Stable Entity ID

Каждая синхронизируемая Entity должна иметь стабильный ID.

Например:

id = "01J..."

ID создаётся локально.

Создание Entity не должно требовать обращения к серверу.

---

# 7. Entity Version

Синхронизируемые Entity должны иметь version.

Минимально:
```
id
version
created_at
updated_at
```
`version` используется для определения последовательности изменений Entity и обнаружения конкурентных изменений в Sync Layer.

`version` не является универсальным механизмом optimistic locking для всей базы данных.

Его основное назначение в рамках данной архитектуры:

- определение версии состояния Entity;
- определение `base_version` для Change;
- обнаружение потенциальных конфликтов;
- поддержка Sync Protocol.
---

# 8. Timestamps

Domain Entities должны иметь необходимые временные метаданные.

Минимально:

created_at

updated_at

Для удалённых объектов:

deleted_at

может храниться в Tombstone или Domain State в зависимости от конкретной модели.

---

# 9. Lifecycle State

Если Entity поддерживает Lifecycle Model, её состояние должно храниться в Domain State.

Например:

ACTIVE

ARCHIVED

DELETED

Однако окончательный набор lifecycle states определяется соответствующим Domain Model.

---


---
# 10. Relationships

LifeOS является системой, ориентированной не только на отдельные Entity, но и на связи между ними.

Поэтому Relationships должны быть представлены явно.

Концептуально:

```text
Relationship
├── id
├── source_entity_id
├── target_entity_id
├── relationship_type
├── version
├── lifecycle_state
└── timestamps
```
Relationship рассматривается как самостоятельный синхронизируемый объект.

Она должна иметь собственный стабильный ID и version.

Lifecycle State позволяет корректно обрабатывать изменения и удаление Relationship без необходимости немедленно физически удалять её из локальной Persistence Model.

Конкретная lifecycle model для Relationships определяется на уровне Domain Model.

---

# 11. Relationship ID

Relationship должна иметь собственный стабильный ID.

Это позволяет синхронизировать изменение самой связи.

Например:

Relationship A

   ↓

DELETE

   ↓

Relationship Change

---

# 12. Relationship Types

Relationship Type не должен быть жёстко зашит в Sync Layer.

Sync должен работать с абстрактным:

relationship_type

а Domain Layer определяет допустимые типы связей.

Например:

parent_of

related_to

depends_on

belongs_to

---

# 13. Relationship Integrity

Relationship должна ссылаться на допустимые Entity.

Однако во время синхронизации возможна ситуация:

```text
Remote Relationship
        ↓
Entity B отсутствует локально
```
В таком случае Relationship может временно находиться в техническом состоянии ожидания применения.

Это состояние относится к Sync / Persistence Layer и не должно становиться частью Domain Model Relationship.

Например:
```
Remote Relationship
        ↓
Entity B отсутствует
        ↓
Sync/Persistence Pending
        ↓
Entity B получена
        ↓
Relationship applied
```
Таким образом, временная недоступность связанной Entity не должна автоматически означать некорректное Domain State.

---

# 14. Outbox

Outbox представляет локальную очередь Changes, ожидающих синхронизации.

Логически Outbox не является отдельной моделью изменения данных.

Он является механизмом доставки Change.

Концептуально:

```text
Change
├── change_id
├── entity_id
├── device_id
├── operation
├── base_version
├── new_version
├── payload
└── schema_version

Outbox Metadata
├── status
├── attempt_count
├── created_at
└── last_attempt_at
```
Физическая структура SQLite может объединять Change и Outbox Metadata в одной таблице, если это упрощает реализацию.

Однако на уровне архитектуры необходимо различать:

```
Change
    =
описание изменения

Outbox
    =
механизм доставки изменения
```

---

# 15. Outbox Purpose

Outbox обеспечивает:

- надёжную передачу изменений;
- Retry;
- восстановление после crash;
- offline operation;
- idempotent synchronization.

---

# 16. Outbox Transaction

Изменение Domain State и создание Outbox Entry должны происходить в одной SQLite transaction.

Например:

BEGIN TRANSACTION

  

Update Domain State

        +

Create Outbox Entry

  

COMMIT

Если transaction завершается ошибкой:

ROLLBACK

Таким образом нельзя получить состояние:

Domain changed

BUT

Outbox missing

---

# 17. Outbox Status

Минимальные состояния:

PENDING

IN_FLIGHT

ACKNOWLEDGED

FAILED

State Machine уточняется во время реализации Sync Worker.

---

# 18. Outbox Retry

Outbox должен сохранять информацию, необходимую для Retry.

Минимально:

attempt_count

last_attempt_at

В дальнейшем могут появиться:

next_attempt_at

last_error

если это потребуется реализации.

---
# 19. Outbox Cleanup

После успешного acknowledgement Outbox Entry может быть удалён.

Удаление допускается только после подтверждения Sync Service и при условии, что Change больше не требуется для:

- Retry;
- Conflict Processing;
- диагностики;
- других обязательных операций Sync Layer.

Конкретная retention strategy определяется во время реализации Sync Protocol.

Удаление Outbox Entry не должно удалять или изменять саму историческую семантику уже созданного Change.

---
# 20. Tombstones

Удаление синхронизируемой Entity должно оставлять информацию о факте удаления.

Tombstone является частью Sync State и должен участвовать в Change Flow.

Концептуально:

```text
DELETE Entity
      ↓
Create Tombstone
      ↓
Create Change
      ↓
Outbox
      ↓
Sync
      ↓
Remote Devices
```
Минимально Tombstone может содержать:
```
tombstones
├── entity_id
├── version
├── device_id
└── deleted_at
```
Tombstone должен позволять Sync Layer определить, что Entity была удалена, даже если её основная Domain-запись больше не существует.

Конкретная физическая структура Tombstone и связь с Change определяется Persistence Implementation.

---

# 21. Tombstone Purpose

Tombstone предотвращает повторное появление удалённой Entity на другом устройстве.

Device A

DELETE Entity

   ↓

Tombstone

   ↓

Sync

   ↓

Device B

   ↓

Entity deleted

---

# 22. Tombstone Retention

Tombstones нельзя удалять только на основании фиксированного времени.

Удаление Tombstone допустимо только тогда, когда система уверена, что необходимые устройства больше не нуждаются в информации об удалении.

Конкретная Retention Policy не фиксируется этим ADR.

---

# 23. Sync State

Каждое устройство должно хранить локальное Sync State.

Концептуально:

sync_state

├── device_id

├── sync_cursor

├── last_sync_at

└── sync_status

---

# 24. Sync Cursor

`sync_cursor` определяет позицию устройства в Remote Change Stream.

Например:

sync_cursor = 10482

После успешного применения следующего набора:

10482

  ↓

10491

---

# 25. Cursor Atomicity

Обновление Cursor должно быть согласовано с применением соответствующих Remote Changes.

Концептуально:

BEGIN TRANSACTION

  

Apply Remote Changes

        +

Update Sync Cursor

  

COMMIT

Это предотвращает ситуацию:

Cursor advanced

BUT

Change not applied

---

# 26. Sync Status

Sync State может содержать техническое состояние:

IDLE

SYNCING

ERROR

PAUSED

Конкретный state machine определяется Sync Layer.

---

# 27. Conflict Records

Неразрешённые конфликты могут храниться отдельно.

Концептуально:

conflicts

├── conflict_id

├── entity_id

├── local_change_id

├── remote_change_id

├── detected_at

├── status

└── resolution

---

# 28. Conflict Status

Минимально:

PENDING

RESOLVED

DISMISSED

---

# 29. Conflict Resolution

Resolution не должна изменять старые immutable Changes.

Вместо этого создаётся новый Domain Change.

Conflict

   ↓

Resolution

   ↓

New Change

   ↓

Outbox

---

# 30. Conflict Data

Conflict Record должен содержать достаточно информации для диагностики.

Например:

local_change_id

remote_change_id

entity_id

detected_at

При необходимости дополнительные данные могут быть получены через Change History или соответствующие Sync records.

---

# 31. Database Transactions

SQLite Transactions являются основным механизмом обеспечения атомарности Persistence операций.

Особенно важны операции:

Domain Change + Outbox

и:

Remote Changes + Cursor Update

---

# 32. Repository Boundary

Application и Domain Layer не должны напрямую обращаться к SQLite.

Предполагается следующая граница:

UI

 ↓

Application

 ↓

Domain

 ↓

Repository

 ↓

Persistence

 ↓

SQLite

---

# 33. Repository Responsibilities

Repository отвечает за:

- чтение Domain State;
- сохранение Domain State;
- транзакции;
- получение Relationships;
- работу с локальными Persistence Models.

Sync-specific операции могут быть выделены в отдельные Persistence/Sync repositories.

---

# 34. Sync Repository

Sync Repository может отвечать за:

- Outbox;
- Sync State;
- Tombstones;
- Conflict Records;
- получение и применение Remote Changes.

Конкретное разделение Repository Interfaces определяется при проектировании Flutter Architecture.

---

# 35. Domain Model vs Persistence Model

Domain Models и SQLite Models не обязаны быть идентичными.

Например:

Domain Model

     ↓

Repository

     ↓

Persistence Model

     ↓

SQLite

Это позволяет не связывать Domain Layer напрямую со структурой database.

---

# 36. Serialization

Payload Changes требует сериализации.

Однако конкретный формат:

JSON

Binary

Other

не фиксируется этим ADR.

---

# 37. Schema Version

Persistence Schema должна иметь собственный механизм миграций.

Например:

Database Version 1

        ↓

Migration

        ↓

Database Version 2

Конкретный migration framework определяется после выбора Flutter persistence tooling.

---

# 38. Database Migration

Изменение SQLite Schema должно выполняться через контролируемые migrations.

Нельзя полагаться на ручное изменение production database.

---

# 39. Foreign Keys

SQLite Foreign Keys должны использоваться там, где они соответствуют Domain и Persistence Model.

Однако Sync-related данные могут временно требовать существования записей без полного набора связанных Entity.

Поэтому конкретные constraints определяются для каждой таблицы отдельно.

---

# 40. Referential Integrity

Persistence Layer должен предотвращать создание некорректных ссылок там, где это возможно.

Но Sync Layer должен также поддерживать временное состояние:

Entity arrives later

Relationship arrives earlier

---

# 41. Indexes

SQLite должна иметь индексы, соответствующие основным query patterns Persistence и Sync Layer.

Индексы должны проектироваться на основании реальных Repository и Sync queries.

Потенциально индексирование может потребоваться для таких полей, как:

```text
entity_id
version
updated_at
change_id
device_id
sync_cursor
status
```
Однако данный ADR не фиксирует окончательный набор индексов.

Конкретные индексы должны быть определены во время проектирования Persistence Schema и проверены на основании реальных запросов и измерений производительности.

Не следует добавлять индексы только на основании предположения о возможной необходимости.

---
# 42. Outbox Indexing

Outbox должен эффективно поддерживать запрос:

PENDING Changes

Например:

WHERE status = 'PENDING'

Поэтому `status` должен быть индексирован или включён в составной индекс при необходимости.

---

# 43. Sync Cursor Indexing

Если Remote Changes хранятся локально во временной таблице, необходим эффективный доступ по Sync Position.

Конкретная необходимость определяется реализацией протокола.

---

# 44. Conflict Indexing

Для быстрого отображения нерешённых конфликтов необходим эффективный запрос:

WHERE status = 'PENDING'

---

# 45. Database Size

SQLite должна оставаться пригодной для долгосрочного локального хранения большого количества пользовательских данных.

Однако оптимизация размера не должна преждевременно усложнять Persistence Layer.

---

# 46. Derived Data

Производные данные не являются обязательной частью Domain Persistence.

Например:

Search Index

Embeddings

AI Cache

Temporary Context

могут храниться отдельно или перестраиваться.

---

# 47. AI Data

AI-generated metadata не должна автоматически становиться частью основной Domain Schema.

Например:

AI Suggestion

Embedding

Confidence

Reasoning Metadata

могут иметь отдельные Persistence Models.

---

# 48. AI Suggestions

Неподтверждённые AI Suggestions должны отличаться от подтверждённого Domain State.

PROPOSED

   ≠

CONFIRMED

Только подтверждённое пользователем изменение становится обычным Domain Change.

---

# 49. Security

Локальная SQLite Database может содержать чувствительные пользовательские данные.

Поэтому Persistence Layer должен учитывать:

- защиту локального хранения;
- безопасное управление ключами;
- минимизацию чувствительных данных в логах;
- безопасные migrations;
- безопасное удаление данных там, где это требуется.

Конкретный механизм encryption не фиксируется этим ADR.

---

# 50. Database Encryption

Локальная SQLite Database может содержать чувствительные пользовательские данные.

Поэтому возможность шифрования локальной базы должна быть рассмотрена отдельно в рамках Security Architecture.

На текущем этапе ADR не фиксирует конкретный механизм:

```text
SQLCipher
Platform-level encryption
Operating system security mechanisms
Other
```
Выбор конкретного механизма должен учитывать:

- безопасность;
- производительность;
- поддержку Windows, macOS и Linux;
- поддержку Android и iOS;
- управление ключами;
- Backup / Restore;
- миграции;
- влияние на выбранный Flutter Persistence Stack.

Решение о конкретном механизме шифрования будет принято отдельным ADR после определения требований Security Architecture и Persistence Stack.

---

# 51. Backup

SQLite Database не должна рассматриваться как единственный механизм Backup.

Backup Architecture определяется ADR-0011.

Persistence Layer должен обеспечивать возможность безопасного создания Backup Snapshot.

---

# 52. Export

Export должен работать через Domain/Application Layer, а не напрямую экспортировать произвольные SQLite таблицы.

Domain

 ↓

Export Service

 ↓

Export Format

Это позволяет сохранить независимость Export Format от внутренней SQLite Schema.

---

# 53. Recovery

После повреждения или восстановления Database система должна иметь возможность:

Restore

   ↓

Validate

   ↓

Open SQLite

   ↓

Rebuild Derived Data

   ↓

Resume Sync

---

# 54. Rebuildable Data

Некоторые локальные структуры должны считаться rebuildable.

Например:

Search Index

Embeddings

AI Cache

Их потеря не должна означать потерю основного Domain State.

---

# 55. Non-Rebuildable Data

Критическими являются:

Domain State

Pending Outbox Changes

Required Tombstones

Required Sync State

Конкретный состав данных, обязательных для Backup, определяется Backup Architecture.

---

# 56. Database Initialization

При первом запуске:

Application Start

   ↓

Open SQLite

   ↓

Check Schema Version

   ↓

Run Migrations

   ↓

Initialize Required State

---

# 57. Database Recovery After Crash

SQLite должна использовать Transactions для обеспечения восстановления после crash.

Application restart:

Restart

 ↓

SQLite Recovery

 ↓

Validate State

 ↓

Resume Outbox / Sync

---

# 58. Concurrency

Несколько компонентов приложения могут обращаться к Persistence Layer.

Однако Domain mutations должны проходить через контролируемые Repository/Application boundaries.

---

# 59. UI Access

Flutter UI не должен напрямую выполнять SQL queries.

UI

 X

 ↓

SQLite

Вместо этого:

UI

 ↓

Application Layer

 ↓

Repository

 ↓

SQLite

---

# 60. Background Sync

Sync Worker может обращаться к Persistence Layer независимо от UI.

Sync Worker

 ↓

Sync Repository

 ↓

SQLite

Это позволяет Sync работать в background без зависимости от UI state.

---

# 61. Atomic Domain Mutation

Любое пользовательское изменение, которое должно быть синхронизировано, должно проходить через механизм:

Domain Mutation

      ↓

SQLite Transaction

      ├── Update Domain State

      └── Create Outbox Change

---

# 62. Atomic Remote Apply

Полученные Remote Changes должны применяться через:

SQLite Transaction

      ├── Validate / Apply Change

      ├── Update related state

      └── Update Sync Cursor

---

# 63. Database Schema Ownership

Persistence Schema является ответственностью Persistence Layer.

Domain Layer определяет семантику данных.

Persistence Layer определяет:

- таблицы;
- колонки;
- индексы;
- migrations;
- database constraints.

---

# 64. No Direct SQL in Domain

Domain Layer не должен зависеть от SQLite-specific APIs.

Это позволит в будущем заменить Persistence technology без переписывания Domain Logic.

---

# 65. Testability

Persistence Layer должен быть тестируемым независимо от UI.

Необходимо предусмотреть:

Unit Tests

Integration Tests

Migration Tests

Transaction Tests

Crash Recovery Tests

Sync Persistence Tests

---

# 66. In-Memory Testing

Для некоторых Domain/Application тестов может использоваться in-memory Persistence implementation.

Это позволит тестировать бизнес-логику без реальной SQLite Database.

---

# 67. Migration Testing

Каждая Schema Migration должна проверяться:

Version N

   ↓

Migration

   ↓

Version N+1

и должна сохранять существующие пользовательские данные.

---

# 68. Backup Compatibility

Backup должен учитывать Database Schema Version.

Например:

Backup

├── schema_version

└── data

Восстановление старой версии Backup может потребовать выполнения migrations.

---

# 69. Data Ownership

Каждая таблица должна иметь понятное назначение.

Domain Tables

→ User Data

  

Outbox

→ Pending Sync Changes

  

Tombstones

→ Deleted Entity Metadata

  

Sync State

→ Sync Metadata

  

Conflicts

→ Unresolved Sync Conflicts

---

# 70. No Mixed Responsibilities

Не следует хранить разные концепции в одной таблице только ради уменьшения количества таблиц.

Например:

Outbox

≠

Domain State

и:

Conflict

≠

Domain Entity

---

# 71. Persistence Boundary

Итоговая граница:

┌──────────────────────────────┐

│          Flutter App         │

│                              │

│ UI                           │

│ ↓                            │

│ Application                  │

│ ↓                            │

│ Domain                       │

│ ↓                            │

│ Repository                   │

│ ↓                            │

│ Persistence                  │

└──────────────┬───────────────┘

               ↓

            SQLite

---

# 72. Conceptual SQLite Structure

На текущем этапе структура выглядит следующим образом:

SQLite

│

├── Domain

│   ├── tasks

│   ├── notes

│   ├── projects

│   └── ...

│

├── Relationships

│   └── relationships

│

├── Sync

│   ├── outbox

│   ├── tombstones

│   ├── sync_state

│   └── conflicts

│

└── Migrations

---

# 73. MVP Tables

Для первого Persistence Prototype необходимо предусмотреть:

Domain tables

relationships

outbox

tombstones

sync_state

conflicts

Конкретные Domain tables будут определены после завершения Domain Model.

---

# 74. MVP Outbox

Минимальная структура:

outbox

├── change_id

├── entity_id

├── device_id

├── operation

├── base_version

├── new_version

├── payload

├── schema_version

├── status

├── attempt_count

├── created_at

└── last_attempt_at

---

# 75. MVP Tombstones

tombstones

├── entity_id

├── version

├── device_id

└── deleted_at

---

# 76. MVP Sync State

sync_state

├── device_id

├── sync_cursor

├── last_sync_at

└── sync_status

---

# 77. MVP Conflicts

conflicts

├── conflict_id

├── entity_id

├── local_change_id

├── remote_change_id

├── detected_at

├── status

└── resolution

---

# 78. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную SQLite ORM;
- Drift;
- Isar;
- Hive;
- конкретный Dart persistence package;
- SQLCipher;
- конкретный encryption mechanism;
- окончательный список Domain Tables;
- окончательный Payload Format;
- JSON vs Binary;
- конкретные индексы;
- конкретные Foreign Key constraints;
- конкретный Sync Backend;
- API Protocol;
- REST / GraphQL / WebSocket;
- Cloud Provider;
- окончательную Conflict Matrix;
- окончательную Tombstone Retention Policy.

---

# 79. Последствия решения

## Положительные

- SQLite становится чёткой локальной Persistence Boundary;
- Local-First архитектура сохраняется;
- Domain State отделён от Sync Metadata;
- Outbox обеспечивает надёжную передачу изменений;
- Transactions обеспечивают атомарность;
- Sync Cursor защищён от рассинхронизации;
- Tombstones позволяют корректно синхронизировать удаления;
- Conflict Records позволяют сохранять нерешённые конфликты;
- Persistence Layer отделён от Domain Layer;
- UI не зависит от SQLite;
- Sync Worker может работать независимо от UI;
- Derived Data можно перестраивать;
- Persistence Stack можно заменить в будущем.

## Отрицательные

- появляется несколько технических таблиц;
- увеличивается сложность Persistence Layer;
- необходимы migrations;
- необходимо тестировать transactions;
- требуется обработка crash recovery;
- требуется поддерживать Outbox;
- требуется поддерживать Tombstones;
- требуется поддерживать Sync State;
- требуется поддерживать Conflict Records;
- необходимо проектировать индексы;
- потребуется выбрать конкретный Dart Persistence Stack.

---

# 80. Следующий шаг

После ADR-0020 необходимо перейти к выбору конкретного Persistence Stack для Flutter/Dart.

Следующим документом предлагается:

**ADR-0021: Flutter Persistence Stack**

В нём необходимо сравнить варианты:

SQLite

   │

   ├── Drift

   ├── sqflite

   └── другие подходящие решения

и выбрать конкретный инструмент для LifeOS.

После этого можно будет определить:

SQLite Schema

      ↓

Dart Models

      ↓

Repositories

      ↓

Database Migrations

      ↓

Persistence Tests

Н