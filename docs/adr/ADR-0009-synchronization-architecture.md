# ADR-0009: Synchronization Architecture LifeOS

**Статус:** Предварительно принято  
**Дата:** 2026-08-15  
**Версия:** 0.1

## Контекст

LifeOS планируется как кроссплатформенная система.

Первоначальная платформа:

- Desktop

В дальнейшем:

- Windows;
- macOS;
- Linux;
- Android;
- iOS;
- Web.

Пользователь должен иметь возможность работать с одними и теми же данными на разных устройствах.

При этом LifeOS должен сохранять принцип:

> Пользователь должен иметь доступ к своим данным даже при отсутствии подключения к интернету.

  

Поэтому синхронизация не должна быть основой работы приложения.

  

Она должна быть механизмом передачи изменений между независимыми локальными экземплярами LifeOS.

  
---

# 1. Основное решение

  

LifeOS использует архитектуру:

**Local-first + Synchronization**

  

Каждое устройство имеет собственную локальную базу данных.

  Концептуально:

  
```text

                 LifeOS User Data
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
       Desktop       Mobile       Tablet
          │            │            │
       Local DB     Local DB     Local DB
          │            │            │
          └────────────┼────────────┘
                       ↓
                  Sync Service

Синхронизация передаёт изменения между устройствами.

```

---

# 2. Почему не Cloud-first

Нежелательная архитектура:

Device

   ↓

Cloud Database

   ↓

Device

В таком варианте устройство фактически зависит от сервера.

Проблемы:

- отсутствие интернета ограничивает работу;
- повышается latency;
- сервер становится критической точкой отказа;
- усложняется offline режим;
- пользователь сильнее зависит от инфраструктуры LifeOS.

---

# 3. Local-first

Предпочтительная модель:

User
 ↓
Local Application
 ↓
Local Database
 ↓
Sync
 ↓

Remote Storage

Пользователь работает прежде всего с локальными данными.

---

# 4. Offline-first

LifeOS должен поддерживать полноценную работу без подключения к сети.

Например:

Internet available
       ↓
LifeOS
       ↓
Local DB
       ↓
Sync

и:

Internet unavailable
       ↓
LifeOS
       ↓
Local DB

Основные операции приложения не должны блокироваться из-за отсутствия сети.

---

# 5. Sync как фоновый процесс

Синхронизация не должна блокировать UI.

Предпочтительная модель:

User
 ↓
Application
 ↓
Local DB
 ↓
UI updated immediately

  

        +

  

Background Sync

---

# 6. Write Path

При изменении данных:

User Action
    ↓
Application
    ↓
Domain Validation
    ↓
Local Database
    ↓
UI Update

После этого:

Local Change
    ↓
Sync Queue
    ↓
Sync Service
    ↓
Remote Server

---

# 7. Read Path

Чтение данных происходит локально:

UI

 ↓

Application

 ↓

Repository

 ↓

Local Database

Не следует делать:

UI

 ↓

Network

 ↓

Server

 ↓

Database

для каждого обычного чтения.

---

# 8. Sync Model

Синхронизация должна передавать не только текущее состояние, но и информацию об изменениях.

Концептуально:

Local Change

    ↓

Change Record

    ↓

Sync

    ↓

Remote

Это позволит корректно обрабатывать:

- offline изменения;
- конфликты;
- повторную синхронизацию;
- восстановление после ошибки.

---

# 9. Change Log

На локальном устройстве может использоваться журнал изменений.

Например:

ChangeLog

├── create

├── update

├── delete

└── relationship_change

Каждое изменение получает идентификатор.

---

# 10. Change ID

Каждое изменение должно иметь уникальный идентификатор.

Например:

change_id

Он должен позволять определить:

- конкретное изменение;
- устройство;
- порядок или версию изменения.

Конкретный формат будет определён во время реализации.

---

# 11. Device ID

Каждый экземпляр LifeOS должен иметь уникальный идентификатор устройства.

Например:

device_id

Это позволит определить:

какое устройство создало изменение

---

# 12. Entity ID

Каждая сущность LifeOS должна иметь стабильный уникальный ID.

Например:

entity_id

ID не должен зависеть от конкретного устройства.

Это важно для синхронизации между несколькими базами.

---

# 13. Не использовать локальный Auto Increment как глобальный ID

Нежелательный вариант:

Desktop:

Task ID = 42

  

Mobile:

Task ID = 42

Оба устройства могут создать разные сущности с одинаковым ID.

Поэтому глобальные идентификаторы должны генерироваться безопасным способом.

Например:

UUID

или другой распределённо уникальный идентификатор.

---

# 14. Sync Identity

Для синхронизации необходимо различать:
User
Device
Entity
Change
Концептуально:
User
 │
 ├── Device A
 │     ├── Entity
 │     └── Changes
 │
 ├── Device B
 │     ├── Entity
 │     └── Changes
 │
 └── Device C
       ├── Entity
       └── Changes

---

# 15. Sync Server

В будущем между устройствами может находиться Sync Backend.

Desktop

   ↓

Sync Backend

   ↑

Mobile

Sync Backend не обязан выполнять бизнес-логику LifeOS.

Его основная задача:

- принимать изменения;
- хранить необходимые данные;
- передавать изменения устройствам;
- помогать обнаруживать конфликты.

---

# 16. Sync Backend не является единственным источником истины

В Local-first архитектуре:

Local DB

является рабочим источником данных конкретного устройства.

Sync Backend хранит состояние, необходимое для синхронизации между устройствами.

Архитектура не должна предполагать, что приложение не может работать без сервера.

---

# 17. Sync Protocol

В будущем будет определён протокол синхронизации.

Концептуально:

Device

 ↓

Push Changes

 ↓

Sync Server

 ↓

Pull Changes

 ↓

Device

---

# 18. Push

Устройство отправляет изменения:

Local Change

     ↓

Sync Queue

     ↓

Push

     ↓

Server

После успешного получения сервер подтверждает изменение.

---

# 19. Pull

Устройство запрашивает изменения:

Server

   ↓

Changes since last sync

   ↓

Device

   ↓

Apply

   ↓

Local DB

---

# 20. Sync Cursor

Устройство должно хранить информацию о том, до какого состояния оно синхронизировано.

Например:

sync_cursor

Концептуально:

Device

  ↓

last_synced_cursor

  ↓

request changes after cursor

Это позволяет не загружать всю базу при каждой синхронизации.

---

# 21. Initial Sync

При первом подключении устройства:

New Device

    ↓

Authentication

    ↓

Initial Sync

    ↓

Local Database populated

После этого используются только изменения.

---

# 22. Incremental Sync

После первоначальной синхронизации:

Initial Sync

     ↓

Incremental Changes

     ↓

Incremental Changes

     ↓

Incremental Changes

Это значительно уменьшает объём передаваемых данных.

---

# 23. Sync Queue

Локальные изменения должны помещаться в очередь:

Sync Queue

├── pending

├── syncing

├── synced

└── failed

Это позволит повторять неудачные операции.

---

# 24. Retry

Временная ошибка сети:

Sync failed

     ↓

Retry

Retry должен использовать:

- ограниченное количество попыток;
- exponential backoff;
- timeout.

Бесконечные мгновенные повторные запросы не допускаются.

---

# 25. Idempotency

Повторная доставка одного изменения не должна приводить к повторному выполнению операции.

Например:

Change A

 ↓

Server

 ↓

Network failure

 ↓

Client retries

 ↓

Change A again

Система должна распознать:

Change A уже обработано

и не создать дубликат.

---

# 26. Sync Conflicts

Конфликт возникает, когда несколько устройств изменяют одну сущность независимо.

Например:

Desktop:

Task.title = "Подготовить презентацию"

  

Mobile:

Task.title = "Подготовить новую презентацию"

Оба изменения произошли offline.

После подключения возникает конфликт.

---

# 27. Conflict Resolution

Конфликты нельзя решать одним универсальным правилом.

Разные типы данных требуют разных стратегий.

Например:

Field-level conflict

Entity-level conflict

Relationship conflict

Delete conflict

---

# 28. Conflict Resolution Strategy

На первом этапе рассматриваются:

Last Write Wins

и:

Manual Conflict Resolution

Но `Last Write Wins` не должен автоматически применяться ко всем данным.

---

# 29. Last Write Wins

Пример:

Device A

10:00

title = A

  

Device B

10:05

title = B

Результат:

title = B

Преимущество:

- простота.

Недостаток:

- информация A может быть потеряна.

---

# 30. Manual Conflict Resolution

Для важных данных:

Conflict detected

      ↓

User

      ↓

Choose A

Choose B

Merge

Например:

Desktop:

deadline = 15 Aug

  

Mobile:

deadline = 20 Aug

LifeOS может показать:

Conflict

  

Desktop → 15 Aug

Mobile  → 20 Aug

  

[15 Aug] [20 Aug] [Edit]

---

# 31. Automatic Merge

Некоторые данные можно объединять автоматически.

Например:

Tags:

A = [work, life]

B = [life, urgent]

Результат:

[work, life, urgent]

Но автоматический merge должен использоваться только там, где семантика данных позволяет это делать безопасно.

---

# 32. Relationship Conflicts

Связи являются отдельными объектами архитектуры.

Например:

Task

 ↓

Project A

на одном устройстве и:

Task

 ↓

Project B

на другом.

Это отдельный тип конфликта.

Он должен рассматриваться независимо от изменения обычных полей.

---

# 33. Delete Conflicts

Особенно опасная ситуация:

Desktop:

Entity deleted

  

Mobile:

Entity edited

После синхронизации необходимо определить:

Delete wins?

Edit wins?

Restore?

Ask user?

Такие правила будут определены отдельно.

---

# 34. Tombstones

Физическое удаление сущности сразу после delete может привести к проблемам синхронизации.

Поэтому может использоваться:

Tombstone

Концептуально:

Entity

 ↓

Deleted

 ↓

Tombstone

Tombstone сообщает другим устройствам:

> Эта сущность была удалена.

---

# 35. Lifecycle и Sync

C+ концепция требует учитывать lifecycle.

Например:

Active

Completed

Archived

Deleted

Sync должен передавать изменения lifecycle так же, как и обычные изменения данных.

---

# 36. Soft Delete

Вместо немедленного физического удаления:

DELETE FROM entity

может использоваться:

deleted_at

или lifecycle state:

Deleted

Физическое удаление может происходить позже после безопасного подтверждения синхронизации.

---

# 37. Sync and AI

AI не должен иметь отдельную систему синхронизации.

AI-generated данные должны становиться обычными сущностями LifeOS.

Например:

AI

 ↓

Suggested Task

 ↓

User Confirmation

 ↓

Task

 ↓

Local DB

 ↓

Sync

---

# 38. AI Suggestions and Sync

Если AI предлагает связь:

Task → Project

и пользователь подтверждает её:

Relationship

 ↓

Local DB

 ↓

Sync

Она синхронизируется как обычное изменение.

---

# 39. Sync and Search

Поисковый индекс не обязательно должен синхронизироваться напрямую.

Предпочтительно:

Entity Data

     ↓

Sync

     ↓

Local Database

     ↓

Local Search Index

Каждое устройство может самостоятельно построить индекс.

---

# 40. Sync and Embeddings

Embeddings также не следует считать основной синхронизируемой сущностью на первом этапе.

Возможная модель:

Entity

 ↓

Sync

 ↓

Local Embedding

Это позволит:

- менять embedding model;
- перестраивать индекс;
- не передавать большие embedding vectors между устройствами без необходимости.

---

# 41. Sync and Files

Файлы требуют отдельной стратегии.

Например:

Entity

 ↓

Attachment

 ↓

File

Не следует передавать большие файлы через тот же механизм, что и обычные изменения сущностей.

В будущем возможна отдельная:

File Sync Service

---

# 42. Large Files

Для больших файлов может использоваться:

Chunked Upload

или:

Object Storage

При этом Entity хранит metadata:

file_id

filename

size

hash

mime_type

---

# 43. File Integrity

Для файлов необходимо проверять целостность.

Например:

File

 ↓

Hash

 ↓

Transfer

 ↓

Hash verification

---

# 44. Encryption in Transit

Данные при синхронизации должны передаваться через защищённое соединение.

Концептуально:

Device

   ↓

Encrypted Connection

   ↓

Sync Backend

Конкретная реализация будет определена в Security Architecture.

---

# 45. Encryption at Rest

Необходимо предусмотреть защиту данных:

Device

 ↓

Local Database

и:

Server

 ↓

Stored Data

Конкретная стратегия шифрования будет определена в Security ADR.

---

# 46. Authentication

Sync Backend должен идентифицировать пользователя и устройство.

Концептуально:

User

 ↓

Authentication

 ↓

Session

 ↓

Device

 ↓

Sync

Конкретный механизм authentication не фиксируется в данном ADR.

---

# 47. Authorization

Пользователь должен иметь доступ только к собственным данным.

Для будущего shared data:

User A

   ↓

Shared Entity

   ↑

User B

потребуется отдельная permission model.

---

# 48. Multi-user Collaboration

Совместная работа нескольких пользователей не является частью MVP.

Но архитектура не должна делать её невозможной.

В будущем могут появиться:

Owner

Member

Viewer

Editor

Admin

---

# 49. Account and Device Management

В будущем пользователь сможет видеть:

Devices

  

Desktop

Mobile

Tablet

и управлять ими.

Например:

Device A

Last sync: 2 min ago

  

Device B

Last sync: 1 hour ago

---

# 50. Revoking Device

Пользователь должен иметь возможность отключить устройство.

Например:

Lost Phone

     ↓

Revoke Device

     ↓

Device loses sync access

Это будет частью Security Architecture.

---

# 51. Sync Status

UI должен показывать состояние синхронизации.

Например:

✓ Synced

⟳ Syncing

! Sync error

○ Offline

Но Sync Status не должен блокировать основную работу приложения.

---

# 52. Sync Errors

Ошибка синхронизации должна быть понятной пользователю.

Плохо:

HTTP 409

Лучше:

Не удалось синхронизировать изменения.

Мы сохранили их локально и повторим попытку автоматически.

---

# 53. Data Safety

При ошибке синхронизации локальные данные не должны удаляться.

Основной принцип:

Sync failure

     ↓

Local data remains

---

# 54. Server Failure

Если Sync Backend недоступен:

Server unavailable

       ↓

Local LifeOS continues

       ↓

Changes queued

       ↓

Retry later

---

# 55. Long Offline Period

Пользователь может работать offline:

Day 1

 ↓

Changes

  

Day 2

 ↓

Changes

  

Day 3

 ↓

Changes

  

Internet restored

 ↓

Sync

Архитектура должна поддерживать накопление изменений.

---

# 56. Large Change Queue

При большом количестве offline изменений необходимо:

- не перегружать память;
- хранить очередь на диске;
- отправлять изменения пакетами;
- поддерживать resume после ошибки.

---

# 57. Batch Sync

Вместо:

Change 1 → request

Change 2 → request

Change 3 → request

может использоваться:

Batch

├── Change 1

├── Change 2

├── Change 3

└── Change 4

Это уменьшает количество сетевых запросов.

---

# 58. Sync Ordering

Некоторые изменения могут зависеть друг от друга.

Например:

Create Project

     ↓

Create Task

     ↓

Create Relationship

Нельзя отправить relationship до существования необходимых сущностей.

Поэтому Sync должен учитывать зависимости.

---

# 59. Eventual Consistency

После изменения на одном устройстве другое устройство может получить изменение не мгновенно.

Например:

Desktop

  ↓

Change

  ↓

Sync

  ↓

Server

  ↓

Mobile

Между этими событиями существует временная задержка.

Это называется:

**Eventual Consistency**

Для LifeOS это приемлемо.

---

# 60. Strong Consistency

Полная синхронная согласованность всех устройств не является обязательным требованием.

Например:

Desktop update

 ↓

wait for server

 ↓

wait for mobile

 ↓

confirm

 ↓

show result

не должна быть необходимой для обычной работы пользователя.

---

# 61. Source of Truth при конфликте

Не следует считать сервер автоматически главным источником истины.

Вместо этого:

Change

 ↓

Conflict Detection

 ↓

Resolution Policy

Определяет итоговое состояние.

---

# 62. Versioning

Для обнаружения конфликтов может использоваться версия сущности.

Например:

entity_version

или другой механизм optimistic concurrency.

---

# 63. Optimistic Concurrency

Концептуально:

Entity version = 5

Device A читает:

version = 5

Device B также читает:

version = 5

A изменяет:

version = 6

B пытается изменить:

expected version = 5

Система обнаруживает:

Conflict

---

# 64. Sync Metadata

Служебные данные синхронизации не должны смешиваться с бизнес-данными без необходимости.

Например:

Sync Metadata

├── device_id

├── change_id

├── cursor

├── version

├── sync_status

└── timestamps

---

# 65. Clock

Нельзя полностью полагаться на локальное время устройства для определения порядка изменений.

Причина:

Device A clock = correct

Device B clock = +2 hours

Поэтому timestamp может использоваться как дополнительная информация, но не как единственный механизм разрешения конфликтов.

---

# 66. Ordering

Для определения порядка изменений могут использоваться:

- server sequence;
- logical clock;
- version;
- change ID;
- timestamp как дополнительный параметр.

Конкретный механизм будет выбран при проектировании Sync Protocol.

---

# 67. Sync Protocol Version

Протокол синхронизации должен иметь версию.

Например:

sync_protocol_version

Это позволит развивать сервер и клиенты независимо.

---

# 68. Backward Compatibility

Новые версии LifeOS не должны автоматически ломать старые устройства.

Например:

Desktop v2

       ↕

Mobile v1

При необходимости сервер должен поддерживать совместимость протокола.

---

# 69. Migration

Изменения схемы данных требуют миграций.

Например:

Database v1

    ↓

Migration

    ↓

Database v2

Sync protocol и database schema должны иметь независимое versioning.

---

# 70. Backup

Sync не является заменой Backup.

Это принципиально разные системы.

Sync

 ↓

Synchronize current state

  

Backup

 ↓

Recover previous state

Если пользователь случайно удалил сущность и удаление синхронизировалось на всех устройствах, Sync не должен автоматически восстанавливать её.

Для этого нужен Backup/History механизм.

---

# 71. History

В будущем LifeOS может хранить историю изменений.

Например:

Entity

 ↓

History

 ├── Created

 ├── Updated

 ├── Updated

 └── Deleted

Это может помочь:

- восстановлению;
- audit;
- конфликтам;
- Undo.

---

# 72. Undo

Локальный Undo должен быть отделён от Sync.

Например:

User

 ↓

Delete Task

 ↓

Undo

может вернуть состояние до синхронизации.

---

# 73. Sync and Undo

После синхронизации Undo становится более сложным.

Поэтому архитектура должна различать:

Local Undo

и:

Synced Change Reversal

---

# 74. Sync and Audit

Для важных действий может потребоваться audit trail.

Например:

Who

What

When

From which device

Но объём и срок хранения audit данных будут определены отдельно.

---

# 75. Privacy

Sync Backend потенциально получает пользовательские данные.

Поэтому необходимо определить:

- какие данные отправляются;
- какие данные хранятся;
- как долго;
- кто имеет доступ;
- шифруются ли данные;
- возможно ли end-to-end encryption.

Эти вопросы будут подробно определены в Security Architecture.

---

# 76. End-to-End Encryption

В будущем может рассматриваться:

Device A

 ↓

Encrypt

 ↓

Server

 ↓

Encrypted data

 ↓

Device B

 ↓

Decrypt

Это может повысить приватность.

Однако E2EE значительно усложняет:

- поиск;
- server-side processing;
- recovery;
- multi-device key management;
- collaboration.

Поэтому E2EE не фиксируется как обязательная часть MVP.

---

# 77. Server-side AI

Sync Backend не должен автоматически получать право использовать пользовательские данные для AI.

Если в будущем будет серверный AI:

User Data

 ↓

Policy

 ↓

Context

 ↓

AI

это должно быть явно разрешено архитектурой и политикой приватности.

---

# 78. Self-hosted Sync

В будущем может поддерживаться:

LifeOS Cloud

и:

Self-hosted Sync Server

Например:

User

 ↓

Own Server

 ↓

LifeOS Devices

Это соответствует долгосрочной цели контроля пользователя над своими данными.

---

# 79. Sync Provider Abstraction

Возможна абстракция:

SyncProvider

с реализациями:

CloudSyncProvider

SelfHostedSyncProvider

LocalNetworkSyncProvider

Но сложная абстракция не реализуется до появления реальной необходимости.

---

# 80. MVP

В MVP синхронизация может быть ограничена:

One User

+

Multiple Devices

+

Local-first

+

Cloud Sync

Без:

- collaboration;
- сложного E2EE;
- self-hosted server;
- peer-to-peer sync;
- advanced conflict UI.

---

# 81. Первый этап реализации Sync

Первый рабочий вариант должен обеспечить:

Device A

   ↓

Create / Update

   ↓

Local DB

   ↓

Sync

   ↓

Server

   ↓

Device B

   ↓

Local DB

---

# 82. Что не реализуем в MVP

Не реализуем сразу:

- multi-user collaboration;
- сложную CRDT-систему;
- peer-to-peer synchronization;
- полноценный E2EE;
- self-hosted deployment;
- сложный conflict editor;
- синхронизацию огромных файлов;
- распределённый AI;
- server-side semantic search.

---

# 83. CRDT

CRDT рассматривается как потенциальная технология для будущего.

CRDT может облегчить автоматическое объединение некоторых параллельных изменений.

Однако внедрение CRDT на раннем этапе может значительно увеличить сложность системы.

Поэтому:

CRDT

= Future option

а не обязательное решение MVP.

---

# 84. Почему не выбрать CRDT сейчас

Причины:

- дополнительная сложность;
- больше служебных данных;
- сложнее отладка;
- не все сущности естественно моделируются через CRDT;
- требования LifeOS ещё не полностью определены.

Сначала необходимо получить реальные сценарии конфликтов.

---

# 85. Sync Testing

Система должна тестироваться на сценариях:

Online

Offline

Reconnect

Duplicate change

Conflict

Delete conflict

Long offline

Network failure

Server failure

Partial sync

App crash during sync

---

# 86. Crash Safety

Если приложение закрывается во время синхронизации:

Sync started

    ↓

Application crash

после запуска:

Restart

 ↓

Read Sync Queue

 ↓

Resume

данные не должны теряться.

---

# 87. Atomicity

Применение изменений к локальной базе должно быть атомарным.

Нельзя получить состояние:

Entity created

Relationship missing

если обе операции должны быть частью одной транзакции.

---

# 88. Transaction

Например:

Create Project

+

Create Task

+

Create Relationship

может выполняться внутри одной локальной транзакции, если бизнес-логика этого требует.

---

# 89. Sync Transaction

При этом локальная транзакция и сетевой sync transaction — разные понятия.

Локальная база может успешно сохранить данные даже если сервер временно недоступен.

Local transaction = success

Sync = pending

Это является нормальным состоянием.

---

# 90. Sync State Machine

Концептуально синхронизация может иметь состояния:

Idle

  ↓

Preparing

  ↓

Uploading

  ↓

Downloading

  ↓

Applying

  ↓

Completed

При ошибке:

Error

  ↓

Retry

---

# 91. User-visible State

В UI не обязательно показывать все технические состояния.

Пользователю достаточно:

✓ Синхронизировано

⟳ Синхронизация

○ Офлайн

! Ошибка синхронизации

---

# 92. Performance

Sync должен минимизировать:

- network requests;
- battery usage;
- CPU;
- disk I/O;
- memory;
- transferred data.

Особенно это важно для мобильных устройств.

---

# 93. Mobile Considerations

На мобильных устройствах Sync должен учитывать:

- ограниченный background execution;
- battery;
- mobile network;
- Wi-Fi;
- roaming;
- ограниченную память.

Синхронизация не должна постоянно работать в фоне.

---

# 94. Desktop Considerations

На Desktop возможно более частое выполнение background sync.

Например:

Application running

 ↓

Periodic Sync

---

# 95. Web Considerations

Web-версия может иметь отдельные ограничения:

- browser storage;
- background execution;
- network lifecycle;
- storage quota.

Архитектура Sync должна учитывать возможность Web, но Web не является первичной платформой MVP.

---

# 96. Sync Frequency

Не фиксируем одну частоту синхронизации.

Она может зависеть от:

- платформы;
- наличия сети;
- количества изменений;
- battery;
- user settings;
- server policy.

---

# 97. Manual Sync

Пользователь должен иметь возможность инициировать синхронизацию вручную.

Например:

Settings

 ↓

Sync now

Это полезно для:

- диагностики;
- миграции устройства;
- проверки соединения.

---

# 98. Sync Diagnostics

В будущем можно предоставить:

Last successful sync

Pending changes

Failed changes

Device

Server status

Это значительно упростит поддержку.

---

# 99. Sync Logs

Технические логи должны помогать определить:

что произошло

но не должны без необходимости содержать пользовательский контент.

---

# 100. Architectural Principles

Для Synchronization Architecture LifeOS принимаются следующие правила:

1. LifeOS использует Local-first архитектуру.
2. Каждое устройство имеет локальную базу.
3. Основные операции не зависят от сети.
4. Sync работает преимущественно в фоне.
5. Local DB обновляется до завершения сетевой синхронизации.
6. Изменения помещаются в локальную Sync Queue.
7. Изменения имеют уникальные идентификаторы.
8. Устройства имеют уникальные Device ID.
9. Сущности имеют глобально уникальные Entity ID.
10. Sync должен поддерживать retry.
11. Sync должен быть idempotent.
12. Sync должен поддерживать incremental synchronization.
13. Конфликты должны обнаруживаться явно.
14. Конфликты не должны автоматически решаться одним правилом для всех типов данных.
15. Важные конфликты могут требовать участия пользователя.
16. Удаления должны учитывать tombstones/lifecycle.
17. Sync не является Backup.
18. Search Index не является основной синхронизируемой сущностью.
19. Embeddings не являются обязательной синхронизируемой сущностью.
20. AI-generated данные синхронизируются как обычные данные после подтверждения/валидации.
21. Sync Backend не должен содержать бизнес-логику LifeOS без необходимости.
22. Sync должен быть устойчив к offline периодам.
23. Sync должен безопасно восстанавливаться после crash.
24. Локальные данные не должны удаляться из-за ошибки Sync.
25. Security и encryption будут определены отдельным ADR.
26. Collaboration не входит в MVP.
27. CRDT не фиксируется для MVP.
28. Sync Protocol должен иметь versioning.
29. Database schema и Sync Protocol должны иметь независимое versioning.
30. Архитектура должна позволять будущий Self-hosted Sync.

---

# 101. Последствия решения

## Положительные

- полноценный offline режим;
- быстрая работа UI;
- независимость от сети;
- возможность нескольких устройств;
- возможность масштабирования;
- возможность будущего mobile;
- возможность Self-hosted;
- более высокий контроль пользователя над данными.

## Отрицательные

- значительно сложнее архитектура;
- необходимо решать конфликты;
- требуется Sync Queue;
- требуется дополнительная инфраструктура;
- сложнее тестирование;
- необходимо продумывать миграции;
- появляются требования к серверу;
- безопасность становится отдельной сложной задачей.

---

# 102. Что пока не фиксируем

Не фиксируем окончательно:

- конкретную Sync Backend технологию;
- конкретную database server;
- конкретный API protocol;
- CRDT;
- E2EE;
- self-hosted deployment;
- P2P;
- collaboration;
- file synchronization implementation.

Эти решения будут приняты после определения MVP и Security Architecture.

---

# 103. Следующие ADR

После ADR-0009:

ADR-0010:  
Security Architecture

ADR-0011:  
Backup and Export Architecture

ADR-0012:  
Search Architecture

В дальнейшем:

ADR-0013:  
AI Context Engine

ADR-0014:  
AI Tool Calling

ADR-0015:  
Semantic Search / Embeddings

ADR-0016:  
Sync Protocol

---

# Итог

LifeOS использует:

Local-first

+

Offline-first

+

Background Synchronization

Основная модель:

                 User
                   │
          ┌────────┴────────┐
          ↓                 ↓
      Desktop             Mobile
          │                 │
      Local DB          Local DB
          │                 │
          └────────┬────────┘
                   ↓
              Sync Backend

Пользователь работает прежде всего с локальными данными.

Синхронизация передаёт изменения между устройствами и не должна блокировать основную работу приложения.

Главный принцип:

> **Синхронизация должна соединять устройства, а не становиться условием работы LifeOS.**

  

### Что мы сейчас зафиксировали

  

У нас постепенно складывается довольно цельная архитектура:

  

```text

                    LIFEOS
                       │
          ┌────────────┴────────────┐
          │                         │
       Local-first              AI Layer
          │                         │
       Local DB               Context Engine
          │                         │
          │                    AI Provider
          │                         │
          └──────────┬──────────────┘
                     │
                  Sync
                     │
              Sync Backend
                     │
          ┌──────────┴──────────┐
          ↓                     ↓
       Desktop                Mobile

И здесь есть **одна очень важная мысль**: мы пока намеренно **не выбираем конкретный сервер синхронизации**. Не надо сейчас преждевременно привязывать LifeOS к Firebase, Supabase, собственному серверу или чему-то ещё.

Сначала определяем **правила системы**, затем выбираем технологию, которая этим правилам лучше всего соответствует.