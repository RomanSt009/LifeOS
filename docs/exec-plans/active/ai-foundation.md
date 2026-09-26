# AI Foundation — Investigation and Execution Plan

Статус плана: blocked pending ADR decision

Текущий checkpoint: отсутствует; implementation не начиналась.

Точка возобновления: принять ADR-0035, затем начать AF-01.

## Current state

### DOCUMENTED

- LifeOS local-first: обычные локальные функции не зависят от сети или AI.
- Domain не зависит от AI provider; Infrastructure реализует adapters,
  Application координирует use cases, Presentation не вызывает AI API.
- ADR-0034 определяет Context как computed Application projection, а не
  persisted Entity/table.
- AI не получает arbitrary database dump. До внешней provider boundary нужны
  data minimization, lifecycle, privacy и bounded-context rules.
- Пользовательские данные являются untrusted data, а не system instructions;
  AI output также недоверен.
- AI не изменяет Domain State напрямую. Tools/actions требуют отдельной
  permission/confirmation architecture.
- Secrets не хранятся в Git, обычных config, SQLite Backup или logs.
- AI ADR-0008/0010/0013/0014 лишь предварительно приняты и оставляют concrete
  provider, budget, privacy policy, prompt и secret mechanism открытыми.

### FACTUAL PRODUCTION STATE

- LifeOsWorkspaceContextReader даёт active direct Task/Note members и Unassigned.
  Порядок: updatedAt DESC, ID ASC. Его public read unbounded и mapping выполняет
  typed-row reads, поэтому это не готовый outbound AI context API.
- GetDirectLifeOsRelatedNeighbors уже bounded, active-only, deterministic one-hop
  Task/Note projection с Relationship provenance.
- SearchLifeOsEntities уже bounded, active-only, deterministic global literal
  retrieval Task/Note/Workspace через Application port.
- WorkspaceMembership — structural edge; LifeOsRelationship — semantic edge;
  Unassigned — computed state, не Workspace.
- Composition root владеет единственным LifeOsDatabase; Presentation получает
  готовые Application boundaries.
- Settings сейчас содержит Backup/Export/Restore. Общего settings repository и
  secure secret store нет.
- Dependencies не содержат HTTP client, AI SDK или secure-storage package.
- schemaVersion 4 и Backup/Export v4; AI state/history/config не persist.
- AI destination и assistant UI отсутствуют.

### INFERRED

- Workspace, Search и one-hop graph — reusable context primitives, но не единый
  AI context contract.
- Нужна specialised Application projection, без Drift rows, concrete
  repositories и Presentation-side aggregation.
- Foundation можно реализовать без network provider, API key, schema, Backup,
  dependency или UI change.

### PROPOSED

- AI Foundation — Application/Infrastructure bounded context, не user-facing AI.
- Она вводит bounded Workspace context assembly и provider-neutral non-streaming
  request/response port.
- Real provider, credential UI и user flow относятся к Context-aware AI #1.

## Product objective

Foundation должна дать будущей feature:

1. deterministic local context selection;
2. typed provenance и bounded content;
3. separation local assembly от outbound send;
4. provider-neutral request/response/errors;
5. local-first graceful degradation;
6. privacy-safe observability seam.

Foundation не показывает chatbot, не делает network request и не выбирает vendor.

## Context primitives

Reusable: active Workspace metadata/direct members, bounded one-hop neighbors,
bounded Unified Search, typed identities, deterministic ordering и lifecycle
filters.

Не являются context автоматически: Unassigned, all-state Backup reads, Outbox,
device_id, internal metadata, archived/deleted state, full graph, hidden Search
retrieval и Backup payloads.

## Context Assembler recommendation

Нужен Application use case BuildLifeOsAiContext и specialised bounded Workspace
read port. Это не Domain service, generic Context Engine, repository aggregator
или provider adapter.

~~~text
BuildLifeOsAiContextInput
  workspaceId: LifeOsEntityId(workspace)
  budget: LifeOsAiContextBudget

LifeOsAiContext
  rootWorkspace
  items: ordered typed Task/Note projections
  budgetResult
~~~

Initial root — только explicit active Workspace. Free-text retrieval, Unassigned,
arbitrary selections и conversation memory excluded. Port читает active Workspace
и bounded direct members одним controlled workflow. Existing UI reader допустим
внутренне только после доказательства bounded query/no N+1.

## Provenance

Минимальные kinds: workspaceRoot и workspaceMember. Item содержит stable ID/type
и typed reasons. Dedupe — по Entity ID; при будущих sources payload один, reasons
объединяются в deterministic priority.

directRelationship, searchMatch, explicitlySelected и currentEntity — future
additions только с конкретным consumer.

## Bounds, ordering, truncation and deduplication

~~~text
LifeOsAiContextBudget
  maxEntities: positive int
  maxTotalCharacters: positive int
  maxCharactersPerItem: positive int
~~~

- Exact numbers задаёт consumer; Foundation не hardcode provider token window.
- Workspace root идёт первым и резервируется отдельно.
- Members: updatedAt DESC, ID ASC.
- Task payload: title + completion.
- Note: title + bounded content prefix.
- Workspace: title + bounded optional description.
- Truncation затрагивает только projection, идёт по Unicode scalar boundary и
  фиксируется truncated + originalCharacterCount.
- Не помещающийся item deterministicly пропускается; result хранит omitted count.
- Duplicate payload запрещён.
- Provider tokenizer abstraction пока не нужен; достаточно item/character bounds.

## Privacy and outbound data boundary

Local assembly не требует network, читает explicit active Workspace, read-only и
не сохраняет snapshot.

Outbound policy:

- default deny при disabled/unconfigured provider;
- send только по explicit user action в future feature;
- до send показывается Workspace scope и external-provider disclosure;
- outbound содержит лишь approved projection, instruction и operation metadata;
- исключены device_id, Outbox, Backup metadata, DB fields, secrets,
  archived/deleted и unrelated state;
- Note content считается sensitive;
- adapter не расширяет context и не читает DB;
- prompts/context/responses не логируются по умолчанию.

Persistent consent и sensitivity taxonomy требуют будущего gate. Для первой
feature безопасный минимум — per-request explicit confirmation.

## Content representation

- Workspace: reference, title, bounded description.
- Task: reference, title, completion.
- Note: reference, title, bounded literal content.
- Relationship: не document; при future inclusion только provenance.

createdAt/updatedAt/lifecycle/version/source/membership/storage fields не
отправляются без concrete need. Lifecycle применяется как filter.

## Provider abstraction

~~~text
LifeOsAiProvider
  generate(LifeOsAiRequest) -> LifeOsAiResponse
~~~

Request: typed purpose, user instruction, assembled context и provider-agnostic
response constraints. Нет provider JSON, secrets, HTTP/SDK types или prompt.

Response: text, optional provider/model/usage metadata и optional context refs.
Refs недоверены и принимаются только если ID был в request context. Tools,
mutations, arbitrary JSON и autonomous follow-ups excluded.

Errors: unavailable, invalidConfiguration, authentication, rateLimited, network,
requestRejected, invalidResponse, unknown. Context-build errors отдельны.

## Streaming, cancellation and timeout

- non-streaming first;
- streaming deferred до UX/capability evidence;
- cancellation не входит в initial port; future UI использует request identity,
  transport cancellation — later capability;
- adapter имеет timeout, no infinite retry; retry policy не часть generic port.

## Provider configuration and secrets

- enablement/provider/model/endpoint — configuration concerns.
- Application видит typed status, не secret.
- Credential читает Infrastructure через secure secret store.
- Settings работает через Application use cases.
- Secrets не входят в SQLite, Backup/Export, logs или generated config.
- Real secret persistence deferred до provider implementation.

Secure-storage dependency сейчас отсутствует и требует explicit dependency/
security gate. Foundation/fake tests dependency не требуют.

## Local-first degradation

AI optional и disabled by default. Unavailable/config/network errors затрагивают
только AI operation. Core LifeOS работает. Local provider позднее реализует тот
же port; router/multi-provider framework не вводится.

## Security and prompt-injection boundary

- Context сериализуется как labelled untrusted data отдельно от system/user.
- Note content не интерпретируется как policy.
- Response/refs валидируются.
- Нет tool calling, filesystem, SQL, arbitrary network, mutation или automatic
  Relationship creation.
- Logs не содержат secrets/content. Допустимы duration, provider/model, counts,
  truncation и error category.

## AI, Search and Graph interaction

Assembler не вызывает Search скрытно. Initial Workspace context — direct members
only. Existing Search и one-hop graph остаются explicit future sources.
Traversal >1, ranking, semantic/vector retrieval и embeddings excluded.
Future source обязан задать explicit trigger, per-source limit, priority, privacy
disclosure и dedupe tests.

## Persistence and Backup implications

Nothing persisted: no history, memory, cache, snapshots, usage ledger or audit
content. schema v5: NO. Backup/Export v5: NO. Backup v4 и Outbox unchanged.
Credentials/config не попадают в Backup автоматически.

## First user-facing AI feature recommendation

Context-aware AI #1: Ask about this Workspace.

Single-turn flow: explicit active Workspace → user question → scope/provider
disclosure → bounded direct-member context → one non-streaming text response with
validated refs → optional open Task/Note. Nothing persists or mutates.

Это проверяет Workspace root, bounds, provenance, provider replacement, privacy
и read-only safety лучше chatbot или action generation. Summarize Workspace может
быть prefilled instruction того же flow.

## Foundation vs Context-aware AI #1

Foundation:

- context/budget/provenance models;
- bounded Workspace assembler;
- provider-neutral contracts/errors;
- fake seams;
- privacy/observability contracts.

Context-aware AI #1:

- localized Presentation and exact UX;
- disclosure/confirmation;
- concrete provider/network/prompt adapter;
- secure credentials and Settings;
- model/endpoint config;
- request lifecycle and citations UI;
- feature-specific numeric budgets.

## ADR decision

ADR REQUIRED.

Предложение: ADR-0035: AI Provider, Bounded Context, and External Data Boundary.

Он фиксирует Foundation/feature split, Workspace root, bounds/provenance/dedupe/
truncation, local-vs-outbound boundary, default deny + explicit action,
non-streaming provider port/errors, no tools/history/persistence, secret
ownership/dependency gate, graceful degradation и no schema/Backup bump.

Причина: ADR-0034 намеренно оставляет provider/budget/privacy AI Foundation.
AI ADR-0008/0010/0013/0014 preliminary и не определяют concrete contracts.
Решения долговременны, cross-layer и privacy-sensitive. Execution plan
недостаточен как source of truth.

ADR здесь не создаётся. Implementation blocked до user acceptance.

## Dependency gates

- Foundation: new dependency NO.
- Real provider: HTTP/SDK explicit gate; сначала оценить dart:io vs minimal direct
  dependency и provider requirements.
- Secure storage: explicit gate + direct dependency.
- Vendor SDK не добавлять без evidence.

## Risks

- Oversharing → explicit root, active-only, budgets.
- Hidden retrieval → Search/graph excluded by default.
- Large Notes → scalar-safe truncation.
- Duplicates → one payload per ID, multiple reasons.
- N+1/unbounded read → specialised bounded query + evidence.
- Prompt injection → structured data, no tools.
- Secret leakage → Infrastructure-only store, sanitized errors/logs.
- Lock-in → narrow port, no SDK types above Infrastructure.
- False grounding → refs restricted to request IDs.
- Offline failure → typed AI-only error.

## Validation policy

Investigation: docs-only, git diff --check and exact scope; no tests/analyze.

Implementation checkpoints: focused architecture-safety tests only; always
git diff --check + scope. Do not defer bounds, query behavior, data leakage,
read-only or import checks required by the next checkpoint.

Final: all AF tests, relevant regressions, flutter analyze, full flutter test
--reporter compact, import/architecture/security/privacy scans, schema/Backup/
dependency/generated guards, git diff --check and exact status.

## Implementation checkpoints

### AF-01 — Bounded Workspace context contracts and assembler

Status: pending, blocked by accepted ADR-0035.

Scope: Application models/use case; specialised bounded Workspace read port/Drift
adapter; active direct Task/Note only; order/dedupe/truncation/omission; focused
tests.

Exclusions: provider/network/config/secrets/UI, Search/graph auto-expansion,
Domain/repository/schema/Backup changes, mutation/Outbox.

Gate: stop on schema/index need, generic Context repository, new Entity/lifecycle
or privacy semantics.

Interim validation: focused assembler/budget/provenance/query/query-count/
read-only tests, Application import scan, git diff --check and scope.

### AF-02 — Provider-neutral contracts and safe disabled boundary

Status: pending. Depends on AF-01.

Scope: provider/request/response/ref/error contracts; Application orchestration
seam; deterministic fake; disabled/unavailable adapter or equivalent safe
composition boundary; privacy-safe observability; focused tests.

Exclusions: real provider, HTTP/SDK, secrets/storage, Settings UI, production
prompts, streaming, tools, history/persistence.

Gate: stop if contract needs vendor payload, streaming, secret implementation or
feature-specific choice.

Interim validation: focused contract/error/ref/no-content-log tests, import and
schema/Backup/dependency guards, git diff --check and scope.

### AF-03 — Final integration and architecture audit

Status: pending. Depends on AF-01/AF-02.

Scope: fake-provider proof Workspace ID → bounded request/response, final privacy/
architecture/local-first audit, minimal accepted fixes, plan completion.

Final validation: all AF tests; relevant Workspace/Search/graph/composition
regressions; flutter analyze; full flutter test --reporter compact; import/
architecture/privacy/dependency/schema/Backup/generated/Outbox guards;
git diff --check and exact status.

## Milestone Definition of Done

- ADR-0035 accepted.
- Bounded typed Workspace context with provenance and no mutation.
- Provider contracts contain no vendor/HTTP/SDK/Flutter/Drift/SQLite types.
- Foundation testable by fakes and safely disabled.
- No provider UI, tools, history, schema/Backup change or dependency.
- Final validation passes and plan moves to completed.

## Deferred scope

Concrete Cloud/Local provider/model; HTTP/SDK and secure-storage choice; API key
Settings; Context-aware AI #1 UI/prompts; streaming/cancellation; history/memory/
cache; tools/agents; Search/graph expansion; Unassigned scope; semantic/vector/
embeddings/RAG; sensitivity/consent profiles; generated entities/relationships;
usage telemetry; schema v5, Backup v5 and Sync interaction.

## Roadmap result

Order remains:

1. AI Foundation;
2. Context-aware AI #1;
3. LifeOS 1.0 Dogfooding & Stabilization;
4. LifeOS 1.0.

No extra milestone required. Provider + secure-storage gates start Context-aware
AI #1 because the concrete feature establishes capability/UX needs.

## Investigation evidence

- Pre-flight: main, HEAD 5381be0 (test: complete unified local search),
  origin/main...HEAD = 0 1.
- Unified Local Search completed; active plans absent before investigation.
- Only pre-existing change: .obsidian/workspace.json; untouched.
- Read: AGENTS, README, required ADR-0016/0023/0028/0030/0032/0033/0034,
  completed Workspace/Knowledge Graph/Unified Search plans, roadmap/vision/
  AI/security/context docs and factual code boundaries.
- Tests/analyze not run: docs-only, no architecture uncertainty required them.
- Production Dart, tests, pubspec/lock, schema, Backup and generated unchanged.

## Blocker

Implementation blocked pending accepted ADR-0035. Minimum decision: accept the
Workspace-rooted bounded context, default-deny outbound boundary, provider-neutral
non-streaming port, no-tools/no-persistence scope and secure-storage gate.
