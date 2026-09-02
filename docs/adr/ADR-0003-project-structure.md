# ADR-0003: Структура Flutter-проекта LifeOS

**Статус:** Предварительно принято  
**Дата:** 2026-08-13  
**Версия:** 0.1

## Контекст

LifeOS является долгосрочным проектом.

Приложение должно постепенно развиваться от первого desktop MVP до полноценной кроссплатформенной системы для:

- Windows;
- macOS;
- Linux;
- Android;
- iOS;
- потенциально Web.

В будущем LifeOS будет содержать большое количество функциональных областей:

- задачи;
- проекты;
- заметки;
- люди;
- события;
- связи между сущностями;
- поиск;
- AI;
- контекст;
- синхронизация;
- настройки;
- локальное хранилище;
- импорт и экспорт;
- уведомления;
- аналитика;
- пользовательские настройки.

Поэтому структура проекта должна позволять добавлять новые возможности без превращения проекта в большое неструктурированное хранилище файлов.

---

# Решение

Для LifeOS выбирается модульная структура проекта, основанная на разделении:

1. Presentation;
2. Application;
3. Domain;
4. Infrastructure;
5. Core / Shared.

При этом функциональные возможности приложения организуются вокруг отдельных feature-модулей.

Основной принцип:

> Код группируется не только по техническому типу, но и по ответственности конкретного функционального модуля.

---


# 1. Общая структура проекта

Предварительная структура:

```text
lifeos/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── assets/
│   ├── icons/
│   ├── images/
│   ├── fonts/
│   └── animations/
│
├── lib/
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── router/
│   │   ├── theme/
│   │   └── config/
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── logging/
│   │   ├── result/
│   │   ├── utils/
│   │   └── platform/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── value_objects/
│   │   ├── repositories/
│   │   └── services/
│   │
│   ├── application/
│   │   ├── use_cases/
│   │   ├── commands/
│   │   ├── queries/
│   │   └── services/
│   │
│   ├── infrastructure/
│   │   ├── database/
│   │   ├── ai/
│   │   ├── sync/
│   │   ├── storage/
│   │   ├── network/
│   │   └── repositories/
│   │
│   └── features/
│       ├── capture/
│       ├── inbox/
│       ├── tasks/
│       ├── projects/
│       ├── notes/
│       ├── people/
│       ├── calendar/
│       ├── search/
│       ├── ai/
│       ├── settings/
│       └── home/
│
├── test/
│
├── integration_test/
│
├── pubspec.yaml
└── README.md
````

---

# 2. Почему используется несколько уровней

На первый взгляд структура может показаться сложной.

Но она разделяет разные типы ответственности.

Например:

```
Feature
    ↓
Что делает пользователь?

Application
    ↓
Что должна сделать система?

Domain
    ↓
Какие правила существуют в LifeOS?

Infrastructure
    ↓
Как технически выполнить операцию?

Presentation
    ↓
Как показать результат пользователю?
```

Это позволяет не смешивать UI, бизнес-логику и работу с базой данных.

---

# 3. App

Каталог:

```
lib/app/
```

Содержит конфигурацию самого приложения.

Например:

```
app.dart
router/
theme/
config/
```

### `app.dart`

Создаёт корневое Flutter-приложение.

Здесь могут находиться:

- MaterialApp / адаптация;
- глобальная конфигурация;
- подключение router;
- глобальные providers.

---

# 4. Core

Каталог:

```
lib/core/
```

Содержит действительно общие компоненты, которые не принадлежат конкретной бизнес-функции.

Например:

```
errors/
logging/
extensions/
constants/
utils/
platform/
```

### Главное правило

В `core` нельзя складывать всё подряд.

Если компонент используется только задачами, он должен находиться в `tasks`.

Если компонент относится только к AI, он должен находиться в `ai`.

Core предназначен только для действительно общих механизмов.

---

# 5. Domain

Каталог:

```
lib/domain/
```

Это ядро бизнес-логики LifeOS.

Здесь находятся:

```
entities/
value_objects/
repositories/
services/
```

Domain не должен зависеть от:

- Flutter UI;
- SQLite;
- Drift;
- конкретного AI-провайдера;
- HTTP;
- платформенных API.

---

# 6. Entities

Например:

```
lib/domain/entities/
```

Здесь находятся основные сущности LifeOS.

Предварительно:

```
Task
Project
Note
Person
Event
Relationship
Attachment
```

В будущем список будет расширяться.

Важно:

> Сущность должна описывать бизнес-объект, а не экран приложения.

Например:

```
Task
```

является сущностью.

А:

```
TaskScreen
```

не является сущностью Domain.

---

# 7. Value Objects

Каталог:

```
lib/domain/value_objects/
```

Используется для небольших типов, имеющих собственное значение и правила.

Например:

```
EntityId
Email
Url
DateRange
Money
```

Это позволяет не передавать по всей системе обычные строки и числа там, где требуется более строгая модель.

---

# 8. Repository Interfaces

Каталог:

```
lib/domain/repositories/
```

Здесь определяются интерфейсы доступа к данным.

Например:

```
TaskRepository
ProjectRepository
NoteRepository
```

Domain определяет:

> Какие операции мне нужны?

Но не знает:

> Где физически находятся данные?

Например:

```
abstract class TaskRepository {
  Future<Task?> getById(EntityId id);

  Future<List<Task>> getAll();

  Future<void> save(Task task);

  Future<void> delete(EntityId id);
}
```

Это концептуальный пример.

Конкретная реализация будет находиться в Infrastructure.

---

# 9. Application

Каталог:

```
lib/application/
```

Application отвечает за выполнение сценариев пользователя.

Здесь находятся:

```
use_cases/
commands/
queries/
services/
```

Например:

```
CreateTask
CompleteTask
CreateProject
ConnectEntities
SearchEntities
GenerateAIContext
```

Application связывает Domain с внешним миром.

---

# 10. Use Cases

Use Case описывает конкретное действие системы.

Например:

```
CreateTask
```

может:

```
1. Получить входные данные
2. Проверить правила
3. Создать Task
4. Сохранить Task через Repository
5. Вернуть результат
```

UI не должен самостоятельно выполнять эти действия.

Вместо:

```
Button
 ↓
SQLite
```

должно быть:

```
Button
 ↓
CreateTask
 ↓
TaskRepository
 ↓
Infrastructure
 ↓
SQLite
```

---

# 11. Commands и Queries

В дальнейшем мы будем разделять операции на:

### Command

Изменяет состояние системы.

Примеры:

```
CreateTask
CompleteTask
UpdateProject
DeleteNote
ConnectEntities
```

### Query

Получает данные без изменения состояния.

Примеры:

```
GetTask
SearchTasks
GetProject
FindRelatedEntities
```

Это подготовит архитектуру к дальнейшему масштабированию.

---

# 12. Infrastructure

Каталог:

```
lib/infrastructure/
```

Содержит технические реализации.

Например:

```
database/
ai/
sync/
storage/
network/
repositories/
```

Здесь может находиться:

```
Drift
SQLite
HTTP clients
AI SDKs
File system
Secure storage
Sync implementation
```

Infrastructure знает о внешних технологиях.

Domain — нет.

---

# 13. Repositories Implementation

Например:

```
lib/infrastructure/repositories/
```

может содержать:

```
DriftTaskRepository
DriftProjectRepository
DriftNoteRepository
```

Связь:

```
Domain
TaskRepository
      ↑
      │ implements
      │
DriftTaskRepository
      ↓
Drift
      ↓
SQLite
```

---

# 14. Features

Каталог:

```
lib/features/
```

Здесь находятся пользовательские функциональные области.

Например:

```
capture/
inbox/
tasks/
projects/
notes/
people/
calendar/
search/
ai/
settings/
home/
```

Feature отвечает на вопрос:

> Какую возможность получает пользователь?

---

# 15. Структура Feature

Каждая feature может иметь собственные слои.

Например:

```
features/tasks/

├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
│
├── application/
│   └── ...
│
└── data/
    └── ...
```

Однако на начальном этапе не требуется создавать все эти каталоги заранее.

Структура должна расти вместе с функциональностью.

---

# 16. Не создавать пустые каталоги заранее

Это важное правило проекта.

Не нужно создавать:

```
50 папок
100 файлов
```

только потому, что они могут понадобиться в будущем.

Например, если пока нет календаря:

```
features/calendar/
```

может не существовать.

Она появляется тогда, когда начинается разработка календаря.

---

# 17. Presentation

Presentation отвечает за отображение и взаимодействие пользователя с приложением.

Включает:

- Flutter Widgets;
- Pages;
- UI components;
- Riverpod providers;
- UI state.

Presentation не должна содержать сложную бизнес-логику.

Например:

```
TaskPage
```

может вызвать:

```
CompleteTask
```

но сама не должна решать, разрешено ли завершать задачу.

---

# 18. AI Feature

AI будет отдельной функциональной областью:

```
features/ai/
```

Но сама AI-инфраструктура находится:

```
infrastructure/ai/
```

Разделение:

```
features/ai/
    ↓
Пользовательский AI-интерфейс

infrastructure/ai/
    ↓
Подключение к AI-провайдеру
```

Это позволяет менять AI-провайдера независимо от UI.

---

# 19. Sync Feature

Аналогично синхронизация разделяется:

```
Application
     ↓
Sync Service
     ↓
Infrastructure
     ↓
Remote API
```

Пользовательский интерфейс синхронизации может находиться в:

```
features/settings/
```

или отдельной feature.

---

# 20. Platform-specific Code

Flutter позволяет использовать общий код, но иногда потребуется платформенный код.

Например:

```
lib/core/platform/
```

может содержать абстракции.

Конкретные реализации находятся в платформенных слоях:

```
android/
ios/
linux/
macos/
windows/
```

Основной принцип:

> Платформенная специфика должна быть изолирована и не распространяться по всему приложению.

---

# 21. Assets

Каталог:

```
assets/
```

предназначен для статических ресурсов:

```
assets/
├── icons/
├── images/
├── fonts/
└── animations/
```

Ресурсы должны подключаться через `pubspec.yaml`.

---

# 22. Tests

Тесты разделяются на несколько уровней.

```
test/
```

Для unit и widget tests.

```
integration_test/
```

Для интеграционных сценариев.

Например:

```
test/
├── domain/
├── application/
├── infrastructure/
└── features/

integration_test/
├── capture_flow_test.dart
├── task_flow_test.dart
└── search_flow_test.dart
```

Структура тестов должна отражать структуру приложения.

---

# 23. Зависимости между слоями

Основное правило:

```
Presentation
      ↓
Application
      ↓
Domain
```

Infrastructure реализует необходимые интерфейсы:

```
Infrastructure
      ↓
implements
      ↓
Domain contracts
```

Запрещается прямой путь:

```
Widget
 ↓
Drift
```

или:

```
Widget
 ↓
SQLite
```

или:

```
Widget
 ↓
OpenAI SDK
```

Вместо этого:

```
Widget
 ↓
Application
 ↓
Domain Contract
 ↓
Infrastructure
```

---

# 24. Feature и Domain

Feature не должна создавать собственную копию бизнес-сущности без необходимости.

Например:

```
Task
```

является Domain Entity.

Feature `tasks` использует эту сущность.

Не следует создавать:

```
TaskEntity
TaskModel
TaskDto
TaskUiModel
```

без реальной необходимости.

Дополнительные модели появляются только тогда, когда они решают конкретную архитектурную задачу.

---

# 25. Почему не используем чистую Feature-First архитектуру

Можно было бы организовать весь проект так:

```
features/
├── tasks/
├── projects/
├── notes/
└── people/
```

и внутри каждой feature полностью разместить:

```
domain/
application/
data/
presentation/
```

Этот подход имеет преимущества.

Однако для LifeOS на раннем этапе важно иметь единое Domain ядро.

LifeOS будет содержать большое количество связей между сущностями.

Например:

```
Task
 ↕
Project
 ↕
Person
 ↕
Note
 ↕
Event
```

Поэтому Domain является общей частью системы.

---

# 26. Предварительная структура после реализации MVP

После появления первых функций структура может выглядеть примерно так:

```
lib/
│
├── app/
│
├── core/
│
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/
│   └── services/
│
├── application/
│   ├── commands/
│   ├── queries/
│   └── services/
│
├── infrastructure/
│   ├── database/
│   ├── repositories/
│   ├── ai/
│   ├── sync/
│   ├── storage/
│   └── network/
│
└── features/
    ├── home/
    ├── capture/
    ├── inbox/
    ├── tasks/
    ├── projects/
    ├── notes/
    ├── people/
    ├── search/
    ├── ai/
    └── settings/
```

Это не означает, что все каталоги должны существовать с первого дня.

---

# 27. Правило роста проекта

Структура должна развиваться постепенно.

```
MVP
 ↓
Добавилась функция
 ↓
Появился новый Use Case
 ↓
Появилась новая Domain Entity
 ↓
Появилась инфраструктурная реализация
 ↓
Добавилась UI Feature
```

Не наоборот.

Мы не проектируем заранее структуру на тысячу файлов.

---

# 28. Принцип «не усложнять раньше времени»

Архитектура должна быть достаточно строгой, чтобы защищать проект от хаоса.

Но недостаточно сложной, чтобы замедлять разработку.

Поэтому:

> Добавляем архитектурный слой тогда, когда он решает реальную проблему.

Например:

если Use Case простой:

```
CreateTask
```

не нужно создавать десять дополнительных классов только ради архитектурной чистоты.

---

# 29. Связь с ADR-0002

ADR-0002 определяет технологический стек.

ADR-0003 определяет место этих технологий.

Например:

```
Riverpod
    ↓
Presentation / Application

Drift
    ↓
Infrastructure

SQLite
    ↓
Infrastructure

Freezed
    ↓
Domain / Data Models

GoRouter
    ↓
App / Presentation
```

---

# 30. Последствия решения

## Положительные

- проект легко ориентировать;
- бизнес-логика отделена от UI;
- инфраструктура изолирована;
- легче тестировать;
- легче заменять технологии;
- проще масштабировать функциональность;
- легче переносить приложение на mobile;
- структура отражает архитектуру продукта.

## Отрицательные

- структура сложнее простого Flutter-приложения;
- разработчику нужно понимать границы слоёв;
- некоторые простые функции потребуют несколько файлов;
- необходимо следить за правильным направлением зависимостей.

---

# 31. Основной принцип структуры LifeOS

Главный принцип:

> **UI показывает, Application выполняет сценарии, Domain определяет правила, Infrastructure работает с внешним миром.**

В упрощённом виде:

```
             USER
               ↓
          Presentation
               ↓
          Application
               ↓
             Domain
               ↑
               │
        Infrastructure
               ↓
      SQLite / AI / Sync
```

---

# 32. Статус

На момент создания ADR:

```
Project Structure
    Accepted

Layered Architecture
    Accepted

Feature Modules
    Accepted

Shared Domain
    Accepted

Infrastructure Separation
    Accepted

Platform Isolation
    Accepted

Exact folder structure
    Preliminary
```

Структура каталогов может изменяться по мере развития проекта.

Изменения, которые существенно влияют на архитектуру, должны фиксироваться отдельным ADR.

---

# 33. Следующие решения

После ADR-0003 необходимо определить:

```
ADR-0004
Dependency Injection Strategy

ADR-0005
Domain Entity Architecture

ADR-0006
Local-first Data Architecture

ADR-0007
Database and Persistence Strategy

ADR-0008
AI Provider Architecture

ADR-0009
Synchronization Architecture
```

Порядок может изменяться в зависимости от развития проекта.

---

# Итог

LifeOS будет использовать модульную layered architecture с общим Domain ядром и отдельными Feature-модулями.

Основная структура:

```
Presentation
     ↓
Application
     ↓
Domain
     ↑
Infrastructure
```

Feature-модули отвечают за пользовательские возможности, а Domain остаётся общим ядром бизнес-правил.

Структура проекта должна развиваться вместе с продуктом и не создавать заранее неиспользуемые слои и файлы.

````

### Что мы сейчас зафиксировали

Самое главное здесь не названия папок, а **границы ответственности**.

Например, когда мы потом напишем кнопку:

> «Завершить задачу»

мы не будем делать так:

```text
Кнопка → база данных
````

Мы будем постепенно строить:

```
Кнопка
  ↓
CompleteTask
  ↓
TaskRepository
  ↓
Drift
  ↓
SQLite
```

А если через год мы решим поменять SQLite — кнопка и бизнес-логика при этом не должны переписываться.

И ещё важное: **не создавай сейчас все эти папки вручную в проекте**. Это пока архитектурная схема. Когда мы дойдём до создания самого Flutter-проекта, я проведу тебя по созданию реальной структуры постепенно. Так мы не получим сотню пустых папок ещё до появления первой функции.