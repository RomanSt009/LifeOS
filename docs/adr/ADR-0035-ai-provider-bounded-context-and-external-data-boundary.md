# ADR-0035: AI Provider, Bounded Context, and External Data Boundary

**Статус:** Принято
**Дата:** 2026-09-26
**Версия:** 0.1

## Контекст

LifeOS является local-first системой. Пользовательские Workspace, Tasks, Notes,
Relationships и результаты Search хранятся и обрабатываются локально. Будущая
AI-функциональность не должна превращать всю локальную базу данных в неявный
контекст внешнего провайдера, связывать Application с конкретным AI SDK или
делать сеть условием работы основных функций.

ADR-0034 определяет Workspace как явную границу организации и будущего контекста,
но намеренно не фиксирует правила AI context assembly, внешний data boundary и
provider contract. Эти решения затрагивают Application, Infrastructure,
Presentation, приватность и будущие AI features, поэтому требуют отдельного ADR.

## Решение

### 1. Назначение AI Foundation

AI Foundation задаёт только устойчивые внутренние границы для:

- ограниченной сборки контекста активного Workspace;
- provider-neutral AI port;
- явной передачи данных внешнему провайдеру;
- безопасной деградации при отсутствии или отказе AI.

Foundation не является готовой пользовательской AI feature. Первым предполагаемым
потребителем является отдельная single-turn возможность «Ask about this Workspace».
Её UX, prompt, provider configuration и сеть проектируются позже.

### 2. Bounded AI Context

Корнем AI context v1 является один явно активный Workspace. В контекст могут
входить только:

- metadata этого Workspace;
- активные прямые Task members Workspace;
- активные прямые Note members Workspace.

Не входят автоматически:

- вся база данных или все Workspace;
- Unassigned entities;
- глобальный Search;
- произвольный Relationship graph;
- скрытая retrieval/ranking логика.

AI context — вычисляемая Application projection. Он не является Domain Entity,
не сохраняется в SQLite, не является Membership или Relationship и не создаёт
Outbox Changes.

Специализированная Application responsibility, например
BuildLifeOsAiContext, собирает проекцию через узкие read contracts. Она обязана
применять явные положительные item и character budgets. Tokenizer abstraction для
v1 не вводится.

Отбор, порядок, дедупликация и truncation детерминированы. Скрытый ranking не
допускается. Одна Entity появляется в payload не более одного раза. Модель
provenance v1 содержит только workspaceRoot и workspaceMember; дополнительные
причины могут быть добавлены позже отдельным решением.

### 3. Содержимое контекста

Допустимое содержимое v1:

- Workspace: title и description;
- Task: title и completion state, когда это необходимо потребителю;
- Note: title и ограниченный фрагмент content;
- Entity ID как внутренний structured reference для сопоставления ответа с
  контекстом, а не обязательная часть natural-language prompt.

Не передаются device identity, Outbox, внутренние database fields, lifecycle
internals, filesystem paths и иное runtime state.

Note content обрезается детерминированно по character budget на границе Unicode
scalar values, без изменения исходной Note и без AI summary. Проекция явно
сообщает, что content был truncated. Исходный порядок и whitespace сохраняются в
попавшем в проекцию фрагменте.

### 4. Local assembly и outbound boundary

Локальная сборка контекста и внешний AI request являются разными операциями.
Сборка контекста сама по себе не выполняет сеть и не разрешает отправку данных.

Передача данных внешнему провайдеру допускается только вследствие явного действия
пользователя через отдельный Application use case/port. Presentation должна до
или во время первого такого действия ясно сообщить, что выбранные данные будут
переданы внешнему провайдеру. Точный текст и форма disclosure не фиксируются этим
ADR.

Политика по умолчанию — deny:

- нет background upload или background indexing у провайдера;
- нет silent context expansion;
- нет автоматической отправки Search/graph результатов;
- нет синхронизации пользовательских данных с AI provider.

### 5. Provider-neutral port

Application зависит от узкого vendor-neutral порта LifeOsAiProvider или
эквивалентного по ответственности. Конкретный HTTP client, vendor SDK, raw JSON,
provider DTO и platform networking остаются в Infrastructure adapter.

Request v1 содержит:

- явную user instruction;
- bounded structured context;
- purpose только когда он действительно нужен конкретному consumer.

System/application instructions, user instruction и пользовательские context data
должны быть структурно разделены. Context data нельзя трактовать как доверенные
инструкции. Это является основной prompt-injection границей v1.

Response v1 содержит generated text, минимальный status/error и при необходимости
нечувствительную diagnostic metadata. Provider может ссылаться только на Entity
IDs, присутствовавшие в request context. Tools, function calls и agent protocol в
контракт v1 не входят.

Контракт v1 non-streaming. Streaming и cancellation отложены. Минимальные
provider-neutral ошибки различают unavailable/network, configuration or
authentication, rate limit и rejected/provider failure без переноса vendor
taxonomy в Application.

### 6. Read-only и graceful degradation

AI v1 является read-only. Provider response не может напрямую:

- изменять Entities, Memberships или Relationships;
- выполнять filesystem или network actions от имени пользователя;
- создавать Tasks или Notes;
- вызывать tools.

Будущие предложения изменений потребуют явного пользовательского действия и
отдельной архитектурной границы.

AI остаётся optional capability. Database startup, Workspace, Tasks, Notes,
Search, Relationships, Backup/Restore и прочие core features работают при
отсутствии конфигурации, сети или доступного provider. Ошибка AI не меняет
локальные данные.

### 7. Configuration, credentials и observability

Несекретные provider/model/endpoint settings и секретные credentials являются
разными данными. Владение credentials относится к Infrastructure и будущему
OS-backed secure storage. Они не хранятся в LifeOS SQLite, Backup, Export или
Outbox. Владение non-secret configuration определяется будущей feature
composition, а её persistence отложена. Конкретный storage package этим ADR не
выбирается.

Запрещено логировать secrets, полный Note content, полный assembled context,
prompts и private provider responses. Допустима минимальная диагностическая
metadata без пользовательского содержимого: тип операции, длительность,
ограниченные counts/sizes и высокоуровневый error kind.

Provider neutrality не означает multi-provider orchestration, failover или
provider marketplace.

### 8. Search и Knowledge Graph

Search и Relationship graph не являются автоматическими источниками AI context
v1. AI Foundation не меняет literal Search semantics и не вводит semantic search,
embeddings, vector storage или скрытый RAG. Их использование потребует отдельного
architecture gate и явной provenance.

### 9. Persistence и зависимости

AI Foundation не требует:

- SQLite schema v5 или новых AI tables;
- Backup/Export format v5;
- Outbox или Sync changes;
- истории, memory, cache или snapshots AI requests/responses;
- новой package dependency.

Реальный provider transport/SDK и secure storage рассматриваются позже отдельными
dependency gates.

## Ответственность слоёв

- **Domain:** существующие Entity invariants; без AI/provider типов.
- **Application:** bounded context projection, budgets, provenance, provider port и
  orchestration boundary.
- **Infrastructure:** bounded reads, concrete provider transport/adapter, будущая
  secure credential storage и sanitized technical diagnostics.
- **Presentation:** explicit user action, disclosure, loading/error/result UX и
  localization.
- **Composition root:** единственное место wiring конкретных adapters; AI может
  быть безопасно disabled.

## Последствия

Положительные:

- external data boundary явный, ограниченный и проверяемый;
- AI не нарушает local-first и не блокирует core functionality;
- Application остаётся независимым от vendor SDK и network implementation;
- context assembly можно детерминированно тестировать без реального provider;
- schema, Backup и Domain не меняются ради Foundation.

Ограничения:

- v1 не использует потенциально релевантные Search/graph данные;
- character budgets приблизительны относительно provider token limits;
- нет streaming, history, tools или автоматических действий;
- concrete provider и credential UX требуют последующего architecture/dependency
  gate.

## Отклонённые альтернативы

### A. Передавать provider всю локальную базу

Отклонено из-за нарушения минимизации данных, Workspace boundary и local-first.

### B. Автоматически использовать Search и весь Relationship graph

Отклонено как скрытый retrieval scope без provenance, bounds и пользовательского
ожидания.

### C. Использовать vendor SDK types в Application

Отклонено из-за provider lock-in и нарушения layered architecture.

### D. Сохранять prompts, context и responses в SQLite

Отклонено: persistence/history не нужны Foundation и расширяют privacy, schema,
Backup и deletion obligations.

### E. Разрешить AI напрямую выполнять tools и mutations

Отклонено: read-only Foundation не может обходить Application use cases и явное
подтверждение пользователя.

### F. Сразу построить multi-provider orchestration и tokenizer abstraction

Отклонено как преждевременная архитектура без concrete consumer requirements.

## Отложено

- concrete Cloud или Local provider и model;
- HTTP client/vendor SDK;
- secure-storage implementation и Settings UX;
- точные numeric budgets и prompt конкретной feature;
- streaming/cancellation;
- multi-turn history, memory, cache и persisted sessions;
- tools, agents и mutation proposals;
- Search/graph expansion, RAG, embeddings и vector search;
- Unassigned или multi-Workspace context;
- sensitivity profiles и granular consent;
- generated Entities/Relationships;
- AI usage telemetry;
- schema v5, Backup v5 и Sync interaction.

## Связанные решения

- ADR-0016 — Entity, Relationship, Context and Lifecycle Model;
- ADR-0023 — Persistence Boundary and Outbox Atomicity;
- ADR-0028 — Backup, Export, Restore and Data Portability;
- ADR-0032 — Relationship Domain Model and Mutation Semantics;
- ADR-0033 — Lifecycle Visibility Policy;
- ADR-0034 — Workspace and Context Architecture.
