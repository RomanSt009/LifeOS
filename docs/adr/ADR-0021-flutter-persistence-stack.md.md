# ADR-0021: Flutter Persistence Stack

**Статус:** Предварительно принято
**Дата:** 2026-08-25
**Версия:** 0.1
## 1. Контекст

ADR-0020 определил логическую архитектуру локального Persistence Layer LifeOS и SQLite как основное локальное хранилище.

  

Теперь необходимо выбрать конкретный инструмент для работы с SQLite из Flutter/Dart.

Persistence Stack должен находиться между Repository Layer и SQLite:
```text
Flutter
   ↓
Application
   ↓
Domain
   ↓
Repository
   ↓
Persistence Stack
   ↓
SQLite
```

Выбранный инструмент должен соответствовать архитектурным требованиям LifeOS:

- Local-First;
- desktop-first с дальнейшей поддержкой mobile;
- SQLite;
- transactions;
- migrations;
- relationships;
- типобезопасность;
- работа с большим количеством данных;
- поддержка Outbox;
- Sync State;
- Tombstones;
- Conflict Records;
- тестируемость;
- долгосрочная поддержка проекта.

---

# 2. Требования

Persistence Stack должен обеспечивать:
### Обязательные требования

- SQLite;
- Windows;
- macOS;
- Linux;
- Android;
- iOS;
- transactions;
- migrations;
- parameterized queries;
- type-safe data access;
- возможность выполнять сложные SQL queries;
- поддержку joins;
- поддержку indexes;
- возможность работать с background operations;
- хорошую интеграцию с Dart;
- тестируемость.

### Желательные требования

- reactive queries;
- compile-time проверки SQL;
- удобное описание Schema;
- удобная работа с Streams;
- хорошая интеграция с Flutter;
- минимальное количество boilerplate;
- возможность использовать raw SQL там, где это действительно необходимо.

---

# 3. Рассмотренные варианты

Основными кандидатами являются:

```text
Drift
sqflite
Isar
Direct SQLite / FFI-based approach
````

Также допускается рассмотрение других решений, если они предоставляют существенные преимущества для архитектуры LifeOS.

Кандидаты оцениваются прежде всего с точки зрения соответствия архитектуре LifeOS:

- Local-First;
- SQLite / relational persistence;
- сложные relationships;
- transactions;
- migrations;
- Sync;
- Outbox;
- Conflict handling;
- type safety;
- тестируемость;
- поддерживаемость;
- возможность изолировать persistence technology от Domain Layer.

---

# 4. Drift

Drift — типобезопасный persistence framework для Dart/Flutter, работающий поверх SQLite.

Концептуально:

```
Dart
 ↓
Drift
 ↓
SQLite
```

Drift позволяет описывать database schema и запросы на уровне Dart/SQL с генерацией типобезопасного кода.

---

# 5. Преимущества Drift

Основные преимущества:

- SQLite как настоящий relational database;
- type-safe API;
- поддержка SQL;
- compile-time validation для значительной части database layer;
- transactions;
- migrations;
- joins;
- indexes;
- reactive queries;
- streams;
- хорошо подходит для сложных relational models;
- возможность использовать raw SQL;
- хорошая интеграция с Dart;
- подходит для тестирования;
- подходит для сложного локального Persistence Layer.

---

# 6. Недостатки Drift

Основные недостатки:

- дополнительный слой абстракции над SQLite;
- code generation;
- необходимо понимать SQL и relational database concepts;
- schema migrations требуют дисциплины;
- первоначальная настройка сложнее, чем у простых key-value решений;
- для очень простого приложения может быть избыточным.

Для LifeOS эти недостатки считаются приемлемыми.

---

# 7. sqflite

`sqflite` предоставляет прямой доступ к SQLite из Flutter/Dart.

Концептуально:

```
Dart
 ↓
sqflite
 ↓
SQLite
```

Он предоставляет более низкоуровневый подход к database operations.

---

# 8. Преимущества sqflite

- зрелый подход к SQLite;
- прямой доступ к SQL;
- относительно простой концептуальный слой;
- широкое использование в Flutter ecosystem;
- хорошо подходит для приложений, которым нужен непосредственный контроль над SQLite.

---

# 9. Недостатки sqflite

Для архитектуры LifeOS существуют дополнительные сложности:

- меньше compile-time type safety;
- больше ручного mapping между SQLite и Dart Models;
- больше boilerplate;
- schema management требует больше ручной работы;
- сложнее поддерживать большое количество таблиц и queries;
- Repository Layer может быстро получить много database-specific кода.

Для небольшого приложения это не является большой проблемой.

Для долгосрочного LifeOS это становится существенным недостатком.

---

# 10. Isar

Isar — локальная database technology для Flutter/Dart, ориентированная на быстрый локальный доступ к объектам.

Концептуально:

```
Dart Objects
     ↓
   Isar
```

Isar не является обычной abstraction layer над SQLite.

---

# 11. Преимущества Isar

- object-oriented подход;
- высокая скорость локальных операций;
- удобная работа с Dart objects;
- reactive queries;
- хорошая интеграция с Flutter;
- простой developer experience для object-centric данных.

---

# 12. Недостатки Isar

Для LifeOS существуют архитектурные ограничения:

- это не SQLite;
- relational model выражена иначе;
- SQL не является основным query language;
- сложные relational queries могут потребовать другого подхода;
- Persistence Layer становится сильнее связан с конкретной database technology;
- миграция на SQLite в будущем потребует дополнительной работы.

LifeOS уже архитектурно ориентирован на SQLite.

Поэтому Isar не является предпочтительным вариантом.

---

# 13. Hive / Hive CE

Hive-подобные решения ориентированы преимущественно на локальное key-value / object storage.

Концептуально:

```
Key
 ↓
Value
```

---

# 14. Преимущества Hive-подобного подхода

- простой API;
- небольшой порог входа;
- удобное локальное хранение;
- хорошо подходит для settings, cache и небольших локальных данных;
- простая модель использования.

---

# 15. Недостатки Hive-подобного подхода

Для LifeOS:

- relational queries ограничены;
- joins отсутствуют или имеют другую модель;
- сложнее реализовать сложные relationships;
- SQL не используется как основной язык запросов;
- сложнее моделировать Sync Data Model;
- менее естественно подходит для Outbox / Conflict / Relationship architecture.

Поэтому Hive-подобный подход не выбирается как основная database technology.

---

# 16. Сравнение

| Требование          | Drift   | sqflite       | Isar              | Direct SQLite / FFI          |
| ------------------- | ------- | ------------- | ----------------- | ---------------------------- |
| SQLite              | Да      | Да            | Нет               | Да                           |
| Relational Model    | Отлично | Отлично       | Иная модель       | Отлично                      |
| SQL                 | Да      | Да            | Нет               | Да                           |
| Transactions        | Да      | Да            | Да                | Да                           |
| Migrations          | Да      | Да            | Да                | Да                           |
| Type Safety         | Высокая | Низкая/ручная | Высокая           | Требует ручного mapping      |
| Joins               | Да      | Да            | Не SQL            | Да                           |
| Reactive Queries    | Да      | Ограниченно   | Да                | Требует дополнительного слоя |
| Complex Queries     | Отлично | Отлично       | Зависит от модели | Отлично                      |
| Outbox              | Отлично | Отлично       | Возможно          | Отлично                      |
| Relationships       | Отлично | Отлично       | Хорошо, но иначе  | Отлично                      |
| Repository Boundary | Отлично | Отлично       | Хорошо            | Отлично                      |
| Контроль над SQLite | Высокий | Высокий       | Не применимо      | Максимальный                 |
| Boilerplate         | Средний | Высокий       | Низкий\средний    | Высокий                      |
| Подходит LifeOS     | **Да**  | Да            | Скорее нет        | Возможно но сложнее          |

---

# 17. Решение

В качестве **предпочтительного** Flutter Persistence Stack LifeOS выбирается:

**Drift + SQLite**

Архитектурная цепочка:

```text
Flutter
   ↓
Application
   ↓
Domain
   ↓
Repository
   ↓
Drift
   ↓
SQLite
````

На текущем этапе решение считается **предварительно принятым для технического прототипа**.

Окончательная фиксация решения зависит от успешной проверки Drift на реальном техническом прототипе.

Прототип должен подтвердить:

- работу на целевых desktop-платформах;
- работу с SQLite;
- migrations;
- transactions;
- Repository Boundary;
- Outbox;
- Relationships;
- базовые Sync сценарии;
- тестируемость;
- приемлемую производительность.

Если прототип выявит существенные архитектурные или технические ограничения, решение может быть пересмотрено до начала полноценной реализации продукта.

---

# 18. Почему выбран Drift

Основная причина выбора — соответствие Drift архитектуре LifeOS.

LifeOS требует одновременно:

```
Local-First
+
Relational Data
+
Relationships
+
Transactions
+
Migrations
+
Outbox
+
Sync State
+
Conflicts
+
Type Safety
```

SQLite предоставляет relational foundation.

Drift предоставляет удобный и типобезопасный Dart слой над SQLite.

---

# 19. Repository Boundary

Несмотря на использование Drift, Domain Layer не должен напрямую зависеть от Drift.

Правильная архитектура:

```
UI
 ↓
Application
 ↓
Domain
 ↓
Repository Interface
 ↓
Repository Implementation
 ↓
Drift
 ↓
SQLite
```

Domain Layer не должен импортировать Drift-specific classes.

---

# 20. Drift как Infrastructure

Drift рассматривается как инфраструктурная технология.

Например:

```
lib/
├── domain/
├── application/
├── infrastructure/
│   └── persistence/
│       └── drift/
└── presentation/
```

Конкретная структура проекта будет определена отдельным ADR по Flutter Architecture.

---

# 21. Domain Models

Domain Models не должны автоматически совпадать с Drift-generated Database Models.

Например:

```
Domain Entity
      ↓
Repository
      ↓
Persistence Model
      ↓
Drift Table
```

Это позволяет сохранять независимость Domain Layer от persistence technology.

---

# 22. Database Models

Drift отвечает за database-specific representation.

Например:
```
TaskTable
RelationshipTable
OutboxTable
TombstoneTable
SyncStateTable
ConflictTable
```
Эти модели являются частью Persistence Layer.

---

# 23. Mapping

Repository отвечает за mapping между:

```
Domain Model
      ↕
Persistence Model
```

Например:

```
Task
  ↕
TaskRow
```
Mapping не должен находиться в UI.

---

# 24. Transactions

Drift должен использовать SQLite Transactions для критических операций.

Например:

```
BEGIN
   │
   ├── Update Domain State
   │
   └── Create Outbox Change
   │
COMMIT
```

---

# 25. Remote Sync Transaction

Применение Remote Changes должно выполняться transactionally.

```
BEGIN
   │
   ├── Apply Changes
   ├── Update Domain State
   ├── Update Tombstones
   └── Update Sync Cursor
   │
COMMIT
```

Это обеспечивает согласованность локального состояния.

---

# 26. Migrations

Database Schema должна изменяться через migrations.

Например:

```
Schema v1
   ↓
Migration
   ↓
Schema v2
   ↓
Migration
   ↓
Schema v3
```

Migration должна быть частью version-controlled codebase.

---

# 27. Migration Safety

Migration должна:

- быть детерминированной;
- сохранять пользовательские данные;
- быть протестирована;
- корректно работать после crash;
- иметь определённую исходную и целевую Schema Version.

---

# 28. Testing

Persistence Layer должен тестироваться независимо от Flutter UI.

Минимально необходимы:

```
Schema Tests
Migration Tests
Repository Tests
Transaction Tests
Outbox Tests
Sync Persistence Tests
Conflict Persistence Tests
```

---

# 29. In-Memory Testing

Для тестов, которым не требуется работа с постоянным database file, может использоваться in-memory SQLite.

Например:

```text
Test
 ↓
Repository
 ↓
Drift
 ↓
In-Memory SQLite
````

Это позволяет ускорить большое количество automated tests.

Однако in-memory SQLite не заменяет тестирование на реальной файловой Database.

Следующие сценарии должны дополнительно проверяться на реальной SQLite Database:

- migrations;
- database initialization;
- file-based persistence;
- locking;
- transaction behavior;
- WAL-related behavior, если используется;
- crash/recovery scenarios;
- database lifecycle.

Таким образом:

```
In-Memory SQLite
=
быстрые изолированные тесты

File-based SQLite
=
проверка реального Persistence поведения
```

---

# 30. Integration Testing

Критические database scenarios должны тестироваться на реальной SQLite Database.

Особенно:

- migrations;
- transactions;
- indexes;
- concurrency;
- crash recovery;
- Outbox;
- Sync;
- Tombstones.

---

# 31. Raw SQL

Использование raw SQL допускается.

Однако оно должно применяться только тогда, когда:

- query слишком сложен для удобного expression через Drift;
- требуется SQLite-specific functionality;
- это даёт существенное преимущество по производительности;
- необходима миграция или database maintenance operation.

Raw SQL не должен становиться стандартным способом работы приложения с database.

---

# 32. Performance

Основной принцип:

> Сначала корректность и архитектурная простота, затем оптимизация.

Оптимизация должна основываться на измерениях.

Необходимо избегать:

- premature optimization;
- необоснованных индексов;
- чрезмерного caching;
- сложных database abstractions без необходимости.

---

# 33. Large Data Sets

Persistence Stack должен поддерживать рост количества пользовательских данных.

В дальнейшем могут потребоваться:

- pagination;
- batching;
- background queries;
- incremental processing;
- indexes;
- database maintenance.

Эти решения принимаются на основании реальных performance measurements.

---

# 34. Reactive Queries

Drift может использовать reactive queries там, где UI или Application Layer действительно нуждается в автоматическом обновлении данных.

Например:

```
SQLite
 ↓
Drift Stream
 ↓
Repository
 ↓
Application State
 ↓
UI
```

Однако Domain Layer не должен становиться зависимым от Flutter-specific reactive mechanisms.

---

# 35. Background Operations

Persistence operations могут выполняться в background isolates или других подходящих execution contexts, если это потребуется для:

- Sync;
- indexing;
- migrations;
- large data processing;
- maintenance.

Конкретная concurrency strategy определяется при реализации.

---

# 36. Encryption

Drift не определяет саму Security Architecture LifeOS.

Database encryption должна быть реализована на уровне выбранного SQLite solution и соответствующей platform strategy.

Решение о конкретном encryption mechanism остаётся отдельным архитектурным вопросом.

---

# 37. Backup

Drift не является Backup System.

Backup должен использовать отдельную Backup Architecture.

Persistence Layer должен только предоставлять безопасный механизм доступа к данным, необходимым для Backup.

---

# 38. Export

Export должен использовать Domain/Application Layer.

Нельзя делать Export напрямую из произвольных Drift Tables, если это приводит к зависимости пользовательского формата от внутренней database schema.

---

# 39. Dependency Direction

Зависимости должны направляться внутрь:

Presentation
      ↓
Application
      ↓
Domain
      ↑
Infrastructure
      ↓
Drift
      ↓
SQLite

Domain не должен зависеть от Infrastructure.

---

# 40. Vendor Lock-In

Выбор Drift создаёт зависимость Persistence Layer от конкретной persistence technology.

Однако эта зависимость должна быть ограничена Infrastructure Layer:

```text
Domain
   X
Drift

Infrastructure
   ↓
Drift
````

Repository Interfaces должны оставаться независимыми от Drift-specific типов.

Поэтому потенциальная замена Persistence Stack в будущем не должна требовать переписывания Domain Logic.

При этом замена Drift не считается бесплатной: Persistence Implementation, mappings, migrations и database-specific code могут потребовать существенной переработки.

Архитектурная цель заключается не в полном отсутствии vendor lock-in, а в ограничении его границ.

---

# 41. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную версию Drift;
- конкретную версию SQLite;
- окончательную структуру Flutter проекта;
- окончательный список Domain Tables;
- SQL Schema;
- конкретные Repository Interfaces;
- конкретный Sync Protocol;
- конкретный Backup Format;
- Database Encryption;
- Encryption Key Management;
- конкретные индексы;
- конкретную Isolate Strategy;
- конкретный State Management Framework;
- конкретный DI Framework.

---

# 42. Последствия решения

## Положительные

- SQLite остаётся основной локальной database technology;
- Drift хорошо соответствует relational модели LifeOS;
- появляется высокая типобезопасность;
- уменьшается количество ручного database mapping;
- поддерживаются transactions;
- поддерживаются migrations;
- сложные queries и joins остаются доступными;
- удобно реализовывать Outbox;
- удобно реализовывать Relationships;
- Persistence Layer можно изолировать от Domain;
- возможна reactive data flow;
- database logic становится тестируемой;
- сохраняется возможность использовать raw SQL при необходимости.

## Отрицательные

- появляется code generation;
- необходимо изучить Drift;
- необходимо поддерживать migrations;
- появляется дополнительный abstraction layer;
- Persistence Layer становится сложнее, чем при простом key-value storage;
- разработчику всё равно необходимо понимать SQL и SQLite;
- появляется зависимость Infrastructure Layer от Drift.

---

# 43. MVP Scope

Для первого технического прототипа Persistence Layer необходимо реализовать минимальный набор:

```
SQLite
  ↓
Drift
  ↓
Persistence Layer
```
С поддержкой:

```
Domain Entity
Relationships
Outbox
Tombstones
Sync State
Conflicts
Transactions
Migrations
```

Необходимо избегать реализации всех будущих возможностей LifeOS до появления реальных требований.

---

# 44. Следующий шаг

После принятия ADR-0021 необходимо определить конкретную структуру Flutter-проекта и границы слоёв.

Следующий документ:

**ADR-0022: Flutter Project Architecture**

В нём необходимо определить:

```
lib/
├── presentation/
├── application/
├── domain/
├── infrastructure/
└── ...
```

и правила взаимодействия между слоями.