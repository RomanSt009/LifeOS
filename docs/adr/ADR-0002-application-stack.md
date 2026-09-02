# ADR-0002: Выбор основного технологического стека приложения

**Статус:** Предварительно принято  
**Дата:** 2026-08-12  
**Версия:** 0.1

## Контекст

В ADR-0001 был выбран Flutter как основной UI-фреймворк LifeOS и Dart как основной язык разработки.

Следующим шагом необходимо определить внутренний технологический стек Flutter-приложения.

LifeOS является долгосрочным проектом, который должен поддерживать:

- desktop как первоначальную платформу;
    
- последующее развитие на Android и iOS;
    
- local-first архитектуру;
    
- локальное хранение данных;
    
- синхронизацию;
    
- AI;
    
- сложную систему сущностей и связей;
    
- масштабирование функциональности;
    
- тестируемость;
    
- возможность замены отдельных инфраструктурных компонентов без переписывания всей системы.
    

Главная архитектурная цель:

> Технологические библиотеки не должны определять бизнес-логику LifeOS.

Бизнес-логика должна оставаться независимой от Flutter UI, базы данных, AI-провайдеров и механизмов синхронизации.

---

# Рассмотренные компоненты

## 1. Управление состоянием — Riverpod

### Решение

Для управления состоянием приложения предварительно выбирается:

**Riverpod**

### Причины

Riverpod позволяет:

- управлять состоянием UI;
    
- управлять зависимостями;
    
- разделять состояние разных частей приложения;
    
- удобно тестировать зависимости;
    
- организовывать асинхронные операции;
    
- постепенно масштабировать приложение.
    

Особенно важно, что Riverpod может использоваться как механизм связывания Presentation и Application слоёв, не становясь частью Domain Logic.

### Принцип

```text
Flutter UI
    ↓
Riverpod
    ↓
Application Layer
    ↓
Domain
```

Domain не должен зависеть от Riverpod.

---

# 2. Навигация — GoRouter

### Решение

Для навигации предварительно выбирается:

**GoRouter**

### Причины

LifeOS должен иметь большое количество экранов и вложенных состояний.

В будущем возможны:

```text
Home
Tasks
Projects
Project Details
Notes
Note Details
People
Person Details
Search
AI
Settings
```

Навигация должна быть централизованной и поддерживать desktop, tablet и mobile сценарии.

GoRouter выбран как отдельный слой навигации, не связанный с бизнес-логикой.

---

# 3. Локальная база данных — SQLite + Drift

### Решение

Для локального хранения данных выбирается:

**SQLite**

Для работы с SQLite в Dart/Flutter предварительно выбирается:

**Drift**

### Причины

LifeOS является local-first приложением.

Локальная база должна поддерживать:

- большое количество сущностей;
    
- связи между сущностями;
    
- индексы;
    
- транзакции;
    
- фильтрацию;
    
- сортировку;
    
- миграции;
    
- сложные запросы;
    
- работу без подключения к интернету.
    

SQLite хорошо соответствует этим требованиям.

Drift добавляется как типобезопасный слой работы с SQLite.

### Архитектурная схема

```text
LifeOS
   ↓
Repository
   ↓
Drift
   ↓
SQLite
```

Application и Domain слои не должны напрямую обращаться к SQLite.

---

# 4. Модели данных — Freezed

### Решение

Для immutable-моделей и некоторых типов данных предварительно выбирается:

**Freezed**

### Причины

LifeOS будет иметь большое количество моделей:

```text
Task
Project
Note
Person
Event
Relationship
Attachment
AI Context
Sync State
```

Модели должны быть предсказуемыми и безопасными при изменении состояния.

Freezed помогает создавать immutable data models и поддерживать различные варианты одного типа данных.

### Важное ограничение

Freezed не является частью Domain Architecture.

Это инструмент реализации моделей.

Domain-модель не должна зависеть от конкретного UI-фреймворка.

---

# 5. Сериализация — json_serializable

### Решение

Для сериализации JSON предварительно выбирается:

**json_serializable**

### Использование

JSON может использоваться для:

- API;
    
- AI providers;
    
- синхронизации;
    
- импорта и экспорта;
    
- конфигурации;
    
- обмена данными.
    

Сериализация должна находиться на границе инфраструктуры.

Пример:

```text
External API
     ↓
JSON
     ↓
Infrastructure
     ↓
Domain Model
```

Domain не должен знать, что данные пришли из JSON.

---

# 6. Secure Storage

Для хранения секретов и чувствительных технических данных будет использоваться отдельный механизм защищённого хранения, подходящий для целевых платформ.

На уровне архитектуры необходимо разделять:

```text
Application Data
```

и

```text
Secrets
```

Например:

```text
SQLite
    ↓
LifeOS data

Secure Storage
    ↓
API keys
Tokens
Credentials
```

Конкретная библиотека secure storage будет окончательно выбрана отдельным ADR перед реализацией соответствующей функциональности.

---

# 7. Архитектурные слои

Выбранный стек должен использоваться внутри следующей архитектуры:

```text
┌─────────────────────────────────────┐
│           Presentation              │
│                                     │
│ Flutter Widgets                     │
│ Riverpod                            │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│           Application               │
│                                     │
│ Use Cases                           │
│ Commands                            │
│ Queries                             │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│              Domain                 │
│                                     │
│ Entities                            │
│ Value Objects                       │
│ Business Rules                      │
│ Domain Services                     │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│          Infrastructure             │
│                                     │
│ Drift / SQLite                      │
│ AI Providers                        │
│ Sync                                │
│ File Storage                        │
│ External APIs                       │
└─────────────────────────────────────┘
```

---

# 8. Dependency Direction

Зависимости должны направляться внутрь архитектуры.

Правильная схема:

```text
Presentation
      ↓
Application
      ↓
Domain
```

Infrastructure реализует интерфейсы, определённые архитектурой:

```text
Infrastructure
      ↓
implements
      ↓
Domain / Application contracts
```

Не допускается:

```text
Domain
  ↓
Flutter
```

или:

```text
Domain
  ↓
Drift
```

или:

```text
Domain
  ↓
AI Provider
```

---

# 9. Repository Pattern

Работа с данными должна происходить через Repository.

Например:

```text
TaskRepository
ProjectRepository
NoteRepository
PersonRepository
```

Application Layer работает с интерфейсом:

```text
TaskRepository
```

а Infrastructure предоставляет реализацию:

```text
DriftTaskRepository
```

Таким образом:

```text
Application
     ↓
TaskRepository
     ↑
DriftTaskRepository
     ↓
Drift
     ↓
SQLite
```

Это позволяет в будущем заменить способ хранения данных без изменения Use Cases.

---

# 10. AI Integration

AI не должен быть встроен непосредственно в UI.

Правильная архитектура:

```text
UI
 ↓
AI Use Case
 ↓
Context Engine
 ↓
AI Provider Interface
 ↓
AI Provider Implementation
```

Например:

```text
AIProvider
   ↑
   ├── OpenAIProvider
   ├── LocalAIProvider
   └── OtherProvider
```

Конкретный AI-провайдер не должен определять архитектуру LifeOS.

---

# 11. Sync Integration

Синхронизация также является инфраструктурной частью системы.

Предварительная схема:

```text
Application
      ↓
Sync Service
      ↓
Sync Engine
      ↓
Remote Storage / API
```

Локальная база остаётся основным рабочим источником данных для offline-first сценария.

Детальная архитектура синхронизации описывается отдельно в:

```text
docs/05-ui-ux/
```

или соответствующем архитектурном документе проекта.

---

# 12. Testing

Архитектура должна поддерживать несколько уровней тестирования.

## Unit Tests

Проверяют:

- Domain;
    
- Use Cases;
    
- бизнес-правила;
    
- преобразования данных.
    

## Repository Tests

Проверяют:

- работу с SQLite;
    
- запросы;
    
- миграции;
    
- сохранение данных.
    

## Widget Tests

Проверяют:

- отдельные UI-компоненты;
    
- состояния;
    
- пользовательские взаимодействия.
    

## Integration Tests

Проверяют полноценные сценарии:

```text
Capture
 ↓
Create Entity
 ↓
Save
 ↓
Search
 ↓
Open Entity
```

---

# 13. Минимизация зависимостей

LifeOS не должен использовать библиотеку только потому, что она популярна.

Новая зависимость добавляется только при наличии конкретной проблемы.

Принцип:

```text
Problem
   ↓
Evaluate
   ↓
Choose library if justified
   ↓
Document decision
```

Не следует заранее добавлять:

- несколько state management решений;
    
- несколько ORM;
    
- несколько routing libraries;
    
- несколько DI frameworks;
    
- библиотеки, которые не используются в MVP.
    

---

# 14. Предварительный стек

На данном этапе выбран следующий основной стек:

|Область|Решение|
|---|---|
|UI Framework|Flutter|
|Language|Dart|
|State / Dependencies|Riverpod|
|Navigation|GoRouter|
|Local Database|SQLite|
|SQLite Layer|Drift|
|Data Models|Freezed|
|JSON Serialization|json_serializable|
|Secrets|Platform Secure Storage|
|Architecture|Layered / Clean-inspired|
|Testing|Flutter Test + Integration Tests|

---

# 15. Что сознательно НЕ выбираем сейчас

До возникновения конкретной необходимости не добавляем:

```text
BLoC
GetX
Provider
Hive
Isar
Firebase
Redux
MobX
Multiple ORM solutions
Multiple DI frameworks
```

Это не означает, что эти технологии плохие.

Они просто не нужны одновременно.

Если появится проблема, требующая другой технологии, решение будет оформлено отдельным ADR.

---

# 16. Почему выбран именно такой подход

LifeOS должен быть долгосрочным проектом.

Поэтому архитектура должна позволять заменить отдельные компоненты.

Например:

```text
SQLite
  ↓
может измениться

AI Provider
  ↓
может измениться

Sync Provider
  ↓
может измениться

UI components
  ↓
могут измениться
```

При этом:

```text
Domain
Business Rules
Use Cases
```

должны оставаться максимально стабильными.

---

# 17. Главный архитектурный принцип

Технологии являются инструментами.

Они не должны становиться архитектурой продукта.

```text
Business Rules
      ↑
   Domain
      ↑
Application
      ↑
Infrastructure / Presentation
```

Flutter, Riverpod, Drift и другие библиотеки являются реализационными инструментами вокруг ядра LifeOS.

---

# 18. Последствия решения

## Положительные

- единый технологический стек;
    
- хорошая поддержка desktop и mobile;
    
- типобезопасность;
    
- локальное хранение;
    
- возможность offline-first;
    
- тестируемость;
    
- возможность замены инфраструктурных компонентов;
    
- относительно небольшое количество зависимостей;
    
- хорошая база для дальнейшего масштабирования.
    

## Отрицательные

- необходимо изучить несколько новых библиотек;
    
- архитектура сложнее простого Flutter-приложения;
    
- потребуется дисциплина при разделении слоёв;
    
- некоторые решения могут потребовать дополнительного кода;
    
- необходимо следить за совместимостью библиотек между desktop и mobile.
    

---

# 19. Статус решений

На момент создания ADR:

```text
Flutter
    Accepted

Dart
    Accepted

Riverpod
    Accepted

GoRouter
    Accepted

SQLite
    Accepted

Drift
    Accepted

Freezed
    Accepted

json_serializable
    Accepted

Secure Storage
    Pending detailed ADR

AI Provider
    Pending

Sync Provider
    Pending
```

---

# 20. Следующие решения

После ADR-0002 необходимо определить:

```text
ADR-0003
Project Structure

ADR-0004
Dependency Injection strategy

ADR-0005
Domain Model / Entity architecture

ADR-0006
Local-first data architecture

ADR-0007
Sync architecture

ADR-0008
AI provider architecture
```

Номера могут измениться в зависимости от фактической последовательности решений.

---

# 21. Итог

Для LifeOS предварительно принимается следующий принцип:

> Flutter отвечает за пользовательский интерфейс, Riverpod — за состояние и зависимости Presentation/Application слоя, Drift — за работу с SQLite, а Domain и Application остаются независимыми от конкретных инфраструктурных технологий.

Базовая архитектура:

```text
                 LifeOS
                    │
                 Flutter
                    │
               Presentation
                    │
                 Riverpod
                    │
               Application
                    │
                  Domain
                    │
             Infrastructure
               /    |     \
           Drift    AI     Sync
             │
           SQLite
```

Данное решение является основой для дальнейшего проектирования структуры Flutter-проекта.