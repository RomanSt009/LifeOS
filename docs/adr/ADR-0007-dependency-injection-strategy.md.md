# ADR-0007: Стратегия Dependency Injection LifeOS

**Статус:** Предварительно принято  
**Дата:** 2026-08-14  
**Версия:** 0.1

## Контекст

LifeOS состоит из большого количества независимых компонентов.

Например:

```text
UI
Application
Domain
Repository
Database
AI
Search
Sync
Security
````

Эти компоненты должны взаимодействовать друг с другом, но не должны быть жёстко связаны с конкретными реализациями.

Например, Application Layer не должен знать:

- используется ли SQLite;
- какой именно AI Provider подключён;
- какой механизм синхронизации используется;
- какая реализация Repository используется.

Без Dependency Injection архитектура может быстро превратиться в систему с большим количеством жёстких зависимостей.

---

# 1. Проблема жёстких зависимостей

Нежелательный вариант:

```
TaskService
    ↓
SQLiteRepository
```

В таком случае `TaskService` напрямую зависит от конкретной реализации.

Если понадобится заменить SQLite:

```
SQLite
   ↓
другая Database
```

придётся изменять `TaskService`.

Это нарушает принцип разделения ответственности.

---

# 2. Решение

LifeOS использует **Dependency Injection** для передачи зависимостей компонентам приложения.

Вместо:

```
TaskService
   ↓
создаёт SQLiteRepository самостоятельно
```

используется:

```
TaskService
   ↑
Repository
```

Конкретная реализация передаётся извне.

---

# 3. Основной принцип

Компонент должен зависеть от абстракции, а не от конкретной реализации.

Например:

```
Application
    ↓
TaskRepository
```

а не:

```
Application
    ↓
SQLiteTaskRepository
```

Конкретная реализация определяется на уровне сборки приложения.

---

# 4. Dependency Graph

Концептуально:

```
                 Application
                      │
                      ↓
                TaskRepository
                      │
             ┌────────┴────────┐
             ↓                 ↓
     SQLiteRepository    MockRepository
```

Application не знает, какая реализация используется.

---

# 5. Repository Example

Например, определяем контракт:

```
TaskRepository
```

Он может предоставлять:

```
createTask()
getTask()
updateTask()
deleteTask()
```

Но не сообщает Application Layer, как именно данные сохраняются.

Реализация:

```
SQLiteTaskRepository
```

использует Drift/SQLite.

Для тестов:

```
InMemoryTaskRepository
```

может хранить данные в памяти.

---

# 6. AI Provider

Dependency Injection особенно важен для AI.

Вместо:

```
Application
   ↓
OpenAI
```

используется:

```
Application
   ↓
AIProvider
```

с реализациями:

```
CloudAIProvider
LocalAIProvider
MockAIProvider
```

Например:

```
                 AIProvider
                     │
          ┌──────────┼──────────┐
          ↓          ↓          ↓
       Cloud        Local       Mock
        AI            AI          AI
```

---

# 7. Почему это важно для LifeOS

AI-модели будут меняться.

Сегодня может использоваться одна модель:

```
Model A
```

а позднее:

```
Model B
```

или:

```
Local Model
```

Application Layer при этом не должен изменяться.

Меняется только реализация:

```
AIProvider
```

---

# 8. Database

Та же архитектура используется для базы.

Например:

```
Repository
    ↓
DatabaseService
```

Конкретная реализация:

```
DriftDatabase
```

Application Layer не должен напрямую импортировать Drift.

---

# 9. Sync

Синхронизация также является заменяемым компонентом.

Например:

```
SyncService
```

может иметь реализацию:

```
CloudSyncService
```

В будущем:

```
SelfHostedSyncService
```

или:

```
LocalNetworkSyncService
```

Application Layer не должен знать конкретную реализацию.

---

# 10. Search

Поисковая система также может использовать абстракцию:

```
SearchService
```

Реализации:

```
SqlSearchService
FullTextSearchService
SemanticSearchService
```

В дальнейшем можно использовать комбинацию:

```
HybridSearchService
```

без изменения UI.

---

# 11. Dependency Direction

Зависимости должны направляться внутрь архитектуры.

Концептуально:

```
┌──────────────────────────┐
│            UI            │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│       Application        │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│          Domain          │
└──────────────────────────┘

Infrastructure
      ↓
implements
      ↓
Application / Domain contracts
```

Infrastructure не должна определять бизнес-правила Domain.

---

# 12. Composition Root

Все конкретные зависимости должны собираться в одном контролируемом месте.

Это называется:

**Composition Root**

Концептуально:

```
main()
  ↓
create database
  ↓
create repositories
  ↓
create AI provider
  ↓
create services
  ↓
create application
  ↓
run UI
```

Таким образом, приложение знает:

> какие конкретные реализации используются.

Но сами бизнес-компоненты не обязаны это знать.

---

# 13. Dependency Injection Container

Для LifeOS допускается использование DI-контейнера.

Однако на раннем этапе не следует добавлять сложный DI-фреймворк без необходимости.

Основной принцип:

> Сначала простая и понятная DI-архитектура, затем автоматизация там, где она действительно полезна.

---

# 14. GetIt

В качестве возможного инструмента Dependency Injection для Flutter рассматривается:

```
get_it
```

GetIt предоставляет Service Locator / Dependency Injection механизм для Dart/Flutter.

Однако использование GetIt не является обязательным архитектурным требованием.

Архитектура должна оставаться независимой от конкретного DI-пакета.

---

# 15. Почему не делать всё через глобальные Singleton

Нежелательный вариант:

```
GlobalDatabase.instance
GlobalAI.instance
GlobalSync.instance
```

Проблемы:

- скрытые зависимости;
- сложнее тестирование;
- сложнее заменять реализации;
- сложнее понимать архитектуру;
- повышается связность.

---

# 16. Singleton и DI

Singleton сам по себе не является запрещённым.

Некоторые инфраструктурные компоненты могут существовать в одном экземпляре.

Например:

```
Database
```

Но управление жизненным циклом должно происходить через Composition Root / DI.

То есть:

```
DI
 ↓
Database instance
```

предпочтительнее:

```
Database.instance
```

доступного отовсюду.

---

# 17. Constructor Injection

Основным способом передачи зависимостей используется Constructor Injection.

Например концептуально:

```
TaskService(
    TaskRepository repository
)
```

Таким образом зависимость видна непосредственно в контракте компонента.

---

# 18. Почему Constructor Injection

Преимущества:

- зависимости очевидны;
- проще тестировать;
- меньше скрытой магии;
- проще анализировать архитектуру;
- меньше глобального состояния.

---

# 19. Method Injection

Передача зависимости непосредственно в метод допускается в случаях, когда зависимость нужна только одной операции.

Например:

```
generateReport(
    ReportExporter exporter
)
```

Но это не должно становиться основным способом построения приложения.

---

# 20. Property Injection

Property Injection не используется как основной подход.

Например:

```
service.repository = repository
```

может привести к состоянию:

```
service exists
repository missing
```

что создаёт возможность ошибок во время выполнения.

---

# 21. Dependency Lifecycle

Зависимости имеют жизненный цикл.

Например:

```
Application lifetime
    ↓
Database
```

или:

```
Request / operation
    ↓
temporary service
```

На первом этапе достаточно поддерживать три концептуальных режима:

```
Singleton
Scoped
Factory
```

Конкретное использование будет определяться по мере реализации.

---

# 22. Database Lifecycle

SQLite/Drift database обычно должна существовать в течение жизненного цикла приложения.

Концептуально:

```
Application Start
      ↓
Open Database
      ↓
Application Running
      ↓
Close Database
      ↓
Application Exit
```

---

# 23. AI Provider Lifecycle

AI Provider может иметь более сложный жизненный цикл.

Например:

```
AIProvider
   ↓
HTTP client
   ↓
API request
```

HTTP client может быть переиспользован.

Конкретная стратегия будет определена при реализации AI слоя.

---

# 24. Testing

DI является критически важным для тестирования.

Например Production:

```
TaskService
    ↓
SQLiteRepository
```

Test:

```
TaskService
    ↓
InMemoryRepository
```

Application код при этом остаётся одинаковым.

---

# 25. AI Testing

Аналогично:

Production:

```
AIProvider
    ↓
Cloud AI
```

Test:

```
AIProvider
    ↓
Mock AI
```

Можно проверить:

```
CreateTaskFromIntent
```

не выполняя реальный API-запрос.

---

# 26. Sync Testing

Production:

```
SyncService
    ↓
Remote API
```

Test:

```
SyncService
    ↓
Mock Remote
```

Это позволит тестировать:

- retry;
- conflicts;
- failures;
- offline scenarios;

без реального сервера.

---

# 27. Dependency Graph Validation

DI-граф не должен содержать циклических зависимостей.

Нежелательно:

```
A
 ↓
B
 ↓
C
 ↓
A
```

Это необходимо проверять при проектировании и тестировании.

---

# 28. Domain Independence

Domain Layer не должен зависеть от:

```
Flutter
Drift
SQLite
HTTP
AI SDK
```

Domain должен оставаться максимально чистым.

Например:

```
Domain
├── Entity
├── Value Object
├── Business Rule
└── Domain Service
```

---

# 29. Application Layer

Application Layer может зависеть от абстракций:

```
Repository
AIProvider
SearchService
SyncService
```

Но не должен напрямую зависеть от конкретных инфраструктурных реализаций.

---

# 30. Infrastructure Layer

Infrastructure реализует необходимые интерфейсы.

Например:

```
Infrastructure
├── Drift
├── SQLite
├── HTTP
├── AI SDK
├── File System
└── Sync
```

---

# 31. UI Layer

UI взаимодействует с Application Layer.

Желательная схема:

```
UI
 ↓
Application Command / Query
 ↓
Domain
 ↓
Repository
```

UI не должен:

- писать SQL;
- обращаться напрямую к AI API;
- выполнять Sync;
- изменять Domain напрямую.

---

# 32. Dependency Graph LifeOS

Итоговая модель:

```
                         UI
                          │
                          ↓
                    Application
                          │
              ┌───────────┼───────────┐
              ↓           ↓           ↓
         Repository    AIProvider   Search
              │           │           │
              ↓           ↓           ↓
        Infrastructure Infrastructure Infrastructure
              │           │           │
              ↓           ↓           ↓
           SQLite       AI API       Search
```

---

# 33. Принцип заменяемости

Любая внешняя технология должна рассматриваться как заменяемая зависимость.

Например:

```
AI Provider
Database
Search Engine
Sync Backend
File Storage
```

Если технология меняется:

```
Old Implementation
       ↓
New Implementation
```

Domain и Application должны оставаться максимально неизменными.

---

# 34. Что не следует абстрагировать заранее

Не каждая библиотека требует собственного интерфейса.

Например, бессмысленно создавать:

```
LoggerInterface
LoggerFactoryInterface
LoggerProviderInterface
LoggerAdapterInterface
```

если проекту требуется просто один стабильный logging package.

Абстракция должна появляться там, где существует реальная вероятность:

- замены;
- тестирования;
- нескольких реализаций;
- изоляции внешней зависимости.

---

# 35. YAGNI

LifeOS придерживается принципа:

> **You Aren't Gonna Need It**

Не создаём сложную инфраструктуру только потому, что она теоретически может понадобиться.

Сначала:

```
простое решение
```

затем:

```
реальная проблема
```

затем:

```
абстракция / масштабирование
```

---

# 36. DI и архитектурные границы

Dependency Injection используется не для усложнения кода.

Его задача:

```
Разделить
        ↓
что компонент делает
        ↓
от
        ↓
как конкретно это реализовано
```

Например:

```
TaskService
```

знает:

> "Мне нужен TaskRepository."

Но не знает:

> "Мне нужен SQLite через Drift версии X."

---

# 37. Основные правила

Для Dependency Injection LifeOS принимаются следующие правила:

1. Зависимости передаются извне.
2. Основной способ — Constructor Injection.
3. Domain не зависит от Infrastructure.
4. Application зависит от абстракций.
5. Infrastructure реализует необходимые контракты.
6. Конкретные реализации собираются в Composition Root.
7. Глобальные Singleton-доступы не используются как основной механизм.
8. DI-контейнер является инструментом, а не архитектурным требованием.
9. GetIt рассматривается как возможный DI-инструмент.
10. Не следует создавать абстракции без реальной необходимости.
11. DI должен облегчать тестирование.
12. Зависимости не должны образовывать циклические графы.

---

# 38. Последствия решения

## Положительные

- слабая связанность;
- простое тестирование;
- возможность менять AI Provider;
- возможность менять Repository;
- возможность заменять Sync;
- возможность использовать Mock;
- более понятные архитектурные границы;
- постепенное масштабирование.

## Отрицательные

- больше интерфейсов;
- больше файлов;
- необходимо понимать Dependency Graph;
- требуется дисциплина при проектировании;
- чрезмерное использование DI может усложнить небольшой код.

---

# 39. Что пока не решаем

Не фиксируем окончательно:

- конкретную DI-библиотеку;
- конкретный Service Locator;
- сложную lifecycle-систему;
- автоматическую code generation;
- конкретную структуру Composition Root.

Эти решения будут приниматься во время создания Flutter-проекта.

---

# 40. Следующие ADR

После ADR-0007:

ADR-0008:  
AI Provider Architecture

ADR-0009:  
Synchronization Architecture

ADR-0010:  
Security Architecture

ADR-0011:  
Backup and Export Architecture

ADR-0012:  
Search Architecture

---

# Итог

LifeOS использует Dependency Injection для разделения архитектурных компонентов.

Основной принцип:

```
Component
    ↓
depends on abstraction
    ↓
implementation provided externally
```

Например:

```
Application
    ↓
AIProvider
    ↓
CloudAIProvider
```

или:

```
Application
    ↓
TaskRepository
    ↓
DriftTaskRepository
```

Это позволяет изменять технологии и конкретные реализации без необходимости переписывать бизнес-логику LifeOS.

Главный принцип:

> **Компонент должен знать, что ему нужно сделать, но не обязан знать, как конкретно это реализовано.**

````

### Что важно понять тебе сейчас

Не нужно пока глубоко разбираться в DI. На уровне проекта тебе достаточно запомнить одну аналогию.

Представь, что у нас есть **розетка**:

```text
TaskService
     │
     │ требует
     ▼
  Розетка
     │
     ├── SQLite
     ├── тестовая база
     └── другая база
````

`TaskService` говорит: **«Мне нужна база, с которой я могу сохранить задачу»**.

Он не говорит: **«Мне обязательно нужна именно SQLite»**.

Поэтому через год мы можем поменять технологию, а большая часть LifeOS даже не заметит этого.

И это ровно тот же принцип, который мы решили применить к AI:

```
LifeOS
   ↓
AIProvider
   ↓
сегодня → одна модель
завтра → другая модель
позже → локальная модель
```