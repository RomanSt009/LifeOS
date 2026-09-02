# ADR-0014: AI Tool Calling and Permissions

  

**Статус:** Предварительно принято  

**Дата:** 2026-08-18  

**Версия:** 0.1

  

## 1. Контекст

  

AI в LifeOS должен уметь не только отвечать на вопросы, но и взаимодействовать с системой.

  

Например:

  

- найти задачу;

- получить информацию о проекте;

- создать задачу;

- изменить статус;

- создать заметку;

- связать две сущности;

- выполнить поиск;

- предложить изменение;

- выполнить действие после подтверждения пользователя.

  

Однако предоставление AI прямого доступа к базе данных или внутренним сервисам представляет значительный риск.

  

AI-модель не должна самостоятельно выполнять произвольные операции с системой.

  

Поэтому между AI и возможностями LifeOS вводится отдельный механизм:

  

**AI Tool Calling**

  

---

  

# 2. Решение

  

AI взаимодействует с LifeOS через ограниченный набор явно определённых Tools.

  

Архитектура:

  

```text

User

  ↓

AI

  ↓

Tool Request

  ↓

Tool Permission Check

  ↓

Tool

  ↓

Application Service

  ↓

Domain

  ↓

Database
```

AI не получает прямого доступа к:

- Database;
- File System;
- OS;
- Network;
- Secrets;
- внутренним сервисам.

---

# 3. Основной принцип

Главный принцип:

> AI может попросить систему выполнить действие, но не получает автоматическое право на его выполнение.

То есть:

AI intent

   ↓

Tool Request

   ↓

Permission Check

   ↓

Execution

---

# 4. AI Tool

Tool — это строго определённая возможность LifeOS, доступная AI.

Например:

search_entities

get_entity

create_task

update_task

create_note

link_entities

Каждый Tool имеет заранее определённый контракт.

---

# 5. Tool Contract

Каждый Tool должен определять:

- имя;
- назначение;
- входные параметры;
- типы параметров;
- обязательные параметры;
- допустимые значения;
- возвращаемый результат;
- требуемые permissions;
- уровень риска;
- необходимость подтверждения пользователя.

Концептуально:

Tool

├── name

├── description

├── input_schema

├── output_schema

├── permission

├── risk_level

└── confirmation_policy

---

# 6. Tool не является API Database

Tool не должен быть прямой обёрткой над Database.

Неправильная архитектура:

AI

 ↓

SQL Tool

 ↓

Database

Правильная:

AI

 ↓

Tool

 ↓

Application Service

 ↓

Domain Logic

 ↓

Repository

 ↓

Database

---

# 7. Почему запрещён прямой Database Access

Прямой доступ AI к Database может позволить модели:

- читать лишние данные;
- изменять неподходящие записи;
- удалять данные;
- обходить бизнес-правила;
- обходить permissions;
- выполнять непредусмотренные операции.

Tool Layer должен ограничивать возможности AI.

---

# 8. Read Tools

Read Tools используются для получения информации.

Примеры:

search_entities

get_entity

get_related_entities

get_project

get_tasks

Read Tools обычно имеют более низкий риск.

---

# 9. Write Tools

Write Tools изменяют состояние LifeOS.

Примеры:

create_task

update_task

create_note

link_entities

change_status

Write Tools должны иметь более строгий контроль.

---

# 10. Delete Tools

Delete Tools являются отдельной категорией риска.

Например:

delete_entity

delete_task

delete_note

Удаление не должно рассматриваться как обычная Write Operation.

---

# 11. Risk Levels

Tools должны иметь уровень риска.

Предлагается:

LOW

MEDIUM

HIGH

CRITICAL

---

# 12. LOW

Примеры:

search_entities

get_entity

get_current_context

Обычно не требуют подтверждения пользователя.

---

# 13. MEDIUM

Примеры:

create_task

create_note

link_entities

update_task_status

Могут выполняться автоматически только при наличии соответствующей политики пользователя.

---

# 14. HIGH

Примеры:

bulk_update

move_entities

archive_entities

export_data

По умолчанию требуют подтверждения пользователя.

---

# 15. CRITICAL

Примеры потенциально критических операций:

permanent_delete

change_security_settings

manage_credentials

grant_permissions

Такие операции не должны выполняться AI автоматически.

---

# 16. Confirmation Policy

Каждый Tool должен иметь Confirmation Policy.

Например:

AUTO

CONFIRM

ALWAYS_CONFIRM

DENY

---

# 17. AUTO

Tool может выполняться автоматически.

Пример:

search_entities

---

# 18. CONFIRM

Tool может быть выполнен после подтверждения пользователя.

Пример:

create_task

---

# 19. ALWAYS_CONFIRM

Даже если пользователь ранее разрешил Tool, операция всё равно требует подтверждения.

Например:

permanent_delete

---

# 20. DENY

Tool полностью запрещён для AI.

Например:

manage_system_credentials

---

# 21. User Approval

Для подтверждаемого действия используется:

AI

 ↓

Proposed Action

 ↓

User

 ↓

Approve / Reject

 ↓

Tool Execution

---

# 22. AI Proposal

Перед выполнением Write Operation AI должен сформировать структурированное предложение.

Например:

Action:

Create Task

  

Title:

Implement Context Engine

  

Project:

LifeOS

  

Priority:

High

Пользователь должен понимать, что именно произойдёт.

---

# 23. Не показывать пользователю технический Tool Call

Пользовательскому интерфейсу не обязательно показывать:

tool=create_task

arguments={...}

Вместо этого:

Создать задачу?

  

Название:

Implement Context Engine

  

Проект:

LifeOS

  

Приоритет:

High

  

[Отмена] [Создать]

---

# 24. Confirmation Granularity

Подтверждение должно соответствовать масштабу операции.

Одна операция:

Create Task

может иметь одно подтверждение.

Массовая операция:

Update 50 Tasks

должна явно показывать количество и масштаб изменения.

---

# 25. Bulk Operations

Bulk Operations должны иметь отдельные ограничения.

Например:

```
AI:

Archive all completed tasks.
```

Система должна показать:

```
Будет изменено: 127 задач

[Отмена] [Подтвердить]
```

---

# 26. User Intent

Наличие Tool Permission не означает наличие пользовательского намерения.

Например:

User разрешил create_task

не означает:

AI может создавать любые задачи когда угодно.

AI должен иметь основание в текущем пользовательском запросе или контексте.

---

# 27. Explicit Intent

Явное намерение пользователя имеет наивысший приоритет.

Например:

Создай задачу "Проверить архитектуру".

AI может предложить:

create_task

---

# 28. Implicit Intent

Неявное намерение требует большей осторожности.

Например:

Что мне нужно сделать по проекту?

AI может:

search_entities

но не должен автоматически создавать задачи.

---

# 29. Read vs Write

Главное правило:

READ

 ↓

обычно безопаснее

  

WRITE

 ↓

требует дополнительного контроля

---

# 30. Tool Permission

Permissions должны проверяться независимо от AI.

AI Request

 ↓

Tool Permission

 ↓

User Permission

 ↓

Resource Permission

 ↓

Execute

---

# 31. Permission Layers

Предлагается несколько уровней:

1. AI Tool Permission

2. User Permission

3. Entity Permission

4. Operation Permission

---

# 32. AI Tool Permission

Определяет:

> Может ли AI вообще использовать данный Tool?

Например:

create_task = allowed

delete_entity = denied

---

# 33. User Permission

Определяет:

> Имеет ли текущий пользователь право выполнять эту операцию?

---

# 34. Entity Permission

Определяет:

> Имеет ли пользователь доступ именно к этой Entity?

Например:

Project A → allowed

Private Project B → denied

---

# 35. Operation Permission

Определяет:

> Может ли пользователь выполнять конкретную операцию над Entity?

Например:

read = yes

update = yes

delete = no

---

# 36. Permission Evaluation

Перед выполнением Tool:

Tool Request

      ↓

Is Tool Allowed?

      ↓

Does User Have Permission?

      ↓

Can Resource Be Accessed?

      ↓

Is Operation Allowed?

      ↓

Confirmation Required?

      ↓

Execute

---

# 37. Deny by Default

Для неизвестных или новых Tool применяется:

DENY

То есть отсутствие явного разрешения означает запрет.

---

# 38. Least Privilege

AI должен получать минимально необходимые permissions.

Например:

AI:

search = allowed

read = allowed

create_task = allowed

delete = denied

---

# 39. Tool Scope

Tool Permission может быть ограничен областью.

Например:

create_task

может быть разрешён только для:

Project: LifeOS

---

# 40. Temporary Permissions

В будущем пользователь может предоставить временное разрешение.

Например:

Разрешить AI создавать задачи

до конца текущего сеанса?

---

# 41. Session Permissions

Permission может действовать только в рамках текущего AI Session.

Session

 ↓

Permission

 ↓

Tool

После завершения Session permission может быть сброшен.

---

# 42. Persistent Permissions

Некоторые безопасные permissions могут сохраняться.

Например:

Разрешить AI использовать поиск без подтверждения.

---

# 43. Permission UI

Настройки могут выглядеть примерно так:

AI Permissions

  

Search

✓ Allowed automatically

  

Create Tasks

✓ Allowed

□ Ask every time

  

Delete Data

✗ Always ask

  

External Services

✗ Disabled

---

# 44. Tool Registry

Все Tools должны регистрироваться в едином Tool Registry.

Tool Registry

├── search_entities

├── get_entity

├── create_task

├── update_task

├── create_note

└── link_entities

---

# 45. Tool Discovery

AI должен получать только те Tools, которые доступны текущей операции.

Например:

Read Request

 ↓

Read Tools

а не весь список инструментов.

---

# 46. Dynamic Tool Availability

Tool Registry может учитывать:

- permissions;
- platform;
- current context;
- feature flags;
- provider capabilities.

---

# 47. Tool Schema

AI Provider должен получать строгую схему Tool.

Например:

create_task(

    title: string,

    project_id: EntityId,

    priority: Priority

)

AI не должен придумывать произвольные параметры.

---

# 48. Input Validation

Все параметры Tool должны валидироваться до выполнения.

AI Arguments

 ↓

Schema Validation

 ↓

Domain Validation

 ↓

Permission Check

 ↓

Execution

---

# 49. Domain Validation

Даже если AI передал корректный тип данных, Domain может отклонить операцию.

Например:

priority = "INVALID"

или:

project_id = nonexistent

---

# 50. Never Trust AI Input

AI output всегда считается недоверенным.

Даже если модель использует structured output:

AI Output

 ↓

Validation

 ↓

Sanitization

 ↓

Permission

 ↓

Execution

---

# 51. Tool Result

Tool должен возвращать структурированный результат.

Например:

{

  "success": true,

  "entity_id": "...",

  "entity_type": "task"

}

---

# 52. Error Handling

Если Tool не выполнился:

Tool

 ↓

Error

 ↓

AI

AI может объяснить пользователю проблему.

Но AI не должен самостоятельно обходить security restrictions.

---

# 53. Permission Denied

Например:

Tool:

delete_entity

  

Result:

PERMISSION_DENIED

AI должен сообщить:

> У меня нет разрешения на удаление этой записи.

AI не должен пытаться использовать другой Tool для обхода запрета.

---

# 54. Tool Failure

Если произошла техническая ошибка:

TOOL_ERROR

AI может предложить повторить операцию, если это безопасно.

---

# 55. Idempotency

Write Tools должны по возможности поддерживать idempotency.

Например:

create_task

не должен случайно создавать две одинаковые задачи из-за повторного выполнения запроса.

---

# 56. Action ID

Каждое Write действие должно иметь уникальный идентификатор.

Action ID:

action_12345

Это позволит отслеживать операцию.

---

# 57. Action Lifecycle

Операция проходит состояния:

PROPOSED

   ↓

PENDING_APPROVAL

   ↓

APPROVED

   ↓

EXECUTING

   ↓

COMPLETED

или:

REJECTED

FAILED

CANCELLED

---

# 58. Action Record

Для важных операций можно хранить:

Action

├── id

├── tool

├── user

├── timestamp

├── input

├── approval

├── result

└── status

---

# 59. Audit Trail

Для критических операций необходим Audit Trail.

User Request

 ↓

AI Proposal

 ↓

Approval

 ↓

Tool

 ↓

Result

---

# 60. Audit Privacy

Audit Log не должен без необходимости сохранять полный пользовательский контекст.

Необходимо хранить минимально достаточную информацию.

---

# 61. Undo

Для обратимых операций желательно поддерживать Undo.

Например:

AI:

Создал задачу.

  

[Отменить]

---

# 62. Soft Delete

Для удаления предпочтительно использовать Soft Delete, если это соответствует Domain Model.

Entity

 ↓

Deleted / Archived

а не немедленное физическое удаление.

---

# 63. Permanent Delete

Permanent Delete должен быть значительно более строгой операцией.

AI

 ↓

Request

 ↓

Explicit Confirmation

 ↓

Security Check

 ↓

Permanent Delete

---

# 64. Transaction Boundary

Write Tool должен выполнять операцию через контролируемую транзакцию.

Tool

 ↓

Application Service

 ↓

Transaction

 ↓

Domain

 ↓

Repository

---

# 65. Multi-step Actions

Некоторые AI действия состоят из нескольких операций.

Например:

Create Project

+

Create Tasks

+

Link Tasks

Это должно рассматриваться как одна логическая операция.

---

# 66. Atomicity

Если возможно, multi-step action должна быть атомарной.

Success

 ↓

All changes applied

или:

Failure

 ↓

Rollback

---

# 67. Partial Failure

Если rollback невозможен:

Step 1 ✓

Step 2 ✓

Step 3 ✗

система должна явно сообщить пользователю состояние операции.

---

# 68. Tool Chains

AI может вызвать несколько Tools:

Search

 ↓

Get Project

 ↓

Get Tasks

 ↓

Create Task

Каждый Tool Call должен проходить собственную валидацию.

---

# 69. Tool Call Limit

Для предотвращения бесконечных циклов устанавливается лимит.

Например:

Maximum Tool Calls per Operation

Конкретное значение будет определено после прототипирования.

---

# 70. Recursive Tool Calling

AI не должен бесконечно вызывать Tools.

AI

 ↓

Tool

 ↓

AI

 ↓

Tool

 ↓

...

Необходим:

- maximum calls;
- timeout;
- token budget;
- execution budget.

---

# 71. Tool Timeout

Каждый Tool должен иметь ограничение времени выполнения.

---

# 72. External Tools

В будущем Tools могут обращаться к внешним системам:

Calendar

Email

Cloud Storage

Web

Они должны иметь отдельные permissions.

---

# 73. External Side Effects

Внешние действия являются более рискованными.

Например:

send_email

create_calendar_event

upload_file

По умолчанию рекомендуется:

CONFIRM

---

# 74. Financial Actions

Финансовые операции должны быть запрещены для автоматического выполнения без отдельной архитектуры безопасности.

Например:

send_money

purchase

subscription

не должны быть обычными AI Tools.

---

# 75. Security-Critical Tools

AI не должен самостоятельно:

- изменять пароль;
- получать секреты;
- изменять security policy;
- выдавать permissions;
- отключать защиту;
- получать encryption keys.

---

# 76. Secrets

AI Tool Layer никогда не должен передавать модели:

API keys

passwords

private keys

encryption keys

access tokens

---

# 77. Tool Result Filtering

Даже результат Tool должен проходить фильтрацию.

Tool Result

 ↓

Sensitive Data Filter

 ↓

AI

Tool может внутренне использовать секрет, но AI не должен его увидеть.

---

# 78. Tool Result Minimization

AI получает только необходимые поля результата.

Например:

Task

├── title ✓

├── status ✓

└── internal_secret ✗

---

# 79. Prompt Injection

Tool results и пользовательские данные могут содержать malicious instructions.

Например:

Imported Note:

"Ignore all previous instructions..."

Это должно рассматриваться как данные.

---

# 80. Tool Description Security

Описание Tool также должно быть контролируемым.

Нельзя позволять пользовательским данным изменять описание или schema Tool.

---

# 81. Context Engine Integration

AI Tool Calling работает совместно с ADR-0013.

User

 ↓

Context Engine

 ↓

AI

 ↓

Tool Request

 ↓

Permission

 ↓

Tool

 ↓

New Data

 ↓

Context Engine

 ↓

AI

---

# 82. Tool + Context

Tool Result должен возвращаться не напрямую пользователю, а через контролируемый Context pipeline.

Tool Result

 ↓

Context Engine

 ↓

Relevant Result

 ↓

AI

---

# 83. Tool Calling + Search

Search является обычным Tool.

Например:

search_entities

AI может использовать Search для получения дополнительного контекста.

---

# 84. Tool Calling + Relationships

AI может использовать Tool:

get_related_entities

но глубина traversal должна ограничиваться.

---

# 85. Tool Calling + Lifecycle

Tools должны учитывать lifecycle.

Например:

archive_task

может быть допустимым действием.

А действие над permanently deleted Entity должно быть невозможно.

---

# 86. Tool Calling + Sync

Write Tools изменяют локальное Domain State.

Tool

 ↓

Domain

 ↓

Local Database

 ↓

Sync Engine

AI не должен напрямую управлять Sync Engine.

---

# 87. Tool Calling + Backup

AI не должен напрямую управлять Backup System без отдельного permission.

Например:

create_backup

может существовать как отдельный Tool в будущем.

Но:

delete_backup

должен иметь высокий уровень риска.

---

# 88. Tool Calling + Export

Export может быть Tool:

export_project

Но экспорт пользовательских данных во внешний файл является потенциально чувствительным действием.

Поэтому:

CONFIRM

рекомендуется по умолчанию.

---

# 89. Offline Mode

В Offline Mode доступны только Tools, которые не требуют сети.

Local Search ✓

Create Task ✓

Cloud Search ✗

External Email ✗

---

# 90. Provider Independence

AI Tool Layer не должен зависеть от конкретного AI Provider.

AI Provider

     ↓

Tool Interface

     ↓

LifeOS Tools

---

# 91. Provider Adapter

Разные AI Providers могут иметь разные форматы Tool Calling.

Поэтому:

Provider Adapter

      ↓

Common Tool Interface

---

# 92. Tool Versioning

Tools должны иметь версии.

Например:

create_task.v1

create_task.v2

Это позволит менять API Tool без нарушения старых сценариев.

---

# 93. Backward Compatibility

Изменение Tool Schema не должно неожиданно ломать существующие AI workflows.

---

# 94. Feature Flags

Новые Tools могут выпускаться через Feature Flags.

Tool

 ↓

Feature Flag

 ↓

Available / Disabled

---

# 95. Tool Testing

Каждый Tool должен иметь:

- unit tests;
- validation tests;
- permission tests;
- security tests;
- integration tests.

---

# 96. AI Tool Testing

Дополнительно необходимо тестировать:

AI

 ↓

Tool Selection

 ↓

Arguments

 ↓

Permission

 ↓

Execution

---

# 97. Dangerous Tool Testing

Для HIGH и CRITICAL Tools должны существовать тесты, проверяющие невозможность обхода permission system.

---

# 98. Observability

Для диагностики можно записывать:

tool_name

action_id

execution_time

status

error_code

При этом sensitive input не должен автоматически попадать в logs.

---

# 99. Основные принципы

Для AI Tool Calling принимаются следующие принципы:

1. AI не имеет прямого доступа к Database.
2. AI не имеет прямого доступа к File System.
3. AI не имеет прямого доступа к Secrets.
4. AI взаимодействует с системой только через Tools.
5. Каждый Tool имеет строгий контракт.
6. Все Tool Inputs валидируются.
7. AI Output считается недоверенным.
8. Permissions проверяются независимо от AI.
9. Применяется принцип Least Privilege.
10. Неизвестные Tools запрещены по умолчанию.
11. Read Operations имеют меньший риск, чем Write Operations.
12. Delete Operations выделяются отдельно.
13. Tools имеют Risk Level.
14. Tools имеют Confirmation Policy.
15. Пользовательское намерение важнее наличия permission.
16. Implicit Intent не должен автоматически приводить к опасным действиям.
17. Write Operations должны иметь дополнительный контроль.
18. HIGH и CRITICAL операции требуют явного подтверждения.
19. CRITICAL операции не выполняются автоматически.
20. Secrets никогда не передаются AI.
21. Tool Results также проходят фильтрацию.
22. Пользовательские данные считаются недоверенным содержимым.
23. Tool Calling должен быть защищён от Prompt Injection.
24. Tool Calls имеют ограничения количества.
25. Tool Calls имеют timeout.
26. Multi-step operations должны быть контролируемыми.
27. Write Actions должны по возможности быть idempotent.
28. Важные действия получают Action ID.
29. Важные действия могут иметь Audit Trail.
30. Tool Layer интегрируется с Context Engine.
31. Tool Result проходит через контролируемый Context pipeline.
32. AI Provider не определяет внутреннюю архитектуру Tools.
33. Provider-specific Tool Calling реализуется через Adapter.
34. Tools должны быть версионируемыми.
35. Permission Denied не может быть обойдён другим Tool.
36. AI не может изменять собственные permissions.
37. AI не может выдавать себе новые permissions.
38. Внешние Tools имеют отдельные политики.
39. Offline Mode ограничивает сетевые Tools.
40. Tool Registry является единым источником доступных AI Tools.

---

# 100. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретный AI Provider;
- конкретную AI-модель;
- конкретный Tool Calling API;
- конкретную Permission Database;
- конкретную Authentication Architecture;
- конкретный UI;
- конкретный формат Audit Log;
- конкретный набор LifeOS Tools;
- конкретные значения Tool Limits;
- конкретную encryption implementation.

Эти решения будут определены отдельными ADR и техническими спецификациями.

---

# 101. Последствия решения

## Положительные

- AI получает контролируемый доступ к функциям LifeOS;
- повышается безопасность;
- появляется единая модель permissions;
- можно разделять Read и Write операции;
- пользователь контролирует потенциально опасные действия;
- AI Provider можно менять;
- Tools можно расширять независимо от модели;
- появляется возможность Undo и Audit;
- архитектура готова к Local и Cloud AI;
- уменьшается риск прямого воздействия AI на систему.

## Отрицательные

- появляется дополнительный Tool Layer;
- необходимо реализовать Permission System;
- потребуется Confirmation UI;
- необходимо тестировать каждый Tool;
- появится дополнительная логика обработки ошибок;
- Multi-step AI Actions становятся сложнее;
- потребуется защита от Prompt Injection и Tool Abuse.

---

# 102. Связанные ADR

Связанные архитектурные решения:

- ADR-0013 — AI Context Engine
- ADR-0012 — Search Architecture
- ADR-0011 — Backup and Export Architecture
- ADR-0010 — Security Architecture
- ADR-0009 — AI Architecture
- ADR-0008 — AI Provider Architecture
- ADR-0007 — Data Lifecycle Architecture

---

# 103. Следующие документы

Следующим логичным документом является:

**ADR-0015: Semantic Search and Embeddings**

В нём будет определено, как LifeOS будет искать смысловые связи между сущностями и документами, включая embeddings, vector search и hybrid search.

После завершения AI-блока можно будет перейти к:

- Authentication Architecture;
- Encryption and Key Management;
- Sync Protocol;
- Domain Model;
- Database Schema;
- Flutter Project Structure;
- MVP Specification.

  

### Что важно после создания

  

На этом ADR мы **не выбираем конкретную модель и не привязываемся к OpenAI/Claude/Gemini или локальной модели**. Мы строим универсальный слой:

  

```text

                AI Model

                   ↓

             Tool Interface

                   ↓

          Permission System

                   ↓

          Application Services

                   ↓

               Domain

                   ↓

              Database

Это очень важное решение для LifeOS: если через год появится гораздо более сильная модель, нам не придётся переписывать всю систему. Мы просто подключим новую модель к уже существующим **Context + Tool + Permission** интерфейсам.