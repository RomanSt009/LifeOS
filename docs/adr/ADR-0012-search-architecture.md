# ADR-0012: Search Architecture

**Статус:** Предварительно принято  
**Дата:** 2026-08-17  
**Версия:** 0.1

## 1. Контекст

LifeOS является Local-first системой, которая со временем будет содержать большое количество пользовательских данных.

В системе могут находиться:

- Notes;
- Tasks;
- Projects;
- Goals;
- Events;
- People;
- Resources;
- Files;
- AI-generated entities;
- Relationships;
- Metadata.

По мере роста количества данных простой просмотр списка становится недостаточным.

Пользователь должен иметь возможность быстро находить нужную информацию.

При этом поиск должен:

- работать offline;
- быть быстрым;
- масштабироваться вместе с количеством данных;
- поддерживать обычный текстовый поиск;
- в будущем поддерживать semantic search;
- учитывать metadata;
- потенциально учитывать relationships;
- не зависеть от конкретного AI provider.  

---
# 2. Проблема

Существует несколько разных типов поиска.
### Keyword Search

Поиск по совпадению текста.

Например:

  
```text

"Flutter"
````
```

```
может найти:
```
Flutter project

Flutter documentation

Flutter architecture
```
```
```
### Filtered Search

Поиск с использованием metadata.

Например:

```
type:project
status:active
tag:flutter
```

### Semantic Search

Поиск по смыслу.

Например:

```
"Что я планировал сделать с мобильной версией?"
```

может найти:

```
Project Mobile App
Note Flutter Architecture
Task Mobile UI
```

даже если точной фразы в документах нет.

### Relationship Search

Поиск через связи.

Например:

```
Project LifeOS
   ↓
Tasks
   ↓
Notes
   ↓
People
```

---
# 3. Основное решение

LifeOS будет использовать **многоуровневую Search Architecture**.

Основной принцип:

```
                    Search
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
      Keyword       Filters      Semantic
          │            │            │
          └────────────┼────────────┘
                       ↓
                  Result Ranking
                       ↓
                    Results
```

Semantic Search не заменяет обычный поиск.

Он является дополнительным уровнем.

---

# 4. Local-first Search

Основной поиск должен работать локально.

```
User
 ↓
Search Query
 ↓
Local Search Engine
 ↓
Results
```

Наличие:

```
- интернет-соединения;
- аккаунта;
- Cloud;
- AI Provider
```

не должно быть обязательным для базового поиска.

---

# 5. Почему нельзя использовать AI для каждого поиска

Если каждый запрос отправлять в AI:

```
User
 ↓
AI
 ↓
Search
```

возникают проблемы:

- задержка;
- стоимость;
- зависимость от сети;
- проблемы приватности;
- непредсказуемость результатов;
- невозможность гарантировать работу offline.

Поэтому:

```
Basic Search
      ↓
No AI required
```

---

# 6. Search Layers

Архитектура состоит из нескольких уровней.

```
Layer 1
Keyword Search

Layer 2
Metadata / Filters

Layer 3
Relationship Search

Layer 4
Semantic Search

Layer 5
AI-assisted Search
```

Каждый последующий уровень является расширением предыдущего.

---

# 7. Keyword Search

Keyword Search является базовым механизмом.

Он должен поддерживать поиск по:

- title;
- body;
- tags;
- properties;
- metadata.

Пример:

```
flutter
```

может найти:

```
Flutter Architecture
Flutter Mobile
Flutter Desktop
```

---

# 8. Full-text Search

Для текстового содержимого должен использоваться Full-text Search.

Конкретная технология будет определена на этапе выбора Database/Search Engine.

Архитектура должна позволять заменить конкретную реализацию.

Например:

```
SearchService
      │
      ↓
FullTextSearchProvider
```

---

# 9. Search Index

Для ускорения поиска может использоваться отдельный Search Index.

```
Domain Data
     ↓
Search Index
     ↓
Search Query
```

Search Index является производной структурой.

Source of Truth остаётся Domain Data.

---

# 10. Search Index Rebuild

Если Search Index повреждён:

```
Database
   ↓
Rebuild Index
   ↓
Search Available
```

Поэтому Search Index не должен считаться критической пользовательской информацией.

Это также согласуется с ADR-0011.

---

# 11. Index Updates

При изменении Entity:

```
Entity Updated
      ↓
Update Search Index
```

При удалении:

```
Entity Deleted
      ↓
Remove From Search Index
```

При создании:

```
Entity Created
      ↓
Add To Search Index
```

---

# 12. Transactional Consistency

По возможности изменение Domain Data и обновление Search Index должны быть согласованы.

Однако Search Index является производным.

Если обновление индекса не удалось:

```
Database Update
      ↓
Index Update FAILED
```

основные пользовательские данные не должны теряться.

В таком случае Index должен быть восстановлен или перестроен.

---

# 13. Search Queue

Для масштабируемости обновление индекса может выполняться через очередь.

```
Entity Change
     ↓
Index Queue
     ↓
Search Index
```

Это позволит не блокировать UI при больших операциях.

---

# 14. Metadata Search

Search должен поддерживать фильтрацию по metadata.

Например:

```
type:task
status:active
priority:high
```

или:

```
tag:flutter
```

---

# 15. Structured Query

В будущем может поддерживаться structured query.

Например:

```
type:project status:active
```

или:

```
tag:AI created:2026
```

Конкретный синтаксис будет определён отдельной Search Specification.

---

# 16. Free Text + Filters

Пользователь должен иметь возможность объединять:

```
Free Text
+
Filters
```

Например:

```
"mobile"
type:project
status:active
```

---

# 17. Search Scope

Поиск должен поддерживать разные области.

Например:

```
Everything
Projects
Tasks
Notes
People
Files
```

---

# 18. Entity Type Search

Можно ограничить поиск конкретным типом Entity.

Например:

```
type:note
```

или:

```
type:project
```

---

# 19. Lifecycle Search

Search должен учитывать Lifecycle Model LifeOS.

Например:

```
status:active
```

или:

```
status:archived
```

---

# 20. Archived Data

Archived Entities должны иметь возможность находиться через Search.

Но в обычных результатах они могут иметь меньший приоритет.

Например:

```
Search
 ↓
Active Results
 ↓
Archived Results
```

---

# 21. Deleted Data

Soft-deleted Entities не должны появляться в обычном поиске.

Исключение:

```
Trash Search
```

если такая функция будет реализована.

---

# 22. Tags

Tags должны индексироваться.

Например:
```
#flutter
#lifeos
#ai
```

Поиск:
```
tag:ai
```

---

# 23. Properties

Пользовательские properties также могут участвовать в поиске.

Например:

```
priority:high
```

или:

```
project:LifeOS
```

---

# 24. Relationships

Search Architecture должна предусматривать возможность поиска по relationships.

Например:

tasks connected to project LifeOS

или:

notes related to Project X

---

# 25. Relationship Search

Концептуально:

Entity A

   │

   └── relationship

           │

           ↓

        Entity B

Search может использовать эту связь для формирования результатов.

---

# 26. Semantic Search

Semantic Search будет дополнительным механизмом.

Он позволяет находить данные не только по словам, но и по смыслу.

Например:

Query:

  

"Какие идеи у меня были по мобильной версии?"

может найти:

Mobile Architecture

Flutter Decision

Mobile UI Ideas

Android Tasks

---

# 27. Embeddings

Semantic Search может использовать embeddings.

Entity

 ↓

Embedding Model

 ↓

Vector

Запрос:

Search Query

 ↓

Embedding Model

 ↓

Query Vector

Затем выполняется similarity search.

---

# 28. Embeddings как производные данные

Embeddings не являются Source of Truth.

Domain Data

      ↓

Embedding

При необходимости:

Domain Data

      ↓

New Embeddings

Это позволяет менять embedding model.

---

# 29. AI Provider Independence

Semantic Search не должен напрямую зависеть от конкретного AI Provider.

Предпочтительная архитектура:

SemanticSearchService

          │

          ↓

EmbeddingProvider

          │

     ┌────┼────┐

     ↓    ↓    ↓

  Local Cloud Future

---

# 30. Local Embeddings

В будущем embeddings могут создаваться локально.

Преимущества:

- приватность;
- offline;
- отсутствие API costs.

Недостатки:

- нагрузка на устройство;
- размер модели;
- возможная более низкая скорость.

---

# 31. Cloud Embeddings

Также может использоваться внешний provider.

Преимущества:

- не требуется большая локальная модель;
- потенциально высокое качество.

Недостатки:

- network dependency;
- стоимость;
- передача данных наружу.

---

# 32. Hybrid Embeddings

Архитектура должна допускать hybrid approach.

                    EmbeddingProvider

                           │

                ┌──────────┴──────────┐

                ↓                     ↓

             Local                  Cloud

Конкретная политика будет определена позже.

---

# 33. Semantic Search Availability

Если Semantic Search недоступен:

Semantic Search

      ↓

Unavailable

базовый Keyword Search должен продолжать работать.

Keyword Search

      ↓

Available

---

# 34. Search Result Ranking

Если используется несколько источников результатов:

Keyword

Metadata

Semantic

Relationships

результаты необходимо ранжировать.

Концептуально:

Score =

Keyword Score

+

Metadata Score

+

Semantic Score

+

Relationship Score

Точная формула будет определена после прототипирования.

---

# 35. Ranking Must Be Tunable

Ranking не должен быть жёстко зашит в UI.

Предпочтительно:

Search Engine

      ↓

Ranking Strategy

      ↓

Results

Это позволит менять алгоритм без переработки интерфейса.

---

# 36. Search Result Explanation

Для AI-assisted поиска желательно объяснять пользователю, почему результат найден.

Например:

Matched because:

  

Semantic similarity

Related to Project LifeOS

Contains "mobile"

Это повышает доверие к системе.

---

# 37. Search and AI Context

Search является одним из основных источников Context Engine.

User Query

     ↓

Search

     ↓

Relevant Entities

     ↓

Context Engine

     ↓

AI

Таким образом Search и AI остаются отдельными подсистемами.

---

# 38. AI Does Not Directly Search Database

AI не должен иметь произвольный прямой доступ к базе данных.

Предпочтительно:

AI

 ↓

Search Tool

 ↓

Search Service

 ↓

Database

Это согласуется с будущим ADR по AI Tool Calling & Permissions.

---

# 39. Search Permissions

Если в будущем появятся:

- multiple users;
- shared data;
- private entities;
- permissions;

Search должен учитывать права доступа.

Например:

User

 ↓

Search

 ↓

Permission Filter

 ↓

Results

---

# 40. Privacy Boundary

Если используется Cloud Semantic Search:

User Query

 ↓

Embedding / Search Request

 ↓

Cloud

необходимо учитывать Security Architecture.

Нельзя отправлять данные наружу без соответствующего разрешения и политики приватности.

---

# 41. Sensitive Data

Некоторые Entities могут содержать чувствительную информацию.

В будущем Search Architecture должна учитывать:

Sensitive Entity

      ↓

Search Policy

Например, Cloud Semantic Search может быть запрещён для определённых данных.

---

# 42. Offline Guarantee

Базовый Search должен работать без:

Internet

Cloud

AI Provider

Account

---

# 43. Performance

Search должен оставаться быстрым при увеличении количества данных.

Целевой принцип:

User Input

   ↓

Local Search

   ↓

Fast Results

Точные performance targets будут определены после появления прототипа.

---

# 44. Incremental Indexing

Не следует полностью перестраивать индекс после каждого изменения.

Предпочтительно:

Create Entity

 ↓

Index Entity

а не:

Create Entity

 ↓

Rebuild Everything

---

# 45. Bulk Operations

При массовом импорте или восстановлении:

1000 Entities

может использоваться пакетная индексация.

Import

 ↓

Bulk Index

 ↓

Search Available

---

# 46. Search During Restore

Во время Restore Search Index может временно отсутствовать.

После восстановления:

Restore Database

 ↓

Rebuild Search Index

 ↓

Enable Search

---

# 47. Search During Migration

После Database Migration:

Migration

 ↓

Validate

 ↓

Rebuild Search Index if required

---

# 48. Search Cache

Search Results могут кэшироваться для ускорения UI.

Но Cache:

≠ Source of Truth

и может быть удалён.

---

# 49. Search History

В будущем LifeOS может сохранять историю поисковых запросов.

Например:

Recent Searches

Но это должно быть опционально.

---

# 50. Privacy of Search History

Search History может содержать чувствительную информацию.

Поэтому она должна рассматриваться как пользовательские данные.

---

# 51. Search Suggestions

В будущем можно поддержать:

Recent searches

Tags

Entities

Properties

---

# 52. Autocomplete

Autocomplete должен работать локально.

User types:

"flut"

  

       ↓

  

flutter

flutter architecture

#flutter

AI для этого не требуется.

---

# 53. Fuzzy Search

В будущем может поддерживаться fuzzy matching.

Например:

"fluter"

может найти:

flutter

Но fuzzy search не должен заменять semantic search.

---

# 54. Typo Tolerance

Search может учитывать распространённые опечатки.

Конкретный алгоритм будет определён позже.

---

# 55. Multi-language Search

LifeOS потенциально должен работать с несколькими языками.

Search Architecture не должна быть жёстко привязана к английскому языку.

---

# 56. Tokenization

Конкретные правила tokenization зависят от выбранного Search Engine.

Это будет определено на техническом этапе.

---

# 57. Search Index Language Support

Search Engine должен по возможности поддерживать:

- русский;
- английский;
- другие языки.

---

# 58. Search and Files

В будущем Search может индексировать:

- filenames;
- metadata;
- text content;
- OCR text.

Но содержимое бинарных файлов не является обязательной частью MVP.

---

# 59. OCR

OCR может быть добавлен позднее:

Image

 ↓

OCR

 ↓

Text

 ↓

Search Index

Это не входит в MVP.

---

# 60. PDF Search

В будущем можно индексировать текст PDF:

PDF

 ↓

Text Extraction

 ↓

Search Index

Также не входит в MVP.

---

# 61. Search Scope

В будущем пользователь может выбирать:

All

Current Project

Current Entity

Selected Folder

---

# 62. Search UI

Search должен быть доступен из основного интерфейса.

На desktop предпочтительно предусмотреть:

Global Search

с быстрым вызовом через keyboard shortcut.

---

# 63. Keyboard Search

Для desktop может использоваться shortcut:

Ctrl / Cmd + K

Конкретный shortcut будет определён в UI/UX Specification.

---

# 64. Mobile Search

На mobile Search должен быть доступен через UI navigation.

---

# 65. Search Result Types

Результаты должны отображать тип Entity.

Например:

Project

Task

Note

Person

File

---

# 66. Result Preview

Результат может содержать:

Title

Entity Type

Relevant Text

Tags

Status

Updated Date

---

# 67. Highlighting

Совпадения по Keyword Search желательно подсвечивать.

Например:

Flutter Architecture

       ^^^^^^^

---

# 68. Semantic Result Explanation

Для semantic results желательно отображать понятное объяснение.

Например:

Related by meaning

вместо создания ложного впечатления точного текстового совпадения.

---

# 69. Search Errors

Если Search Engine временно недоступен:

Search unavailable

приложение должно предложить восстановить индекс.

---

# 70. Search Index Recovery

Например:

Settings

 ↓

Maintenance

 ↓

Rebuild Search Index

---

# 71. Search Observability

Search должен иметь диагностические метрики:

- query duration;
- index size;
- index status;
- number of indexed entities.

Но пользовательские данные не должны попадать в обычные logs.

---

# 72. Search Logging

Нельзя автоматически логировать полный пользовательский запрос, если он может содержать чувствительные данные.

Например, вместо:

Search query:

"мои пароли от..."

лучше:

Search executed

duration=15ms

---

# 73. Search Security

Search должен наследовать Security Architecture.

То есть:

Security

   ↓

Data Access

   ↓

Search

а не наоборот.

---

# 74. Search Architecture Independence

Search subsystem не должен напрямую зависеть от:

- Flutter UI;
- AI provider;
- конкретной database implementation.

Предпочтительно:

UI

 ↓

Search Application Service

 ↓

Search Domain Interface

 ↓

Search Infrastructure

---

# 75. Search API

Концептуально:

SearchService

может предоставлять:

search()

suggest()

rebuildIndex()

getStatus()

Конкретный API будет определён позже.

---

# 76. Search Provider

Инфраструктурная реализация:

SearchProvider

может быть заменена без изменения Domain Layer.

---

# 77. Future Search Engines

Архитектура должна позволять использовать:

Local FTS

Vector Search

Hybrid Search

Future Search Engine

без изменения пользовательской модели данных.

---

# 78. Database Independence

Search Architecture не должна заставлять Domain Model зависеть от конкретной базы.

Например:

Domain Entity

не должна знать о:

SQLite

FTS

Vector Database

---

# 79. Vector Storage

Если будут использоваться embeddings, Vector Storage может быть:

- встроенным;
- отдельным;
- локальным;
- cloud-based.

Конкретный вариант будет выбран позднее.

---

# 80. Hybrid Search

В будущем предпочтительным вариантом может стать:

Keyword Search

       +

Semantic Search

       +

Metadata

       +

Relationships

с последующим ranking.

---

# 81. Search Pipeline

Обобщённый pipeline:

User Query

     ↓

Query Parser

     ↓

Search Strategy

     ↓

┌────┼────────┬───────────┐

↓    ↓        ↓           ↓

FTS Filters Semantic Relationships

└────┼────────┴───────────┘

     ↓

Result Merge

     ↓

Ranking

     ↓

Permission Filter

     ↓

Results

---

# 82. Query Parser

Query Parser может определять:

Free Text

Filters

Tags

Properties

Entity Type

---

# 83. Search Strategy

Search Strategy выбирает необходимые уровни.

Простой запрос:

flutter

может использовать:

Keyword Search

Сложный запрос:

"что я планировал по мобильной версии"

может использовать:

Keyword

+

Semantic

+

Relationships

---

# 84. Search Cost

Более сложный Search может быть дороже по ресурсам.

Поэтому система должна начинать с дешёвого механизма и расширять поиск при необходимости.

Cheap

 ↓

Keyword

 ↓

Filters

 ↓

Semantic

 ↓

AI

Expensive

---

# 85. AI-assisted Search

AI может интерпретировать естественный язык.

Например:

"Покажи активные проекты связанные с LifeOS"

AI может преобразовать запрос в structured search.

Но:

AI

 ↓

Search Tool

а не:

AI

 ↓

Direct Database Access

---

# 86. Search Result Trust

Search должен стремиться быть детерминированным там, где это возможно.

Keyword Search:

same query

+

same data

=

predictable results

Semantic Search может быть менее детерминированным.

---

# 87. Search Reproducibility

Для диагностики желательно иметь возможность определить:

Search Version

Index Version

Embedding Model Version

---

# 88. Embedding Version

Embeddings должны иметь metadata:

embedding_model

embedding_version

Это позволит понять, нужно ли пересоздавать embeddings после смены модели.

---

# 89. Re-embedding

Если embedding model меняется:

Model A

 ↓

Old Embeddings

можно выполнить:

Model B

 ↓

Re-embedding

 ↓

New Embeddings

Основные данные при этом не меняются.

---

# 90. Search Migration

При изменении Search Engine:

Old Index

 ↓

New Index

может быть выполнена полная rebuild operation.

---

# 91. Search Backup

Search Index не является обязательной частью Backup.

Backup

 ↓

Core Data

После Restore:

Rebuild Search Index

---

# 92. Search and Export

Export не должен зависеть от Search Index.

Export должен читать Source of Truth.

Database

 ↓

Export

а не:

Search Index

 ↓

Export

---

# 93. Search and Sync

После Sync изменения должны попадать в Search Index.

Sync Change

 ↓

Domain Data

 ↓

Search Index Update

---

# 94. Search Consistency After Sync

Если Sync завершился:

Sync Success

но Search Index ещё обновляется:

Sync

 ↓

Indexing

UI может временно показывать:

Updating search index...

---

# 95. Search and Lifecycle

Lifecycle state должен участвовать в ranking/filtering.

Например:

Active

может иметь больший приоритет, чем:

Archived

---

# 96. Search and Relationships

Relationship graph не должен заменять Search Index.

Они выполняют разные задачи:

Search

 ↓

Find relevant entities

  

Graph

 ↓

Understand connections

---

# 97. Search and Context Engine

Search является одним из инструментов Context Engine.

AI Context Engine

       │

       ↓

Search

       │

       ↓

Relevant Entities

---

# 98. Search and Privacy

При использовании AI:

User

 ↓

Search

 ↓

Local filtering

 ↓

Only required context

 ↓

AI

Это позволяет минимизировать количество данных, отправляемых AI Provider.

---

# 99. Minimal Context Principle

AI не должен получать:

Entire Database

если ему нужны:

5 relevant entities

Поэтому Search становится важной частью Privacy Architecture.

---

# 100. Search Architecture Summary

Итоговая архитектура:

                         Search

                           │

                 ┌─────────┴─────────┐

                 ↓                   ↓

            Local Search       Semantic Search

                 │                   │

        ┌────────┼───────┐           ↓

        ↓        ↓       ↓       Embeddings

     Keyword  Filters  Relations      │

        └────────┼───────┘            │

                 └─────────┬──────────┘

                           ↓

                        Ranking

                           ↓

                   Permission Filter

                           ↓

                        Results

---

# 101. Основные принципы

Для Search Architecture принимаются:

1. Базовый Search работает offline.
2. Базовый Search не требует AI.
3. Keyword Search является фундаментом.
4. Full-text Search используется для текстового содержимого.
5. Metadata может участвовать в поиске.
6. Relationships могут участвовать в поиске.
7. Semantic Search является дополнительным уровнем.
8. AI не получает прямой доступ к Database.
9. AI использует Search через контролируемый интерфейс.
10. Search Index является производной структурой.
11. Search Index может быть полностью пересоздан.
12. Embeddings являются производными данными.
13. Embeddings могут быть пересозданы при смене модели.
14. Search не зависит от конкретного AI Provider.
15. Search не зависит от конкретной UI реализации.
16. Search не должен зависеть от конкретной Database implementation на уровне Domain.
17. Export не использует Search Index как Source of Truth.
18. Backup не обязан содержать Search Index.
19. Restore может выполнять rebuild Search Index.
20. Search должен учитывать Lifecycle.
21. Search должен учитывать Security.
22. Search должен учитывать Permissions в будущем.
23. Cloud Semantic Search не должен быть обязательным.
24. Local Keyword Search должен работать без Cloud.
25. AI должен получать только необходимый Context.
26. Search должен поддерживать расширение до Hybrid Search.
27. Search Ranking должен быть заменяемым.
28. Search Engine должен быть заменяемым.
29. Search Index должен поддерживать incremental updates.
30. Search должен поддерживать rebuild после миграций.
31. Search History, если будет реализована, считается пользовательскими данными.
32. Пользовательские запросы не должны без необходимости попадать в logs.
33. Search должен поддерживать многоязычность.
34. Производные Search Data не являются Source of Truth.

---

# 102. Что не фиксируется этим ADR

Этот ADR не определяет конкретно:

- конкретную Database;
- конкретный Full-text Search Engine;
- конкретный Vector Database;
- embedding model;
- AI Provider;
- алгоритм ranking;
- query syntax;
- fuzzy search algorithm;
- OCR engine;
- PDF parser;
- конкретную UI реализацию;
- keyboard shortcuts;
- точные performance targets.

Эти решения будут определены позднее.

---

# 103. Последствия решения

## Положительные

- быстрый локальный поиск;
- работа offline;
- отсутствие обязательной зависимости от AI;
- возможность semantic search;
- возможность hybrid search;
- возможность учитывать relationships;
- возможность менять AI models;
- возможность менять Search Engine;
- уменьшение объёма данных, передаваемых AI;
- хорошая совместимость с Local-first архитектурой;
- Search может стать основой AI Context Engine.

## Отрицательные

- появляется отдельная Search Infrastructure;
- необходимо поддерживать Search Index;
- потребуется rebuild mechanism;
- Semantic Search требует embeddings;
- Hybrid Search сложнее обычного Full-text Search;
- потребуется продумать ranking;
- multilingual search может быть сложнее;
- Search должен учитывать Security и Permissions.

---

# 104. Следующие документы

После ADR-0012 предлагается перейти к:

ADR-0013:  
AI Context Engine

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

  

### Что особенно важно в этом ADR

  

Я специально зафиксировал архитектуру так, чтобы **AI не стал центром всей системы**.

  

Получается:

  

```text

                LIFEOS

                   │

              Domain Data

                   │

        ┌──────────┼──────────┐

        ↓          ↓          ↓

      Search      Sync      Backup

        │

        ├── Keyword

        ├── Filters

        ├── Relations

        └── Semantic

                  │

                  ↓

             Context Engine

                  │

                  ↓

                  AI

Это хорошая основа для нашей дальнейшей идеи: **AI не должен "знать весь LifeOS". Он должен уметь находить нужные сущности, получать нужный контекст и работать с ним.**

И ещё одно решение здесь особенно полезно для будущего: **если через пару лет мы заменим AI-модель, embedding-модель или поисковый движок, основная модель данных LifeOS от этого не должна измениться.**