# AI-архитектура LifeOS

**Статус:** Черновик  
**Версия:** 0.1  
**Дата:** 2026-08-10

---

# 1. Назначение

Этот документ описывает архитектуру искусственного интеллекта в LifeOS.

AI является отдельным интеллектуальным слоем системы и не должен быть жёстко связан с конкретным поставщиком или моделью.

Архитектура должна позволять использовать:

- Cloud AI;
- Local AI;
- разные AI-модели;
- разные AI-провайдеры;
- различные embedding-модели;
- semantic search;
- RAG;
- AI-assisted actions;
- AI-assisted conflict resolution.

---

# 2. Главный принцип

AI LifeOS не является обычным чат-ботом.

Его задача — понимать контекст пользователя и помогать ему работать с собственной информацией.

Основная модель:

```
User
  ↓
LifeOS
  ↓
Context Engine
  ↓
AI
  ↓
Recommendation / Action
  ↓
User
```

AI не должен напрямую работать с базой данных.

---

# 3. AI как интеллектуальный слой

Общая архитектура:

```
                         LIFEOS
                            │
                            ↓
                     Context Engine
                            │
                  ┌─────────┴─────────┐
                  ↓                   ↓
              Local AI             Cloud AI
                  │                   │
                  └─────────┬─────────┘
                            ↓
                      AI Orchestrator
                            │
                 ┌──────────┴──────────┐
                 ↓                     ↓
          Recommendation            Action
                 ↓                     ↓
               User              Application
```

---

# 4. AI Orchestrator

AI Orchestrator является центральной точкой взаимодействия LifeOS с AI.

Он отвечает за:

- выбор AI-провайдера;
- подготовку запроса;
- передачу контекста;
- контроль permissions;
- обработку ответа;
- оценку результата;
- маршрутизацию действий;
- logging;
- обработку ошибок.

Application Layer не должен напрямую вызывать конкретный AI API.

---

# 5. AI Provider Abstraction

AI должен быть скрыт за интерфейсом.

Предварительно:

```
AIProvider
│
├── LocalAIProvider
├── CloudAIProvider
└── MockAIProvider
```

Это позволяет заменить модель без изменения остальной архитектуры.

Например:

```
LifeOS
  ↓
AIProvider
  ↓
Provider A
```

может позднее стать:

```
LifeOS
  ↓
AIProvider
  ↓
Provider B
```

---

# 6. Context Engine

Context Engine является одним из ключевых компонентов LifeOS.

Его задача:

> определить, какая информация действительно необходима AI для решения конкретной задачи.

Архитектура:

```
User Request
      ↓
Context Engine
      ↓
Search
      ↓
Relationships
      ↓
Lifecycle
      ↓
Permissions
      ↓
Sensitivity
      ↓
Ranking
      ↓
Relevant Context
      ↓
AI
```

---

# 7. Почему нельзя отправлять всю базу

Нельзя использовать модель:

```
SQLite
   ↓
Entire Database
   ↓
AI
```

Это приводит к:

- огромному контексту;
- высокой стоимости;
- медленной обработке;
- утечке лишней информации;
- ухудшению качества ответа;
- сложностям с приватностью.

Правильная модель:

```
Entire Database
      ↓
Context Engine
      ↓
Relevant Information
      ↓
AI
```

---

# 8. C+ модель контекста

LifeOS использует ранее выбранную модель:

**Context + Lifecycle**

Контекст определяется не только содержанием сущности, но и её состоянием жизненного цикла.

Например:

```
Task
├── Active
├── Archived
└── Deleted
```

При обычном запросе:

```
"Что мне сделать сегодня?"
```

AI получает:

```
Active Tasks
Today's Events
Relevant Projects
Recent Changes
```

Но не получает автоматически:

```
Archived Tasks
Deleted Entities
Old Notes
```

---

# 9. Relationships

Context Engine должен учитывать связи между сущностями.

Например:

```
Project
   │
   ├── Task
   │
   ├── Person
   │
   ├── Note
   │
   └── Event
```

Если пользователь спрашивает о Project, Context Engine может определить связанные сущности.

---

# 10. Graph-aware Context

В будущем данные LifeOS можно рассматривать как граф:

```
              Person
                 │
                 │
Project ───── Task ───── Event
   │             │
   │             │
 Note        Dependency
```

AI получает не только отдельные записи, но и релевантную часть графа.

---

# 11. Context Expansion

Контекст может расширяться от исходной сущности.

Например:

```
User:
"Почему я не могу закончить проект?"
```

Context Engine:

```
Project
   ↓
Tasks
   ↓
Dependencies
   ↓
Blocked Tasks
   ↓
People
   ↓
Recent Notes
   ↓
Events
```

Таким образом AI получает не только название проекта, но и его актуальное состояние.

---

# 12. Context Budget

Контекст имеет ограниченный размер.

Поэтому Context Engine должен ранжировать информацию.

Пример:

```
Relevance Score

Task A      0.98
Task B      0.91
Project C   0.86
Note D      0.62
Old Note E  0.14
```

В AI передаются наиболее релевантные элементы.

---

# 13. Relevance

Релевантность может определяться на основе:

- текстового совпадения;
- semantic similarity;
- relationships;
- lifecycle;
- времени;
- приоритета;
- частоты использования;
- недавних изменений;
- текущего контекста пользователя.

Формула оценки будет определена после создания поискового прототипа.

---

# 14. Semantic Search

LifeOS должен поддерживать не только поиск по словам.

Например:

Пользователь спрашивает:

```
"Что связано с поездкой в Берлин?"
```

В базе может находиться:

```
"Забронировать гостиницу"
"Купить билет"
"Встреча с Марком"
"Конференция"
```

Даже если слово "поездка" отсутствует.

Semantic Search позволит находить смысловые совпадения.

---

# 15. Embeddings

Для semantic search могут использоваться embeddings.

Общая модель:

```
Text
 ↓
Embedding Model
 ↓
Vector
 ↓
Vector Index
```

Например:

```
"купить билет"
      ↓
[0.12, -0.43, 0.91, ...]
```

Конкретная embedding-модель пока не выбирается.

---

# 16. Vector Storage

Векторный индекс должен быть отдельным механизмом от основной реляционной модели.

Предварительно:

```
SQLite
 ├── Entities
 ├── Relationships
 └── Metadata

Vector Index
 └── Embeddings
```

На ранней стадии необходимо проверить возможность хранения embeddings непосредственно рядом с SQLite либо использования специализированного локального решения.

---

# 17. RAG

RAG используется как механизм:

```
User Question
      ↓
Search
      ↓
Relevant Data
      ↓
Context
      ↓
AI
      ↓
Answer
```

LifeOS не должен отправлять AI запрос без предварительного формирования контекста, когда ответ требует пользовательских данных.

---

# 18. Context Sources

Источниками контекста могут быть:

```
Entities
Relationships
Tasks
Projects
Notes
Events
Files
History
Recent Changes
User Preferences
```

Однако каждый источник должен проходить фильтрацию.

---

# 19. Context Priority

Предварительный порядок:

```
1. Explicit User Input
2. Active Entities
3. Direct Relationships
4. Recent Changes
5. Relevant Historical Data
6. Archived Data
```

Deleted data не включается без специального запроса.

---

# 20. Explicit Context

Пользователь должен иметь возможность явно указать контекст.

Например:

```
"Проанализируй этот проект и связанные с ним задачи."
```

В таком случае Context Engine понимает начальную точку:

```
Project #123
```

и расширяет контекст вокруг неё.

---

# 21. User Context Preferences

В будущем пользователь сможет настроить:

```
AI Context
├── Include archived data
├── Include personal notes
├── Include calendar
├── Include files
└── Include sensitive data
```

Это позволит пользователю управлять поведением AI.

---

# 22. Sensitivity

Сущности могут иметь уровень чувствительности:

```
public
normal
sensitive
highly_sensitive
```

Чем выше уровень чувствительности, тем строже правила доступа AI.

---

# 23. AI Permissions

AI должен работать через permission layer.

```
User Request
      ↓
Permission Check
      ↓
Context Engine
      ↓
AI
```

Например:

```
AI может:
✓ читать Tasks

AI не может:
✕ читать Highly Sensitive Notes
```

без соответствующего разрешения.

---

# 24. Cloud AI Privacy

Если используется Cloud AI:

```
Local Data
    ↓
Context Filtering
    ↓
Permission Check
    ↓
Minimal Context
    ↓
Cloud AI
```

В Cloud не должна отправляться вся база пользователя.

---

# 25. Local AI

Архитектура должна позволять запускать AI локально.

```
LifeOS
   ↓
Context Engine
   ↓
Local AI
```

Преимущества:

- приватность;
- offline operation;
- отсутствие сетевой задержки;
- потенциально отсутствие стоимости API.

Недостатки:

- требования к CPU/GPU/RAM;
- размер моделей;
- качество некоторых моделей;
- энергопотребление на мобильных устройствах.

---

# 26. Hybrid AI

В будущем LifeOS может выбирать между Local и Cloud AI.

```
                  AI Request
                       │
                AI Router
                  /      \
                 /        \
             Local       Cloud
```

Например:

```
Simple request
      ↓
Local AI
```

Сложная задача:

```
Complex reasoning
      ↓
Cloud AI
```

Правила маршрутизации должны контролироваться пользователем.

---

# 27. AI Router

AI Router выбирает подходящий AI Provider.

Критерии:

- тип задачи;
- сложность;
- privacy level;
- наличие интернета;
- стоимость;
- latency;
- доступность модели;
- размер контекста.

---

# 28. AI Actions

AI может не только отвечать, но и предлагать действия.

Например:

```
User:
"Создай задачу купить билеты."
```

AI:

```
Action Proposal

Create Task:
"Купить билеты"
```

После подтверждения:

```
User
 ↓
Confirm
 ↓
Application Layer
 ↓
Domain
 ↓
Repository
 ↓
SQLite
```

---

# 29. AI не изменяет базу напрямую

Запрещённая архитектура:

```
AI
 ↓
SQLite
```

Правильная:

```
AI
 ↓
Action Proposal
 ↓
Application
 ↓
Domain Rules
 ↓
Repository
 ↓
Database
```

Это обязательная граница безопасности.

---

# 30. Structured AI Actions

AI должен возвращать структурированные действия.

Например:

```
Action:
CREATE_TASK

Parameters:
title = "Купить билеты"
priority = "high"
```

Application Layer проверяет:

```
Is action valid?
Are parameters valid?
Does user have permission?
```

Только после этого действие выполняется.

---

# 31. Confirmation Policy

Для действий вводится политика подтверждений.

Например:

```
Low Risk
→ можно выполнить автоматически

Medium Risk
→ требуется подтверждение

High Risk
→ всегда требуется подтверждение
```

Примеры:

```
Create Task
→ Low

Delete Task
→ High

Send Message
→ High

Modify Calendar Event
→ Medium/High
```

Конкретная классификация будет определена отдельно.

---

# 32. Destructive Actions

Особенно осторожно обрабатываются:

- удаление;
- массовое изменение;
- отправка сообщений;
- изменение важных событий;
- экспорт чувствительных данных;
- изменение permissions.

AI не должен выполнять такие действия без явного разрешения пользователя.

---

# 33. AI Confidence

AI может сообщать уровень уверенности.

Например:

```
Recommendation
Confidence: High
```

или:

```
Recommendation
Confidence: Low
```

Confidence не должен восприниматься как математическая гарантия правильности.

Он является дополнительным сигналом для пользователя.

---

# 34. Provenance

AI должен по возможности уметь объяснить, откуда взял информацию.

Например:

```
Ответ основан на:

✓ Project "Ремонт"
✓ Task "Купить краску"
✓ Note от 8 августа
✓ Event "Поездка в магазин"
```

Пользователь может открыть исходные сущности.

Это повышает доверие к AI.

---

# 35. Hallucination Protection

AI может ошибаться.

Поэтому:

```
AI Answer
    ↓
Source Verification
    ↓
User
```

Если AI не нашёл подтверждение в данных:

```
"В базе LifeOS не найдено подтверждение."
```

AI не должен выдавать предположение как факт.

---

# 36. Grounded Answers

Для вопросов о данных пользователя предпочтительна модель:

```
User Data
     ↓
Context
     ↓
AI
     ↓
Grounded Answer
```

AI должен отличать:

```
Known
Inferred
Unknown
```

---

# 37. AI Memory

AI Memory не должна быть отдельной копией всей базы пользователя.

Вместо этого память должна строиться поверх LifeOS entities.

Например:

```
Person
Project
Preference
Relationship
Event
Note
```

AI использует эти сущности как долговременную память.

---

# 38. Short-term Context

Краткосрочный контекст:

```
Current Conversation
Current Screen
Current Entity
Recent User Actions
```

Он существует ограниченное время.

---

# 39. Long-term Context

Долгосрочный контекст:

```
Projects
People
Preferences
Goals
Relationships
History
```

Он хранится как структурированные данные LifeOS.

---

# 40. AI Conversation History

История разговоров с AI может храниться отдельно.

```
AI Conversation
├── id
├── created_at
├── messages
└── context_references
```

Важно сохранять не только текст разговора, но и ссылки на сущности, использованные в контексте.

---

# 41. Context References

Например:

```
Conversation #123

Referenced:
Project #45
Task #88
Person #12
Note #91
```

Это позволит восстановить контекст разговора без хранения всей базы внутри AI history.

---

# 42. AI Feedback

Пользователь может исправлять AI.

Например:

```
AI:
"Эта задача связана с проектом X."

User:
"Нет, она относится к проекту Y."
```

Такое исправление может использоваться для:

- текущего результата;
- изменения relationship;
- улучшения будущих рекомендаций.

---

# 43. AI Suggestions vs User Decisions

Важно различать:

```
AI Suggestion
```

и:

```
User Decision
```

Например:

```
AI:
"Связать Task A с Project B?"

User:
YES
```

Только после решения пользователя связь становится частью данных.

---

# 44. Automatic Relationships

AI может предлагать новые связи:

```
Task A
   ↓
AI
   ↓
Potential Relationship
   ↓
User
```

В будущем для высокоуверенных и безопасных случаев может быть разрешено автоматическое создание связей.

Но по умолчанию новая важная связь должна быть подтверждена пользователем.

---

# 45. Relationship Confidence

Для AI-предложений связи может использоваться confidence:

```
Task A
   ↓
Related to
   ↓
Project B

Confidence: 0.94
```

Пользователь может:

```
Accept
Reject
Edit
```

---

# 46. Learning from Corrections

Пользовательские исправления являются ценным сигналом.

Например:

```
AI Suggestion
      ↓
User Correction
      ↓
Feedback
      ↓
Future Ranking
```

Однако данные пользователя не должны автоматически отправляться внешнему AI-провайдеру для обучения.

---

# 47. AI Safety Boundary

AI не должен иметь неограниченный доступ к системе.

Условная модель:

```
AI
 │
 ├── Read Context
 │
 ├── Suggest Action
 │
 └── Request Action
```

Но:

```
AI
 ├── Direct Database Access  ✕
 ├── Direct File Deletion    ✕
 ├── Direct Network Access   ✕
 └── Unrestricted OS Access  ✕
```

---

# 48. AI Tool System

В будущем AI может использовать инструменты.

Например:

```
AI
 │
 ├── Search
 ├── Create Task
 ├── Update Task
 ├── Search Calendar
 ├── Find Person
 └── Analyze Project
```

Каждый инструмент имеет строго определённый интерфейс.

---

# 49. Tool Permissions

Каждый AI Tool имеет permissions.

Например:

```
SearchTasks
→ read

CreateTask
→ write

DeleteTask
→ destructive
```

AI не может использовать инструмент, если permission не разрешает операцию.

---

# 50. AI Agent

В будущем LifeOS может получить агентный режим.

Например:

```
Goal:
"Подготовь меня к поездке."
```

Agent:

```
Search Events
      ↓
Find Trip
      ↓
Find Tasks
      ↓
Find Documents
      ↓
Find Missing Tasks
      ↓
Create Suggestions
```

Но агент должен работать через ограниченный набор инструментов.

---

# 51. Agent Execution

Агент не должен иметь бесконтрольный цикл.

Необходимо:

```
Goal
 ↓
Plan
 ↓
Actions
 ↓
Validation
 ↓
User Approval
 ↓
Execution
```

Для потенциально опасных действий требуется подтверждение.

---

# 52. Offline AI

При отсутствии интернета LifeOS должен продолжать работать.

Минимально:

```
Local Data
Search
Basic Context
```

AI может быть:

```
Available
```

если локальная модель установлена.

Иначе:

```
AI unavailable
```

но остальные функции продолжают работать.

---

# 53. AI Cost Control

Для Cloud AI необходимо учитывать стоимость.

Context Engine должен уменьшать:

- размер контекста;
- количество запросов;
- повторные запросы;
- ненужные embeddings;
- повторную обработку одинаковых данных.

В будущем может появиться:

```
AI Usage
├── Requests
├── Tokens
├── Estimated Cost
└── Provider
```

---

# 54. Caching

Некоторые AI-результаты можно кэшировать.

Например:

```
Question
+
Context Hash
      ↓
Cached Result
```

Если контекст не изменился, повторный запрос может не понадобиться.

Кэш должен иметь срок действия.

---

# 55. Privacy Modes

В будущем LifeOS может поддерживать режимы:

```
Maximum Privacy
Balanced
Cloud AI
```

Например:

### Maximum Privacy

```
Local Context
+
Local AI
```

### Balanced

```
Local Context
+
Cloud AI
```

только для разрешённых данных.

---

# 56. AI Audit Log

Для чувствительных AI-действий может использоваться audit log.

Например:

```
AI Action
├── timestamp
├── provider
├── action
├── affected_entities
├── user_confirmation
└── result
```

Это помогает расследовать ошибки.

---

# 57. AI Error Recovery

Если AI выдал неправильное действие:

```
AI
 ↓
Action
 ↓
Validation
 ↓
Rejected
```

действие не должно применяться.

Если действие уже было выполнено:

```
Action
 ↓
Audit
 ↓
Undo / Recovery
```

Для обратимых операций желательно поддерживать Undo.

---

# 58. AI and Sync

AI должен работать поверх локального состояния.

```
SQLite
 ↓
Context Engine
 ↓
AI
```

Sync работает отдельно:

```
SQLite
 ↓
Sync Queue
 ↓
Sync Engine
```

AI не должен напрямую управлять Sync Engine.

---

# 59. AI-generated Changes

Если AI создал или изменил сущность:

```
AI
 ↓
Action Proposal
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

То есть AI-generated изменения становятся обычными LifeOS изменениями.

Это важный принцип.

---

# 60. Architecture Summary

Итоговая архитектура:

```
                         LIFEOS
                            │
                   ┌────────┴────────┐
                   ↓                 ↓
              Application        Context Engine
                   │                 │
                   ↓                 ↓
                Domain             Search
                   │                 │
                   ↓                 ├── Semantic
              Repository            ├── Relationships
                   │                 ├── Lifecycle
             ┌─────┴─────┐          ├── Permissions
             ↓           ↓          └── Ranking
          SQLite      Files              │
             │           │               ↓
             └─────┬─────┘              AI
                   │              ┌──────┴──────┐
              Sync Queue          ↓             ↓
                   │           Local AI      Cloud AI
                   ↓
              Sync Engine
```

---

# 61. Основные архитектурные принципы

1. AI является отдельным слоем системы.
2. AI не имеет прямого доступа к SQLite.
3. AI не должен напрямую изменять данные.
4. Все изменения проходят через Application и Domain.
5. Context Engine определяет необходимый контекст.
6. AI не получает всю базу пользователя.
7. Lifecycle учитывается при формировании контекста.
8. Relationships используются для расширения контекста.
9. Semantic Search будет использоваться для поиска по смыслу.
10. Embeddings являются отдельным механизмом поиска.
11. RAG используется для grounded answers.
12. AI Provider скрыт за абстракцией.
13. Поддерживается возможность Local AI.
14. Поддерживается возможность Cloud AI.
15. Возможен Hybrid AI.
16. AI Router может выбирать подходящую модель.
17. AI может предлагать действия.
18. Критические действия требуют подтверждения.
19. AI Suggestions и User Decisions являются разными состояниями.
20. AI может предлагать relationships.
21. Пользовательские исправления могут использоваться как feedback.
22. AI должен по возможности указывать источники ответа.
23. AI должен отличать известное от предположительного.
24. AI Memory строится поверх данных LifeOS.
25. AI Conversation History хранит ссылки на использованный контекст.
26. AI Tools имеют отдельные permissions.
27. Agent Mode будет ограничен набором инструментов.
28. AI не должен иметь неограниченного доступа к ОС.
29. Privacy является частью AI-архитектуры.
30. Cloud AI получает только необходимый контекст.
31. AI должен работать поверх локального состояния.
32. AI-generated changes проходят обычный жизненный цикл данных.
33. Sync и AI являются независимыми подсистемами.
34. Конкретная AI-модель пока не фиксируется.

---

# 62. Открытые решения

Пока не определены:

- конкретный AI Provider;
- Local AI Runtime;
- Cloud AI API;
- embedding model;
- vector storage;
- semantic search engine;
- RAG implementation;
- AI Router;
- AI Tool protocol;
- Agent framework;
- AI memory implementation;
- AI cost tracking;
- privacy mode implementation.

Каждое существенное техническое решение должно быть оформлено отдельным ADR.

---

# 63. Следующий этап

После завершения AI-архитектуры необходимо определить архитектуру пользовательского интерфейса.

Следующий документ:

docs/05-ui-ux/ui-ux-architecture.md

После этого необходимо:

1. Провести ревью AI-архитектуры.
2. Провести ревью UI/UX архитектуры.
3. Выбрать конкретные Flutter-библиотеки.
4. Создать ADR по технологическому стеку.
5. Создать минимальный Flutter-проект.
6. Реализовать Domain Model.
7. Реализовать SQLite.
8. Реализовать Repository.
9. Создать первый рабочий экран LifeOS.
