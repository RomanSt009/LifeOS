# ADR-0013: AI Context Engine

**Статус:** Предварительно принято  
**Дата:** 2026-08-18  
**Версия:** 0.1

## 1. Контекст

AI является одной из ключевых функциональных возможностей LifeOS.

Однако LifeOS потенциально будет содержать большое количество пользовательских данных:

- Notes;
- Tasks;
- Projects;
- Goals;
- People;
- Events;
- Resources;
- Files;
- Relationships;
- Metadata;
- AI-generated content.

Передача всей базы данных AI-модели для каждого запроса является непрактичной и небезопасной.

Она приводит к:

- большому объёму контекста;
- увеличению стоимости API;
- снижению скорости;
- ухудшению качества ответа;
- повышению риска утечки чувствительных данных;
- невозможности эффективно работать с большими объёмами информации;
- зависимости AI от конкретной структуры базы данных.

Поэтому между AI и пользовательскими данными должен существовать отдельный слой управления контекстом.

---

# 2. Решение

В LifeOS вводится отдельная подсистема:

**AI Context Engine**

Её задача — определить, какая информация необходима AI для выполнения конкретной задачи.

Основной принцип:

```text
User Request
      ↓
Context Engine
      ↓
Relevant Data
      ↓
AI Model
      ↓
Response / Action
```

AI не получает прямой доступ ко всей базе данных.

---

# 3. Основной принцип

Context Engine должен придерживаться принципа:

> Give AI the minimum relevant context required to complete the task.

То есть:

Не:

Entire Database → AI

  

А:

User Request

     ↓

Relevant Context

     ↓

AI

---

# 4. Context Engine как независимый слой

Context Engine не должен зависеть напрямую от конкретной AI-модели.

Предпочтительная архитектура:

Application

     ↓

AI Context Engine

     ↓

AI Provider Interface

     ↓

AI Model

Это позволяет менять AI Provider или модель без переработки Context Engine.

---

# 5. Основные задачи Context Engine

Context Engine отвечает за:

- анализ пользовательского запроса;
- определение необходимого контекста;
- поиск релевантных сущностей;
- получение relationships;
- получение metadata;
- определение приоритета информации;
- фильтрацию данных;
- применение security policies;
- ограничение объёма контекста;
- формирование AI Context Package;
- передачу контекста AI Provider.

---

# 6. Источники контекста

Context Engine может получать информацию из нескольких источников:

                    Context Engine

                         │

        ┌────────────────┼────────────────┐

        ↓                ↓                ↓

      Search          Domain Data      Relationships

        │                │                │

        └────────────────┼────────────────┘

                         ↓

                     Context

В будущем могут добавляться:

- текущий экран;
- текущая Entity;
- история диалога;
- пользовательские предпочтения;
- временный контекст;
- внешние источники.

---

# 7. Search как основной источник

Search Architecture из ADR-0012 является одним из основных источников Context Engine.

User Request

     ↓

Search

     ↓

Relevant Entities

     ↓

Context Engine

     ↓

AI

Таким образом Search и AI остаются независимыми подсистемами.

---

# 8. Context != Search

Search и Context Engine выполняют разные задачи.

### Search

Отвечает на вопрос:

> Какие данные могут быть релевантны?

### Context Engine

Отвечает на вопрос:

> Какие из найденных данных действительно нужно передать AI?

Search

  ↓

100 candidates

  ↓

Context Engine

  ↓

10 relevant entities

  ↓

AI

---

# 9. Context Assembly

Context Engine собирает контекст из нескольких источников.

Например:

User Request

     ↓

Current Project

     ↓

Related Tasks

     ↓

Related Notes

     ↓

Relevant Search Results

     ↓

User Preferences

     ↓

Context Package

---

# 10. Current Context

Одним из наиболее важных источников является текущий контекст пользователя.

Например:

Current Screen:

Project / LifeOS

  

Current Entity:

Project LifeOS

  

Selected Task:

Implement AI Context Engine

AI может использовать эту информацию без необходимости повторно искать её.

---

# 11. Explicit Context

Пользователь может явно указать контекст.

Например:

"Используй этот проект и связанные с ним задачи."

В таком случае Context Engine должен учитывать явное указание пользователя.

---

# 12. Implicit Context

Context Engine может самостоятельно определять дополнительный контекст.

Например:

User:

"Что мне осталось сделать?"

  

Current Project:

LifeOS

  

Context Engine:

Project

+

Active Tasks

+

Dependencies

---

# 13. Context Sources Priority

Источники контекста могут иметь разный приоритет.

Например:

1. Explicit User Context

2. Current Entity

3. Current Screen

4. Direct Relationships

5. Search Results

6. Historical Context

7. Optional External Context

Конкретные веса будут определены после прототипирования.

---

# 14. Context Relevance

Каждый кандидат в Context Package должен иметь relevance score.

Концептуально:

Entity

   ↓

Relevance Score

   ↓

Ranking

Score может учитывать:

- текстовое совпадение;
- semantic similarity;
- relationship distance;
- entity type;
- lifecycle status;
- recency;
- current context;
- explicit user selection.

---

# 15. Relationship Distance

Связанные сущности могут иметь разную степень релевантности.

Например:

Project

   ↓

Task

   ↓

Note

   ↓

Person

Чем дальше Entity от текущего контекста, тем ниже её базовый приоритет.

Однако это правило не является абсолютным.

---

# 16. Recency

Недавно изменённые данные могут иметь больший приоритет.

Например:

Updated today

     ↓

higher priority

  

Updated 2 years ago

     ↓

lower priority

Recency не должна полностью вытеснять релевантность.

---

# 17. Lifecycle Awareness

Context Engine должен учитывать Lifecycle Model.

Например:

Active

Archived

Completed

Deleted

Удалённые сущности не должны попадать в обычный AI Context.

Archived entities могут использоваться, если они релевантны.

---

# 18. Context Budget

Каждый AI запрос имеет ограниченный context budget.

Поэтому Context Engine должен уметь сокращать контекст.

100 relevant entities

        ↓

Context Budget

        ↓

20 entities

        ↓

AI

---

# 19. Token Budget

Для AI Provider Context Engine должен учитывать ограничения модели.

Например:

Context Budget

      ↓

System Instructions

+

Conversation

+

Relevant Data

+

Tool Results

Система должна оставлять место для ответа модели.

---

# 20. Context Compression

Если найдено слишком много информации, Context Engine может выполнять compression.

Например:

100 Notes

   ↓

Relevant Notes

   ↓

Summaries

   ↓

AI Context

Конкретная стратегия будет определена позже.

---

# 21. Summarization

Для больших наборов данных может использоваться summary.

Например:

Project History

      ↓

Summary

      ↓

Context

Но summary не должен автоматически заменять Source of Truth.

---

# 22. Context Hierarchy

Контекст может быть представлен уровнями:

Level 1

Current Context

  

Level 2

Direct Relationships

  

Level 3

Search Results

  

Level 4

Historical Context

  

Level 5

External Context

Система должна начинать с наиболее релевантного уровня.

---

# 23. Conversation Context

AI может учитывать историю текущего диалога.

Conversation

     ↓

Context Engine

     ↓

Current Context

Но вся история разговора не обязательно должна передаваться модели целиком.

---

# 24. Conversation Compression

Длинный разговор может быть преобразован:

Conversation History

       ↓

Summary / Relevant Turns

       ↓

Current Context

Это позволяет контролировать размер контекста.

---

# 25. Persistent Memory

В будущем LifeOS может поддерживать долгосрочную AI Memory.

Например:

User Preference

     ↓

Persistent Memory

     ↓

Context Engine

Однако Memory должна рассматриваться отдельно от обычной Conversation History.

---

# 26. Memory != Context

Memory хранит потенциально полезную информацию.

Context Engine решает:

> Нужна ли эта информация именно сейчас?

Memory

  ↓

Candidate

  ↓

Context Engine

  ↓

Use / Ignore

---

# 27. User Control

Пользователь должен иметь возможность управлять контекстом.

Например:

Use current project

Use related tasks

Don't use archived data

---

# 28. Context Inspection

В будущем желательно предоставить пользователю возможность увидеть, какой контекст использовал AI.

Например:

AI Context

  

✓ Project LifeOS

✓ 5 active tasks

✓ 3 related notes

✓ Current task

Это повышает прозрачность системы.

---

# 29. Context Editing

В будущем пользователь может вручную изменить Context Package.

Например:

AI Context

  

Included:

✓ Project LifeOS

✓ Task A

  

Excluded:

✗ Old Note

Это соответствует общей концепции LifeOS:

AI suggests

User controls

---

# 30. Context Permissions

Context Engine обязан учитывать Security Architecture.

User

 ↓

Permission

 ↓

Context Engine

 ↓

Allowed Data

 ↓

AI

AI не должен получать данные, к которым пользователь не имеет доступа.

---

# 31. Sensitive Data

Sensitive entities должны проходить отдельную policy check.

Candidate Data

      ↓

Security Policy

      ↓

Allowed?

   /      \

 Yes       No

  ↓         ↓

Context    Exclude

---

# 32. Cloud AI Privacy

Если используется Cloud AI Provider:

Context Engine

      ↓

Privacy Filter

      ↓

Minimal Context

      ↓

Cloud AI

Таким образом Context Engine становится важной частью Privacy Architecture.

---

# 33. Local AI

При использовании Local AI политика может быть менее ограничительной с точки зрения передачи данных наружу.

Однако Security Policy всё равно должна применяться.

Local AI

   ↑

Context Engine

не означает:

Local AI

   ↑

Entire Database

---

# 34. AI Provider Independence

Context Engine не должен знать конкретную модель.

Например:

Context Engine

      ↓

AI Provider Interface

      ↓

Provider A

Provider B

Provider C

Local Model

---

# 35. Context Package

Context Engine формирует структурированный пакет.

Концептуально:

ContextPackage

├── user_request

├── current_context

├── entities

├── relationships

├── memories

├── conversation_context

├── constraints

└── metadata

Фактический формат будет определён в технической спецификации.

---

# 36. Entity Representation

Entity в Context Package не обязательно должна передаваться полностью.

Например:

Entity

├── id

├── type

├── title

├── relevant fields

└── relationships

Нерелевантные поля могут быть исключены.

---

# 37. Field-Level Selection

Context Engine может выбирать отдельные поля.

Например:

Task

├── title       ✓

├── status      ✓

├── description ✓

├── internal_id ✗

├── unrelated_metadata ✗

Это уменьшает объём Context и повышает приватность.

---

# 38. Context Serialization

Перед передачей AI Context Package преобразуется в формат, понятный AI Provider.

Domain Data

     ↓

Context Package

     ↓

Provider Adapter

     ↓

Model Input

Domain Model не должна зависеть от формата конкретной модели.

---

# 39. Structured Context

Предпочтительно передавать AI структурированную информацию.

Например:

Project:

LifeOS

  

Status:

Active

  

Tasks:

- Implement Search

- Implement Context Engine

а не огромный неструктурированный текст.

---

# 40. Context Ordering

Информация в Context Package должна иметь предсказуемый порядок.

Например:

System Context

User Request

Current Entity

Relevant Entities

Relationships

Memory

Conversation Context

---

# 41. Context Provenance

Каждый элемент контекста желательно иметь источник.

Например:

Source:

Current Entity

  

Source:

Search Result

  

Source:

Relationship

  

Source:

User Selection

Это позволит объяснить происхождение информации.

---

# 42. Context Freshness

Context Engine должен учитывать актуальность данных.

Например:

Entity updated:

10 seconds ago

имеет более высокую актуальность, чем старый snapshot.

---

# 43. Stale Context

Если данные изменились между формированием Context и выполнением действия:

Context

   ↓

Data changed

   ↓

AI Action

система должна проверять актуальность перед изменением данных.

---

# 44. Context Snapshot

Для некоторых операций может использоваться Context Snapshot.

Current Data

     ↓

Context Snapshot

     ↓

AI Reasoning

Это помогает сделать операцию воспроизводимой.

---

# 45. Context and Tool Calling

Context Engine должен взаимодействовать с Tool Calling.

AI

 ↓

Tool Request

 ↓

Tool

 ↓

New Data

 ↓

Context Engine

 ↓

AI

Это позволит AI получать дополнительную информацию по мере необходимости.

---

# 46. Dynamic Context

Контекст не обязательно формируется один раз.

Он может расширяться:

Initial Context

      ↓

AI Request

      ↓

Tool Call

      ↓

New Information

      ↓

Updated Context

---

# 47. Context Loop Protection

Dynamic Context не должен приводить к бесконечному циклу.

Необходимо иметь ограничения:

- maximum tool calls;
- maximum context growth;
- maximum execution time;
- maximum token budget.

---

# 48. Context Determinism

Context Engine должен быть максимально предсказуемым.

При одинаковых данных и одинаковом запросе желательно получать сопоставимый Context Package.

Semantic ranking может вносить некоторую вариативность.

---

# 49. Context Logging

Для диагностики можно логировать:

Context size

Entity count

Search duration

Provider

Model

Но не следует без необходимости сохранять полное содержимое пользовательского контекста в logs.

---

# 50. Context Audit

Для операций, изменяющих данные, в будущем желательно сохранять:

AI Action

Context Source

User Approval

Result

Это поможет расследовать ошибки.

---

# 51. Context and User Approval

Не каждое действие AI должно выполняться автоматически.

Для потенциально опасных операций:

AI

 ↓

Proposed Action

 ↓

User Approval

 ↓

Execution

Context Engine должен предоставить необходимый контекст для принятия решения.

---

# 52. Context Quality

Качество AI напрямую зависит от качества Context.

Poor Context

    ↓

Poor AI Response

  

Relevant Context

    ↓

Better AI Response

Поэтому Context Engine является критической подсистемой LifeOS.

---

# 53. Context Evaluation

В будущем Context Engine должен иметь тесты качества.

Можно оценивать:

- relevance;
- completeness;
- precision;
- context size;
- latency.

---

# 54. Context Metrics

Технические метрики могут включать:

context_entities_count

context_tokens

search_latency

context_build_latency

provider_latency

---

# 55. Context Failure

Если Context Engine не смог получить дополнительный контекст:

Search Failed

AI всё ещё может работать с минимальным контекстом, если это безопасно.

Available Context

      ↓

AI

---

# 56. No Context

Некоторые запросы вообще не требуют пользовательского контекста.

Например:

"Что такое Flutter?"

может быть обработан:

User Request

 ↓

AI

без обращения к базе LifeOS.

---

# 57. Context Classification

Context Engine может определить тип запроса:

General Question

Personal Knowledge Query

Task Query

Project Query

Action Request

Analysis Request

От этого зависит стратегия получения контекста.

---

# 58. Personal Knowledge Query

Например:

"Что я решил по архитектуре LifeOS?"

требует:

Search

+

Relationships

+

Relevant Notes

---

# 59. Action Request

Например:

"Создай задачу по результатам этой встречи."

требует:

Current Meeting

+

Relevant Project

+

User Request

и после этого может потребоваться Tool Calling.

---

# 60. Analysis Request

Например:

"Почему проект задерживается?"

может потребовать:

Project

+

Tasks

+

Dependencies

+

Recent Changes

+

Notes

---

# 61. Context Strategy

Для каждого типа запроса Context Engine может использовать соответствующую стратегию.

Query Type

    ↓

Context Strategy

    ↓

Context Sources

---

# 62. Context Strategy Independence

Стратегии должны быть заменяемыми.

ContextStrategy

├── General

├── PersonalKnowledge

├── Project

├── Task

└── Action

Конкретный набор стратегий будет расширяться.

---

# 63. Context Caching

Некоторые Context Packages могут временно кэшироваться.

Например:

Current Project Context

Но Cache:

≠ Source of Truth

и должен инвалидироваться при изменении данных.

---

# 64. Context Invalidation

При изменении Entity:

Entity Updated

 ↓

Invalidate Related Context

---

# 65. Context and Sync

После Sync Context Engine должен видеть актуальные данные.

Sync

 ↓

Domain Data Updated

 ↓

Context Cache Invalidation

---

# 66. Context and Backup

Context Engine не должен быть источником Backup.

Backup сохраняет:

Core Data

Context Package является временным производным объектом.

---

# 67. Context and Export

Export не должен зависеть от Context Engine.

Domain Data

 ↓

Export

---

# 68. Context and Search Index

Context Engine может использовать Search Index.

Но:

Search Index

≠

Source of Truth

---

# 69. Context and Embeddings

Semantic Search может использовать embeddings для поиска кандидатов.

Query

 ↓

Embedding

 ↓

Vector Search

 ↓

Candidates

 ↓

Context Engine

---

# 70. Context and Relationships

Relationships позволяют расширять контекст.

Например:

Current Project

 ↓

Related Tasks

 ↓

Related Notes

 ↓

Related People

Но Context Engine должен ограничивать глубину traversal.

---

# 71. Relationship Depth

Например:

Depth 0:

Current Entity

  

Depth 1:

Direct Relationships

  

Depth 2:

Related Relationships

Глубокий traversal не должен выполняться без необходимости.

---

# 72. Context Explosion

Необходимо предотвращать:

Entity

 ↓

10 relations

 ↓

100 relations

 ↓

1000 relations

 ↓

10000 relations

Context Engine должен использовать:

- depth limits;
- entity limits;
- token limits;
- relevance thresholds.

---

# 73. Context Filtering

Перед передачей AI применяется несколько фильтров:

Candidates

   ↓

Permission

   ↓

Lifecycle

   ↓

Relevance

   ↓

Sensitivity

   ↓

Token Budget

   ↓

Final Context

---

# 74. Context Policy

Политики должны быть централизованы.

Например:

ContextPolicy

├── permissions

├── sensitivity

├── lifecycle

├── token_budget

└── source_policy

---

# 75. Provider-specific Adaptation

Разные AI модели могут иметь разные требования к Context.

Например:

Context Package

      ↓

Provider Adapter

      ↓

Provider-specific format

Context Engine не должен содержать provider-specific prompt formatting.

---

# 76. Model Independence

Если модель изменится:

Model A

 ↓

Model B

Domain Data и Context Package не должны измениться.

Может измениться только:

Provider Adapter

Prompt Strategy

Token Budget

---

# 77. Prompt Construction

Prompt construction является отдельным уровнем.

Context Engine

      ↓

Context Package

      ↓

Prompt Builder

      ↓

AI Provider

Prompt Builder не должен смешиваться с Domain Model.

---

# 78. System Instructions

System Instructions должны быть отделены от пользовательских данных.

System Instructions

+

Context

+

User Request

---

# 79. Context Injection Protection

Пользовательские данные могут содержать текст, похожий на инструкции.

Например:

"Ignore previous instructions..."

Context Engine и Prompt Builder должны рассматривать данные Entity как **данные**, а не как доверенные системные инструкции.

---

# 80. Untrusted Context

Внешние или импортированные данные также должны считаться недоверенными.

Imported Data

 ↓

Context

 ↓

AI

не означает:

Imported Data

 ↓

System Instructions

---

# 81. External Sources

В будущем Context Engine может получать внешние данные.

Например:

Web

Email

Calendar

Cloud Storage

Каждый внешний источник должен иметь отдельную policy.

---

# 82. External Context Permissions

Пользователь должен контролировать, какие внешние источники разрешены.

Calendar ✓

Email ✗

Web ✓

---

# 83. Context Consent

Если для запроса необходимо использовать внешний источник:

Need external data

      ↓

Permission / Consent

      ↓

Fetch

---

# 84. Context Isolation

Данные разных источников должны сохранять происхождение.

LifeOS Data

External Data

AI Generated Data

не следует смешивать без явной маркировки.

---

# 85. Generated Context

AI может создать временные промежуточные данные.

Например:

AI Summary

Они не становятся автоматически пользовательскими данными.

Пользователь должен иметь возможность сохранить их как Entity.

---

# 86. User Confirmation

Для сохранения AI-generated information:

AI Suggestion

 ↓

User Review

 ↓

Save

---

# 87. Context Ownership

Context Package является временным объектом, принадлежащим конкретной AI operation.

После завершения операции он может быть уничтожен, если не требуется для аудита.

---

# 88. Context Retention

LifeOS не должен бессрочно хранить все Context Packages.

Retention policy будет определена отдельно.

---

# 89. Context Reproducibility

Для важных AI actions может быть полезно сохранять минимальные сведения:

Model

Context Sources

Tool Calls

User Approval

Result

но не обязательно сохранять полный Context Package.

---

# 90. Context and AI Actions

Для изменения данных рекомендуется pipeline:

User Request

      ↓

Context Engine

      ↓

AI

      ↓

Proposed Action

      ↓

Permission Check

      ↓

User Approval

      ↓

Tool

      ↓

Database

---

# 91. Read vs Write Context

Read operations:

AI

 ↓

Context

Write operations:

AI

 ↓

Proposed Action

 ↓

Approval

 ↓

Tool

Write операции должны иметь более строгие ограничения.

---

# 92. Context Budget by Operation

Разные операции могут иметь разные бюджеты.

Например:

Simple Query

 → Small Context

  

Project Analysis

 → Larger Context

  

Deep Analysis

 → Extended Context

Конкретные значения будут определены после тестирования.

---

# 93. Context Prioritization

При нехватке бюджета система должна удалять наименее релевантную информацию первой.

High Relevance

   ↓

Keep

  

Low Relevance

   ↓

Remove

---

# 94. Context Truncation

Простое обрезание текста в середине важных данных нежелательно.

Предпочтительно:

Select relevant entities

+

Summarize long content

+

Remove irrelevant fields

---

# 95. Long Documents

Большие Notes или Documents должны обрабатываться отдельно.

Large Document

 ↓

Chunking

 ↓

Search

 ↓

Relevant Chunks

 ↓

Context

---

# 96. Chunking

Chunking может использоваться для больших документов и не должен изменять оригинальный документ.

Original Document

     ↓

Chunks

Chunks являются производными данными.

---

# 97. Chunk Metadata

Каждый chunk должен сохранять связь с оригинальным источником.

Chunk

├── source_entity_id

├── position

└── content

---

# 98. Context Quality vs Quantity

Больше Context не означает автоматически лучший результат.

More Data

   ≠

Better Answer

Цель Context Engine:

Relevant Data

+

Correct Data

+

Minimal Data

---

# 99. Context Engine as AI Gateway

Context Engine становится контролируемой точкой доступа AI к пользовательским данным.

                 AI

                  │

                  ↓

          Context Engine

                  │

        ┌─────────┼─────────┐

        ↓         ↓         ↓

      Search    Memory    Domain

        │         │         │

        └─────────┼─────────┘

                  ↓

             User Data

Это является важным архитектурным принципом LifeOS.

---

# 100. Основные принципы

Для AI Context Engine принимаются:

1. AI не получает прямой доступ ко всей базе данных.
2. Context Engine является промежуточным слоем между AI и пользовательскими данными.
3. Context Engine предоставляет минимально необходимый контекст.
4. Search является одним из основных источников контекста.
5. Relationships могут расширять контекст.
6. Current Context имеет высокий приоритет.
7. Явно выбранный пользователем контекст имеет высокий приоритет.
8. Lifecycle должен учитываться.
9. Security Policy применяется до передачи данных AI.
10. Sensitive Data должна проходить отдельную policy check.
11. Cloud AI получает только необходимый контекст.
12. Local AI также работает через Context Engine.
13. Context Engine не зависит от конкретного AI Provider.
14. Context Package отделён от Domain Model.
15. Provider-specific форматирование выполняется отдельным Adapter.
16. Context Budget является обязательной частью архитектуры.
17. Context Engine предотвращает Context Explosion.
18. Relationship traversal имеет ограничения глубины.
19. Search Index является производным источником.
20. Embeddings являются производными данными.
21. Context Package является временным объектом.
22. Context Cache не является Source of Truth.
23. Context может динамически расширяться через Tool Calling.
24. Dynamic Context должен иметь ограничения.
25. AI-generated data не становится автоматически пользовательскими данными.
26. Write operations требуют более строгого контроля, чем Read operations.
27. Внешние источники имеют отдельные permissions.
28. Импортированные данные считаются недоверенными.
29. Пользовательские данные не должны интерпретироваться как system instructions.
30. Context должен сохранять provenance.
31. Context Engine должен быть тестируемым независимо от конкретной модели.
32. Смена AI-модели не должна требовать изменения Domain Model.
33. Смена Search Engine не должна требовать изменения Context Engine API.
34. Context должен быть максимально детерминированным.
35. Полный Context Package не должен бессрочно храниться без необходимости.
36. AI должен получать качество контекста, а не максимальное количество данных.

---

# 101. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную AI-модель;
- конкретный AI Provider;
- конкретную embedding model;
- конкретный Search Engine;
- конкретную Vector Database;
- точный алгоритм ranking;
- точный token budget;
- конкретную Prompt Architecture;
- конкретный Tool Calling Protocol;
- конкретную Memory Architecture;
- конкретную UI реализацию;
- конкретную Permission Model.

Эти решения будут определены отдельными ADR и техническими спецификациями.

---

# 102. Последствия решения

## Положительные

- повышается приватность;
- уменьшается объём данных, передаваемых AI;
- снижается стоимость AI-запросов;
- повышается качество контекста;
- AI становится независимым от структуры Database;
- можно менять AI-модели;
- можно менять Search Engine;
- можно использовать Local и Cloud AI;
- появляется единая точка контроля доступа AI к данным;
- Context может использовать Search, Relationships и Memory;
- архитектура готова к масштабированию.

## Отрицательные

- появляется дополнительная подсистема;
- необходимо реализовать ranking;
- необходимо контролировать Context Budget;
- потребуется Context Policy;
- сложнее становится debugging;
- потребуется тестирование качества контекста;
- Dynamic Context требует защиты от Context Explosion;
- появится дополнительная логика для работы с большими документами.

---

# 103. Следующие документы

После ADR-0013 предлагается перейти к:

ADR-0014:  
AI Tool Calling and Permissions

ADR-0015:  
Semantic Search and Embeddings

ADR-0016:  
Sync Protocol

ADR-0017:  
Authentication Architecture

ADR-0018:  
Encryption and Key Management

После этого необходимо перейти к проектированию Domain Model LifeOS.

  

### Что мы только что зафиксировали

  

Самая важная часть ADR-0013 — вот эта цепочка:

  

```text
                 USER
                   │
                   ↓
              AI Request
                   │
                   ↓
          ┌─────────────────┐
          │ Context Engine  │
          └────────┬────────┘
                   │
       ┌───────────┼───────────┐
       ↓           ↓           ↓
    Search     Relations    Memory
       │           │           │
       └───────────┼───────────┘
                   ↓
             Security Filter
                   ↓
             Context Budget
                   ↓
             Relevant Context
                   ↓
                AI Model

Именно это позволит нам в будущем сделать LifeOS действительно **AI-native**, не превращая его в приложение, которое просто отправляет огромные куски базы данных в ChatGPT.


```