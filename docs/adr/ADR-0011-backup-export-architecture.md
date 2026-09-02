# ADR-0011: Backup and Export Architecture

 ```text
 
**Статус:** Предварительно принято  

**Дата:** 2026-08-16  

**Версия:** 0.1

  

## 1. Контекст

LifeOS является Local-first системой.

Основная рабочая копия пользовательских данных находится на устройстве.

В будущем LifeOS может работать одновременно на нескольких устройствах:

```text

Desktop

Laptop

Mobile

Tablet

При этом Sync и Backup решают разные задачи.

### Sync

Sync предназначен для:

> поддержания нескольких экземпляров LifeOS в актуальном состоянии.

### Backup

Backup предназначен для:

> восстановления данных после потери, повреждения или удаления основной рабочей копии.

### Export

Export предназначен для:

> предоставления пользователю возможности забрать свои данные из LifeOS в независимом формате.

Поэтому Backup и Export не должны быть побочным эффектом Sync.

 ``` 

---

# 2. Основное решение

LifeOS использует три независимых механизма:

```
                    LifeOS
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
         Sync        Backup       Export
          │            │            │
      устройства    recovery     portability
```

Каждый механизм имеет собственную ответственность.

---

# 3. Sync ≠ Backup

Sync не считается полноценным Backup.

Например:

```
User
 ↓
Delete important data
 ↓
Sync
 ↓
Deletion propagated
```

Если Sync является единственной копией данных, удаление может распространиться на все устройства.

Поэтому Backup должен иметь независимую историю хранения.

---

# 4. Backup ≠ Export

Backup и Export также имеют разные цели.

### Backup

Оптимизирован для:

- полного восстановления;
- сохранения внутреннего состояния;
- сохранения metadata;
- сохранения relationships;
- сохранения системной информации.

### Export

Оптимизирован для:

- переносимости;
- чтения человеком;
- миграции;
- независимости от LifeOS.

---

# 5. Основная модель

Архитектура:

```
                 LifeOS
                    │
        ┌───────────┼───────────┐
        ↓           ↓           ↓
      Local        Sync       Export
       Data          │
        │            │
        ↓            ↓
      Backup      Devices
```

Backup создаётся из локального состояния или из специально подготовленного snapshot.

---

# 6. Backup Types

В будущем могут поддерживаться:

Full Backup

Incremental Backup

Snapshot

Automatic Backup

Manual Backup

На первом этапе предпочтительно начать с:

Full Backup

+

Manual Backup

После стабилизации архитектуры добавить:

Automatic Backup

---

# 7. Full Backup

Full Backup содержит всё необходимое для восстановления LifeOS.

Концептуально:

Full Backup
│
├── Entities
├── Relationships
├── Metadata
├── Lifecycle
├── Settings
├── Files metadata
├── Search metadata
└── Version information

Необязательно хранить все производные данные.

Например, search index или embeddings могут быть пересозданы.

---

# 8. Source of Truth

Основным источником истины считается:

Local Domain Data

а не:

Search Index

Cache

Embeddings

AI Context Cache

Это важно для восстановления.

---

# 9. Rebuildable Data

Некоторые данные могут быть восстановлены из основного состояния.

Например:

Database

   ↓

Rebuild

   ├── Search Index

   ├── Embeddings

   └── Caches

Это уменьшает размер Backup.

---

# 10. Backup Manifest

Каждый Backup должен иметь manifest.

Например:

backup/

├── manifest

├── database

├── files/

└── metadata/

Manifest может содержать:

- backup_id;
- LifeOS version;
- schema version;
- creation time;
- device information;
- backup format version;
- checksums;
- feature compatibility.

---

# 11. Backup Versioning

Формат Backup должен иметь собственную версию.

Например:

Backup Format

v1

v2

v3

Версия приложения:

LifeOS

v0.1

v0.2

v1.0

не должна автоматически означать версию Backup Format.

---

# 12. Schema Version

Database schema также должна иметь собственную версию.

Например:

Application Version

        │

        ├── Backup Format Version

        │

        └── Database Schema Version

Это позволит выполнять migrations при восстановлении.

---

# 13. Backup Integrity

Backup должен проверяться на целостность.

Концептуально:

Create Backup

      ↓

Calculate Checksums

      ↓

Store

      ↓

Verify

При восстановлении:

Backup

 ↓

Integrity Check

 ↓

Restore

---

# 14. Backup Encryption

Backup может содержать практически всю пользовательскую информацию.

Поэтому Backup должен поддерживать шифрование.

Архитектурно:

User Data

    ↓

Encryption

    ↓

Backup

Конкретный encryption algorithm и key management определяются отдельным ADR.

---

# 15. Password-protected Backup

В будущем пользователь может создавать Backup с отдельным паролем или ключом.

Например:

Create Backup

      ↓

Encryption

      ↓

User-defined protection

      ↓

Backup file

Важно не смешивать этот механизм с authentication аккаунта без необходимости.

---

# 16. Backup Storage

Backup может храниться:

### Local

Computer

 ↓

External Drive

 ↓

Backup

### Cloud

LifeOS

 ↓

Encrypted Backup

 ↓

Cloud Storage

### Self-hosted

LifeOS

 ↓

Encrypted Backup

 ↓

User-controlled Server

---

# 17. Provider Independence

Backup Architecture не должна зависеть от конкретного cloud provider.

Не следует проектировать:

LifeOS

 ↓

Provider X

как единственный вариант.

Предпочтительно:

Backup Service

      │

 ┌────┼─────┬────────┐

 ↓    ↓     ↓        ↓

Local Cloud Self-hosted Future

---

# 18. Automatic Backup

В будущем LifeOS может выполнять автоматические Backup.

Например:

Every day

Every week

After major changes

Before migration

Before destructive operation

Пользователь должен иметь возможность настроить policy.

---

# 19. Backup Retention

Необходимо предусмотреть retention policy.

Например:

Latest

Daily

Weekly

Monthly

Но конкретная policy будет определена позже.

---

# 20. Backup Rotation

При автоматических Backup количество файлов может быстро расти.

Поэтому потребуется rotation:

New Backup

   ↓

Retention Policy

   ↓

Delete expired backups

Удаление старых Backup должно быть предсказуемым.

---

# 21. Backup Before Migration

Перед потенциально опасной migration рекомендуется создавать Backup.

Например:

Update

 ↓

Schema Migration

может выполняться как:

Create Backup

 ↓

Migration

 ↓

Validation

 ↓

Success

---

# 22. Backup Before Destructive Operations

Перед массовым удалением или крупным изменением данных в будущем можно создавать snapshot.

Например:

User requests destructive action

          ↓

Create Snapshot

          ↓

Confirm

          ↓

Execute

---

# 23. Restore

Restore должен быть отдельным процессом.

Backup

 ↓

Validate

 ↓

Compatibility Check

 ↓

Migration if necessary

 ↓

Restore

 ↓

Integrity Check

 ↓

Start LifeOS

---

# 24. Restore Safety

Restore не должен автоматически уничтожать текущую рабочую копию.

Предпочтительный процесс:

Current Data

     ↓

Safety Backup

     ↓

Restore Backup

Это позволяет вернуться назад при ошибке.

---

# 25. Restore Preview

В будущем пользователь должен иметь возможность увидеть:

- дату Backup;
- LifeOS version;
- количество entities;
- количество relationships;
- количество files;
- размер;
- совместимость.

Например:

Backup:

2026-08-16

  

Entities:

12 842

  

Relationships:

35 901

  

Files:

218

  

Status:

Compatible

---

# 26. Partial Restore

В будущем может быть полезен partial restore.

Например:

Restore

 ├── Everything

 ├── Projects

 ├── Notes

 ├── Tasks

 └── Files

Однако partial restore усложняет relationships.

Поэтому это не входит в MVP.

---

# 27. Export

Export должен быть отдельным пользовательским механизмом.

Основной принцип:

> Пользователь не должен быть заперт внутри LifeOS.

---

# 28. Export Formats

Возможные форматы:

JSON

Markdown

CSV

HTML

ZIP

На первом этапе рекомендуется:

JSON

+

Markdown

+

ZIP

---

# 29. JSON Export

JSON подходит для:

- machine-readable данных;
- миграций;
- резервного экспорта;
- интеграций.

Пример:

{

  "entity_id": "123",

  "type": "task",

  "title": "Подготовить проект",

  "status": "active"

}

---

# 30. Markdown Export

Markdown подходит для:

- заметок;
- чтения человеком;
- Obsidian;
- Git;
- долгосрочной переносимости.

Например:

export/

├── notes/

├── projects/

├── tasks/

└── README.md

---

# 31. CSV Export

CSV может использоваться для табличных данных.

Например:

tasks.csv

projects.csv

contacts.csv

Но CSV плохо подходит для сложных relationships.

Поэтому CSV не является основным универсальным форматом.

---

# 32. Export with Relationships

Export должен сохранять relationships настолько, насколько это возможно.

Например:

Project A

   │

   ├── Task 1

   ├── Task 2

   └── Note 1

не должен превращаться в набор несвязанных файлов без возможности восстановить связи.

---

# 33. Portable Export

Желательно иметь формат:

LifeOS Export

который не зависит от конкретной database.

Например:

lifeos-export/

├── manifest.json

├── entities/

├── relationships/

├── files/

└── README.md

---

# 34. Export Manifest

Manifest должен содержать:

- export format version;
- LifeOS version;
- creation date;
- schema version;
- entity count;
- relationship count;
- file count.

---

# 35. Export and Privacy

Export может содержать большое количество чувствительных данных.

Поэтому перед Export пользователь должен понимать:

What is being exported?

Where is it going?

---

# 36. Export Scope

В будущем пользователь сможет выбирать:

Export Everything

Export Selected Projects

Export Notes

Export Tasks

Export Files

На первом этапе достаточно:

Export Everything

---

# 37. Export Destination

Экспорт может быть сохранён:

Local filesystem

В будущем:

Cloud

External storage

Self-hosted storage

---

# 38. Export Does Not Require Cloud

Export должен работать полностью offline.

Local Data

 ↓

Export

 ↓

File

Наличие аккаунта или Sync не должно быть обязательным.

---

# 39. Backup Does Not Require Sync

Пользователь должен иметь возможность создать Backup:

Offline

без подключения к серверу.

---

# 40. Backup and Files

Если LifeOS содержит файлы:

Entity

 ↓

File

Backup должен иметь возможность включать эти файлы.

Например:

backup/

├── database

├── manifest

└── files/

---

# 41. Large Files

Большие файлы могут значительно увеличивать Backup.

Поэтому в будущем можно предусмотреть:

Database Backup

+

File Backup

как отдельные компоненты.

---

# 42. Deduplication

В будущем Backup может использовать deduplication.

Например:

File A

File A

File A

не обязательно хранить три раза.

Но это не входит в MVP.

---

# 43. Compression

Backup и Export могут использовать compression.

Например:

LifeOS Data

 ↓

Compression

 ↓

Encryption

 ↓

Backup

Порядок encryption/compression должен быть определён при реализации.

---

# 44. Backup Metadata

Backup может содержать:

Creation Date

Device

Application Version

Schema Version

Backup Version

Checksum

Но не должен содержать лишнюю диагностическую информацию.

---

# 45. Device-specific Data

Не все данные являются переносимыми.

Например:

Window Position

OS-specific Settings

Device ID

Local Cache

могут не переноситься на другое устройство.

Поэтому Backup должен разделять:

Portable Data

Device-specific Data

Rebuildable Data

---

# 46. Portable Data

Portable:

Entities

Relationships

Notes

Tasks

Projects

Goals

Files

User Preferences

---

# 47. Device-specific Data

Potentially device-specific:

Window Size

Window Position

Local Notifications

Device Credentials

OS Integration Settings

Local Cache

---

# 48. Rebuildable Data

Potentially rebuildable:

Search Index

Embeddings

AI Cache

Temporary Files

---

# 49. Backup Categories

Итоговая модель:

                 Backup

                   │

       ┌───────────┼───────────┐

       ↓           ↓           ↓

   Portable    Device      Rebuildable

     Data       Data          Data

---

# 50. Migration

Backup должен потенциально использоваться для миграции между версиями LifeOS.

Например:

LifeOS v1

   ↓

Backup

   ↓

LifeOS v2

   ↓

Migration

---

# 51. Cross-platform Restore

В будущем пользователь должен иметь возможность:

Windows

   ↓

Backup

   ↓

macOS

или:

Desktop

   ↓

Backup

   ↓

Mobile

если формат данных и функциональность позволяют.

---

# 52. Platform Compatibility

Restore должен проверять:

OS

App Version

Schema Version

Backup Version

Feature Compatibility

---

# 53. Export for Obsidian

Markdown Export особенно интересен из-за совместимости с системами заметок.

В будущем возможен экспорт:

LifeOS

 ↓

Markdown

 ↓

Obsidian

При этом необходимо отдельно решить:

- как экспортировать relationships;
- как представлять metadata;
- как экспортировать tags;
- как сохранять links.

Это будет отдельной частью Export Specification.

---

# 54. Export for Migration

Portable Export должен потенциально позволять:

LifeOS

 ↓

Portable Export

 ↓

Future Application

даже если LifeOS больше не используется.

---

# 55. Open Format Principle

По возможности Export должен использовать открытые и распространённые форматы.

Предпочтение:

JSON

Markdown

CSV

ZIP

а не proprietary format без необходимости.

---

# 56. User Ownership

Пользователь должен иметь возможность:

- создавать Backup;
- создавать Export;
- хранить его самостоятельно;
- переносить его;
- удалять его;
- восстанавливать его.

---

# 57. No Vendor Lock-in

Пользователь не должен зависеть от:

LifeOS Cloud

для доступа к собственным данным.

---

# 58. Backup Security

Backup должен следовать Security Architecture из ADR-0010.

В частности:

- encryption;
- integrity checks;
- secure storage;
- minimal metadata;
- no secrets in logs.

---

# 59. Backup Authentication

Доступ к облачному Backup в будущем должен требовать authentication.

Однако локальный Backup должен быть доступен пользователю независимо от наличия online account.

---

# 60. Backup Integrity

Для каждого Backup необходимо иметь механизм проверки:

Backup

 ↓

Checksum / Integrity Verification

 ↓

Valid / Invalid

---

# 61. Corrupted Backup

Если Backup повреждён:

Backup

 ↓

Integrity Check

 ↓

FAILED

LifeOS не должен выполнять частичное восстановление молча.

Пользователь должен получить понятное сообщение.

---

# 62. Backup Verification

В будущем автоматические Backup желательно проверять после создания.

Create

 ↓

Verify

 ↓

Mark as valid

---

# 63. Backup Testing

Backup считается ненадёжным, если его невозможно восстановить.

Поэтому должна существовать регулярная проверка:

Backup

 ↓

Test Restore

 ↓

Validate

В production эта процедура может выполняться автоматически для выбранных Backup.

---

# 64. Recovery Point

В будущем Backup policy должна учитывать:

RPO — Recovery Point Objective

То есть:

> сколько данных пользователь готов потерять в худшем случае.

Например:

RPO = 24h

означает потенциальную потерю до суток изменений.

Конкретные значения будут определены позже.

---

# 65. Recovery Time

Также существует:

RTO — Recovery Time Objective

То есть:

> сколько времени допустимо потратить на восстановление.

Например:

RTO = 30 min

Конкретные требования будут определены после появления реального MVP.

---

# 66. Backup Policy

В будущем пользователь сможет выбрать:

```
Backup
 ├── Manual
 ├── Daily
 ├── Weekly
 └── Custom
```

---

# 67. Storage Quota

Cloud Backup может иметь ограничение:

Storage Limit

При достижении лимита должна применяться retention policy.

---

# 68. Backup Failure

Если автоматический Backup не удался:

Backup Failed

это не должно приводить к потере локальных данных.

Пользователь должен быть уведомлён.

---

# 69. Offline Backup Queue

Если Backup destination временно недоступен:

```
Create Backup
 ↓
Local Backup
 ↓
Queue Upload
 ↓
Network Available
 ↓
Upload
```

---

# 70. Backup and Sync Independence

Backup upload не должен блокировать обычную работу Sync.

```
Sync
   │
   └── independent

  Backup
   │
   └── independent
```

---

# 71. Export Independence

Export также не должен зависеть от Sync.

```
Local Data
   ↓
Export
```

---

# 72. Backup Lifecycle

Backup должен иметь lifecycle:
```

Created
   ↓
Verified
   ↓
Stored
   ↓
Retained
   ↓
Expired
   ↓
Deleted
```

---

# 73. Export Lifecycle

Export проще:
```

Requested
   ↓
Generated
   ↓
Saved
   ↓
User manages file
```

---

# 74. Backup Naming

Backup должен иметь предсказуемое имя.

Например:

lifeos-backup-2026-08-16-1200.lifeos

Конкретный extension может быть выбран позднее.

---

# 75. Export Naming

Например:

lifeos-export-2026-08-16.zip

---

# 76. Backup Format

На архитектурном уровне формат должен быть контейнером:

Container

├── Manifest
├── Data
├── Files
└── Metadata

Конкретная serialization технология будет определена позже.

---

# 77. Restore Into Existing Installation

Пользователь может выбрать:

Restore into current LifeOS

Перед этим необходимо:

Current Data
 ↓
Safety Backup

---

# 78. Restore Into New Installation

Поддерживается сценарий:

Install LifeOS
 ↓
Restore Backup
 ↓
Continue

---

# 79. Export Import

В будущем Export должен потенциально использоваться обратно:

Export
 ↓
Import
 ↓
LifeOS

Это особенно важно для миграции.

---

# 80. Import Validation

Import должен проходить:

Parse
 ↓
Validate
 ↓
Normalize
 ↓
Resolve Relationships
 ↓
Import

---

# 81. Import Conflicts

Если импорт содержит существующие entities:

Existing Entity

+

Imported Entity

необходимо определить:

Skip

Merge

Replace

Create Duplicate

Эта политика будет определена отдельным документом.

---

# 82. Backup vs Snapshot

Snapshot может быть временной точкой восстановления:

Before Update

Before Migration

Before Mass Delete

Snapshot не обязательно должен иметь такую же retention policy, как Backup.

---

# 83. Local Snapshots

На Desktop можно потенциально поддерживать:

Recent Snapshots

для быстрого Undo/recovery.

---

# 84. Security Boundary

Backup files должны считаться чувствительными данными.

Например:

Backup

 ≈

Copy of user's LifeOS

Поэтому нельзя автоматически отправлять Backup сторонним сервисам.

---

# 85. AI Data in Backup

Если AI Context или AI-generated data являются частью пользовательских данных, они могут быть включены в Backup.

Но временные AI cache данные могут быть исключены.

---

# 86. Embeddings in Backup

Embeddings могут быть исключены, если они могут быть полностью восстановлены.

Backup
 ↓
Core Data
 ↓
Rebuild Embeddings

Это уменьшает размер Backup.

---

# 87. Search Index in Backup

Search Index также желательно пересоздавать после Restore.

Restore Database
 ↓
Rebuild Search Index

---

# 88. Cache

Cache не является обязательной частью Backup.

Cache
 ↓
Exclude

---

# 89. Temporary Data

Temporary files и temporary processing data не должны входить в Backup без необходимости.

---

# 90. Backup Size

Размер Backup должен быть отображён пользователю перед сохранением/загрузкой.

Например:

Estimated backup size:

2.4 GB

---

# 91. Progress

Для больших Backup и Export должен отображаться progress:

Preparing...

██████████░░░░ 68%

  
Compressing...

Uploading...

Verifying...

---

# 92. Cancellation

Пользователь должен иметь возможность отменить длительную операцию.

Например:

Export
 ↓
Cancel

При отмене незавершённый файл не должен считаться валидным Export.

---

# 93. Atomicity

Backup должен создаваться атомарно насколько это возможно.

Не должно происходить:

backup.lifeos

который выглядит завершённым, но содержит только половину данных.

Предпочтительный процесс:

Create temporary file
 ↓
Write
 ↓
Verify
 ↓
Rename to final Backup

---

# 94. Crash Safety

Если LifeOS завершится во время Backup:

Application Crash

незавершённый Backup не должен заменять валидный.

---

# 95. Export Crash Safety

Аналогично:

Export
 ↓
Crash

не должен создавать файл, который пользователь примет за полный Export.

---

# 96. Data Ownership

LifeOS должен исходить из принципа:

> Пользователь должен иметь возможность покинуть систему без потери своих данных.

---

# 97. Future Cloud Backup

В будущем возможно:

Encrypted Backup
        ↓
Cloud Storage
        ↓
Multiple Devices

Но Cloud Backup не должен становиться обязательным для работы приложения.

---

# 98. Future Self-hosted Backup

Архитектура должна позволять:

LifeOS
 ↓
User's Server

без полной переделки Backup subsystem.

---

# 99. Backup API

Внутренне можно определить abstraction:

BackupService

например:

createBackup()
restoreBackup()
verifyBackup()
deleteBackup()
listBackups()

Конкретный API будет определён на этапе технического проектирования.

---

# 100. Export API

Аналогично:

ExportService

может предоставлять:

exportAll()
exportSelected()
estimateSize()

---

# 101. Architecture

Итоговая архитектура:
                    LifeOS
                       │
               Domain Data
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
        Sync         Backup       Export
          │            │            │
          ↓            ↓            ↓
       Devices      Recovery    Portability

---

# 102. Принципы

Для Backup и Export принимаются:

1. Sync не является Backup.
2. Backup не является Export.
3. Export не должен зависеть от Cloud.
4. Backup не должен зависеть от Sync.
5. Backup должен быть проверяемым.
6. Backup должен иметь версию.
7. Backup должен поддерживать encryption.
8. Backup должен иметь integrity checks.
9. Restore не должен молча уничтожать текущие данные.
10. Перед опасным Restore может создаваться Safety Backup.
11. Search Index является rebuildable data.
12. Embeddings являются потенциально rebuildable data.
13. Cache не является обязательной частью Backup.
14. Пользователь должен владеть своими данными.
15. Export должен использовать открытые форматы.
16. Архитектура не должна зависеть от одного cloud provider.
17. Backup должен работать offline.
18. Export должен работать offline.
19. Backup должен быть пригоден для миграции между версиями.
20. Архитектура должна допускать Self-hosted Backup.
21. Backup и Export должны учитывать relationships.
22. Backup должен поддерживать future encryption/key management.
23. Автоматические Backup не должны блокировать обычную работу приложения.
24. Незавершённый Backup не должен считаться валидным.
25. Незавершённый Export не должен считаться валидным.
26. Пользователь должен иметь возможность отменить длительную операцию.
27. Backup и Export должны учитывать безопасность из ADR-0010.

---

# 103. Что не фиксируется этим ADR

Данный документ не определяет конкретно:

- формат базы данных;
- serialization library;
- encryption algorithm;
- key management;
- cloud provider;
- storage provider;
- backup file extension;
- compression algorithm;
- exact retention policy;
- exact RPO;
- exact RTO;
- import conflict resolution;
- authentication provider.

Эти решения будут определены отдельными ADR или техническими спецификациями.

---

# 104. Последствия решения

## Положительные

- пользовательские данные не зависят от Sync;
- существует путь восстановления;
- пользователь может экспортировать свои данные;
- снижается vendor lock-in;
- появляется возможность миграции;
- сохраняется Local-first модель;
- возможен Self-hosted Backup;
- Backup может быть зашифрован;
- производные данные можно пересоздавать;
- архитектура подходит для долгосрочного проекта.

## Отрицательные

- появляется дополнительная подсистема;
- требуется versioning;
- требуется integrity verification;
- Restore достаточно сложен;
- необходимо проектировать migration;
- Backup больших файлов может занимать много места;
- encryption и key management усложняют систему;
- автоматические Backup потребуют retention policy.

---

# 105. Следующие документы

После ADR-0011 предлагается перейти к:

ADR-0012:  
Search Architecture

ADR-0013:  
AI Context Engine

ADR-0014:  
AI Tool Calling and Permissions

ADR-0015:  
Semantic Search and Embeddings

ADR-0016:  
Sync Protocol

ADR-0017:  
Authentication Architecture

ADR-0018:  
Encryption and Key Management

После этого необходимо перейти к проектированию Domain Model LifeOS.

### Что мы зафиксировали

Самая важная вещь здесь — **мы не делаем Backup частью Sync**.

Получается три независимые системы:

```text
                    LIFEOS
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
        SYNC         BACKUP       EXPORT
          │            │            │
     устройства     восстановление   свобода

И это даст нам очень полезную возможность в будущем: **если Sync-сервер сломается, аккаунт будет заблокирован или вообще появится другой способ синхронизации — пользователь всё равно имеет локальные данные и независимый Backup.**