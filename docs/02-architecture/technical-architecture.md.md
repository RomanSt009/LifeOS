# Техническая архитектура LifeOS

**Статус:** Черновик  
**Версия:** 0.1  
**Дата:** 2026-08-10

---

# 1. Назначение

Этот документ описывает техническую архитектуру приложения LifeOS.

Он является связующим уровнем между продуктовыми и архитектурными решениями и будущей реализацией программного обеспечения.

Документ определяет:

- основной технологический стек;
- структуру приложения;
- архитектурные слои;
- границы ответственности компонентов;
- управление состоянием;
- работу с базой данных;
- Repository Pattern;
- Dependency Injection;
- обработку ошибок;
- логирование;
- тестирование;
- подготовку к мобильной версии;
- подготовку к AI;
- подготовку к синхронизации.

Конкретные библиотеки могут изменяться в процессе разработки.

---

# 2. Основные технологические решения

Предварительный стек:

```text
Language:
Dart

UI Framework:
Flutter

Local Database:
SQLite

Architecture:
Layered Architecture + Domain-driven boundaries

State Management:
будет выбран на этапе технического прототипа

Dependency Injection:
будет выбран на этапе технического прототипа

Cloud:
не определён

AI:
не определён

Sync:
собственная подсистема поверх выбранного backend
````

---

# 3. Основной архитектурный принцип

LifeOS строится вокруг разделения:

```
Presentation
     ↓
Application
     ↓
Domain
     ↓
Infrastructure
```

Основное правило:

> Верхние слои могут использовать нижние абстракции, но Domain не должен зависеть от конкретных технологий хранения, UI или сетевого API.

---

# 4. Общая архитектура

```
                         LIFEOS
                            │
                    ┌───────┴───────┐
                    ↓               ↓
              Presentation      Background
                    │             Services
                    ↓
              Application
                    │
                    ↓
                 Domain
                    │
                    ↓
              Infrastructure
                    │
          ┌─────────┴─────────┐
          ↓                   ↓
       SQLite             File Storage
          │
          ↓
      Sync Queue
          │
          ↓
      Sync Engine
          │
          ↓
        Cloud
```

AI будет подключаться через отдельный Context/AI слой.

---

# 5. Presentation Layer

Presentation отвечает только за взаимодействие с пользователем.

Включает:

- экраны;
- виджеты;
- UI state;
- navigation;
- пользовательские действия;
- отображение ошибок;
- loading states.

Presentation не должен:

- выполнять SQL;
- напрямую обращаться к SQLite;
- содержать бизнес-правила;
- самостоятельно управлять синхронизацией;
- напрямую вызывать AI API.

Пример:

```
User
 ↓
UI
 ↓
Application Command
```

---

# 6. Application Layer

Application Layer координирует действия пользователя.

Примеры:

```
CreateTask
UpdateTask
ArchiveEntity
SearchEntities
CreateRelationship
ResolveConflict
```

Application Layer:

- получает команду;
- проверяет контекст;
- вызывает Domain;
- использует Repository;
- возвращает результат Presentation Layer.

Пример:

```
UI
 ↓
CreateTask
 ↓
Task Domain
 ↓
TaskRepository
 ↓
SQLite
```

---

# 7. Domain Layer

Domain является ядром LifeOS.

Здесь находятся:

- Entities;
- Value Objects;
- Relationships;
- Domain Rules;
- Lifecycle;
- бизнес-правила;
- Domain Services.

Domain не должен знать:

- Flutter;
- SQLite;
- HTTP;
- конкретный Cloud Backend;
- конкретную AI-модель.

Например:

```
Task
Project
Person
Note
Relationship
LifecycleState
```

являются частью Domain.

---

# 8. Infrastructure Layer

Infrastructure отвечает за конкретные технологии.

Примеры:

```
SQLite
File System
HTTP
Cloud API
Encryption
Secure Storage
Logging
```

Пример:

```
TaskRepository
      │
      ↓
SQLiteTaskRepository
      │
      ↓
SQLite
```

Domain работает с интерфейсом Repository, а Infrastructure предоставляет реализацию.

---

# 9. Repository Pattern

Repository используется для отделения Domain от конкретного хранилища.

Например:

```
abstract TaskRepository
```

Domain знает:

```
getTask()
createTask()
updateTask()
deleteTask()
```

Но не знает:

```
SELECT *
FROM tasks
```

Конкретная реализация находится в Infrastructure.

---

# 10. Почему Repository важен

Это позволит в будущем изменить:

```
SQLite
```

на другой механизм хранения без переписывания Domain Layer.

Также это упрощает:

- тестирование;
- миграцию;
- синхронизацию;
- mock repositories;
- offline-first;
- мобильную версию.

---

# 11. Source of Truth

Для локального устройства:

```
SQLite + File Storage
```

являются локальным источником истины.

Однако LifeOS является распределённой системой.

Поэтому нельзя считать, что существует только один глобальный Source of Truth.

Предварительная модель:

```
                 LifeOS Data
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
       PC           Phone         Cloud
    Replica A      Replica B    Sync State
```

Каждое устройство содержит локальную реплику данных.

Sync Engine отвечает за согласование изменений между репликами.

---

# 12. Entity Identity

Каждая сущность получает стабильный уникальный ID.

Например:

```
Entity
├── id
├── type
├── created_at
└── updated_at
```

ID не должен зависеть от:

- расположения файла;
- конкретного устройства;
- SQLite rowid;
- Cloud database ID.

Это позволяет переносить сущности между устройствами.

---

# 13. Entity Revision

Для каждой синхронизируемой сущности используется revision.

Пример:

```
Task #123
revision = 42
```

После изменения:

```
revision = 43
```

Revision используется для:

- обнаружения устаревших данных;
- определения конфликтов;
- контроля конкурентных изменений;
- синхронизации.

---

# 14. Sync Operation Identity

Каждая операция синхронизации должна иметь собственный уникальный ID.

Предварительная структура:

```
SyncOperation
├── operation_id
├── device_id
├── entity_id
├── base_revision
├── operation
├── payload
└── created_at
```

`operation_id` позволяет обеспечить идемпотентность.

Повторная доставка одной операции не должна создавать повторное изменение.

---

# 15. Optimistic Concurrency

При изменении сущности устройство сообщает revision, на основании которой было выполнено изменение.

Пример:

```
Current:
revision = 42
```

PC изменяет:

```
base_revision = 42
new_revision = 43
```

Если Cloud уже знает:

```
revision = 43
```

значит, другое устройство также изменило сущность.

Возникает потенциальный конфликт.

---

# 16. Конфликт

Пример:

```
Task #123
revision = 42
```

PC:

```
42 → 43
due_date = Tuesday
```

Phone:

```
42 → 43
due_date = Friday
```

После синхронизации:

```
base_revision PC    = 42
base_revision Phone = 42
```

Обе операции основаны на одной старой версии.

Это является настоящим конфликтом.

---

# 17. Field-level Merge

Если разные устройства изменили разные поля:

```
PC:
priority = high

Phone:
due_date = Friday
```

изменения могут быть объединены:

```
priority = high
due_date = Friday
```

Если изменено одно и то же поле:

```
PC:
due_date = Tuesday

Phone:
due_date = Friday
```

необходимо разрешение конфликта.

---

# 18. Conflict Resolution

Стратегия:

```
Automatic Merge
       ↓
   если возможно
       ↓
Manual Resolution
       ↓
если требуется
```

Пользователь должен иметь возможность:

- выбрать значение PC;
- выбрать значение Phone;
- изменить значение вручную.

---

# 19. AI-assisted Conflict Resolution

AI может предложить решение.

Например:

```
Конфликт:

PC → Вторник
Phone → Пятница

AI recommendation:
Пятница
```

Но:

> AI не является окончательным арбитром пользовательских данных.

Модель:

```
Conflict
   ↓
AI Analysis
   ↓
Recommendation
   ↓
User Decision
```

Для некритичных конфликтов в будущем могут быть предусмотрены автоматические правила.

---

# 20. Lifecycle

Каждая сущность имеет жизненный цикл.

Предварительно:

```
Created
   ↓
Active
   ↓
Archived
   ↓
Deleted
```

В зависимости от типа сущности могут существовать дополнительные состояния.

Lifecycle используется не только для UI.

Он также влияет на:

- поиск;
- AI Context;
- синхронизацию;
- очистку;
- архивирование;
- retention.

---

# 21. Архив

Архивные сущности остаются доступными, но не должны автоматически попадать в обычный рабочий контекст.

Например:

```
User:
"Что мне сделать сегодня?"

Context:
✓ Active Tasks
✓ Today's Events

Не включать автоматически:
✕ Archived Projects
✕ Old Notes
```

При явном запросе архив может быть включён в поиск.

---

# 22. Context Engine

AI не должен получать прямой доступ ко всей базе.

Архитектура:

```
User Request
      ↓
Context Engine
      ↓
Search
      ↓
Relevant Entities
      ↓
Filtering
      ↓
Ranking
      ↓
AI
```

Context Engine отвечает за:

- релевантность;
- lifecycle;
- relationships;
- permissions;
- sensitivity;
- ограничение объёма контекста.

---

# 23. AI Boundary

AI должен взаимодействовать с системой через определённый интерфейс.

Не:

```
AI
 ↓
SQLite
```

а:

```
AI
 ↓
Context / AI Service
 ↓
Application / Domain
 ↓
Repository
```

Это позволяет:

- заменить AI-модель;
- добавить локальный AI;
- добавить Cloud AI;
- контролировать доступ;
- тестировать AI независимо.

---

# 24. Local AI и Cloud AI

Архитектура должна позволять использовать:

```
              AI Interface
                    │
          ┌─────────┴─────────┐
          ↓                   ↓
      Local AI            Cloud AI
```

Конкретная модель будет выбрана позже.

---

# 25. State Management

Flutter UI будет использовать отдельную систему управления состоянием.

Требования:

- предсказуемые обновления;
- реактивность;
- тестируемость;
- отсутствие бизнес-логики в Widgets;
- поддержка async operations;
- возможность масштабирования.

Конкретная библиотека будет выбрана после технического прототипа.

Предварительно рассматриваются:

- Riverpod;
- Bloc/Cubit.

Выбор будет зафиксирован отдельным ADR.

---

# 26. Dependency Injection

Компоненты не должны создавать свои зависимости напрямую.

Плохо:

```
TaskService()
  ↓
new SQLiteDatabase()
```

Предпочтительно:

```
TaskService
    ↓
TaskRepository
```

а конкретная реализация передаётся извне.

Это упрощает:

- тестирование;
- замену компонентов;
- конфигурацию;
- поддержку разных платформ.

---

# 27. Navigation

Navigation должна находиться в Presentation Layer.

UI не должен самостоятельно решать бизнес-логику переходов.

Например:

```
TaskScreen
 ↓
Task Details
```

Навигационная архитектура должна поддерживать:

- Desktop;
- Mobile;
- deep links;
- восстановление состояния;
- различные размеры экранов.

---

# 28. Desktop и Mobile

Одна из ключевых целей архитектуры:

> Бизнес-логика должна быть максимально общей между Desktop и Mobile.

```
                 Shared Core
                     │
          ┌──────────┴──────────┐
          ↓                     ↓
       Desktop               Mobile
       Flutter               Flutter
```

Различаться могут:

- layout;
- navigation;
- input;
- shortcuts;
- platform integrations.

---

# 29. Responsive UI

LifeOS не должен быть просто Desktop-приложением, уменьшенным до размера телефона.

UI должен учитывать:

```
Desktop
Tablet
Phone
```

Но Domain и Application Layer остаются общими.

---

# 30. Background Tasks

Некоторые операции не должны блокировать UI.

Например:

- индексация;
- импорт;
- экспорт;
- генерация embeddings;
- обработка файлов;
- синхронизация;
- backup.

Архитектура:

```
UI
 ↓
Command
 ↓
Background Worker
 ↓
Result
 ↓
UI
```

---

# 31. Error Handling

Ошибки должны проходить через контролируемую систему.

Типы:

```
Domain Error
Database Error
Network Error
Sync Error
AI Error
File Error
Authentication Error
```

Infrastructure errors не должны напрямую попадать в UI.

Например:

```
SQLiteException
```

должна преобразовываться в понятную Application/Domain ошибку.

---

# 32. Logging

LifeOS должен иметь структурированное логирование.

Уровни:

```
DEBUG
INFO
WARNING
ERROR
```

Логи не должны автоматически содержать:

- пароли;
- encryption keys;
- access tokens;
- полное содержимое приватных документов;
- чувствительные пользовательские данные.

---

# 33. Observability

Даже локальное приложение должно иметь возможность диагностировать проблемы.

Минимально:

```
Application Logs
Database Diagnostics
Sync Diagnostics
Performance Metrics
```

При этом диагностика должна учитывать приватность пользователя.

---

# 34. Testing

Каждый архитектурный слой должен иметь собственные тесты.

```
Domain
 ↓
Unit Tests

Application
 ↓
Unit Tests

Repository
 ↓
Integration Tests

SQLite
 ↓
Database Tests

UI
 ↓
Widget / Integration Tests
```

---

# 35. Domain Testing

Domain должен тестироваться без Flutter и SQLite.

Например:

```
Task
 ↓
complete()
 ↓
status == completed
```

Это позволяет быстро тестировать бизнес-логику.

---

# 36. Repository Testing

Repository проверяется на реальном или тестовом SQLite.

Проверяется:

- создание;
- чтение;
- изменение;
- удаление;
- транзакции;
- миграции;
- индексы;
- поиск.

---

# 37. Sync Testing

В будущем Sync Engine должен тестироваться на сценариях:

```
Offline
Reconnect
Duplicate Operation
Concurrent Update
Conflict
Partial Failure
Retry
Device Revocation
Long Offline Period
```

---

# 38. Database Migrations

Изменения структуры SQLite выполняются только через миграции.

```
Database v1
     ↓
Migration 2
     ↓
Database v2
     ↓
Migration 3
     ↓
Database v3
```

Запрещается изменять production-схему вручную без соответствующей миграции.

---

# 39. File Storage

Большие файлы хранятся отдельно от SQLite.

```
LifeOS Data
│
├── database/
│   └── lifeos.db
│
└── files/
    ├── documents/
    ├── images/
    ├── audio/
    └── video/
```

SQLite содержит metadata и ссылки на файлы.

---

# 40. Security Boundary

Безопасность должна рассматриваться на нескольких уровнях:

```
Application
     ↓
Local Storage
     ↓
Network
     ↓
Cloud
     ↓
Other Devices
```

Необходимо учитывать:

- authentication;
- authorization;
- encryption;
- secure storage;
- device identity;
- key management;
- backup security.

---

# 41. Encryption

LifeOS должен поддерживать шифрование:

```
Data at Rest
Data in Transit
Sensitive Data
Backup
```

Конкретная реализация будет определена отдельным ADR.

Криптографические алгоритмы самостоятельно реализовываться не будут.

Будут использоваться проверенные библиотеки и системные механизмы.

---

# 42. Sync Architecture Boundary

Sync Engine не должен быть частью Domain.

```
Domain
  ↑
Application
  ↑
Sync Engine
  ↓
Infrastructure
```

Sync работает с Domain через определённые интерфейсы.

Это позволит изменять механизм синхронизации без изменения основной бизнес-логики.

---

# 43. Cloud Abstraction

Application не должен знать конкретного Cloud Provider.

Плохо:

```
Application
 ↓
Firebase API
```

Предпочтительно:

```
Application
 ↓
Sync Service
 ↓
Cloud Adapter
 ↓
Cloud Provider
```

Таким образом в будущем можно заменить backend.

---

# 44. Offline-first Data Flow

Основной путь:

```
User
 ↓
UI
 ↓
Application
 ↓
Domain
 ↓
Repository
 ↓
SQLite
 ↓
Sync Queue
```

Сеть не находится на критическом пути пользовательской операции.

---

# 45. Online Sync Flow

После появления сети:

```
Sync Queue
     ↓
Sync Engine
     ↓
Cloud Adapter
     ↓
Cloud
     ↓
Remote Changes
     ↓
Conflict Detection
     ↓
SQLite
```

---

# 46. Direct Sync

Direct Sync будет отдельным транспортом.

```
Sync Engine
     │
     ├── Cloud Transport
     │
     └── Direct Transport
```

Application и Domain не должны знать, какой транспорт используется.

---

# 47. Transport Abstraction

Предварительно:

```
SyncTransport
│
├── CloudSyncTransport
└── DirectSyncTransport
```

Это позволяет использовать разные каналы передачи данных.

---

# 48. Idempotency

Каждая Sync Operation имеет уникальный ID.

Если операция получена повторно:

```
operation_id = ABC123
```

система должна распознать её как уже обработанную.

Это предотвращает дублирование.

---

# 49. Partial Failure

Синхронизация может выполняться частично.

Например:

```
10 operations

✓ 1
✓ 2
✓ 3
✓ 4
✕ 5
- 6
- 7
```

После ошибки состояние сохраняется.

После восстановления сети Sync Engine продолжает работу с необходимого места.

---

# 50. Backup

Backup является отдельным механизмом.

```
Sync
↔
Devices

Backup
↓
Snapshot
```

Backup должен позволять восстановить данные после:

- повреждения базы;
- ошибки пользователя;
- потери устройства;
- критической ошибки синхронизации.

---

# 51. Export

LifeOS должен предоставлять экспорт пользовательских данных.

Минимально рассматриваются:

```
JSON
Markdown
CSV
```

Для полного восстановления должен существовать специальный формат backup/export LifeOS.

---

# 52. Performance Principles

Основные требования:

1. UI не должен блокироваться тяжёлыми операциями.
2. Database operations должны выполняться асинхронно.
3. Поиск должен использовать индексы.
4. Большие файлы не должны полностью загружаться в память.
5. AI Context должен быть ограничен.
6. Индексация должна выполняться в фоне.
7. Sync не должен блокировать пользовательские операции.
8. Кэш может быть удалён и восстановлен.

---

# 53. Scalability

Архитектура должна масштабироваться:

```
MVP
 ↓
Desktop
 ↓
Mobile
 ↓
Multiple Devices
 ↓
Cloud Sync
 ↓
Advanced AI
```

При этом не требуется заранее строить сложную распределённую инфраструктуру.

Сначала создаётся качественное локальное приложение.

---

# 54. Project Structure

Предварительная структура Dart/Flutter проекта:

```
lib/
│
├── app/
│   ├── app.dart
│   ├── router/
│   └── configuration/
│
├── core/
│   ├── errors/
│   ├── logging/
│   ├── utils/
│   └── types/
│
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/
│   ├── services/
│   └── rules/
│
├── application/
│   ├── commands/
│   ├── queries/
│   ├── services/
│   └── state/
│
├── infrastructure/
│   ├── database/
│   ├── filesystem/
│   ├── sync/
│   ├── security/
│   └── ai/
│
└── presentation/
    ├── screens/
    ├── widgets/
    ├── navigation/
    └── state/
```

Структура может измениться после создания первого прототипа.

---

# 55. Feature-based Organization

По мере роста проекта возможно перейти к feature-oriented структуре.

Например:

```
features/
├── tasks/
├── projects/
├── notes/
├── relationships/
├── search/
├── ai/
└── sync/
```

Выбор между layered и feature-based организацией будет проверен после появления первых реальных модулей.

На ранней стадии предпочтительно сохранить ясное разделение архитектурных слоёв.

---

# 56. Правило зависимости

Зависимости должны двигаться в одном направлении:

```
Presentation
      ↓
Application
      ↓
Domain
      ↑
Infrastructure
```

Infrastructure реализует интерфейсы, определённые более внутренними слоями.

Domain не должен зависеть от Flutter.

---

# 57. Что нельзя делать

Запрещается без архитектурного обоснования:

```
Widget
 ↓
SQLite

Widget
 ↓
HTTP

Widget
 ↓
AI API

Domain
 ↓
Flutter

Domain
 ↓
SQLite implementation
```

Также нельзя помещать всю бизнес-логику в UI.

---

# 58. MVP Boundary

Первая рабочая версия должна содержать:

```
✓ Flutter Application
✓ Local SQLite
✓ Domain Model
✓ Repository Layer
✓ Application Layer
✓ Basic UI
✓ Entity Lifecycle
✓ Relationships
✓ Search
✓ Basic Logging
✓ Database Migrations
```

Пока не реализуются:

```
✕ Cloud Sync
✕ Direct Sync
✕ E2E
✕ Multi-device
✕ Cloud AI
✕ Advanced Semantic Search
```

Архитектура только подготавливается к этим функциям.

---

# 59. Архитектурный приоритет

Порядок разработки:

```
1. Domain
      ↓
2. Database
      ↓
3. Repository
      ↓
4. Application
      ↓
5. UI
      ↓
6. Search
      ↓
7. AI Context
      ↓
8. Sync
```

Это позволяет не строить инфраструктуру вокруг ещё не проверенной бизнес-модели.

---

# 60. Архитектурные принципы

На текущем этапе зафиксированы:

1. Flutter + Dart являются основным технологическим стеком.
2. LifeOS строится по принципу Local First.
3. SQLite является основной локальной БД.
4. Domain не зависит от Flutter или SQLite.
5. Repository изолирует Domain от Infrastructure.
6. Application Layer координирует пользовательские сценарии.
7. UI не содержит основной бизнес-логики.
8. Каждая сущность имеет стабильный ID.
9. Синхронизируемые сущности имеют revision.
10. Каждая Sync Operation имеет operation ID.
11. Sync должен быть идемпотентным.
12. Конфликты не должны приводить к молчаливой потере данных.
13. Возможно автоматическое объединение изменений разных полей.
14. Конфликты одного поля требуют разрешения.
15. AI может рекомендовать решение, но не является окончательным арбитром.
16. Каждое устройство является локальной репликой данных.
17. Cloud не является единственным глобальным источником истины.
18. Lifecycle является частью Domain Model.
19. Архивные данные не включаются автоматически в обычный AI Context.
20. AI получает данные через Context Engine.
21. Cloud Provider скрыт за абстракцией.
22. Sync Transport скрыт за абстракцией.
23. Direct Sync может быть добавлен без изменения Domain.
24. Backup и Sync являются разными механизмами.
25. Криптография реализуется только проверенными библиотеками.
26. UI должен быть адаптирован для Desktop и Mobile.
27. Тяжёлые операции выполняются в фоне.
28. Архитектура должна оставаться простой до появления реальной необходимости усложнения.

---

# 61. Открытые архитектурные решения

Пока не определены:

- State Management;
- Dependency Injection library;
- SQLite package;
- ORM / query builder;
- encryption library;
- Cloud Provider;
- Backend architecture;
- Authentication;
- AI provider;
- Local AI runtime;
- embedding model;
- vector search;
- Sync protocol;
- file sync protocol.

Каждый существенный выбор должен быть зафиксирован отдельным ADR.

---

# 62. Следующий этап

После завершения этого документа необходимо провести техническое ревью.

Следующие решения:

1. Выбрать State Management.
2. Выбрать SQLite/Dart library.
3. Выбрать Dependency Injection.
4. Определить тестовый стек.
5. Определить минимальную структуру Flutter-проекта.
6. Создать первый технический прототип.
7. Проверить производительность SQLite.
8. Проверить миграции.
9. Проверить Repository.
10. Только после этого начать создание MVP UI.

Следующий крупный документ:

```
docs/04-ai/ai-architecture.md
```

Но до него необходимо провести техническое ревью текущей архитектуры.

````

### После вставки

Сохрани файл, **но пока не делай новый commit**.

Теперь у нас появилась очень важная цепочка:

```text
02-architecture
      │
      └── technical-architecture.md
                    │
                    ↓
03-database
      │
      ├── data-model.md
      └── database-overview.md
                    │
                    ↓
06-sync
      │
      └── sync-architecture.md
````

И я специально зафиксировал здесь нашу новую модель:

**Entity ID → Revision → Sync Operation ID → Conflict Resolution.**

Это будет одним из ключевых технических механизмов LifeOS.