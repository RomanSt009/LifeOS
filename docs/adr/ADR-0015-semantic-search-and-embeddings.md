# ADR-0015: Semantic Search and Embeddings

**Статус:** Предварительно принято  
**Дата:** 2026-08-18  
**Версия:** 0.1
## 1. Контекст

LifeOS должен позволять пользователю находить информацию не только по точному совпадению слов, но и по смыслу.

Например, пользователь может написать:

> Где мы обсуждали идею автономного режима?

В базе при этом могут находиться записи:
  
- "Offline-first архитектура";
- "Работа без подключения к интернету";
- "Локальный режим приложения";
- "Синхронизация после восстановления сети".

Обычный keyword search может не найти все эти записи.

Semantic Search позволяет искать информацию по смысловой близости.

--- 

# 2. Проблема

LifeOS будет содержать большое количество различных типов данных:

- Notes;
- Tasks;
- Projects;
- Ideas;
- People;
- Documents;
- Events;
- Relationships;
- AI-generated context;
- пользовательские документы.

Количество сущностей со временем может значительно увеличиться.

Поэтому поиск должен масштабироваться от простого:

```text

"Flutter"

до более сложного:

"Что мы решили насчёт технологии интерфейса?"
```

---

# 3. Решение

В LifeOS используется гибридная система поиска:

```
                 Search Query
                      |
          ┌───────────┴───────────┐
          ↓                       ↓
   Keyword Search          Semantic Search
          |                       |
          └───────────┬───────────┘
                      ↓
               Result Ranking
                      ↓
                 Final Results
```

Основу составляют:

1. Keyword Search;
2. Semantic Search;
3. Hybrid Ranking.

---

# 4. Почему не только Semantic Search

Semantic Search хорошо понимает смысл, но не всегда хорошо работает с:

- точными именами;
- ID;
- датами;
- кодовыми словами;
- названиями файлов;
- редкими терминами;
- номерами задач;
- техническими идентификаторами.

Например:

```
ADR-0015
```

лучше искать обычным keyword search.

---

# 5. Почему не только Keyword Search

Keyword Search плохо работает с синонимами и переформулировками.

Например:

"работа без интернета"

и:

"offline-first"

могут означать практически одно и то же.

Semantic Search способен определить эту связь.

---

# 6. Hybrid Search

Основным подходом становится:

**Hybrid Search**

Он объединяет:

Keyword Score

+

Semantic Score

+

Context Score

+

Lifecycle Score

И формирует итоговый ranking.

---

# 7. Архитектура поиска

Концептуальная архитектура:

User Query

    |

    ↓

Query Processor

    |

    ├───────────────┐

    ↓               ↓

Keyword Search   Embedding Search

    |               |

    └───────┬───────┘

            ↓

      Result Fusion

            ↓

       Re-ranking

            ↓

       Context Filter

            ↓

        Final Results

---

# 8. Search Engine

Search Engine является отдельным application-level компонентом.

Он не должен быть частью AI Provider.

AI Provider

    |

    ↓

Search Tool

    |

    ↓

Search Engine

    |

    ├── Keyword Index

    └── Semantic Index

---

# 9. AI не владеет Search Engine

AI может использовать Search Tool.

Но Search Engine является частью LifeOS.

Это позволяет:

- менять AI Provider;
- использовать поиск без AI;
- использовать разные AI-модели;
- работать offline;
- тестировать поиск независимо от AI.

---

# 10. Embedding

Embedding — это числовое представление информации, которое позволяет сравнивать тексты по смысловой близости.

Условно:

"offline mode"

       ↓

[0.12, -0.44, 0.83, ...]

Другой текст:

"работа без подключения к сети"

       ↓

[0.10, -0.41, 0.79, ...]

Векторное расстояние между ними может быть небольшим.

---

# 11. Embedding не является текстом

Embedding не предназначен для чтения человеком.

Это математическое представление содержания.

Text

 ↓

Embedding Model

 ↓

Vector

---

# 12. Embedding Model

Для генерации embeddings используется отдельная модель.

Она не обязана совпадать с основной AI-моделью.

                LifeOS

                   |

        ┌──────────┴──────────┐

        ↓                     ↓

   Chat Model          Embedding Model

        |                     |

   reasoning              vectors

---

# 13. Provider Independence

Архитектура не должна зависеть от конкретного embedding provider.

Используется абстракция:

EmbeddingProvider

Например:

EmbeddingProvider

        |

   ┌────┴────┐

   ↓         ↓

 Local      Cloud

 Model      API

---

# 14. Local Embeddings

Возможен локальный embedding provider.

Преимущества:

- приватность;
- offline работа;
- отсутствие сетевых запросов;
- отсутствие зависимости от внешнего API;
- потенциально низкая стоимость.

Недостатки:

- больше требований к устройству;
- необходимо хранить модель;
- возможны ограничения производительности.

---

# 15. Cloud Embeddings

Возможен внешний embedding API.

Преимущества:

- проще первоначальная реализация;
- не требуется локальная модель;
- можно использовать более мощные модели;
- проще обновлять модель.

Недостатки:

- требуется сеть;
- данные могут покидать устройство;
- возможна стоимость API;
- появляется зависимость от provider.

---

# 16. Архитектурное решение

На уровне архитектуры LifeOS поддерживает оба варианта:

EmbeddingProvider

       |

       ├── LocalEmbeddingProvider

       |

       └── RemoteEmbeddingProvider

Конкретный provider выбирается отдельно.

---

# 17. Embedding Version

Каждый embedding должен иметь информацию о версии модели.

Например:

embedding_model:

"model-x"

  

embedding_version:

"v1"

---

# 18. Почему нужна версия

Если embedding model изменится:

Model V1

   ↓

Model V2

старые vectors могут стать несовместимыми или хуже работать вместе с новыми.

Поэтому система должна знать:

какая модель

+

какая версия

+

какая размерность

использовалась для создания embedding.

---

# 19. Embedding Metadata

Концептуально:

Embedding

├── entity_id

├── entity_type

├── model_id

├── model_version

├── dimensions

├── vector

├── created_at

└── content_hash

---

# 20. Content Hash

Embedding должен быть связан с версией исходного содержимого.

Например:

Content

   ↓

Hash

   ↓

Embedding

Если содержимое не изменилось, embedding не обязательно создавать заново.

---

# 21. Incremental Embedding

При изменении одной Entity не нужно пересчитывать embeddings всей базы.

Entity changed

      ↓

Content Hash changed

      ↓

Re-embed Entity

---

# 22. Embedding Queue

Для больших объёмов можно использовать очередь:

Entity Changed

      ↓

Embedding Job

      ↓

Embedding Provider

      ↓

Vector Index

---

# 23. Initial Indexing

При первом запуске LifeOS может потребоваться проиндексировать существующие данные.

Existing Data

      ↓

Batch Indexing

      ↓

Embeddings

      ↓

Vector Index

---

# 24. Background Processing

Embedding generation не должна блокировать UI.

Предпочтительный подход:

UI

 |

 └── Save Entity

          |

          ↓

     Local Database

          |

          ↓

    Background Job

          |

          ↓

       Embedding

---

# 25. Offline Mode

Offline режим должен поддерживать keyword search.

Semantic Search может работать offline только при наличии локального embedding provider.

Offline

  

Keyword Search       ✓

Local Embeddings     ✓

Cloud Embeddings     ✗

---

# 26. Search Availability

Если semantic search временно недоступен:

Semantic Search

      ↓

Unavailable

      ↓

Keyword Search

Поиск не должен полностью ломаться.

---

# 27. Graceful Degradation

Система должна деградировать постепенно:

Hybrid Search

     ↓

Semantic + Keyword

     ↓

Keyword only

     ↓

Basic local search

---

# 28. Vector Storage

Embeddings должны храниться отдельно от основной Entity-модели либо через специализированный vector index.

Концептуально:

Domain Database

      |

      ├── Entities

      ├── Relationships

      └── Metadata

  

Vector Index

      |

      └── Embeddings

---

# 29. Vector Database

На раннем этапе LifeOS не должен зависеть от отдельной внешней Vector Database без необходимости.

Предпочтение:

**local-first storage**

Конкретная технология будет определена после проверки выбранной Flutter/Dart экосистемы.

---

# 30. Local-first Principle

Semantic Search должен по возможности работать локально.

Это соответствует общей архитектуре LifeOS:

Local Data

    ↓

Local Search

    ↓

Optional Cloud Services

---

# 31. Vector Index Synchronization

Vector Index является производным состоянием.

Основным источником истины остаётся Domain Data.

Domain Data

     |

     ↓

Embedding

     |

     ↓

Vector Index

---

# 32. Source of Truth

Embedding не является источником истины.

Если embedding потерян:

Domain Data ✓

Embedding ✗

система должна иметь возможность восстановить embedding.

---

# 33. Rebuild

Vector Index должен поддерживать полную перестройку:

Domain Data

     ↓

Rebuild Embeddings

     ↓

New Vector Index

---

# 34. Embedding Migration

При смене embedding model:

Old Model

    ↓

Old Embeddings

  

New Model

    ↓

New Embeddings

Миграция должна выполняться постепенно или пакетно.

---

# 35. Dual Index

При необходимости переходного периода можно поддерживать:

Vector Index V1

Vector Index V2

После завершения миграции V1 удаляется.

---

# 36. Search Scope

Поиск должен учитывать область поиска.

Например:

All LifeOS

Project

Task

Notes

Current Context

Archived

---

# 37. Permission-aware Search

Search не должен возвращать пользователю Entity, к которой у него нет доступа.

Query

 ↓

Search

 ↓

Permission Filter

 ↓

Results

---

# 38. Permission Filter Before AI

Если поиск используется AI:

User Query

 ↓

Search

 ↓

Permission Filter

 ↓

Context

 ↓

AI

AI не должен получать запрещённые результаты.

---

# 39. Lifecycle-aware Search

Поиск должен учитывать lifecycle Entity.

Например:

Active

Archived

Deleted

По умолчанию:

Active → included

Archived → optional

Deleted → excluded

---

# 40. Context-aware Search

Search может использовать текущий Context.

Например:

Current Project:

LifeOS

  

Query:

"архитектура"

Система может повысить рейтинг документов проекта LifeOS.

---

# 41. Context Score

В будущем ranking может учитывать:

Semantic Similarity

+

Keyword Match

+

Current Context

+

Relationship Strength

+

Lifecycle

+

Recency

---

# 42. Recency

Для некоторых типов данных свежесть может повышать рейтинг.

Например:

Недавнее решение

может быть релевантнее старой заметки с похожим текстом.

---

# 43. Не использовать Recency глобально

Recency не должна автоматически повышать рейтинг для всех типов Entity.

Например, старый архитектурный ADR может быть важнее новой случайной заметки.

Ranking должен учитывать тип Entity.

---

# 44. Entity Type Weight

Можно использовать разные веса:

ADR

Project

Task

Note

Idea

Document

Конкретные значения не фиксируются этим ADR.

---

# 45. Relationship Score

Связанные Entity могут иметь дополнительный ranking score.

Например:

Current Project

      ↓

Related ADR

      ↓

Related Task

может быть релевантнее полностью независимой записи.

---

# 46. Semantic Similarity

Semantic Search использует similarity metric.

Конкретная метрика зависит от embedding implementation.

Наиболее распространённый вариант:

Cosine Similarity

Но конкретная реализация не фиксируется этим ADR.

---

# 47. Top-K

Semantic Search возвращает ограниченное количество кандидатов.

Например:

Top K = N

Конкретное значение будет определено после тестирования.

---

# 48. Re-ranking

После получения кандидатов выполняется дополнительный ranking.

Vector Search

      ↓

Candidates

      ↓

Re-ranking

      ↓

Top Results

---

# 49. Hybrid Ranking

Концептуально:

Final Score =

    Semantic Score

  + Keyword Score

  + Context Score

  + Relationship Score

  + Lifecycle Score

  + Optional Recency Score

Конкретная формула не фиксируется на данном этапе.

---

# 50. Search Query Processing

Пользовательский запрос может быть обработан:

Raw Query

   ↓

Normalization

   ↓

Keyword Query

   ↓

Embedding Query

---

# 51. Query Expansion

В будущем Search Engine может использовать query expansion.

Например:

"работа без сети"

может быть расширено до концептов:

offline

offline-first

local-first

network unavailable

Это не является обязательной частью первой реализации.

---

# 52. Search Explainability

По возможности Search UI должен позволять понять, почему результат показан.

Например:

Высокое смысловое совпадение

+ находится в текущем проекте

+ связано с текущей задачей

---

# 53. AI Search

AI может использовать Search Tool:

AI

 ↓

search_entities

 ↓

Hybrid Search

 ↓

Results

 ↓

Context

 ↓

AI

---

# 54. AI не должен получать всю базу

Даже при использовании Semantic Search AI получает только необходимые результаты.

Database

   ↓

Search

   ↓

Relevant Results

   ↓

Context Budget

   ↓

AI

---

# 55. Context Budget

Количество данных, передаваемых AI, должно быть ограничено.

Ограничение может зависеть от:

- модели;
- текущего запроса;
- размера результата;
- типа контекста;
- доступного token budget.

---

# 56. Chunking

Большие документы могут разбиваться на части.

Document

   ↓

Chunks

   ├── Chunk 1

   ├── Chunk 2

   ├── Chunk 3

   └── ...

Каждый chunk может иметь собственный embedding.

---

# 57. Chunk Metadata

Chunk должен сохранять связь с исходным документом:

Chunk

├── document_id

├── chunk_id

├── position

├── content_hash

└── embedding

---

# 58. Chunk Size

Конкретный размер chunk не фиксируется этим ADR.

Он будет определён экспериментально.

---

# 59. Overlap

Для некоторых документов может использоваться overlap между chunks.

Chunk 1

   └───────┐

           ├── overlap

           └───────┐

                   Chunk 2

Это решение также будет проверено экспериментально.

---

# 60. Structured Data

Не все Entity должны превращаться в один большой текст.

Например Task имеет:

title

status

priority

project

description

deadline

Embedding content должен формироваться контролируемо.

---

# 61. Search Representation

Для каждой Entity может существовать отдельное Search Representation.

Например:

Task

 ↓

Search Representation

 ↓

Embedding

---

# 62. Search Representation не является Domain Model

Search Representation является производным представлением.

Изменение Search Representation не должно менять Domain Model.

---

# 63. Sensitive Data

Чувствительные данные не должны автоматически попадать в embeddings.

Перед embedding generation может применяться filtering.

Entity

 ↓

Sensitive Data Filter

 ↓

Embedding Content

---

# 64. Secrets

Никогда не создавать embeddings для:

- passwords;
- API keys;
- private keys;
- access tokens;
- encryption keys.

---

# 65. Privacy

Если используется Remote Embedding Provider, данные должны проходить через отдельную privacy policy.

Пользователь должен понимать, какие данные могут отправляться наружу.

---

# 66. Local Embedding Preference

При наличии подходящей локальной модели LifeOS должен иметь возможность предпочесть local embeddings для чувствительных данных.

---

# 67. Remote Embedding Consent

В будущем использование Remote Embeddings может требовать отдельной настройки:

Allow cloud semantic search

[ ON / OFF ]

---

# 68. Embedding Cache

Embeddings могут кэшироваться.

Но cache является производным состоянием.

Удаление cache не должно приводить к потере Domain Data.

---

# 69. Cache Invalidation

При изменении:

Content Hash

старый embedding становится неактуальным.

---

# 70. Search Index Health

Система должна уметь определять:

Indexed

Pending

Outdated

Failed

для Entity.

---

# 71. Index Status

Например:

Entity

 ↓

Embedding Status

  

✓ Indexed

⟳ Processing

⚠ Outdated

✗ Failed

---

# 72. Failed Embeddings

Ошибка embedding generation не должна блокировать сохранение Entity.

Save Entity ✓

Embedding ✗

После этого может быть повторная обработка.

---

# 73. Retry

Embedding Jobs могут повторяться при временных ошибках.

Количество retries будет определено отдельно.

---

# 74. Rate Limits

Remote Embedding Provider может иметь rate limits.

Архитектура должна учитывать:

- batching;
- queue;
- retry;
- backoff;
- rate limiting.

---

# 75. Cost Control

Remote embeddings могут создавать расходы.

Поэтому система должна минимизировать ненужную генерацию embeddings.

Основные механизмы:

- content hash;
- incremental updates;
- batching;
- caching;
- configurable provider.

---

# 76. Search Telemetry

Можно собирать агрегированную техническую статистику:

search_time

result_count

embedding_latency

index_status

Без необходимости сохранять содержимое пользовательского запроса.

---

# 77. Security

Search Engine должен соблюдать общую Security Architecture LifeOS.

Особенно:

- permissions;
- data isolation;
- local encryption;
- privacy;
- audit requirements.

---

# 78. Sync

Embeddings являются производными данными.

Поэтому Sync Architecture может рассматривать их отдельно от основного Domain State.

Domain State

    ↓

Sync

  

Embedding Index

    ↓

Rebuild / Regenerate

---

# 79. Не синхронизировать embeddings без необходимости

Большие vector datasets могут значительно увеличивать размер синхронизации.

Поэтому первоначальное архитектурное решение:

> Embeddings не являются обязательной частью синхронизируемого Domain State.

При необходимости они могут быть восстановлены на другом устройстве.

---

# 80. Device-specific Index

Разные устройства могут иметь разные embedding models.

Например:

Desktop

 ↓

Local Model A

  

Mobile

 ↓

Local Model B

Это допустимо при сохранении provider abstraction.

---

# 81. Cross-device Consistency

Разные устройства могут иметь немного разные semantic ranking results.

Это допустимо.

Основной источник истины:

Domain Data

а не embedding index.

---

# 82. Deterministic Keyword Search

Keyword Search должен оставаться предсказуемым механизмом.

Semantic Search является дополнительным уровнем.

---

# 83. Search Fallback

Если embedding index повреждён:

Vector Search ✗

      ↓

Keyword Search ✓

---

# 84. Rebuild Trigger

Перестройка embeddings может запускаться:

- вручную;
- после обновления embedding model;
- после восстановления backup;
- после повреждения index;
- после миграции.

---

# 85. Backup

Основные Domain Data должны входить в Backup.

Embedding Index может быть:

included

или:

rebuildable

Конкретная стратегия определяется Backup Architecture.

---

# 86. Version Compatibility

Embedding Index должен проверять совместимость:

Model Version

Embedding Dimension

Index Version

---

# 87. Invalid Index

Если параметры несовместимы:

Index

 ↓

Invalid

 ↓

Rebuild

---

# 88. Search API

Внутренний интерфейс поиска должен быть абстрактным.

Концептуально:

SearchEngine

├── search()

├── semanticSearch()

├── keywordSearch()

└── rebuildIndex()

Конкретный API будет определён на этапе реализации.

---

# 89. Search Result

Результат поиска должен содержать минимум:

SearchResult

├── entity_id

├── entity_type

├── score

├── matched_content

└── metadata

---

# 90. Search Result Security

SearchResult не должен содержать данные, к которым пользователь не имеет доступа.

---

# 91. Search Result for AI

AI может получать сокращённый результат:

entity_id

title

relevant_excerpt

relationship_context

score

вместо полного объекта.

---

# 92. Search Result for UI

UI может показывать:

Title

Type

Excerpt

Project

Relevance

---

# 93. Search Result Deduplication

Если один объект найден одновременно:

Keyword Search

+

Semantic Search

результаты должны объединяться.

---

# 94. Result Fusion

Например:

Keyword Results

      +

Semantic Results

      ↓

Deduplication

      ↓

Combined Ranking

---

# 95. Search Performance

Поиск не должен блокировать UI.

Особенно:

- embedding generation;
- vector search;
- index rebuild.

---

# 96. Background Indexing

Индексация выполняется в background.

UI Thread

   |

   └── Save

  

Background

   |

   └── Index

---

# 97. MVP Search

Для первой версии LifeOS достаточно:

1. Keyword Search

2. Basic Semantic Search

3. Hybrid Search

4. Local Index

5. Incremental Embeddings

6. Permission Filtering

7. Lifecycle Filtering

8. Rebuild Index

---

# 98. Не входит в MVP

На первом этапе не обязательны:

- сложный learning-to-rank;
- персональный ranking model;
- federated semantic search;
- distributed vector database;
- сложный query expansion;
- autonomous search agents;
- cross-user semantic search.

---

# 99. Основные принципы

Для Semantic Search принимаются следующие принципы:

1. Используется Hybrid Search.
2. Keyword Search остаётся обязательным.
3. Semantic Search является дополнительным уровнем.
4. AI не владеет Search Engine.
5. Search Engine является частью LifeOS.
6. Embeddings являются производными данными.
7. Domain Data остаётся Source of Truth.
8. Embedding Provider абстрагируется.
9. Поддерживается Local Embedding Provider.
10. Поддерживается Remote Embedding Provider.
11. Конкретный Provider не фиксируется этим ADR.
12. Embeddings имеют версию модели.
13. Embeddings имеют Content Hash.
14. При изменении контента embedding обновляется.
15. Индексация выполняется инкрементально.
16. Индексация не должна блокировать UI.
17. Ошибка embedding generation не должна блокировать сохранение данных.
18. Vector Index может быть полностью перестроен.
19. Semantic Search должен деградировать до Keyword Search.
20. Search учитывает permissions.
21. Search учитывает lifecycle.
22. Search может учитывать context.
23. Search может учитывать relationships.
24. Recency не применяется глобально без учёта типа Entity.
25. Большие документы могут использовать chunking.
26. Search Representation отделён от Domain Model.
27. Sensitive Data не должна без необходимости попадать в embeddings.
28. Secrets никогда не embedding-ятся.
29. Remote Embeddings требуют отдельной privacy policy.
30. Embedding Index не является обязательным Domain State.
31. Embeddings не должны без необходимости увеличивать Sync Payload.
32. Разные устройства могут использовать разные embedding models.
33. Search Results проходят permission filtering.
34. AI получает только необходимые результаты.
35. Context Budget ограничивает объём данных, передаваемых AI.
36. Search должен поддерживать deduplication.
37. Search должен поддерживать result fusion.
38. Vector Index является rebuildable.
39. Search API должен быть provider-independent.
40. Semantic Search развивается независимо от конкретной AI-модели.

---

# 100. Что не фиксируется этим ADR

Этот ADR не определяет:

- конкретную embedding model;
- конкретного embedding provider;
- конкретную vector database;
- конкретную SQLite/vector extension;
- конкретный размер embedding;
- конкретную similarity metric;
- конкретный chunk size;
- конкретную формулу ranking;
- конкретные значения Top-K;
- конкретные веса ranking;
- конкретную Flutter/Dart библиотеку;
- конкретную cloud infrastructure.

Эти решения будут приняты после прототипирования и benchmark-тестов.

---

# 101. Последствия решения

## Положительные

- поиск понимает смысл, а не только слова;
- сохраняется надёжность keyword search;
- AI получает качественный механизм поиска контекста;
- embedding provider можно заменить;
- можно использовать локальные embeddings;
- система остаётся local-first;
- embeddings можно пересоздать;
- изменение AI-модели не требует изменения Domain Model;
- поиск может развиваться независимо от AI;
- architecture готова к большим объёмам данных.

## Отрицательные

- появляется дополнительный индекс;
- требуется embedding generation;
- увеличивается сложность архитектуры;
- локальные модели могут требовать ресурсов;
- cloud embeddings создают privacy и cost concerns;
- потребуется механизм re-indexing;
- ranking потребует экспериментальной настройки;
- semantic search сложнее тестировать, чем keyword search.

---

# 102. Связанные ADR

Связанные архитектурные решения:

- ADR-0014 — AI Tool Calling and Permissions
- ADR-0013 — AI Context Engine
- ADR-0012 — Search Architecture
- ADR-0011 — Backup and Export Architecture
- ADR-0010 — Security Architecture
- ADR-0009 — AI Architecture
- ADR-0008 — AI Provider Architecture
- ADR-0007 — Data Lifecycle Architecture

---

# 103. Следующий шаг

Следующим логичным этапом является:

**ADR-0016: Domain Model and Entity Architecture**

В нём необходимо определить фундамент LifeOS:

- что такое Entity;
- какие типы Entity существуют;
- как работают Relationships;
- как устроены Context;
- как Entity проходят Lifecycle;
- какие поля являются общими;
- какие данные относятся к Domain;
- какие являются производными;
- как всё это связано с AI.

После ADR-0016 мы уже приблизимся к тому месту, где архитектурные документы начнут превращаться непосредственно в **структуру кода Flutter/Dart и Domain Model**.