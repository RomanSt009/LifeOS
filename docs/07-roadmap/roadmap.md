# Дорожная карта LifeOS после 1.0

Статус: canonical roadmap; post-1.0 рекомендации, не утверждённый feature scope.
Дата сверки: 2026-10-02. LifeOS 1.0.0 выпущен.

## Источники и commitment levels

Выпуск подтверждён пользователем; tag `v1.0.0` указывает на `0b8abf5`.
[Stabilization](../exec-plans/completed/lifeos-1-dogfooding-stabilization.md)
completed: P0 = 0, P1 = 0, recorded analyze PASS и full suite 430 PASS.
Это историческая validation, не повторённая docs-only reconciliation.

Поздние принятые [ADR](../adr/) и completed evidence уточняют preliminary vision.
ADR-0001–0022 имеют статус «Предварительно принято», ADR-0023–0035 — «Принято».
Completed plans сохраняются как история; их старые non-goals не возвращают
в backlog функции, уже реализованные более поздними milestones.

- **COMMITTED / NEXT:** выпущенная база; next recommendation — post-release
  feedback, без автоматического разрешения feature implementation.
- **PLANNED:** документированное направление с prerequisites, без дат.
- **CANDIDATE:** возможность, требующая evidence и product/architecture gate.
- **DEFERRED / SOMEDAY:** явно отложенное или пока недостаточно обоснованное.

Inventory codes: **A** — принятая архитектурная основа; **B** — investigation/ADR;
**C** — bounded implementation opportunity; **D** — dependency на другой milestone;
**E** — speculative/long-term. A не означает готовность всего будущего протокола.

## Выпущенная база 1.0

| Область | Production boundary |
|---|---|
| Desktop | Windows, Flutter/Dart, Riverpod; NavigationRail + IndexedStack, shell-local state; Home/Workspaces/Tasks/Notes/Search/Settings |
| Domain/UI | Tasks create/edit/complete/reopen/Trash; plain-text Notes с explicit save/dirty guards/Trash; Workspaces/Unassigned, mixed members, attach/detach/quick-create |
| Persistence | Drift/SQLite schema v4, atomic migrations, один composition-owned database lifecycle; stable typed IDs, UTC metadata, lifecycle/version/source, installation identity и atomic full-snapshot Outbox |
| Unified Search | Active Task title, Note title/content, Workspace title/description; literal substring, English/Cyrillic case contract; updatedAt DESC, id ASC; global limit 50; без FTS/ranking |
| Graph | Task/Note nodes, undirected canonical related pair; bounded one-hop projection/navigation; membership — отдельный structural edge |
| Backup | Logical ZIP и Export JSON v4, atomic replace Restore v1-v4; active Outbox/device_id исключены; installation identity сохраняется |
| AI | Optional local Ollama, exact qwen2.5-coder:7b, loopback 127.0.0.1:11434 + DIRECT; bounded direct-member Workspace context, single-turn plain text, read-only |
| Release | en/ru platform locale + English fallback; unsigned full-runtime Windows ZIP, не portable-data mode |

Нет Sync, Projects, Documents, full Dashboard, attachments/rich editor, cloud AI,
history/tools/mutations, semantic Search или graph visualization. Basic local
работа не требует AI, сети или аккаунта.

## Фаза 0 — LifeOS 1.0 Post-Release Dogfooding / 1.0.x

**NEXT recommendation:** ежедневное использование, сбор regressions/friction и
оснований следующего milestone. Не большой implementation plan.

Наблюдения: app version, Windows/profile conditions, locale/window/text scale,
шаги, expected/actual behavior, frequency/severity, data safety/recovery и
sanitized evidence. Не сохранять private Notes, AI prompts/responses, credentials
или личные Backup в repo. Измерять объём/latency до запроса на index/FTS.

### Maintenance policy

1.0.x: bounded fixes crashes/data loss, persistence/migration defects, severe UX
regressions, packaging, accessibility blockers и compatibility bugs.
Обычно feature release: новые Entity, schema-changing features, redesign,
AI expansion, Sync, time/reminder model. Срочная schema correction доказанного
опасного дефекта допустима только с migration/compatibility/safety validation.
Data-loss и dirty-state проверки нельзя откладывать до финала любой ценой.
P2 polish не является обязательным patch release без evidence.

[Smoke checklist](../dogfooding-rc-checklist.md),
[distribution/recovery](../release-windows.md).

## Рекомендуемые post-1.0 фазы

| Фаза | Тема | Commitment / gate |
|---|---|---|
| 0 | Post-release evidence + conservative 1.0.x | NEXT recommendation; safety прежде features |
| 1: подготовка LifeOS 1.1 | Выбрать одну daily-use capability по feedback | CANDIDATE; конкретный scope 1.1 не принят. Fork: Time/Reminders при planning friction или Sync investigation при multi-device need |
| 2: последующие 1.x | Один принятый vertical slice после investigation | PLANNED direction; независимые Time/Sync/Search/graph/context темы не объединять в один giant milestone |
| 3: последующие 1.x | Local provider UX, editor/navigation polish, distribution | CANDIDATE; порядок и версии определяются evidence, не модой |
| Долгосрочно / 2.0 candidates | Более широкая personal OS | SOMEDAY; не утверждённый scope 2.0 |

Приоритет: data safety/reliability → daily-use friction → architectural leverage →
dependency ordering → implementation risk → user value → проверяемый vertical slice.
Новые темы не получают номера release только из-за упоминания в vision.

## Inventory: оставшийся документированный scope

### Sync / security

| Работа | Класс / commitment | Origin / gate |
|---|---|---|
| Remote Sync, Outbox consumption, multiple devices | A+B+D / PLANNED direction | ADR-0009/0018/0019; ADR-0023/0025; [MVP](../exec-plans/completed/lifeos-mvp.md). Сначала Sync investigation |
| Backend/transport/API/protocol versioning | B / CANDIDATE | ADR-0018 §126, ADR-0023 §10; [Sync](../06-sync/sync-architecture.md); technology не выбрана |
| Account/auth, device pairing/registration/trust/revocation | B+D / CANDIDATE | ADR-0010/0025, Sync account model |
| Conflict matrix/merge, delete-vs-edit/restore concurrency, multi-device ordering/clock skew | B+D / CANDIDATE | ADR-0018; ADR-0033 Future Sync; нельзя выбрать общий LWW молча |
| Idempotency/retry/backoff, acknowledgement/cursor/resume/pruning, offline convergence | B+D / PLANNED requirements | ADR-0009/0018/0019, ADR-0023; delivery protocol не реализован |
| Remote tombstone retention/purge, Restore bootstrap/reconciliation | B+D / CANDIDATE | ADR-0028 §7, ADR-0033; [Backup](../exec-plans/completed/backup-export.md); replay старой queue запрещён |
| Relationship/Membership replication ordering | A+B+D / CANDIDATE | ADR-0032/0034: endpoints/Workspace/member должны существовать до edges; remote algorithm не выбран |
| Database encryption, encrypted/password Backup, key/recovery policy | B / DEFERRED | ADR-0010/0011/0028/0029; конкретные алгоритмы/storage не приняты; не retroactive blocker local 1.0 |
| E2EE, trusted devices/recovery, direct/P2P/file sync, self-hosted relay | B+D+E / SOMEDAY | ADR-0009/0010/0018; отдельные security/protocol gates |
| Privacy-safe audit/incident response, biometric/OS-backed security and session/clipboard policy | B+D+E / DEFERRED | ADR-0010: будущие concrete threat-model/security gates, не разрешение логировать private content |
| Collaboration, CRDT, semantic merge/conflict history | B+D+E / SOMEDAY | ADR-0018/0019; не current production policy |

### Time / desktop / distribution

| Работа | Класс / commitment | Origin / gate |
|---|---|---|
| Task due dates, scheduling/Today, reminder/timezone model | B / CANDIDATE | ADR-0004/0016 examples; [DFUX](../exec-plans/completed/dogfooding-ux-improvements-1.md), STAB deferred; temporal contract отсутствует |
| Notifications, tray, background lifecycle/startup with Windows | B+D / DEFERRED | DFUX, ADR-0034, STAB; delivery/privacy/lifecycle gate; tray не обязательна для всех notifications |
| Priority, estimates/richer planning | B / DEFERRED | STAB deferred; Domain/schema/Backup semantics ещё не определены |
| Spellcheck | B+C / CANDIDATE | Workspace/STAB deferred; bounded platform/privacy/dependency check |
| LifeOS icon, About/version surface, single version owner | C / CANDIDATE, P2 | STAB P2; нужен approved brand asset, pubspec/lifeOsApplicationVersion ownership cleanup |
| Installer, signing, updater, store/winget distribution | B+D / CANDIDATE | release guide/STAB; отдельный distribution gate, не retroactive requirement 1.0 |
| Multi-window/deep links/URL/persistent navigation history | B / DEFERRED | [Shell](../exec-plans/completed/desktop-shell-navigation.md), STAB; routing package только при requirement |
| Mobile/tablet shell и другие платформы | B+D+E / SOMEDAY | vision, ADR-0001/0022, UI/UX; не уменьшение desktop shell |
| Dark Mode/design system/tokens/density, personalization/shortcuts/capture/onboarding/drag-drop | B+C+E / DEFERRED | [UI/UX](../05-ui-ux/ui-ux-architecture.md); existing shortcuts не считать отсутствующими |
| Manual locale selector, новые locales, RTL/date formatting | A+B+C / DEFERRED | ADR-0027; механизм принят, selector/RTL/date policy не определены |

Recurrence: конкретный recurring Task contract не найден; vision о повторяющихся
процессах не является requirement повторения Tasks. Это возможный вопрос будущего
Time investigation, а не отдельное обещание roadmap.

### Search / Knowledge Graph

| Работа | Класс / commitment | Origin / gate |
|---|---|---|
| Filters/facets/grouping/query language, highlighting/snippets | B+C / CANDIDATE | [Unified Search](../exec-plans/completed/unified-local-search.md) §§16/21; semantic contract before UI |
| Pagination/infinite scroll, history/saved searches/command palette | B / DEFERRED | Unified Search §21; ADR-0012 history privacy |
| FTS/FTS5/index/performance/isolate strategy | B+D / CANDIDATE после measurement | Unified Search §8, ADR-0012/0021; query-plan/latency gate before schema/index |
| Unicode normalization/collation/stemming/fuzzy/typos, ranking/scoring/boosts | B / DEFERRED | Unified Search §21; linguistic matching не обещан current contract |
| Workspace-scoped/membership-aware Search | A+B / CANDIDATE | ADR-0034 direct-active-member direction; отдельный Unified Search scope gate |
| Graph-aware Search/backlinks/related-result expansion | B+D / DEFERRED | [KG #2](../exec-plans/completed/knowledge-graph-foundation-2.md); graph не implicit Search scope |
| Semantic/vector/embedding/hybrid Search; remote/OCR/PDF/file search | B+D+E / SOMEDAY | ADR-0012/0015; Unified Search §21; не automatic next step |
| Relationship kinds/directionality/Workspace endpoints | B / CANDIDATE | ADR-0032/0034, KG #2; meaning/inverse/uniqueness/lifecycle/Backup gate |
| 2+ hops/traversal/cycles/fan-out/depth/ranking | B+D / DEFERRED | KG #2; one-hop достаточен, сначала concrete consumer |
| Visualization/graph destination, recommendations/inferred/AI-created links | B+D+E / SOMEDAY | ADR-0032, KG #2; graph concept не требует graph database |
| Relationship re-link/undo | B / DEFERRED | ADR-0033/KG #2; не путать с реализованным membership reattach |

### AI / Context

| Работа | Класс / commitment | Origin / gate |
|---|---|---|
| Streaming/cancellation/local UX/provider status improvements | B+C / CANDIDATE | ADR-0035; [CAI #1](../exec-plans/completed/context-aware-ai-1.md); non-streaming port, close не обещает cancellation |
| Model/provider selector, capability probing/persisted configuration | B / CANDIDATE | CAI #1; provider-neutral не значит одинаковые model capabilities |
| Remote/LAN Ollama, automatic install/pull/launch/update | B / DEFERRED | CAI #1; current contract loopback-only/manual setup |
| Search/graph-assisted context, richer provenance/budgets/consent | A+B+D / CANDIDATE | ADR-0035 §§2/8; [AI Foundation](../exec-plans/completed/ai-foundation.md); read primitives есть, implicit retrieval не разрешён |
| RAG/vector/embeddings/reranking/tokenizer | B+D+E / SOMEDAY | ADR-0013/0015, CAI #1; concrete retrieval/privacy/scale need сначала |
| History/memory/cache/sessions, citations/references/Markdown/HTML output | B / DEFERRED | CAI #1; retention/privacy/rendering gates |
| Tools/mutations/agents/generated Entities/Relationships | A+B+D+E / DEFERRED | ADR-0014/0035; future permissions/confirmation/validation не current authority |
| Cloud/BYOK/credentials/fallback/hybrid router | B+D / DEFERRED | ADR-0035, CAI #1; отдельный post-1.0 privacy/dependency gate; early cloud-first ADR-0008 не current boundary |
| Multi-Workspace/Unassigned context, sensitivity/granular consent, telemetry/failover | B+E / DEFERRED | AI Foundation/ADR-0035; no global context or private logging |

Разделять будущие AI темы: local UX/provider capability; retrieval/context;
history/tools/mutations; cloud/privacy. «AI #2/#3/#4» пока не утверждённые identifiers
и не обещанный порядок release. RAG не следующий шаг по умолчанию.

### Domain / Workspace / editor / Backup / vision

| Работа | Класс / commitment | Origin / gate |
|---|---|---|
| Archive/Unarchive UI/Application exposure | A+C / CANDIDATE | ADR-0033/0034; semantics приняты, Delete/Trash/Restore уже выпущены |
| Global Trash/hard purge/retention/history; multi-profile/portable-data/custom DB path | B / DEFERRED | ADR-0024/0033, STAB; не destructive reset |
| Workspace hierarchy/inherited context/richer memberships/member types | B / DEFERRED | ADR-0034: cycles/visibility/lifecycle/compatibility; membership не ownership |
| Workspace icon/color/pinning/layout/permissions/ACL/collaboration | B+C+E / DEFERRED | ADR-0034; Workspace не security boundary |
| Custom/plugin-like Entity types | B+D+E / SOMEDAY | ADR-0004/0016; typed production contracts не превращаются в untyped dynamic model |
| Новые Entity: Projects/Documents/Person/Event и другие vision modules | B+D+E / SOMEDAY | product/vision, ADR-0016/0034; упоминание не делает их 1.1 |
| Markdown/rich text/WYSIWYG/autosave/empty drafts/revision history | B / DEFERRED | ADR-0030/STAB; opaque content + explicit save остаются boundary |
| Tags/folders/notebooks/templates/checklists/embedded Tasks/files/images/attachments | B+D+E / DEFERRED | ADR-0030; storage/lifecycle/Search/Backup/privacy gates |
| Backup automation/scheduling/retention/rotation/cloud/self-hosted | B+D / DEFERRED | ADR-0011/0028; не зависит автоматически от Sync |
| Incremental Backup, snapshot policy, compression/encryption ordering, RPO/RTO | B+D / DEFERRED | ADR-0011; не второй implicit backup architecture, сначала recovery/compatibility requirements |
| Selective/merge/conflict-aware Restore/Import; Markdown/CSV/HTML Export | B+D / DEFERRED | ADR-0028; current atomic replace и one-way Export не менять молча |
| Plugins/SDK/marketplace/integrations/workflow/triggers/scheduled automation | B+D+E / SOMEDAY | исходная roadmap, vision, ADR-0003/0016; никаких placeholders |
| Calendar/Finance/Contacts/Habits/Goals/Journal/Health/OCR/recommendations | B+D+E / 2.0 candidates only | исходная roadmap и vision; Entity/release contracts отсутствуют |

## Sync reassessment

Принято/реализовано: stable typed UUID, UTC/source/version/lifecycle,
device_id/change_id, baseVersion/newVersion, atomic full JSON snapshot Outbox.
Soft delete — локальная tombstone foundation, не remote retention protocol.
Backup исключает active queue/device_id; Restore очищает Outbox и сохраняет
installation identity. Будущий Sync требует отдельного bootstrap/reconciliation.

Не выбраны backend/transport/account/auth/trust, cursor/ack/pruning/retry,
idempotent remote protocol, ordering/conflict matrix, deleted-vs-edited concurrency,
retention и offline/Restore convergence. Preliminary ADR-0018/0019 не являются
полным implementation contract. **Sync Architecture Investigation + ADR требуется
до implementation**. Ни LWW для всех типов, ни CRDT, ни server authority не выбраны.

## Time / Reminders reassessment

dueDate examples не определяют production time model. До implementation нужны
решения date vs datetime, timezone/DST, Today/scheduling, reminder identity/value
object, notification/background ownership, lifecycle и schema/Backup impact.
Recurrence только при доказанном use case. **Time investigation/ADR required**.
Прямое добавление date field/scheduler/notification package пока не обосновано.

## Dependency graph — не обязательный глобальный порядок

```text
Post-release evidence -> одна product theme -> её architecture gate
Sync investigation + ADR -> bounded two-device slice -> broader sync/recovery
Time model gate -> due/reminder slice -> notification delivery/lifecycle gate
Measured Search problem -> query-plan/FTS gate -> performance/index implementation
Workspace Search gate -> bounded direct-member Search
Retrieval/privacy gate -> Search/graph-assisted AI context
Semantic retrieval gate -> возможный vector/hybrid layer -> возможный RAG consumer
Relationship semantics gate -> новые kinds/directionality
Concrete traversal consumer -> bounds/cycle/privacy gate -> context expansion
Hierarchy/new Entity gate -> migration + Backup compatibility -> UI
Public distribution need -> identity/update/signing gate -> distribution tooling
```

Sync не prerequisite Time/local AI/Search. FTS/vector не prerequisite bounded
Search-assisted context. Tray не mandatory prerequisite reminders. Visualization
не автоматически требует traversal. Новые schema/Backup versions не назначены.

## Унаследованный P2 и next recommendation

STAB P2: default Flutter icon; duplicate version owner; optional About/version;
scale measurements до index; privacy-safe diagnostics только при evidence;
legacy Task-only Search/три lint suppressions; отдельное решение tracked Obsidian
noise. Это не P0/P1 и не разрешение cleanup сейчас.

**Следующий кандидат: Post-Release Dogfooding Evidence Review**, короткое docs-only
product/architecture investigation. Почему сейчас: 1.0 выпущен, working slices и
checklist готовы, но сравнительного post-release evidence для 1.1 пока нет.
Нужно выяснить главную ежедневную проблему. ADR для сбора feedback не нужен;
для Sync/time capability потребуется. Следующий implementation plan не создаётся.

Если выбирать capability сразу: **Time/Reminders при planning friction vs Sync
Architecture при multi-device need**. Документация не доказывает одного победителя.
Минимальные будущие proof slices: один Task с однозначным due/reminder behavior
либо один supported Entity roundtrip между двумя isolated installations с
idempotency/offline/conflict/recovery evidence. Это validation sketches, не новые
принятые контракты.

## Исключения этого reconciliation

Не выбраны backend/auth/conflicts/time/reminders/Relationship kinds/hierarchy/
cloud provider/RAG. Нет production changes, placeholders или нового feature plan.
Версии кроме выпущенного 1.0.0 не обещаны.
[Reconciliation evidence](../exec-plans/completed/post-1.0-roadmap-reconciliation.md).
