# ADR-0016: Domain Model and Entity Architecture

**Статус:** Предварительно принято  
**Дата:** 2026-08-18  
**Версия:** 0.1

## 1. Контекст

LifeOS должен работать не как обычный набор заметок, задач и папок, а как единая система взаимосвязанных сущностей.

Пользователь может создавать:

- задачи;
- заметки;
- проекты;
- идеи;
- людей;
- документы;
- события;
- цели;
- ресурсы;
- другие типы данных.

При этом одна сущность может быть связана с несколькими другими.

Например:
```text
Project
   |
   ├── Task
   ├── Note
   ├── Document
   ├── Person
   └── Idea
```

Эти связи являются важной частью контекста LifeOS.

Поэтому необходимо определить единую Domain Model, которая позволит системе развиваться без постоянной перестройки фундаментальной архитектуры.

---

# 2. Основная идея

LifeOS строится вокруг концепции:

**Entity + Relationship + Context + Lifecycle**

```
             LifeOS Domain
                  |
       ┌──────────┼──────────┐
       ↓          ↓          ↓
    Entity   Relationship  Context
       |
    Lifecycle
```

---

# 3. Entity

Entity — это самостоятельный объект предметной области LifeOS, который имеет собственную идентичность.

Примеры:

```
Task
Project
Note
Idea
Person
Document
Goal
Event
```
---

# 4. Identity

Каждая Entity имеет уникальный идентификатор.

Концептуально:
```
Entity
├── id
├── type
├── created_at
└── updated_at
```
ID должен сохраняться в течение всего жизненного цикла Entity.

---

# 5. Stable Identity

Изменение содержимого Entity не должно менять её ID.

Например:
```
Task ID:
task_123

Title:
"Создать архитектуру"
        ↓
"Создать архитектуру LifeOS"

ID остаётся:
task_123
```

---

# 6. Entity Type

Каждая Entity имеет тип.

Например:
```
task
project
note
person
idea
document
goal
event
```
Тип определяет Domain semantics Entity.

---

# 7. Base Entity

Все Entity используют общий фундамент.

Концептуально:
```
BaseEntity
├── id
├── type
├── created_at
├── updated_at
├── lifecycle_state
└── version
```
Конкретные поля зависят от типа Entity.

---
# 8. Entity Data

Например Task:
```
Task
├── id
├── title
├── description
├── status
├── priority
├── due_date
└── ...
```
Project:
```
Project
├── id
├── name
├── description
└── ...
```
---

# 9. Не все Entity одинаковы

LifeOS не должен превращать все данные в одну универсальную таблицу без Domain semantics.

Неправильный подход:

Entity

├── field1

├── field2

├── field3

├── field4

└── ...

Правильный подход:

Entity

   |

   ├── Task

   ├── Project

   ├── Note

   ├── Person

   └── ...

при наличии общего базового контракта.

---

# 10. Entity-specific Data

Каждый тип Entity имеет собственные свойства.

Например:

Task

status

priority

due_date

и:

Person

name

email

role

не должны искусственно объединяться в один набор полей.

---

# 11. Entity Relationships

Entity могут быть связаны между собой.

Например:

Project

   ↓

contains

   ↓

Task

или:

Person

   ↓

works_on

   ↓

Project

---

# 12. Relationship как отдельная концепция

Relationship не является просто строковым полем внутри Entity.

Например:

Task.project_id

может быть недостаточно для сложной системы.

LifeOS рассматривает Relationship как самостоятельную часть Domain Model.

---

# 13. Relationship

Концептуально:

Relationship

├── id

├── source_entity_id

├── target_entity_id

├── type

├── created_at

└── metadata

---

# 14. Direction

Некоторые связи направлены.

Например:

Task

  ──belongs_to──>

Project

Другие могут быть симметричными.

Например:

Person

  ──knows──

Person

Архитектура должна поддерживать оба варианта.

---

# 15. Relationship Type

Тип связи является частью Domain semantics.

Примеры:

contains

belongs_to

depends_on

blocks

related_to

created_by

assigned_to

derived_from

references

---

# 16. Typed Relationships

Связь должна иметь тип.

Например:

Task

   ──depends_on──>

Task

отличается от:

Task

   ──related_to──>

Task

---

# 17. Relationship Metadata

Некоторые связи могут иметь дополнительные данные.

Например:

Relationship

├── type: assigned_to

├── source: Task

├── target: Person

└── metadata:

      role: owner

---

# 18. Relationship Strength

В будущем Relationship может иметь степень уверенности или силы.

Например:

strong

medium

weak

Однако конкретная модель strength не фиксируется этим ADR.

---

# 19. AI-generated Relationships

AI может предлагать связи.

Например:

Task A

   ↓

AI suggests

   ↓

related_to

   ↓

Note B

---

# 20. AI не должен безусловно создавать связи

AI-generated relationship должен проходить через установленную политику.

AI

 ↓

Suggested Relationship

 ↓

Validation

 ↓

Permission / Policy

 ↓

Create

---

# 21. Confidence

AI может указывать confidence:

confidence:

0.87

Но confidence не означает автоматически:

confirmed = true

---

# 22. Relationship Status

Связь может иметь состояние:

PROPOSED

CONFIRMED

REJECTED

ARCHIVED

---

# 23. Human Override

Пользователь должен иметь возможность исправить AI-generated Relationship.

Например:

AI:

Task A related_to Note B

  

User:

Reject

или:

User:

Change to depends_on

---

# 24. Human Authority

Если пользователь явно изменил AI-предложение, пользовательское решение имеет приоритет.

AI Suggestion

      ↓

User Correction

      ↓

User-defined Relationship

---

# 25. Context

Context — это временная или логическая область, в которой Entity рассматривается системой.

Например:

Current Project:

LifeOS

может влиять на:

- поиск;
- AI;
- рекомендации;
- отображение;
- ranking;
- связанные Entity.

---

# 26. Context не является Entity

Context не обязательно является отдельной Domain Entity.

Он может быть вычисляемым состоянием.

Entity

 +

Relationships

 +

User State

 =

Context

---

# 27. Context Sources

Context может формироваться из:

- текущего экрана;
- выбранного проекта;
- текущей задачи;
- последних действий;
- активного поиска;
- связанных Entity;
- пользовательских настроек;
- AI Session.

---

# 28. Context Window

AI получает не весь граф LifeOS, а ограниченный Context Window.

LifeOS Graph

      ↓

Context Selection

      ↓

Relevant Entities

      ↓

AI Context

---

# 29. Entity Graph

LifeOS можно представить как граф:

             Project

            /   |   \

           /    |    \

        Task   Note   Idea

         |       |

      Person   Document

Entity являются узлами.

Relationships являются рёбрами.

---

# 30. Graph не должен быть единственной моделью хранения

Graph representation является логической моделью.

Физическое хранение может использовать:

- relational database;
- graph-like tables;
- indexes;
- vector index;
- другие структуры.

Конкретная реализация определяется Database Architecture.

---

# 31. Domain Model vs Storage Model

Domain Model и Database Schema не должны быть полностью идентичны.

Domain Model

     ↓

Persistence Layer

     ↓

Database

Это позволит менять storage implementation без изменения всей бизнес-логики.

---

# 32. Domain Layer

Архитектура должна разделять:

Presentation

Application

Domain

Infrastructure

---

# 33. Domain

Domain содержит:

- Entity;
- Value Objects;
- Relationships;
- Domain Rules;
- Domain Events.

Domain не должен зависеть от Flutter UI.

---

# 34. Application Layer

Application Layer координирует use cases.

Например:

CreateTask

UpdateTask

LinkEntities

ArchiveEntity

SearchEntities

---

# 35. Infrastructure

Infrastructure отвечает за:

- Database;
- File System;
- Sync;
- AI Providers;
- Embedding Providers;
- external services.

---

# 36. Presentation

Presentation отвечает за:

- Flutter UI;
- screens;
- widgets;
- navigation;
- user interaction.

---

# 37. Dependency Direction

Зависимости должны идти внутрь:

Presentation

      ↓

Application

      ↓

Domain

      ↑

Infrastructure

Infrastructure реализует интерфейсы, определённые внутренними слоями.

---

# 38. Domain Independence

Domain Model не должен зависеть от:

- Flutter;
- конкретной Database;
- конкретного AI Provider;
- конкретного Sync Provider;
- конкретного Vector Database.

---

# 39. Value Objects

Некоторые данные лучше моделировать как Value Objects.

Например:

EntityId

DateRange

Priority

EmailAddress

EntityReference

---

# 40. EntityId

EntityId должен быть типизированным значением, а не произвольной строкой во всей системе.

Например концептуально:

EntityId

├── value

└── entity_type

---

# 41. EntityReference

Для ссылки на другую Entity может использоваться:

EntityReference

├── entity_id

└── entity_type

---

# 42. Domain Rules

Domain Rules определяют допустимые состояния.

Например:

Task

COMPLETED

не должна одновременно иметь состояние:

NOT_STARTED

если Domain Model этого не допускает.

---

# 43. State Machine

Для Entity с жизненным циклом может использоваться state machine.

Например Task:

BACKLOG

   ↓

IN_PROGRESS

   ↓

COMPLETED

---

# 44. Entity Lifecycle

Каждая Entity имеет lifecycle.

Базовые состояния:

ACTIVE

ARCHIVED

DELETED

Конкретные типы могут иметь дополнительные состояния.

---

# 45. Soft Delete

По умолчанию удаление Entity должно быть логическим, если Domain допускает это.

ACTIVE

  ↓

DELETED

Физическое удаление выполняется отдельно.

---

# 46. Restore

Если Entity находится в состоянии, допускающем восстановление:

DELETED

   ↓

RESTORED

   ↓

ACTIVE

---

# 47. Archive

Archive отличается от Delete.

ACTIVE

   ↓

ARCHIVED

Archived Entity сохраняет данные, но обычно исключается из активного Context.

---

# 48. Lifecycle and Search

По умолчанию:

ACTIVE     → included

ARCHIVED   → optional

DELETED    → excluded

---

# 49. Lifecycle and AI

AI по умолчанию должен получать:

ACTIVE

и только необходимые Archived Entity.

Deleted Entity не должны попадать в обычный AI Context.

---

# 50. Lifecycle and Relationships

При удалении Entity её Relationships не обязательно физически удалять сразу.

Они могут стать неактивными или быть обработаны отдельным lifecycle policy.

---

# 51. Version

Entity должна иметь версию.

Например:

version:

42

Version может использоваться для:

- concurrency;
- sync;
- conflict detection;
- optimistic locking;
- audit.

---

# 52. Optimistic Concurrency

При изменении Entity система может проверять версию.

Client A → version 10

Client B → version 10

  

A saves → version 11

  

B saves version 10

        ↓

Conflict

---

# 53. Domain Events

Изменения Domain Model могут порождать события.

Например:

EntityCreated

EntityUpdated

EntityArchived

EntityDeleted

RelationshipCreated

RelationshipRemoved

---

# 54. Domain Events не равны UI Events

Domain Event описывает изменение состояния системы.

UI Event описывает взаимодействие пользователя с интерфейсом.

Они не должны смешиваться.

---

# 55. Event-driven Extensions

Domain Events могут использоваться для:

- indexing;
- embeddings;
- sync;
- audit;
- notifications.

Например:

EntityUpdated

      |

      ├── Search Index

      ├── Embedding Job

      └── Sync

---

# 56. Derived Data

Некоторые данные являются производными:

Embedding

Search Index

AI Summary

Recommendations

Caches

Они не должны считаться Source of Truth.

---

# 57. Source of Truth

Source of Truth:

Domain State

Производные данные могут быть пересозданы.

---

# 58. AI-generated Data

AI может создавать:

- summary;
- tags;
- relationships;
- classifications;
- suggestions.

Но такие данные должны иметь происхождение.

---

# 59. Provenance

AI-generated данные должны по возможности содержать provenance.

Например:

GeneratedBy:

AI

  

Provider:

...

  

Model:

...

  

Timestamp:

...

---

# 60. AI Suggestions

Предложение AI не обязательно сразу становится Domain State.

Например:

AI Suggestion

      ↓

PENDING

      ↓

User Approves

      ↓

Domain Entity

---

# 61. User-created Data

Пользовательские данные имеют более высокий уровень доверия, чем AI Suggestions.

Например:

User Relationship

не должна автоматически перезаписываться:

AI Relationship

---

# 62. Conflict Resolution

Если AI предлагает изменить пользовательское значение:

User Data

   +

AI Suggestion

AI не должен автоматически перезаписывать данные пользователя.

---

# 63. Metadata

Entity может иметь технические metadata.

Например:

created_at

updated_at

version

source

Но metadata не должна превращаться в бесконтрольный набор полей.

---

# 64. Custom Fields

В будущем пользователь может захотеть собственные поля.

Например:

Task

├── title

├── priority

└── custom:

      estimate: 4h

Custom Fields не входят в базовый MVP и требуют отдельной архитектуры.

---

# 65. Extensibility

Domain Model должна позволять добавлять новые Entity Types без переписывания существующих.

Например:

v1:

Task

Note

Project

  

v2:

Goal

Person

Event

  

v3:

Resource

Habit

Area

---

# 66. Plugin-like Entity Types

В будущем некоторые Entity Types могут предоставляться модулями.

Core

 |

 ├── Task

 ├── Note

 └── Project

  

Extensions

 |

 ├── Habit

 ├── Finance

 └── CRM

Это не является обязательной частью MVP.

---

# 67. Core Entity Types

Для MVP предлагается ограниченный набор:

Task

Note

Project

Person

Document

Idea

Дополнительные типы будут добавляться по мере необходимости.

---

# 68. Task

Минимально:

Task

├── id

├── title

├── description

├── status

├── priority

├── due_date

├── created_at

├── updated_at

└── version

---

# 69. Project

Минимально:

Project

├── id

├── name

├── description

├── status

├── created_at

├── updated_at

└── version

---

# 70. Note

Минимально:

Note

├── id

├── title

├── content

├── created_at

├── updated_at

└── version

---

# 71. Person

Минимально:

Person

├── id

├── name

├── notes

├── created_at

├── updated_at

└── version

---

# 72. Document

Минимально:

Document

├── id

├── title

├── content_reference

├── mime_type

├── created_at

├── updated_at

└── version

---

# 73. Idea

Минимально:

Idea

├── id

├── title

├── description

├── status

├── created_at

├── updated_at

└── version

---

# 74. Entity Relationships Example

LifeOS может содержать:

Project: LifeOS

      |

      ├── contains ──> Task: ADR-0016

      |

      ├── contains ──> Note: Domain Model

      |

      ├── related_to ──> Idea: Knowledge Graph

      |

      └── assigned_to ──> Person: Roman

---

# 75. Graph Traversal

Context Engine может проходить Relationships:

Current Task

    ↓

Project

    ↓

Related Notes

    ↓

Related Documents

Но traversal должен иметь ограничения.

---

# 76. Traversal Depth

Чтобы не загружать весь граф:

Depth 0

Current Entity

  

Depth 1

Direct Relations

  

Depth 2

Relations of Relations

Конкретный default depth определяется Context Engine.

---

# 77. Cycles

Граф может содержать циклы:

A → B

B → C

C → A

Context Engine и Search Engine должны уметь предотвращать бесконечный traversal.

---

# 78. Relationship Constraints

Некоторые Relationship Types могут иметь ограничения.

Например:

Task

belongs_to

Project

может разрешать только определённые типы source/target.

---

# 79. Relationship Validation

Перед созданием Relationship:

Source exists?

      ↓

Target exists?

      ↓

Relationship Type valid?

      ↓

Permission valid?

      ↓

Create

---

# 80. Referential Integrity

Удаление или архивирование Entity должно учитывать существующие Relationships.

---

# 81. Orphan Relationships

Неактивные Relationships не должны бесконтрольно накапливаться.

Необходим lifecycle policy для orphan relationships.

---

# 82. Entity Garbage Collection

Удалённые и неиспользуемые производные данные могут очищаться.

Но физическое удаление Domain Data является отдельной операцией.

---

# 83. Dead Entities

Entity не должна оставаться бессмысленным «мёртвым грузом» только потому, что была когда-то создана AI.

AI-generated Entity должна проходить lifecycle.

Например:

PROPOSED

   ↓

ACTIVE

или:

PROPOSED

   ↓

REJECTED

   ↓

CLEANUP

---

# 84. AI-generated Entity Lifecycle

Для AI-created объектов может использоваться:

PROPOSED

PENDING

ACTIVE

ARCHIVED

REJECTED

DELETED

Конкретная state machine будет определена отдельной спецификацией.

---

# 85. Context Lifecycle

Context также должен быть временным.

Например:

AI Session

    ↓

Context

    ↓

Session End

    ↓

Context expires

Не весь Context должен сохраняться навсегда.

---

# 86. Persistent Context

Некоторые результаты Context могут становиться Domain Data.

Например:

Temporary AI Context

       ↓

User approves

       ↓

Note

---

# 87. Separation of Temporary and Persistent Data

Это важный принцип:

Temporary AI State

        ≠

Domain State

AI не должен превращать каждый промежуточный результат в постоянную Entity.

---

# 88. Entity Creation Policy

Новая Entity может быть создана:

- пользователем;
- AI через Tool;
- импортом;
- синхронизацией;
- системным процессом.

Источник должен быть известен.

---

# 89. Entity Source

Например:

source:

USER

AI

IMPORT

SYNC

SYSTEM

---

# 90. Provenance Chain

Для импортированных или AI-generated данных желательно сохранять происхождение.

Source

 ↓

Transformation

 ↓

Entity

---

# 91. Domain Events + Sync

Domain Event может инициировать Sync:

EntityUpdated

      ↓

Sync Queue

Но Domain не должен зависеть непосредственно от Sync implementation.

---

# 92. Domain Events + Search

EntityUpdated

      ↓

Search Index Update

---

# 93. Domain Events + AI

Изменение Entity может создавать AI background job.

Например:

NoteUpdated

      ↓

Embedding Job

Но AI не должен автоматически менять Domain State без соответствующей политики.

---

# 94. Transactions

Изменение Entity и её критических Relationships должно выполняться в контролируемой транзакции, когда это необходимо.

---

# 95. Atomic Relationship Changes

Например:

Create Task

+

Assign Project

может быть одной Domain Operation.

---

# 96. Domain Services

Если бизнес-логика не принадлежит одной Entity, может использоваться Domain Service.

Например:

RelationshipService

LifecycleService

ContextService

Конкретный набор будет определён в реализации.

---

# 97. Repository Abstraction

Domain/Application Layer не должны напрямую обращаться к Database.

Используются Repository Interfaces.

Application

     ↓

Repository Interface

     ↑

Infrastructure

     ↓

Database

---

# 98. Repository Responsibility

Repository отвечает за persistence, но не должен становиться местом всей бизнес-логики.

---

# 99. Use Cases

Application Layer предоставляет use cases:

CreateEntity

UpdateEntity

ArchiveEntity

RestoreEntity

CreateRelationship

RemoveRelationship

SearchEntities

---

# 100. Domain Model Principles

Для Domain Model принимаются следующие принципы:

1. LifeOS строится вокруг Entity.
2. Entity имеют стабильную идентичность.
3. Entity имеют тип.
4. Все Entity имеют общий базовый контракт.
5. Entity-specific data остаётся типизированной.
6. Relationships являются отдельной концепцией Domain Model.
7. Relationships имеют тип.
8. Relationships могут быть направленными или симметричными.
9. Relationships проходят validation.
10. AI может предлагать Relationships.
11. AI не получает безусловное право изменять Relationships.
12. Пользователь может корректировать AI-generated Relationships.
13. Пользовательские изменения имеют приоритет.
14. Context является отдельным понятием.
15. Context не обязан быть Entity.
16. Context является ограниченным представлением Domain Graph.
17. Context Engine не должен загружать весь граф без необходимости.
18. Entity Graph является логической моделью.
19. Graph Model не определяет физическую Database implementation.
20. Domain Model отделена от Storage Model.
21. Domain не зависит от Flutter.
22. Domain не зависит от AI Provider.
23. Domain не зависит от Database implementation.
24. Domain не зависит от Sync implementation.
25. Используются Value Objects там, где это оправдано.
26. Entity имеют Lifecycle.
27. Archive и Delete различаются.
28. Soft Delete предпочтителен, если это допустимо.
29. Entity имеют version.
30. Optimistic Concurrency поддерживается архитектурно.
31. Domain Events используются для интеграции производных систем.
32. Derived Data не является Source of Truth.
33. AI-generated Data имеет provenance.
34. AI Suggestions могут быть временными.
35. Temporary AI State не равен Domain State.
36. Новая Entity должна иметь source.
37. Entity Types должны быть расширяемыми.
38. MVP использует ограниченный набор Core Entity Types.
39. Relationships должны иметь lifecycle policy.
40. Context traversal имеет ограничения.
41. Graph cycles должны обрабатываться.
42. Repository abstractions отделяют Domain от persistence.
43. Application Layer содержит use cases.
44. Domain Services используются только там, где это необходимо.
45. Domain Model является фундаментом для AI, Search, Sync и UI.

---

# 101. MVP Entity Types

Первоначально предлагаются:

Task

Note

Project

Person

Document

Idea

Этот список является предварительным и может измениться после прототипирования.

---

# 102. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную Database;
- конкретную SQLite schema;
- конкретный ORM;
- точный формат serialization;
- конкретную Sync implementation;
- конкретный AI Provider;
- конкретную embedding model;
- UI representation Entity;
- конкретный Flutter state management;
- конкретный JSON формат API;
- полный список Entity Types;
- финальную Relationship Taxonomy;
- точные Lifecycle State Machines.

---

# 103. Последствия решения

## Положительные

- появляется единая модель данных LifeOS;
- AI, Search и Sync работают с одной Domain Model;
- Relationships становятся полноценной частью системы;
- Context Engine может работать поверх графа Entity;
- Domain не зависит от конкретных технологий хранения;
- новые Entity Types можно добавлять постепенно;
- AI-generated данные можно контролировать;
- появляется понятное разделение Domain и Derived Data;
- упрощается дальнейшее тестирование;
- архитектура готова к масштабированию.

## Отрицательные

- Domain Model становится сложнее обычного CRUD-приложения;
- Relationships требуют отдельной инфраструктуры;
- Lifecycle требует дополнительных состояний;
- AI-generated данные требуют provenance;
- Context traversal требует ограничений;
- необходимо следить за количеством Entity и Relationships;
- потребуется более серьёзная Database Architecture;
- понадобится тщательное тестирование Domain Rules.

---

# 104. Связанные ADR

Связанные архитектурные решения:

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

# 105. Следующий шаг

Следующим логичным документом является:

**ADR-0017: Database and Persistence Architecture**

В нём мы определим, где и как физически будут храниться Entity, Relationships, Lifecycle, версии и производные данные.

После него фундаментальная цепочка будет выглядеть так:

ADR-0016

Domain Model

      ↓

ADR-0017

Database / Persistence

      ↓

ADR-0018

Sync Architecture

      ↓

Technical Implementation

      ↓

Flutter / Dart Code

Именно после этого мы уже сможем начать переходить от архитектурной документации к **реальному проекту Flutter**.