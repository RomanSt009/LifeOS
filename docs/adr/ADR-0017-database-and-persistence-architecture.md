# ADR-0017: Database and Persistence Architecture

  

**Статус:** Предварительно принято  

**Дата:** 2026-08-18  

**Версия:** 0.1

  

## 1. Контекст

  

LifeOS является local-first приложением.

  

Основные данные пользователя должны:

  

- храниться локально;

- быть доступны без подключения к интернету;

- сохраняться независимо от AI Provider;

- сохраняться независимо от Sync Provider;

- поддерживать работу на desktop и mobile;

- обеспечивать целостность Domain State;

- позволять масштабировать приложение без полной замены persistence layer.

  

В ADR-0016 была определена Domain Model:

  

```text

Entity

Relationship

Context

Lifecycle

Domain Events

Теперь необходимо определить физическую архитектуру хранения этих данных.
```
---

# 2. Основное решение

В качестве основной локальной базы данных LifeOS предварительно выбирается:

**SQLite**

SQLite используется как локальное persistent storage для Domain State.

Flutter Application

        |

        ↓

Application Layer

        |

        ↓

Repository Interfaces

        |

        ↓

Persistence Layer

        |

        ↓

SQLite

---

# 3. Почему SQLite

SQLite подходит для LifeOS по нескольким причинам:

- локальная работа;
- отсутствие отдельного database server;
- зрелая технология;
- транзакции;
- индексы;
- foreign keys;
- хорошая производительность;
- поддержка desktop;
- поддержка mobile;
- компактность;
- удобство backup;
- возможность работы offline.

---

# 4. SQLite как локальный Source of Truth

Для локального устройства:

SQLite Domain State

        ↓

Source of Truth

Производные данные:

Embeddings

Search Index

Caches

AI Summaries

не являются основным источником истины.

---

# 5. Domain State

К основному Domain State относятся:

- Entities;
- Relationships;
- Lifecycle State;
- Entity metadata;
- необходимые версии;
- данные, необходимые для восстановления приложения.

---

# 6. Derived State

Производными являются:

- embeddings;
- semantic search index;
- caches;
- temporary AI context;
- некоторые AI-generated summaries;
- UI-specific caches.

Производные данные должны иметь возможность быть пересозданными.

---

# 7. Общая структура хранения

Концептуально:

LifeOS Storage

│

├── Domain Database

│   ├── entities

│   ├── relationships

│   ├── lifecycle

│   └── metadata

│

├── Search Index

│

├── Embedding Index

│

├── Files

│

└── Temporary Data

---

# 8. Domain Database

Основная SQLite database содержит Domain State.

Предварительно:

lifeos.db

Имя файла и физический путь могут быть изменены при реализации.

---

# 9. Не хранить всё в одной таблице

Не следует создавать универсальную таблицу:

entities

├── field1

├── field2

├── field3

├── field4

└── ...

для всех типов Entity.

Domain semantics должны сохраняться.

---

# 10. Гибридная модель хранения

Для LifeOS предлагается гибрид:

Common Entity Metadata

        +

Typed Entity Data

        +

Relationships

Например:

Entity

   |

   ├── common metadata

   |

   └── Task-specific data

---

# 11. Common Metadata

Общие технические поля могут включать:

id

entity_type

created_at

updated_at

version

lifecycle_state

source

---

# 12. Typed Data

Типизированные данные хранятся отдельно от общего metadata.

Например:

Task

├── entity metadata

└── task data

---

# 13. Relationships Table

Relationships являются отдельной структурой.

Концептуально:

relationships

├── id

├── source_entity_id

├── target_entity_id

├── relationship_type

├── status

├── created_at

├── updated_at

└── metadata

---

# 14. Referential Integrity

SQLite foreign keys должны использоваться там, где это необходимо.

Например:

Relationship

      |

      ├── source_entity

      └── target_entity

не должна ссылаться на несуществующую Entity.

---

# 15. Transactions

Критические изменения Domain State должны выполняться транзакционно.

Например:

Create Task

+

Create Relationship

может быть одной транзакцией.

---

# 16. Atomicity

Если часть операции не выполнена:

Create Entity ✓

Create Relationship ✗

система не должна оставаться в неконсистентном состоянии, если операция определена как атомарная.

---

# 17. Repository Pattern

Domain/Application Layer не должен напрямую обращаться к SQLite.

Используется Repository abstraction.

Application

     ↓

Repository Interface

     ↓

SQLite Repository

     ↓

SQLite

---

# 18. Repository Responsibility

Repository отвечает за:

- чтение;
- сохранение;
- обновление;
- удаление;
- транзакции persistence;
- запросы;
- mapping между storage и domain.

Repository не должен содержать всю бизнес-логику приложения.

---

# 19. Domain Mapping

Persistence Layer выполняет преобразование:

Database Row

      ↓

Persistence Model

      ↓

Domain Entity

и обратно:

Domain Entity

      ↓

Persistence Model

      ↓

Database Row

---

# 20. Domain Model Independence

Domain Entity не должна напрямую наследоваться от SQLite-specific classes.

Нежелательно:

Task extends SQLiteModel

Предпочтительно:

Task

  ↑

Repository Mapper

  ↓

SQLite Model

---

# # 21. Migration

Database Schema должна поддерживать миграции.

Например:

Schema v1

   ↓

Migration

   ↓

Schema v2

---

# 22. Migration Version

SQLite database должна иметь версию схемы.

Например:

schema_version = 3

---

# 23. Forward Migration

При обновлении приложения:

Old Database

      ↓

Migration

      ↓

New Database

пользовательские данные должны сохраняться.

---

# 24. Migration Safety

Migration должна быть:

- контролируемой;
- тестируемой;
- повторяемой;
- versioned.

---

# 25. Failed Migration

Если migration не может завершиться корректно, приложение не должно молча уничтожать пользовательские данные.

Перед рискованными миграциями должна существовать стратегия восстановления.

---

# 26. Backup Before Migration

Для потенциально destructive migrations рекомендуется:

Backup

   ↓

Migration

   ↓

Validation

---

# 27. Database Corruption

LifeOS должен предусматривать сценарий повреждения SQLite database.

Основной принцип:

Corrupted Database

       ↓

Detection

       ↓

Recovery / Restore

---

# 28. Database Integrity

SQLite integrity checks могут использоваться для диагностики.

Например концептуально:

Database Integrity Check

        ↓

OK / FAILED

Конкретный механизм определяется реализацией.

---

# 29. Database Locking

SQLite поддерживает concurrency, но приложение должно контролировать конкурентный доступ.

Особенно:

- background jobs;
- AI processing;
- sync;
- indexing.

---

# 30. Single Persistence Boundary

Application не должна создавать большое количество независимых SQLite connections без необходимости.

Persistence Layer контролирует доступ к database.

---

# 31. Async Operations

Database operations не должны блокировать UI thread.

Flutter UI

    |

    ↓

Async Repository

    |

    ↓

SQLite

---

# 32. Background Work

Следующие операции могут выполняться background:

- indexing;
- embedding generation;
- migrations;
- cleanup;
- sync;
- large imports;
- exports.

---

# 33. Entity Versioning

Entity содержит version.

Например:

Entity

version = 12

Version может использоваться для:

- optimistic concurrency;
- Sync;
- conflict detection;
- audit.

---

# 34. Updated Timestamp

Entity должна иметь:

created_at

updated_at

Для timestamp следует использовать единый формат времени.

---

# 35. UTC

Внутреннее хранение timestamp рекомендуется выполнять в UTC.

UI может преобразовывать время в локальный timezone пользователя.

Database

   ↓

UTC

  

UI

   ↓

Local Time

---

# 36. IDs

Entity IDs должны быть стабильными и уникальными.

Предпочтение отдаётся ID, которые можно безопасно создавать offline.

Например:

UUID

ULID

Конкретный формат будет определён в implementation stage.

---

# 37. Offline ID Generation

Создание Entity не должно требовать обращения к серверу только для получения ID.

Offline

   ↓

Generate ID

   ↓

Create Entity

---

# 38. Sync Compatibility

Persistence Architecture должна быть совместима с будущей Sync Architecture.

Например:

Entity ID

Version

Updated At

Lifecycle

должны позволять определить изменения.

---

# 39. Change Tracking

Для Sync и background processing необходимо иметь возможность определить изменённые Entity.

Возможные механизмы:

updated_at

version

change log

domain events

Конкретная реализация будет определена в Sync Architecture.

---

# 40. Change Log

В будущем может использоваться отдельный change log:

change_log

├── id

├── entity_id

├── operation

├── version

└── timestamp

Это не обязательно для первого MVP.

---

# 41. Domain Events

Domain Events могут использоваться для запуска производных операций.

Например:

EntityUpdated

      |

      ├── Search Index

      ├── Embedding

      └── Sync

---

# 42. Event Persistence

Не все Domain Events должны храниться постоянно.

Система должна различать:

Transient Event

Persistent Event

---

# 43. Outbox Pattern

Для надёжной передачи изменений внешним системам в будущем может использоваться Outbox Pattern.

Например:

Transaction

   |

   ├── Update Entity

   └── Create Outbox Event

После успешной транзакции:

Outbox

   ↓

Sync / Worker

---

# 44. Outbox не обязателен для MVP

На первом этапе достаточно определить архитектурную возможность.

Реализация Outbox будет зависеть от Sync Architecture.

---

# 45. Files

Большие бинарные данные не рекомендуется хранить непосредственно внутри основной Entity таблицы.

Например:

- изображения;
- PDF;
- видео;
- аудио;
- большие документы.

Предпочтительно:

Entity

   ↓

File Reference

   ↓

Local File Storage

---

# 46. File Reference

Например:

Document

├── id

├── title

└── content_reference

---

# 47. File Storage

Файлы могут находиться в отдельном storage:

LifeOS Data

├── lifeos.db

├── files/

├── search/

└── embeddings/

Физическая структура может измениться.

---

# 48. Database vs File Storage

Основное правило:

Structured Data → SQLite

Large Binary Data → File Storage

---

# 49. File Metadata

Для файлов необходимо хранить metadata:

file_id

entity_id

path/reference

mime_type

size

created_at

updated_at

hash

---

# 50. Content Hash

File hash может использоваться для:

- проверки целостности;
- дедупликации;
- Sync;
- определения изменений.

---

# 51. Search Index

Search Index является производным storage.

SQLite Domain State

       ↓

Search Index

Если Search Index потерян:

Rebuild

---

# 52. Embedding Index

Embeddings также являются производными.

Domain State

      ↓

Embedding Generation

      ↓

Embedding Index

---

# 53. Search and Embedding Storage

Search/Embedding storage не должен становиться альтернативным Source of Truth.

SQLite

  ↓

Source of Truth

  

Search / Vector Index

  ↓

Derived State

---

# 54. AI Cache

AI responses могут кэшироваться.

Например:

AI Request

      ↓

Cache

      ↓

Provider

Но AI cache не является Domain State.

---

# 55. Temporary Data

Temporary AI Context, processing jobs и другие временные данные должны иметь lifecycle.

Например:

TEMPORARY

   ↓

EXPIRED

   ↓

CLEANUP

---

# 56. Cleanup

Производные и временные данные могут очищаться без потери Domain State.

Domain State ✓

Cache ✗

После очистки:

Cache

   ↓

Rebuild

---

# 57. Database Encryption

Local database может содержать чувствительные пользовательские данные.

Поэтому encryption at rest должна рассматриваться частью Security Architecture.

Конкретная технология шифрования не фиксируется этим ADR.

---

# 58. Encryption Keys

Ключи шифрования не должны храниться внутри SQLite database в открытом виде.

Для хранения ключей используется platform secure storage.

---

# 59. Platform Secure Storage

Архитектура должна предусматривать использование:

- Windows Credential / secure storage;
- macOS Keychain;
- Linux secure storage;
- Android Keystore;
- iOS Keychain.

Конкретная Flutter implementation определяется отдельно.

---

# 60. Database Access

Persistence Layer не должен предоставлять произвольный SQL доступ всему приложению.

Предпочтительно:

Use Case

   ↓

Repository

   ↓

Controlled Query

---

# 61. SQL Injection

Использование parameterized queries обязательно там, где SQL формируется динамически.

---

# 62. Schema Constraints

Database должна использовать ограничения там, где это помогает сохранять целостность:

- NOT NULL;
- UNIQUE;
- FOREIGN KEY;
- CHECK;
- indexes.

---

# 63. Indexes

Индексы должны создаваться на часто используемых полях.

Например:

entity_id

entity_type

updated_at

lifecycle_state

relationship_type

source_entity_id

target_entity_id

Конкретный набор определяется benchmark-тестами.

---

# 64. Не индексировать всё

Избыточные индексы:

- увеличивают размер database;
- замедляют записи;
- усложняют migrations.

Индексация должна основываться на реальных запросах.

---

# 65. Query Performance

Основные операции должны тестироваться:

Create Entity

Read Entity

Update Entity

Delete Entity

Search

Load Relationships

Load Context

---

# 66. Pagination

Большие коллекции не должны загружаться полностью.

Например:

Tasks

   ↓

Page 1

Page 2

Page 3

---

# 67. Lazy Loading

Связанные данные могут загружаться по необходимости.

Например:

Project

   ↓

Load basic data

  

User opens relationships

   ↓

Load relationships

---

# 68. Context Loading

Context Engine должен сам определять, какие данные необходимо загрузить.

Database не должна автоматически возвращать весь граф Entity.

---

# 69. Repository Queries

Repository должен предоставлять понятные Domain/Application операции.

Например:

getEntity()

getEntities()

saveEntity()

deleteEntity()

findRelationships()

а не только:

executeRawSql()

---

# 70. Database Abstraction

Необходимо избежать чрезмерной абстракции.

Мы не создаём универсальный database framework.

Цель:

Domain

   ↓

Repository

   ↓

SQLite

---

# 71. SQLite Dependency

Конкретная Flutter/Dart SQLite библиотека не фиксируется этим ADR.

Выбор будет сделан после проверки:

- desktop support;
- mobile support;
- FFI;
- migrations;
- transactions;
- performance;
- ecosystem maturity.

---

# 72. ORM

ORM не является обязательным требованием.

Возможны:

Raw SQL

Query Builder

ORM

Конкретный вариант будет выбран после прототипирования.

---

# 73. Почему не фиксируем ORM сейчас

Преждевременный выбор ORM может:

- ограничить архитектуру;
- добавить лишнюю сложность;
- создать зависимость от конкретного package;
- повлиять на performance.

Сначала фиксируем архитектурные границы.

---

# 74. Testing

Persistence Layer должен тестироваться отдельно от UI.

Минимально:

Repository Tests

Migration Tests

Transaction Tests

Integrity Tests

Performance Tests

---

# 75. Test Database

Автоматические тесты должны использовать отдельную временную database.

Production database не используется в automated tests.

---

# 76. Migration Tests

Каждая migration должна проверяться:

Schema N

   ↓

Migration

   ↓

Schema N+1

и проверять сохранность данных.

---

# 77. Recovery Tests

Необходимо тестировать:

- corrupted database;
- interrupted migration;
- incomplete write;
- restore from backup;
- rebuild derived indexes.

---

# 78. Backup Compatibility

Database должна быть совместима с Backup Architecture.

Backup должен позволять восстановить:

Domain State

а производные данные могут быть восстановлены отдельно.

---

# 79. Export

Domain Data должна иметь возможность быть экспортирована в portable format.

Например:

SQLite

   ↓

Export

   ↓

Portable Data

Конкретный формат определяется Backup/Export Architecture.

---

# 80. Import

Import не должен безусловно перезаписывать существующую database.

Предпочтительный процесс:

Import

  ↓

Validation

  ↓

Conflict Detection

  ↓

User / Policy Decision

  ↓

Apply

---

# 81. Conflict Detection

При импорте или Sync могут возникать конфликты.

Version и stable IDs должны помогать их обнаруживать.

---

# 82. Multi-device

На разных устройствах может существовать собственная локальная SQLite database.

Desktop SQLite

       |

       | Sync

       |

Mobile SQLite

Каждое устройство работает local-first.

---

# 83. Server Database

LifeOS не требует центральной database для основной работы.

В будущем server-side storage может существовать для Sync:

Local DB

   ↕

Sync Service

   ↕

Remote Storage

Но это не является обязательным для MVP.

---

# 84. Offline-first

Основной сценарий:

User

 ↓

Flutter

 ↓

Local SQLite

 ↓

UI updated immediately

Сеть не должна быть обязательным условием обычной работы.

---

# 85. Online Services

Внешние сервисы используются как дополнительные возможности:

AI API

Sync

Cloud Backup

Remote Embeddings

а не как обязательный слой для базовой работы приложения.

---

# 86. Data Ownership

Пользователь должен владеть локальным Domain State.

Архитектура не должна создавать обязательную зависимость от конкретного cloud provider.

---

# 87. Portability

Database architecture должна поддерживать перенос пользовательских данных.

LifeOS Device A

      ↓

Export

      ↓

Portable Data

      ↓

LifeOS Device B

      ↓

Import

---

# 88. Data Deletion

Удаление пользователя должно иметь понятную политику.

Необходимо различать:

Archive

Soft Delete

Permanent Delete

Cleanup Derived Data

---

# 89. Permanent Deletion

Физическое удаление должно быть отдельной операцией.

После permanent deletion соответствующие:

- embeddings;
- search entries;
- caches;
- file references;

также должны быть обработаны.

---

# 90. Data Retention

Необходимо определить retention policy для:

- deleted entities;
- audit data;
- temporary context;
- AI cache;
- sync queue;
- logs.

Это будет уточняться отдельными документами.

---

# 91. Observability

Persistence Layer может предоставлять технические метрики:

query_duration

transaction_duration

database_size

migration_duration

index_size

Но не должен автоматически записывать содержимое пользовательских данных в технические логи.

---

# 92. Logging

Логи должны избегать:

- passwords;
- API keys;
- tokens;
- sensitive content;
- полного содержимого документов.

---

# 93. Database Size

LifeOS должен контролировать размер локального storage.

В будущем могут потребоваться:

- cleanup;
- compression;
- archive;
- cache eviction;
- file management.

---

# 94. Performance Target

На раннем этапе не фиксируются жёсткие числовые performance targets.

Они будут определены после создания прототипа и реальных benchmark-тестов.

---

# 95. Scalability

Persistence Architecture должна быть рассчитана на постепенный рост:

100 entities

      ↓

10,000

      ↓

100,000

      ↓

1,000,000+

При этом реальные пределы будут определены benchmark-тестами.

---

# 96. MVP

Для первой реализации достаточно:

SQLite

Repository Layer

Entity Persistence

Relationship Persistence

Transactions

Migrations

Basic Indexes

Lifecycle Persistence

Versioning

File References

Async Database Access

Backup Compatibility

---

# 97. Не входит в MVP

Не требуется сразу реализовывать:

- distributed database;
- cloud database;
- advanced sharding;
- graph database;
- separate vector database server;
- complex event sourcing;
- full audit log;
- multi-region replication.

---

# 98. Event Sourcing

LifeOS не использует Event Sourcing как основной storage model на текущем этапе.

Основным источником истины является текущее состояние Domain.

Current Domain State

        ↓

Source of Truth

История изменений может добавляться отдельно.

---

# 99. CQRS

Полный CQRS не требуется для MVP.

Read/Write separation может использоваться локально там, где это действительно улучшает производительность.

---

# 100. Основные принципы

Для Persistence Architecture принимаются следующие принципы:

1. SQLite является основной локальной database.
2. SQLite хранит Domain State.
3. Domain State является Source of Truth.
4. Embeddings являются производными данными.
5. Search Index является производным данным.
6. AI Cache является производным состоянием.
7. Большие binary files хранятся отдельно от основной Entity data.
8. Domain Model отделена от Storage Model.
9. Repository Layer отделяет Domain от SQLite.
10. Domain не зависит от SQLite.
11. Entity IDs создаются offline.
12. Entity имеют stable identity.
13. Entity имеют version.
14. Entity имеют created_at и updated_at.
15. Timestamp внутри системы хранится в UTC.
16. Relationships хранятся отдельно.
17. Referential integrity поддерживается.
18. Критические операции используют transactions.
19. Database schema versioned.
20. Database migrations обязательны.
21. Migration должна быть тестируемой.
22. UI не блокируется database operations.
23. Background processing выполняется асинхронно.
24. Производные данные можно пересоздать.
25. Search Index можно перестроить.
26. Embedding Index можно перестроить.
27. Database должна поддерживать backup.
28. Database должна поддерживать export/import architecture.
29. Sync не является обязательным для локальной работы.
30. Cloud database не является обязательным Source of Truth.
31. Repository не должен превращаться в место всей бизнес-логики.
32. ORM не является обязательным.
33. Конкретная SQLite library не фиксируется этим ADR.
34. Индексы создаются на основе реальных запросов.
35. Большие коллекции используют pagination.
36. Context Engine контролирует объём загружаемых данных.
37. Database не должна автоматически загружать весь graph.
38. Sensitive data не должна попадать в технические логи.
39. Encryption at rest рассматривается Security Architecture.
40. Encryption keys хранятся в platform secure storage.
41. Event Sourcing не используется как основной storage model.
42. Full CQRS не требуется для MVP.
43. Persistence Layer должен быть отдельно тестируемым.
44. Database corruption должен иметь recovery strategy.
45. Architecture должна позволять дальнейшее развитие Sync.
46. Architecture должна позволять заменять производные storage implementations.
47. Основной сценарий работы остаётся local-first.

---

# 101. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную SQLite Flutter/Dart library;
- конкретный ORM;
- окончательную SQL schema;
- окончательный формат Entity storage;
- конкретный ID format;
- конкретную encryption implementation;
- конкретный Search Index;
- конкретную Vector Database;
- конкретную Sync implementation;
- конкретный Cloud Provider;
- окончательную Backup format;
- конкретные performance limits.

Эти решения принимаются после прототипирования и benchmark-тестов.

---

# 102. Последствия решения

## Положительные

- LifeOS остаётся local-first;
- данные доступны offline;
- SQLite зрелая и компактная технология;
- Domain State отделён от производных данных;
- AI не становится обязательной частью persistence;
- Search и Embeddings можно перестраивать;
- Sync можно добавить позже;
- Database implementation скрыта за Repository Layer;
- миграции позволяют развивать schema;
- архитектура подходит для desktop и mobile;
- пользовательские данные не зависят от cloud provider.

## Отрицательные

- появляется необходимость поддерживать migrations;
- SQLite требует аккуратного concurrency management;
- сложные graph queries потребуют дополнительных indexes;
- большие файлы требуют отдельного storage;
- потребуется recovery strategy;
- потребуется отдельный механизм производных indexes;
- Repository Layer увеличивает количество кода;
- Sync потребует дополнительной change tracking infrastructure.

---

# 103. Связанные ADR

Связанные архитектурные решения:

- ADR-0016 — Domain Model and Entity Architecture
- ADR-0015 — Semantic Search and Embeddings
- ADR-0014 — AI Tool Calling and Permissions
- ADR-0013 — AI Context Engine
- ADR-0012 — Search Architecture
- ADR-0011 — Backup and Export Architecture
- ADR-0010 — Security Architecture
- ADR-0009 — AI Architecture
- ADR-0008 — AI Provider Architecture
- ADR-0007 — Data Lifecycle Architecture
- ADR-0001 — Flutter as UI Framework

---

# 104. Следующий шаг

Следующим логичным документом является:

**ADR-0018: Sync and Conflict Resolution Architecture**

После ADR-0017 мы уже знаем:

Что храним

    ↓

ADR-0016

Domain Model

  

Где храним

    ↓

ADR-0017

SQLite / Persistence

  

Что дальше

    ↓

ADR-0018

Sync + Conflict Resolution

Именно ADR-0018 будет особенно важен для нашей концепции **local-first + AI + несколько устройств**, потому что там мы определим, что происходит, когда пользователь изменил одну и ту же информацию на компьютере и телефоне без интернета, а потом оба устройства снова подключились к сети.