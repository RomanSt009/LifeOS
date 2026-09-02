# ADR-0022: Flutter Project Architecture

**Статус:** Предварительно принято
**Дата:** 2026-08-26
**Версия:** 0.1

## 1. Контекст

Предыдущие ADR определили основные архитектурные принципы LifeOS:

- Local-First;
- Domain-centric architecture;
- Repository Boundary;
- SQLite как локальное хранилище;
- Drift как предпочтительный Persistence Stack;
- Sync как отдельный инфраструктурный механизм;
- AI как отдельный слой, не связанный напрямую с конкретной моделью;
- возможность дальнейшего развития приложения без полной переработки Domain Layer.

Следующим шагом необходимо определить физическую структуру Flutter-проекта.

Цель данного ADR — установить:

- структуру исходного кода;
- границы слоёв;
- направление зависимостей;
- правила размещения кода;
- правила взаимодействия между слоями;
- границы Infrastructure;
- место для AI;
- место для Sync;
- место для Persistence;
- базовые правила масштабирования проекта.

---

# 2. Архитектурные принципы

Архитектура LifeOS должна следовать следующим принципам:

1. Domain Logic не зависит от Flutter.
2. Domain Logic не зависит от Drift.
3. Domain Logic не зависит от конкретного AI Provider.
4. Domain Logic не зависит от Sync Provider.
5. Infrastructure реализует технические детали.
6. Application координирует use cases.
7. Presentation отвечает за UI и пользовательское взаимодействие.
8. Repository Interfaces принадлежат Domain Layer.
9. Repository Implementations принадлежат Infrastructure Layer.
10. Зависимости направляются внутрь архитектуры.
11. Feature-specific код должен по возможности находиться рядом с соответствующей функциональностью.
12. Общие abstractions не должны создаваться заранее без необходимости.

---

# 3. Общая архитектура

Базовая архитектура:

```text
┌───────────────────────────────────────┐
│              Presentation             │
│          Flutter UI / Widgets         │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│              Application              │
│             Use Cases                 │
│         Application Services          │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│                Domain                 │
│ Entities / Value Objects / Repos      │
│ Domain Services / Business Rules      │
└───────────────────────────────────────┘
                    ▲
                    │
                    │ Interfaces
                    │
┌───────────────────────────────────────┐
│            Infrastructure             │
│ Persistence / Sync / AI / Platform    │
└───────────────────────────────────────┘
````

Направление зависимостей:

```
Presentation → Application → Domain

Infrastructure → Domain
```

Infrastructure реализует необходимые интерфейсы и abstractions, определённые внутренними слоями.

Application не зависит от конкретных Infrastructure Implementations.

Конкретные реализации связываются через Composition Root в `app/`.

Domain является центром архитектуры и не зависит от Presentation или Infrastructure.

---

# 4. Основная структура проекта

Базовая структура:

```
lib/
├── app/
│
├── presentation/
│
├── application/
│
├── domain/
│
└── infrastructure/
```

Внутри Infrastructure находятся технические реализации:

```
lib/
└── infrastructure/
    ├── persistence/
    ├── sync/
    ├── ai/
    ├── platform/
    └── ...
```

---

# 5. App Layer

`app/` содержит composition root приложения.

Основные задачи:

- создание Application;
- dependency injection;
- configuration;
- initialization;
- запуск Flutter Application;
- регистрация Infrastructure implementations;
- настройка environment-specific configuration.

Пример:

```
lib/app/
├── app.dart
├── bootstrap.dart
└── dependencies.dart
```

`app/` не содержит бизнес-логику.

---

# 6. Presentation Layer

Presentation отвечает за отображение пользовательского интерфейса.

Содержит:

- Pages;
- Screens;
- Widgets;
- UI State;
- navigation;
- user interaction;
- presentation-specific models.

Пример:

```
lib/presentation/
├── features/
│   ├── dashboard/
│   ├── tasks/
│   ├── notes/
│   └── settings/
│
├── navigation/
└── widgets/
```

Presentation Layer не должен напрямую обращаться к SQLite, Drift или AI Provider.

---

# 7. Application Layer

Application Layer координирует выполнение пользовательских сценариев.

Примеры:

```text
CreateTask
UpdateTask
DeleteTask
CreateRelationship
SearchKnowledge
StartSync
ExportData
````

Application Layer:

- вызывает Domain;
- координирует Repository;
- управляет use case flow;
- использует необходимые abstractions;
- не содержит UI-кода;
- не зависит от конкретных Infrastructure Implementations.

Application может работать с abstractions внешних возможностей приложения, если они необходимы конкретному Use Case.

Например:

```
Application Use Case
        ↓
Abstraction
        ↓
Infrastructure Implementation
```

Конкретная реализация связывается в Composition Root.

Пример:

```
StartSyncUseCase
        ↓
SyncService abstraction
        ↓
SyncService implementation
```

При этом не каждая техническая возможность должна автоматически становиться частью Domain Layer.

---

# 8. Domain Layer

Domain является ядром LifeOS.

Он содержит:

- Entities;
- Value Objects;
- Domain Rules;
- Domain Services;
- Repository Interfaces;
- Domain Events, если они необходимы;
- Domain-specific abstractions.

Пример:

```
lib/domain/
├── entities/
├── value_objects/
├── repositories/
├── services/
├── events/
└── ...
```

Domain Layer не должен импортировать:

```
flutter
drift
sqlite
http clients
AI SDKs
platform APIs
```

---

# 9. Entities

Entities представляют основные объекты LifeOS.

Например:

```
Entity
Relationship
Task
Note
Project
Person
Event
```

Конкретный набор Entity будет развиваться вместе с Domain Model.

Entity должна содержать бизнес-смысл, а не детали SQLite.

---

# 10. Value Objects

Value Objects используются для значений, имеющих Domain semantics.

Например:

```
EntityId
RelationshipType
Timestamp
EntityType
LifecycleState
```

Value Objects должны помогать предотвращать передачу некорректных значений внутри Domain.

---

# 11. Repository Interfaces

Repository Interfaces определяются в Domain Layer.

Например:

```
abstract interface class TaskRepository {
  Future<Task?> getById(EntityId id);

  Future<void> save(Task task);

  Future<void> delete(EntityId id);
}
```

Это пример архитектурного принципа.

Конкретный API будет определён во время реализации.

Repository Interface не должен знать о:

```
Drift
SQLite
HTTP
Flutter
AI
```

---

# 12. Repository Implementations

Repository Implementations находятся в Infrastructure.

Например:

```
lib/infrastructure/persistence/
├── drift/
│   ├── database.dart
│   ├── tables/
│   ├── daos/
│   └── repositories/
```

Repository Implementation реализует Domain Interface.

```
Domain
   │
   │ interface
   ▼
TaskRepository
   ▲
   │ implementation
   │
Infrastructure
   │
   ▼
Drift
```

---

# 13. Persistence Layer

Persistence отвечает за локальное хранение данных.

Основная технология:

```
Drift
  ↓
SQLite
```

Persistence Layer содержит:

- database;
- tables;
- DAOs;
- migrations;
- persistence models;
- mappings;
- repository implementations.

Persistence Layer не должен содержать UI logic.

---

# 14. Sync Layer

Sync является частью Infrastructure.

Пример:

```
lib/infrastructure/sync/
├── sync_engine/
├── transport/
├── outbox/
├── conflicts/
└── ...
```

Sync Layer отвечает за:

- Outbox;
- Remote Changes;
- synchronization;
- cursor management;
- conflict processing;
- retry;
- sync state.

Sync Layer не должен напрямую управлять Flutter Widgets.

---

# 15. AI Layer

AI является Infrastructure capability.

Пример:

```text
lib/infrastructure/ai/
├── providers/
├── adapters/
├── prompts/
├── context/
└── ...
````

AI Provider не должен напрямую использоваться Presentation Layer.

Правильный flow:

```
Presentation
      ↓
Application Use Case
      ↓
AI Abstraction
      ↓
Infrastructure AI
      ↓
AI Provider
```

AI Abstraction размещается на границе, которая соответствует конкретному use case.

Она не должна автоматически становиться частью Domain Layer.

Если AI capability имеет непосредственное значение для Domain Business Rules, соответствующая abstraction может быть размещена в Domain.

В остальных случаях AI остаётся Application / Infrastructure concern.

---

# 16. AI Provider Abstraction

Конкретный AI Provider должен быть скрыт за abstraction.

Например:

```dart
abstract interface class AiProvider {
  Future<AiResponse> generate(AiRequest request);
}
````

Конкретные реализации:

```
AiProvider
    ↑
    │
OpenAiProvider
LocalModelProvider
OtherProvider
```

AI Provider abstraction позволяет менять AI Model или Provider без изменения Presentation Layer и без привязки Application Use Cases к конкретному SDK.

Конкретная реализация подключается через Composition Root.

AI Provider не должен использоваться непосредственно из Domain Entity.

---

# 17. Platform Layer

Platform-specific code находится в Infrastructure.

Например:

```
lib/infrastructure/platform/
├── filesystem/
├── notifications/
├── secure_storage/
└── ...
```

Platform-specific implementation не должна проникать в Domain.

---

# 18. Dependency Direction

Главное правило архитектуры:

```
Presentation
     ↓
Application
     ↓
Domain
     ↑
Infrastructure
```

Infrastructure реализует интерфейсы Domain.

Domain не знает о существовании Infrastructure.

---

# 19. Запрещённые зависимости

Следующие зависимости запрещены:

```
Domain → Flutter
Domain → Drift
Domain → SQLite
Domain → AI SDK
Domain → HTTP Client
Domain → Platform API
```

Также запрещается:

```
Presentation → Drift
Presentation → SQLite
Presentation → AI Provider
Presentation → Sync Engine
```

Presentation должна обращаться к Application Layer.

---

# 20. Dependency Injection

Dependency Injection используется для связывания Interfaces с Implementations.

Например:

```
TaskRepository
      ↓
DriftTaskRepository
```

Composition Root:

```
lib/app/dependencies.dart
```

создаёт конкретные зависимости.

Domain при этом не знает, какая реализация была выбрана.

---

# 21. Feature Organization

На раннем этапе используется hybrid layer-first / feature-oriented структура.

Основные архитектурные слои остаются отдельными:

```text
presentation/
application/
domain/
infrastructure/
````

При этом Presentation и Application группируются по функциональности:

```
presentation/
└── features/
    ├── tasks/
    ├── notes/
    ├── relationships/
    └── dashboard/

application/
└── features/
    ├── tasks/
    ├── notes/
    ├── relationships/
    └── search/
```

Domain остаётся организованным преимущественно по Domain Concepts, а Infrastructure — по техническим подсистемам.

Это позволяет сохранить архитектурные границы и одновременно избежать чрезмерно больших общих папок.

По мере роста проекта структура может эволюционировать в полноценную feature-oriented архитектуру, если это будет оправдано размером и сложностью проекта.

---

# 22. Shared Code

Необходимо избегать создания огромной папки:

```
shared/
utils/
helpers/
common/
```

без чёткой ответственности.

Код должен размещаться рядом с тем слоем или feature, которому он принадлежит.

Общий код создаётся только тогда, когда его повторное использование действительно подтверждено.

---

# 23. Models

Необходимо различать:

```
Domain Model
Persistence Model
Presentation Model
AI Model
```

Они не должны автоматически становиться одной универсальной моделью.

Например:

```
Task
 ↓
TaskDto
 ↓
TaskRow
```

может существовать в разных слоях, если это необходимо.

---

# 24. Mapping

Mapping выполняется на границах слоёв.

Например:

```
Persistence Row
      ↓
Repository
      ↓
Domain Entity
      ↓
Application
      ↓
Presentation Model
```

Presentation не должна самостоятельно преобразовывать Drift Rows в Domain Entities.

---

# 25. Error Handling

Каждый слой отвечает за свои ошибки.

Infrastructure может иметь:

```
DatabaseException
NetworkException
AiProviderException
PlatformException
```

Они не должны бездумно проникать в Domain.

Infrastructure должен преобразовывать технические ошибки в подходящие abstractions на границе слоя.

---

# 26. Async Operations

Flutter Application использует asynchronous operations для:

- database;
- AI;
- Sync;
- network;
- filesystem.

Application Layer должен корректно координировать asynchronous use cases.

UI не должен самостоятельно управлять низкоуровневыми database или sync operations.

---

# 27. State Management

Этот ADR не фиксирует конкретный State Management Framework.

Допускается использование:

- Riverpod;
- Bloc;
- другого подходящего решения.

State Management должен находиться преимущественно в Presentation/Application Boundary и не проникать в Domain.

Выбор конкретного State Management Framework будет сделан отдельно.

---

# 28. Navigation

Navigation относится к Presentation Layer.

Например:

```
lib/presentation/navigation/
```

Navigation не должна содержать Domain Business Rules.

Navigation может запускать Application Use Cases или реагировать на Application State.

---

# 29. Testing Architecture

Каждый слой должен тестироваться независимо.

```
Domain
   ↓
Unit Tests

Application
   ↓
Use Case Tests

Infrastructure
   ↓
Integration Tests

Presentation
   ↓
Widget / Integration Tests
```

---

# 30. Domain Testing

Domain Tests должны работать без:

```
Flutter
SQLite
Drift
Network
AI Provider
```

Это позволяет тестировать Business Logic быстро и детерминированно.

---

# 31. Application Testing

Application Tests должны использовать test doubles для внешних зависимостей.

Например:

```
CreateTaskUseCase
      ↓
FakeTaskRepository
```

Это позволяет тестировать use case без реальной SQLite Database.

---

# 32. Infrastructure Testing

Infrastructure должна тестироваться на реальных технических компонентах там, где это необходимо.

Например:

```
Repository
   ↓
Drift
   ↓
SQLite
```

Для Sync:

```
Sync Engine
   ↓
Test Transport
   ↓
Persistence
```

---

# 33. Presentation Testing

Presentation должна тестироваться через:

- Widget Tests;
- integration tests;
- пользовательские сценарии.

Presentation Tests не должны требовать реального AI Provider или production Sync Service.

---

# 34. Configuration

Configuration должна быть отделена от Business Logic.

Например:

```
Development
Testing
Production
```

Могут иметь различные:

- AI Provider;
- logging;
- Sync endpoint;
- feature flags;
- database configuration.

---

# 35. Logging

Logging является Infrastructure concern.

Domain не должен напрямую использовать конкретный logging package.

При необходимости может существовать abstraction:

```
abstract interface class Logger {
  void info(String message);
  void error(String message);
}
```

Конкретная реализация находится в Infrastructure.

---

# 36. Observability

Архитектура должна предусматривать возможность диагностировать:

- database errors;
- sync failures;
- AI failures;
- performance issues;
- migration failures;
- application crashes.

Конкретная observability technology не определяется этим ADR.

---

# 37. Project Structure

Предварительная структура:

```
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   └── dependencies.dart
│
├── presentation/
│   ├── features/
│   ├── navigation/
│   └── widgets/
│
├── application/
│   ├── tasks/
│   ├── relationships/
│   ├── search/
│   └── sync/
│
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/
│   ├── services/
│   └── events/
│
└── infrastructure/
    ├── persistence/
    │   └── drift/
    │
    ├── sync/
    │
    ├── ai/
    │
    └── platform/
```

Это является базовой структурой и может эволюционировать по мере роста проекта.

---

# 38. Dependency Rules

Каждый слой имеет следующие разрешённые зависимости:

```text
Presentation
    ↓
Application
    ↓
Domain

Infrastructure
    ↓
Domain
````

Дополнительные правила:

- Presentation может зависеть от Application;
- Application может зависеть от Domain;
- Infrastructure может зависеть от Domain Interfaces;
- Infrastructure не зависит от Presentation;
- Infrastructure не зависит от конкретных Presentation State;
- Application не зависит от конкретных Infrastructure Implementations;
- Domain не зависит от Presentation;
- Domain не зависит от Infrastructure;
- Domain не зависит от Flutter;
- конкретные Implementations связываются через Composition Root.

Composition Root:

```
app/
   ↓
создаёт конкретные Implementations
   ↓
передаёт их в Application
```

Таким образом, Dependency Inversion сохраняется независимо от конкретного DI Framework.

---

# 39. Запрещённая архитектура

Не допускается:

```
Widget
 ↓
Drift DAO
 ↓
SQLite
```

или:

```
Widget
 ↓
OpenAI SDK
```

или:

```
Domain Entity
 ↓
Drift Table
```

или:

```
Domain
 ↓
Flutter BuildContext
```

Такие зависимости создают сильную связанность и затрудняют тестирование и развитие проекта.

---

# 40. Принцип минимальной архитектуры

Архитектура не должна создавать abstraction ради abstraction.

Например, не следует создавать:

```
IRepositoryFactory
IRepositoryProvider
IRepositoryManager
IRepositoryResolver
```

если они не решают реальную проблему.

Каждая abstraction должна иметь конкретную архитектурную цель.

---

# 41. Эволюция структуры

По мере роста LifeOS структура может перейти от layer-first к hybrid feature architecture.

Например:

```
lib/
├── app/
│
├── features/
│   ├── tasks/
│   │   ├── presentation/
│   │   ├── application/
│   │   └── domain/
│   │
│   └── relationships/
│       ├── presentation/
│       ├── application/
│       └── domain/
│
└── infrastructure/
```

Однако переход на такую структуру не выполняется заранее.

Он должен быть оправдан реальным размером проекта.

---

# 42. Почему не используем Clean Architecture буквально

LifeOS использует принципы Clean Architecture, но не требует буквального копирования всех её шаблонов.

Мы не обязаны создавать отдельные классы и interfaces для каждой операции только ради соответствия методологии.

Основные принципы:

```
Dependency Inversion
Separation of Concerns
Domain Independence
Testability
```

важнее конкретного названия архитектурного паттерна.

---

# 43. Почему не используем MVVM как основную архитектуру

MVVM может использоваться внутри Presentation Layer, если это окажется удобным.

Однако MVVM не является общей архитектурой приложения.

Например:

```
MVVM
 ↓
Presentation
```

а не:

```
LifeOS
 ↓
MVVM
 ↓
Everything
```

Общая архитектура определяется слоями Domain / Application / Infrastructure / Presentation.

---

# 44. Scalability

Архитектура должна позволять добавлять:

- новые Entity;
- новые Features;
- новые AI Providers;
- новые Sync Providers;
- новые Persistence implementations;
- новые платформы;
- новые UI surfaces.

При этом существующий Domain Layer должен изменяться минимально.

---

# 45. Offline-First Compatibility

Архитектура полностью совместима с Local-First моделью.

Основной путь данных:

```
User
 ↓
Presentation
 ↓
Application
 ↓
Domain
 ↓
Repository
 ↓
SQLite
```

Remote Sync является дополнительным механизмом:

```
SQLite
 ↓
Outbox
 ↓
Sync
 ↓
Remote
```

Приложение не должно требовать network connection для выполнения базовых локальных операций.

---

# 46. AI Compatibility

AI не является обязательной частью базовой Domain Logic.

Например:

```
User
 ↓
Application
 ↓
AI Interface
 ↓
AI Infrastructure
 ↓
Provider
```

Если AI Provider недоступен, базовые Local-First функции приложения должны продолжать работать, если конкретный use case не требует AI.

---

# 47. Security Boundary

Security-sensitive operations должны находиться в Infrastructure.

Например:

- secure storage;
- encryption;
- credentials;
- API keys;
- authentication tokens;
- platform security APIs.

Domain не должен хранить или обрабатывать provider-specific secrets.

---

# 48. Performance Boundary

Performance-sensitive operations могут выполняться в Infrastructure.

Например:

- database queries;
- indexing;
- Sync processing;
- AI request preparation;
- large data transformations.

Однако оптимизация не должна нарушать архитектурные границы без необходимости.

---

# 49. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретный State Management Framework;
- конкретный DI Framework;
- конкретную Navigation Library;
- конкретный Logging Package;
- конкретную AI Model;
- конкретный AI Provider;
- конкретный Sync Provider;
- конкретную SQLite Schema;
- конкретные Drift Tables;
- конкретные Repository APIs;
- конкретный folder structure для каждой Feature;
- конкретную platform implementation.

Эти решения принимаются отдельными ADR или во время реализации, если они не требуют отдельного архитектурного решения.

---

# 50. Последствия решения

## Положительные

- чёткое разделение ответственности;
- Domain независим от Flutter;
- Domain независим от Drift;
- AI можно менять независимо от Domain;
- Sync можно развивать независимо от UI;
- Persistence можно заменить с ограниченным влиянием;
- тестирование становится проще;
- архитектура совместима с Local-First;
- проект может постепенно масштабироваться;
- структура остаётся понятной для небольшого MVP.

## Отрицательные

- больше файлов и слоёв;
- необходимо соблюдать dependency rules;
- требуется mapping между некоторыми моделями;
- первоначальная структура сложнее простого Flutter-приложения;
- разработчику необходимо понимать архитектурные границы;
- некоторые простые операции могут потребовать прохождения через несколько слоёв.

---

# 51. MVP Strategy

Для первого прототипа необходимо реализовать не всю архитектуру целиком, а один полноценный vertical slice.

Минимальный пример:

```text
Create Note
     ↓
Application Use Case
     ↓
Domain Note
     ↓
NoteRepository
     ↓
Drift
     ↓
SQLite
     ↓
Read Note
     ↓
Presentation
````

Этот vertical slice должен подтвердить работу всей цепочки:

```
Flutter UI
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
```

При этом необходимо сохранить реальные архитектурные границы:

- UI не обращается напрямую к Drift;
- Domain не зависит от Flutter;
- Domain не зависит от Drift;
- Repository Interface отделён от Repository Implementation;
- Persistence остаётся в Infrastructure.

После успешной проверки первого vertical slice можно постепенно добавлять:

```
Relationships
Outbox
Sync
AI
Search
```

Необходимо избегать реализации будущих подсистем до появления реальной необходимости их проверить.

---

# 52. Validation

Архитектура ADR-0022 должна быть проверена техническим прототипом.

Прототип должен подтвердить:

- корректность dependency direction;
- работу Repository Boundary;
- работу Drift;
- тестируемость Domain;
- тестируемость Application;
- возможность подключения Infrastructure;
- корректную работу Flutter UI;
- возможность замены Infrastructure implementation.

---

# 53. Следующий шаг

После принятия ADR-0022 необходимо создать минимальный Flutter project skeleton.

Первый технический milestone:

```
Flutter Project
      ↓
Architecture Skeleton
      ↓
Domain
      ↓
Application
      ↓
Repository
      ↓
Drift
      ↓
SQLite
      ↓
Simple UI
```

После успешного создания skeleton можно перейти к реализации первого vertical slice LifeOS.

На этом этапе документация должна начать уступать место практической проверке архитектуры.