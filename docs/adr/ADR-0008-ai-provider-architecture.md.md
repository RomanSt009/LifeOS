
**Статус:** Предварительно принято  
**Дата:** 2026-08-14  
**Версия:** 0.1

## Контекст

AI является одним из центральных компонентов LifeOS.

AI должен помогать пользователю:

- понимать естественный язык;
- создавать и изменять сущности;
- предлагать связи между сущностями;
- находить релевантную информацию;
- формировать контекст;
- помогать планировать;
- анализировать информацию;
- взаимодействовать с пользователем через AI Assistant.


При этом LifeOS не должен зависеть от конкретной AI-модели или конкретного AI-провайдера.

AI-модели быстро развиваются.

Поэтому архитектура должна позволять заменять:

- модель;
- API provider;
- локальную модель;
- способ запуска модели;

без изменения основной бизнес-логики приложения.

---

# 1. Основное архитектурное решение


LifeOS использует абстракцию:


```text
AIProvider
```


Application Layer взаимодействует с AI только через этот контракт.

Конкретная реализация может использовать:
```
Cloud AI
Local AI
Mock AI
```

Концептуально:
```
                         LifeOS
                            │
                            ↓
                       AIProvider
                            │
              ┌─────────────┼─────────────┐
              ↓             ↓             ↓
        Cloud Provider   Local Provider   Mock
              │             │
              ↓             ↓
        Remote Model    Local Model
```


---

# 2. Почему не фиксируем конкретную модель

На момент создания архитектуры невозможно гарантировать, какая модель будет оптимальной для LifeOS через несколько лет.

Модели могут изменяться по:

качеству;
скорости;
стоимости;
размеру;
требованиям к оборудованию;
возможностям reasoning;
поддержке multimodal;
контекстному окну;
лицензии.

Поэтому архитектура не должна зависеть от конкретной модели.

---

# 3. AI Provider и AI Model

Необходимо разделять:

AI Provider

и:

AI Model

Например:

AIProvider
    ↓
Cloud Provider
    ↓
Model A

или:

AIProvider
    ↓
Cloud Provider
    ↓
Model B

или:

AIProvider
    ↓
Local Provider
    ↓
Local Model

Provider отвечает за взаимодействие с моделью.

Модель является заменяемой реализацией.

---

# 4. Основной контракт

Концептуально AIProvider предоставляет операции:

generate()
analyze()
extract()
classify()
embed()

Конкретный интерфейс будет определён во время реализации.

Важно не создавать чрезмерно универсальный API заранее.

# 5. AI Engine

AIProvider не должен содержать всю AI-логику LifeOS.

Над Provider располагается:

AI Engine

Архитектура:

Application
     ↓
AI Engine
     ↓
AIProvider
     ↓
Model

AI Engine отвечает за бизнес-логику взаимодействия LifeOS с AI.

# 6. Почему нужен AI Engine

Нежелательный вариант:

Application
    ↓
AIProvider
    ↓
Model

если Application начинает самостоятельно:

собирать контекст;
формировать prompts;
управлять памятью;
анализировать ответы;
проверять результаты;
сохранять AI state.

Это приведёт к сильной связанности.

Вместо этого:

Application
    ↓
AI Engine
    ↓
Context Engine
    ↓
AIProvider

# 7. Context Engine

Одним из центральных компонентов LifeOS является:

Context Engine

Он определяет:

Какая информация действительно нужна AI для выполнения текущей задачи?

# 8. Context Engine и C+

Ранее была принята концепция:

C+ = Context + Lifecycle

Поэтому AI не должен получать всю базу LifeOS.

Вместо:

Entire LifeOS Database
        ↓
        AI

используется:

User Request
      ↓
Context Engine
      ↓
Relevant Entities
      ↓
Relevant Relationships
      ↓
Lifecycle / State
      ↓
Context
      ↓
AI
# 9. Почему нельзя отправлять всю базу

Отправка всей базы создаёт проблемы:

приватность;
стоимость;
размер контекста;
скорость;
шум;
снижение качества ответа.

AI должен получать только релевантную информацию.

# 10. Context Budget

Контекст должен иметь ограничение.

Например:

User Request
     +
Relevant Entities
     +
Relevant Relationships
     +
Relevant History
     ↓
Context Budget
     ↓
AI

Context Engine должен выбирать наиболее полезную информацию.

# 11. Relevance

Релевантность может определяться несколькими факторами:

Semantic relevance
Temporal relevance
Relationship relevance
User intent
Entity type
Lifecycle state
Recency
Priority

Например, если пользователь спрашивает:

"Что мне нужно сделать по проекту LifeOS?"

AI не должен получать:

старые завершённые проекты;
удалённые заметки;
нерелевантные контакты;
случайные сущности.
# 12. Relationship-aware Context

LifeOS является системой связанных сущностей.

Поэтому Context Engine должен учитывать граф связей.

Например:

Project LifeOS
      │
      ├── Task A
      ├── Task B
      ├── Note
      ├── Person
      └── Deadline

При запросе о проекте AI может получить связанные сущности.

# 13. Context Depth

Не следует автоматически загружать бесконечное количество уровней связей.

Например:

Project
   ↓
Task
   ↓
Person
   ↓
Company
   ↓
Event
   ↓
...

Context Engine должен ограничивать глубину.

Например:

Depth 0 = текущая сущность
Depth 1 = прямые связи
Depth 2 = связи связанных сущностей

Конкретный алгоритм будет определён позднее.

# 14. Lifecycle-aware Context

Context Engine должен учитывать lifecycle.

Например:

Active
Archived
Deleted
Completed
Expired

Удалённая или архивная сущность не должна автоматически попадать в контекст.

Она может быть включена только если действительно релевантна запросу.

# 15. AI не изменяет данные напрямую

Это принципиально важно.

Нежелательная схема:

AI
 ↓
Database

AI не должен напрямую выполнять:

INSERT
UPDATE
DELETE
# 16. AI предлагает действие

Предпочтительная схема:

User
 ↓
AI
 ↓
Proposed Action
 ↓
Validation
 ↓
Application Layer
 ↓
Domain
 ↓
Database

Например:

AI:


Создать задачу:
"Подготовить презентацию"


Проект:
"LifeOS"


Срок:
15 августа

Application Layer проверяет предложенное действие.

# 17. Structured AI Output

AI должен по возможности возвращать структурированный результат.

Например:

{
  "action": "create_task",
  "title": "Подготовить презентацию",
  "project_id": "project-123",
  "due_date": "2026-08-15"
}

Application Layer проверяет этот результат.

# 18. Validation

AI Output не считается доверенным.

Любой результат AI проходит:

AI Output
    ↓
Schema Validation
    ↓
Domain Validation
    ↓
Permission Check
    ↓
Execution

Если validation не пройдена:

Reject
# 19. AI Suggestions

AI может предлагать:

новые сущности;
связи;
изменения;
классификацию;
теги;
приоритет;
действия.

Но предложение не обязательно должно автоматически становиться фактом.

# 20. Human-in-the-loop

Для важных изменений используется принцип:

AI Suggestion
      ↓
User Review
      ↓
Accept / Edit / Reject

Особенно для:

удаления;
массовых изменений;
важных связей;
изменения приоритетов;
изменения пользовательских данных.
# 21. Автоматические действия

Автоматизация может появиться позднее.

Например:

AI
 ↓
Low-risk action
 ↓
Automatic execution

Но список автоматически разрешённых действий должен быть ограниченным.

# 22. AI и Relationships

AI может предлагать новые связи.

Например:

Task
  ↓
AI
  ↓
Possible relationship
  ↓
Project

AI может сказать:

"Эта задача вероятно относится к проекту LifeOS"

Но связь должна пройти:

Validation
+
Confidence
+
User policy
# 23. Confidence

AI может предоставлять confidence score.

Например:

relationship:
Task → Project


confidence:
0.91

Но confidence модели не является абсолютной истиной.

Это сигнал для принятия решения, а не гарантия.

# 24. AI Memory

AI Memory не должна быть отдельной независимой копией всей жизни пользователя.

Вместо этого AI должен использовать данные LifeOS как основной источник истины.

LifeOS Data
     ↓
Context Engine
     ↓
AI

AI-generated memory может существовать только как отдельный тип данных с собственным lifecycle.

# 25. Source of Truth

Основным источником истины является:

LifeOS Database

а не AI.

Если AI утверждает:

"У пользователя есть задача X"

но в базе её нет:

Database
    ↓
Truth

AI не должен создавать факт только потому, что "помнит" его.

# 26. AI Hallucination

AI может ошибаться.

Поэтому архитектура должна предполагать:

AI Output ≠ Truth

Любой важный AI результат должен быть:

проверяемым;
валидируемым;
связанным с источником;
при необходимости подтверждаемым пользователем.
# 27. Grounding

AI должен получать ссылки на исходные данные.

Например:

Answer
  ↓
Sources
  ├── Entity A
  ├── Entity B
  └── Relationship C

Это позволяет пользователю понять:

На основании чего AI сделал вывод.

# 28. AI Request

Каждый AI request концептуально содержит:

User Intent
+
Context
+
Task
+
Constraints

Например:

Intent:
plan


Task:
создать план проекта


Context:
Project
Tasks
Deadlines
Notes


Constraints:
не менять существующие задачи
# 29. AI Response

Ответ может содержать:

Natural Language Response
+
Structured Actions
+
Sources
+
Confidence
+
Metadata

Не все поля обязательны для каждого запроса.

# 30. Provider Abstraction

Концептуально:

AIProvider
├── generate
├── structuredOutput
├── embeddings
└── capabilities

Конкретный интерфейс будет определён во время реализации.

# 31. Cloud AI Provider

Cloud Provider может выглядеть:

CloudAIProvider
      ↓
HTTPS
      ↓
AI API
      ↓
Model

Он отвечает за:

authentication;
request;
response;
timeout;
retry;
rate limits;
serialization.
# 32. Local AI Provider

В будущем:

LocalAIProvider
      ↓
Local Runtime
      ↓
Local Model

Например:

Local Model

может работать непосредственно на компьютере пользователя.

# 33. Local AI преимущества

Потенциальные преимущества:

приватность;
отсутствие API latency;
возможность offline AI;
отсутствие стоимости API;
локальный контроль.
# 34. Local AI ограничения

Потенциальные проблемы:

требования к RAM;
GPU;
размер моделей;
скорость;
качество;
сложность установки;
обновления моделей;
энергопотребление.

Поэтому Local AI не является обязательным компонентом MVP.

# 35. Hybrid AI

В будущем LifeOS может использовать Hybrid AI.

Например:

                 AI Router
                    │
          ┌─────────┴─────────┐
          ↓                   ↓
       Local AI            Cloud AI
          │                   │
     simple/private        complex
     operations            reasoning
# 36. AI Router

В будущем может появиться:

AI Router

Он выбирает подходящий Provider.

Например:

Simple task
    ↓
Local AI


Complex reasoning
    ↓
Cloud AI


Sensitive data
    ↓
Local AI

Но AI Router не реализуется на первом этапе.

# 37. Privacy

Перед отправкой данных Cloud AI необходимо определить:

What data?
Why?
Where?

Context Engine должен формировать минимально необходимый контекст.

# 38. Sensitive Data

В будущем Context Engine должен учитывать классификацию данных.

Например:

Public
Private
Sensitive
Highly Sensitive

Политика передачи в Cloud AI может выглядеть:

Public       → Cloud allowed
Private      → Cloud allowed by policy
Sensitive    → restricted
Highly       → local only

Конкретная модель классификации будет определена в Security Architecture.

# 39. API Keys

API keys не должны храниться:

в исходном коде;
в Git;
в документации;
в обычных текстовых конфигурационных файлах.

Используется безопасное хранение credentials.

Конкретный механизм будет определён в Security ADR.

# 40. Network Failure

AI не должен ломать основную работу LifeOS.

Если Cloud AI недоступен:

AI unavailable
      ↓
LifeOS continues working

Local-first приложение должно продолжать:

создавать задачи;
читать данные;
редактировать данные;
работать с локальной базой.
# 41. AI Failure

AI может:

вернуть ошибку;
вернуть неправильный формат;
превысить timeout;
вернуть невалидный результат;
быть временно недоступным.

Каждый такой случай должен обрабатываться безопасно.

# 42. Retry

Повторные запросы допустимы только для определённых ошибок.

Например:

Temporary network error
       ↓
Retry

Но не:

Invalid request
       ↓
Infinite retry

Retry должен иметь:

ограничение;
backoff;
timeout.
# 43. Cost Control

Cloud AI может иметь стоимость.

Поэтому архитектура должна учитывать:

Request count
Token usage
Context size
Model selection
Caching

В будущем может появиться:

AI Usage Monitor
# 44. Caching

Некоторые AI-операции могут использовать caching.

Например:

Same request
+
Same context
+
Same model

может не требовать повторного вызова.

Однако caching не должен приводить к использованию устаревших данных.

# 45. Model Version

AI request должен позволять определить:

provider
model
model_version

Это важно для:

debugging;
reproducibility;
analytics;
migration;
сравнения моделей.
# 46. AI Observability

Для диагностики необходимо сохранять техническую metadata.

Например:

request_id
provider
model
timestamp
latency
token_usage
status

Но не следует автоматически сохранять весь пользовательский контекст.

# 47. AI Logs

AI logs должны разделяться на:

Technical Metadata

и:

User Content

Технические логи могут быть разрешены.

Сохранение пользовательского prompt/response должно зависеть от privacy policy пользователя.

# 48. Prompt Management

Prompts не должны быть разбросаны по UI-коду.

Например:

Widget
  ↓
"Ты полезный ассистент..."

нежелательно.

Prompts должны находиться в AI/Application слое.

# 49. Prompt Templates

Возможная структура:

AI
├── prompts
│   ├── task_creation
│   ├── summarization
│   ├── planning
│   └── relationship_detection

Конкретная структура будет определена во время реализации.

# 50. Prompt Injection

AI должен рассматриваться как потенциально уязвимый к prompt injection.

Особенно если контекст содержит:

импортированные документы;
web content;
пользовательские заметки;
внешние источники.

Контент пользователя не должен автоматически считаться инструкцией для AI.

# 51. Instruction Hierarchy

Концептуально:

System Policy
      ↓
Application Rules
      ↓
User Intent
      ↓
Retrieved Data

Retrieved data является данными, а не инструкциями.

# 52. External Content

Если LifeOS в будущем будет использовать web search или внешние источники:

External Content
       ↓
Untrusted Data
       ↓
Context Engine
       ↓
AI

Внешний текст не должен получать такие же права, как системные инструкции.

# 53. AI Permissions

AI не должен автоматически обладать полными правами пользователя.

Вместо:

AI = full access

используется:

AI
 ↓
Allowed Operations
 ↓
Permission Check
# 54. Tool Calling

В будущем AI может использовать инструменты LifeOS.

Например:

AI
 ↓
Tool
 ├── search_entities
 ├── create_task
 ├── update_task
 └── create_relationship

Но каждый tool должен иметь:

определённую схему;
разрешённые параметры;
validation;
permission policy.
# 55. Tool Calling Security

AI не должен самостоятельно создавать произвольные команды.

Нежелательно:

AI
 ↓
execute arbitrary code

или:

AI
 ↓
execute arbitrary SQL

Tools должны предоставлять ограниченные операции.

# 56. AI and Database

AI никогда не получает прямой доступ к SQLite.

Правильная схема:

AI
 ↓
Tool
 ↓
Application
 ↓
Repository
 ↓
Database
# 57. AI and File System

Аналогично AI не должен иметь произвольный доступ к файловой системе.

Вместо:

AI
 ↓
File System

используются ограниченные инструменты:

AI
 ↓
File Tool
 ↓
Allowed Directory
# 58. AI Provider Security Boundary

Provider является границей между LifeOS и внешней моделью.

LifeOS
    │
    │ controlled context
    ↓
AI Provider
    │
    │ API request
    ↓
External AI

Перед границей должны применяться:

filtering;
policy;
serialization;
authentication;
logging policy.
# 59. Offline Mode

LifeOS должен работать без AI.

Минимальная функциональность:

Offline
 ↓
LifeOS
 ↓
Database

AI становится дополнительной возможностью.

# 60. Graceful Degradation

Если AI недоступен:

AI unavailable
       ↓
Manual workflow

Например:

AI не смог определить проект
       ↓
Пользователь выбирает проект вручную
# 61. MVP

На первом этапе реализуется:

AIProvider
      ↓
CloudAIProvider
      ↓
один выбранный API

и:

Context Engine
      ↓
минимальный контекст
      ↓
AI
# 62. Что НЕ реализуем в MVP

Не реализуем сразу:

Local AI;
AI Router;
сложную Agent System;
автономных AI agents;
бесконечную AI memory;
vector database;
сложный RAG;
автоматическое изменение всех данных;
автономное выполнение опасных действий.
# 63. Первый AI Use Case

Первым AI-сценарием рекомендуется сделать:

Natural Language → Structured Entity

Например:

Пользователь пишет:

"Завтра в 10 утра встреча с Иваном по проекту LifeOS"

AI должен предложить:

Entity:
Event


Title:
Встреча с Иваном


Date:
2026-08-15


Time:
10:00


Project:
LifeOS


Person:
Иван

После этого:

AI
 ↓
Structured Result
 ↓
Validation
 ↓
User Confirmation
 ↓
Create Entity
# 64. Второй AI Use Case

Следующим сценарием может стать:

Relationship Suggestion

Например:

Task A
    ↓
AI
    ↓
"Вероятно относится к Project B"

Пользователь:

Accept
Edit
Reject
# 65. Третий AI Use Case

После этого:

Contextual Assistant

Например:

"Что у меня сейчас самое важное по LifeOS?"

Context Engine:

Tasks
Projects
Deadlines
Relationships
Notes
Lifecycle

формирует контекст.

AI формирует ответ.

# 66. Архитектурная схема

Итоговая архитектура:

┌──────────────────────────────┐
│             UI               │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│         Application          │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│          AI Engine           │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│       Context Engine         │
└──────────────┬───────────────┘
               ↓
       Relevant Context
               │
               ↓
┌──────────────────────────────┐
│         AIProvider           │
└──────────────┬───────────────┘
               │
       ┌───────┴────────┐
       ↓                ↓
 Cloud Provider    Local Provider
       ↓                ↓
    AI Model         Local Model
# 67. Основные архитектурные принципы

Для AI LifeOS принимаются следующие правила:

AI является заменяемой подсистемой.
Application не зависит от конкретной AI-модели.
Используется абстракция AIProvider.
AI Engine отделён от AI Provider.
Context Engine отвечает за формирование контекста.
AI не является источником истины.
AI не имеет прямого доступа к базе данных.
AI Output считается недоверенным.
AI Actions проходят validation.
Важные действия могут требовать подтверждения пользователя.
LifeOS должен работать без AI.
Cloud AI является первым вариантом для MVP.
Local AI предусматривается архитектурно, но не реализуется сразу.
Конкретная модель не фиксируется в архитектуре.
Provider и Model являются независимыми понятиями.
AI Context должен быть минимально необходимым.
Пользовательские данные не должны отправляться в Cloud AI без необходимости.
AI Tools должны иметь ограниченные права.
AI не должен выполнять произвольный код или SQL.
Внешний контент считается недоверенным.
AI Usage должен быть контролируемым.
AI observability не должна нарушать privacy.
Архитектура должна поддерживать замену модели без переписывания Application/Domain.
# 68. Последствия решения
Положительные
возможность менять модели;
возможность использовать нескольких AI providers;
возможность Local AI;
возможность Hybrid AI;
изоляция AI от Domain;
контроль приватности;
возможность тестирования через Mock AI;
возможность постепенно развивать AI;
снижение риска привязки к одному поставщику.
Отрицательные
больше архитектурных компонентов;
Context Engine требует отдельной разработки;
необходимо контролировать стоимость Cloud AI;
требуется дополнительная validation;
AI privacy становится отдельной архитектурной задачей;
Local AI значительно усложнит deployment.
# 69. Что требует следующих решений

Следующие документы должны определить:

конкретный AI API для MVP;
формат AIProvider;
structured output;
Context Engine;
embeddings;
semantic search;
prompt management;
AI permissions;
privacy policy;
security;
AI caching;
AI observability;
Local AI runtime.
``

# 70. Следующие ADR

После ADR-0008:

ADR-0009:
Synchronization Architecture

ADR-0010:
Security Architecture

ADR-0011:
Backup and Export Architecture

ADR-0012:
Search Architecture

В дальнейшем могут появиться:

ADR-0013:
AI Context Engine

ADR-0014:
AI Tool Calling

ADR-0015:
Semantic Search / Embeddings

Итог

AI в LifeOS является заменяемым инфраструктурным компонентом.

Основная архитектура:

Application
      ↓
AI Engine
      ↓
Context Engine
      ↓
AIProvider
      ↓
┌──────────────┬──────────────┐
│ Cloud AI     │ Local AI     │
└──────────────┴──────────────┘

Основным источником истины остаётся база LifeOS.

AI не должен напрямую изменять данные.

Предпочтительный жизненный цикл AI-действия:

User Intent
     ↓
Context Engine
     ↓
AI
     ↓
Structured Result
     ↓
Validation
     ↓
Permission
     ↓
User Confirmation
     ↓
Application
     ↓
Domain
     ↓
Database

Главный принцип:

AI должен быть помощником и интеллектуальным интерфейсом LifeOS, но не владельцем данных и не источником истины.



### И здесь есть важное архитектурное решение


Мы сейчас фактически разделили **три уровня**, и это стоит хорошо запомнить:


```text
┌─────────────────────────────┐
│       AI Provider           │
│                             │
│ Как поговорить с моделью?   │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│       Context Engine        │
│                             │
│ Что показать модели?        │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│         AI Engine           │
│                             │
│ Что сделать с результатом?  │
└─────────────────────────────┘

Именно поэтому смена модели потом не должна ломать LifeOS.

Например, сегодня:

AI Engine
   ↓
Context Engine
   ↓
OpenAI-compatible API
   ↓
Model A

а завтра:

AI Engine
   ↓
Context Engine
   ↓
LocalAIProvider
   ↓
Model B

Для остального приложения это практически одна и та же система.

ADR-0008 особенно важен ещё и потому, что здесь мы заложили основу нашей C+ концепции. В следующем этапе мы сможем отдельно спроектировать, как LifeOS будет понимать, какие сущности и связи действительно нужны AI в конкретный момент. Это, на мой взгляд, будет одной из самых интересных частей проекта.

После создания и коммита ADR-0008 следующим логичным шагом будет 
ADR-0009 — Synchronization Architecture. Там уже разберём, как сделать так, чтобы данные пользователя могли безопасно синхронизироваться между ПК, телефоном и другими устройствами, сохраняя наш принцип Local-first.
