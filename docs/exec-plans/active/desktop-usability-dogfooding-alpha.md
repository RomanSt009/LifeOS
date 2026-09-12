# Desktop Usability & Dogfooding Alpha

Статус плана: active

Точная точка возобновления: `DU-03 — Task editing vertical slice` (`pending`, не начат). Перед implementation перечитать ADR-0033 и сверить план с Git.

## Goal

Довести существующий local-first desktop core LifeOS до первой пригодной для ежедневного использования Alpha: пользователь может безопасно работать с Tasks, Notes и Relationships, управлять данными мышью и основными ожидаемыми keyboard actions, видеть результат операций и восстанавливаться после пользовательских ошибок без расширения продуктового scope новыми Entity или подсистемами.

## Non-goals

- Unified/Note Search, FTS, semantic/fuzzy/vector search и embeddings.
- Sync, Workspace/Projects, AI, mobile/tablet shell и новые Relationship kinds.
- Dashboard/Home feature, graph visualization, rich-text/Markdown editor semantics.
- Новый routing/state-management stack.
- Schema migration, Backup format revision или dependency change без отдельного доказанного требования.
- Speculative generic repositories, lifecycle services или action frameworks.

## Current baseline

Аудит выполнен на `main`, HEAD `b5adea790e1e6a4a0e8b8728edf6373311946a49`.

- Upstream divergence: `HEAD...@{upstream}` = `0 0`.
- До создания плана staged/untracked files отсутствовали; единственное исходное изменение — user-owned `.obsidian/workspace.json`, которое не анализировалось и не изменялось.
- В `docs/exec-plans/active/` активных планов не было.
- Completed Relationships plan находится в `docs/exec-plans/completed/relationships-vertical-slice.md`.
- ADR-0032 уже имеет принятый статус в HEAD; отдельное documentation housekeeping выполнено ранее.
- `flutter analyze`: PASS, `No issues found`.
- `flutter test`: PASS, 184 tests.
- Production shell: Flutter SDK `NavigationRail` + `IndexedStack`, shell-local selected destination; destinations Home, Tasks, Notes, Search, Settings; стартовый destination Tasks.
- Persistence: SQLite/Drift schema v3; production composition root владеет database/repositories; обычные material mutations атомарно создают Outbox.
- Localization: ARB `en`/`ru`, по 69 одинаковых message keys; статические Presentation strings используют localization resources.

## DU-01 — Daily-use UX Gap Audit

Статус: done

### Goal

Восстановить фактические user journeys и отделить отсутствующую кнопку от отсутствующей Domain/Application/persistence/architecture capability; сформировать проверяемый scope Alpha.

### Relevant ADRs

- ADR-0016 — common Entity lifecycle и conceptual soft delete/archive/restore.
- ADR-0022 — layered Flutter architecture и composition.
- ADR-0023 — atomic Domain state + Outbox persistence.
- ADR-0026 — creation identity/defaults.
- ADR-0027 — localization.
- ADR-0028, ADR-0031 — Backup/Export/Restore contracts и versioning.
- ADR-0030 — Note model/edit; Note lifecycle operations explicitly deferred.
- ADR-0032 — Relationship model/unlink semantics.

### Allowed scope

Read-only code/document/test audit и создание этого execution plan.

### Explicit non-goals

Любые production/test/schema/dependency/generated/ADR changes и начало DU-02.

### User journey inventory

Легенда: `yes` — пригодный flow существует; `partial` — capability существует, но flow неполон; `no` — отсутствует.

| Area / operation | Visible / mouse | Keyboard | Lower-layer mutation | Feedback / safety | Restart persistence | Daily-use finding |
|---|---|---|---|---|---|---|
| Global navigation | yes, selected Rail item visible | стандартный widget focus; dedicated shortcuts не заданы | n/a | visual selection | shell starts at Tasks | usable; focus/shortcut behavior не доказан focused tests |
| Home | placeholder only | reachable | n/a | n/a | n/a | не блокирует direct Tasks/Notes work; dashboard deferred |
| Task create | yes | Enter and Tab/activate | yes | empty validation + save error | yes | implemented |
| Task open/inspect | ExpansionTile exposes contextual Relationships | standard activation | n/a | no dedicated detail/selection model | n/a | partial, достаточность зависит от actions in list |
| Task edit title | no | no | no Domain/Application mutation | none | repository/schema could store value | P0; architecture undefined |
| Task complete/reopen | icon action | focus + standard activation | yes | visual result; mutation failure has no localized UI feedback | yes | implemented with P1 error gap |
| Task archive/delete/restore | no | no | no typed mutations/use cases | none | lifecycle column exists | P0; architecture gate required |
| Notes create/edit/save | yes | controls reachable; no Ctrl+N/Ctrl+S | yes | validation and save error; no dirty/saved indicator | saved values yes | implemented but dirty-state loss is P0 |
| Note select/new with dirty draft | yes | list/button standard activation | n/a | no warning; controllers overwritten | unsaved values no | P0 data-loss risk |
| Note navigation away/back | yes | Rail | IndexedStack retains widget/controllers | no dirty indication | only in-process | state retained; app close protection undefined |
| Note archive/delete/restore | no | no | explicitly deferred by ADR-0030 | none | lifecycle column exists | P0 architecture gate |
| Task Search | yes, clearly Task-specific copy/results | Enter submits; no clear/focus shortcut | read-only use case | initial/loading/no-results/error | query/result only in IndexedStack | usable but result cannot open source Task; clear/focus polish missing |
| View/add Relationships | contextual in Task/Note | standard controls/dialog | yes | empty/loading/error; duplicate/self-link prevented below UI | yes | core Alpha capability exists |
| Unlink Relationship | icon button | standard activation | yes, soft lifecycle UPDATE | no confirmation/undo; generic error only | yes | P0 destructive-safety gap |
| Settings | yes | standard traversal | n/a | section is understandable | n/a | enough for Alpha data controls |
| Backup | yes + native destination picker | standard controls/native dialog | yes | progress/success/typed error | artifact persists | implemented; existing-file refusal is safe but could be clearer |
| Export | yes + native destination picker | standard controls/native dialog | yes | progress/success/typed error | artifact persists | implemented |
| Restore | yes + native source picker | standard controls/dialog | yes | explicit replace confirmation + typed errors | yes | backend safe; mounted Notes/Relationships/Search projections are not all refreshed |

### Task lifecycle findings

| Operation | Status | Evidence |
|---|---|---|
| Create | IMPLEMENTED | factory/use case/repository/UI; persisted with Outbox CREATE |
| Open/select/inspect | PARTIAL | list ExpansionTile and Relationships exist; no stable selected Task/detail editing surface |
| Edit title | ARCHITECTURE UNDEFINED | Task has no edit mutation; ADR-0016 only names conceptual UpdateTask and does not define validation/no-op/timestamp rules |
| Complete | IMPLEMENTED | immutable toggle, Application coordination, repository UPDATE |
| Uncomplete/reopen | IMPLEMENTED | same toggle path |
| Archive | ARCHITECTURE UNDEFINED | common state exists; Task-specific transition/visibility/recovery absent |
| Delete | ARCHITECTURE UNDEFINED | conceptual soft delete exists; exact Task transition and relationship behavior absent |
| Restore deleted/archived | ARCHITECTURE UNDEFINED | conceptual restore exists but exact state machine/API/list semantics absent |
| Relationships | IMPLEMENTED | contextual view/add/unlink, persisted and restored |
| Search | IMPLEMENTED | active Task title-only local search, deterministic ordering |
| Keyboard actions | PARTIAL | Enter create and standard control activation; no Ctrl+N/edit/delete commands |
| Context menu | MISSING | no right-click action surface |
| Error handling | PARTIAL | create/list errors present; toggle failure is not surfaced in the list UI; load errors lack retry |
| Persistence/reopen | IMPLEMENTED | repository and production reopen coverage |

Task has `title` and `isCompleted` typed state plus common Entity metadata. Its only Domain mutation is `toggleCompletion(updatedAt)`, which always changes completion/version and does not validate UTC/monotonic time itself. `save()` can physically update the row and produce Outbox UPDATE, but this does not define a valid title-edit or lifecycle contract.

### Note lifecycle findings

| Operation | Status | Evidence |
|---|---|---|
| Create | IMPLEMENTED | explicit New + Save path; no empty persisted draft |
| Open/select | IMPLEMENTED | list selection loads title/content |
| Edit title/content | IMPLEMENTED | atomic `LifeOsNote.edit` with normalization/invariants/no-op semantics |
| Save | IMPLEMENTED | material edit persists and emits Outbox UPDATE |
| Unsaved/dirty state | MISSING | no dirty marker, save success state, prompt or comparison state |
| Navigate to another Note/New while dirty | MISSING | controller content is overwritten without warning |
| Navigate shell away/back | IMPLEMENTED IN-PROCESS | IndexedStack preserves controllers and selection |
| App/window close while dirty | ARCHITECTURE/PLATFORM UX UNDEFINED | no close guard; autosave explicitly deferred by ADR-0030 |
| Delete/archive/restore | DEFERRED BY ADR / ARCHITECTURE UNDEFINED | ADR-0030 explicitly defers lifecycle use cases to a future gate |
| Relationships | IMPLEMENTED | contextual section for persisted selected Note |
| Search | DEFERRED | Note/Unified Search is a separate gate and not Alpha CRUD scope |
| Keyboard/context menu | PARTIAL/MISSING | standard controls only; no Ctrl+S/Ctrl+N/right-click actions |
| Error handling | PARTIAL | localized validation/save/list errors; no retry and no success/dirty feedback |
| Persistence/reopen | IMPLEMENTED | saved values persist; unsaved draft does not |

The principal daily-use blockers are silent draft replacement and absent safe removal/lifecycle. Empty title is valid when exact content is semantically non-empty; empty content is valid when normalized title is non-empty; UI currently exposes the shared invariant as a localized validation error.

### Relationship findings

- View/add/unlink, self-link rejection, duplicate prevention, deterministic contextual refresh and restart persistence are implemented.
- Picker is bounded to existing Tasks/Notes and sufficient for Alpha; no new kind or graph surface is justified.
- Unlink is a persisted `active -> deleted` lifecycle UPDATE. The row is then excluded from active contextual reads, but UI offers neither confirmation nor supported reactivation/undo, so the action is effectively irreversible to the user.
- Duplicate and self-link failures become a generic localized relationship-save error; more specific copy is P1, not a new Domain requirement.
- Endpoint label lookup uses a `FutureBuilder`; endpoint read exceptions are not rendered as an error and can leave the row showing a loading label indefinitely.
- No endpoint cascade is accepted. ADR-0032/physical FK policy use `NO ACTION`; future Task/Note lifecycle behavior with active Relationships therefore requires the lifecycle gate.

### Desktop interaction findings

| Interaction | Current state | Alpha classification |
|---|---|---|
| Single click | navigation, selection, expand/action controls work | required and implemented |
| Double click | no explicit behavior | optional polish; avoid inventing alternate semantics |
| Right click/context menu | absent | P1 after edit/lifecycle actions exist |
| Hover | standard Material feedback/tooltips on icon actions | adequate; extra hover affordance P2 |
| Selection | Notes selected; shell selected; Tasks only expanded, Search read-only | Task action targeting requires explicit safe design in implementation checkpoint |
| Ctrl+N | absent | P1 contextual shortcut for Tasks/Notes |
| Ctrl+S | absent | P1/high-value for Note explicit-save model |
| Delete | absent | only after lifecycle gate and selection safety; never global/implicit |
| Enter | Task create and Search submit implemented | adequate |
| Escape | standard dialogs/native pickers expected, not explicitly covered | P1 focused verification for destructive/custom dialogs |
| Arrow keys | standard list/Rail behavior not contract-tested | P2 unless dogfooding shows blocker |
| Tab/focus traversal | standard Flutter controls; no explicit focus choreography | P1 tests and bounded fixes |
| Space | standard focused button/icon activation | adequate, verify critical actions |

No explicit `Shortcuts`/`Actions` or feature focus strategy exists. Shortcuts should remain Presentation-local and context-aware; a global action architecture is not justified.

### Navigation, focus and selection findings

- Active section is visually clear and shell-local state is appropriate.
- `IndexedStack` preserves Notes draft/selection and Search query/results while navigating; existing architecture should remain.
- A Note can become stale or be silently replaced through in-feature New/selection, not through shell navigation.
- Task has no stable selection model. Contextual actions must be bound to the clicked row or introduce an explicit selected-row contract so Delete cannot target the wrong item.
- After create/edit there is no deliberate refocus/select-all behavior; after future removal stale selection must be cleared deterministically.
- Search has request-generation race protection: stale success/error cannot overwrite a newer request.
- Restore invalidates `taskListControllerProvider` only. Mounted Notes state, contextual Relationships and previous Search results can remain stale after a successful replace-style Restore. This is a P0 correctness gap in Presentation/provider invalidation.

### Destructive-action safety findings

- Restore already requires an explicit, non-barrier-dismissible replace confirmation and provides localized failure categories. Cancellation returns to idle.
- Relationship unlink has no confirmation. Because no re-link/restore UX exists, confirmation is required for Alpha; undo would require defined Relationship reactivation semantics and is not silently assumed.
- Task/Note delete buttons must not be added before the lifecycle gate. Preferred common soft-delete direction exists, but recovery, list filtering, relationship endpoint handling and exact mutations remain unresolved.
- Note dirty replacement is a data-loss action and needs a save/discard/cancel guard (or another explicitly accepted policy); autosave must not be introduced implicitly.

### Backup / Export / Restore UX findings

- All three operations are discoverable under Settings and open native file selection.
- Busy controls disable concurrent operations; progress, success and localized categorized errors are visible.
- Backup/Export `fail-if-exists` is safe and existing target remains unchanged; the native save flow can still lead to a refusal after selecting an existing name, so clearer recovery copy is P1 polish.
- Restore explains replace behavior and requires confirmation after file selection; invalid/corrupt/future/checksum/persistence failures map to localized messages.
- Main defect: successful Restore refreshes Tasks only. Notes/Relationships/Search views must not continue displaying pre-restore projections.

### Home / Settings findings

- Home placeholder does not block daily work because shell opens Tasks and all real features have direct destinations. Dashboard remains deferred; a small non-authoritative getting-started summary is P2 only.
- Settings contains the only currently necessary Alpha controls: Backup, Export and Restore.
- Manual language selection is not required: ADR-0027 defines platform locale selection/fallback. AI/Sync controls remain out of scope.

### Search usability findings

- Copy identifies Task-only scope; initial/loading/no-results/error states and completed styling exist.
- Enter submits; async race/stale-error protection exists; state survives IndexedStack navigation.
- Results cannot navigate to/open the corresponding Task. This is P1 usability, but must not become Unified Search or new routing architecture.
- Query has no clear affordance or focused search shortcut; P2/P1 polish respectively.
- Note/Unified Search is a known separate milestone and does not block Task/Note CRUD Alpha.

### Error, empty and loading findings

- Task, Note, Search, Relationships and Settings have localized principal empty/loading/error states.
- Collection/relation load errors generally have no explicit retry action.
- Task completion mutation failure is not caught and shown as localized user feedback.
- Relationship endpoint label read failure can remain visually stuck as loading.
- Relationship invariant failures are intentionally collapsed to generic save error; useful but not blocking refinement.
- Backup picker/backend failures receive a safe generic filesystem message rather than technical exception text.
- No production private user content is intentionally logged by these flows.

### Localization and basic accessibility findings

- `app_en.arb` and `app_ru.arb` have parity (69 user keys each); no static hardcoded Presentation string was found in the audited feature files.
- Task/Note/Related/Backup/Export/Restore terminology is internally consistent enough for Alpha.
- Future menus, prompts, shortcut labels and status messages must be added to both ARB files; generated localization files must not be manually edited.
- Icon-only completion/unlink actions have localized tooltips. Standard Material controls provide reasonable targets and visible focus, but focused keyboard/dialog tests are missing.
- Destructive dialog initial/default focus, Escape behavior and safe focus return should be proven in the relevant checkpoint, not assumed.

### Architecture gap matrix

| Gap | Priority | Presentation | Application | Domain | Repository | Persistence/schema | ADR/gate |
|---|---:|---|---|---|---|---|---|
| Task title edit | P0 | editor/action absent | use case absent | mutation/invariants absent | existing `save` physically capable | columns already sufficient | required |
| Task/Note delete/archive/restore | P0 | actions/trash absent | use cases absent | typed transitions absent | contracts lack lifecycle operations beyond `save` | lifecycle column exists; active filtering incomplete | required |
| Dirty Note replacement | P0 | guard/status absent | existing edit sufficient | ADR-0030 sufficient | no change | no change | no new ADR |
| Relationship unlink safety | P0 | confirmation absent | unlink exists | ADR-0032 unlink exists | supported | supported | confirmation needs no ADR; undo/reactivation would |
| Restore stale projections | P0 | incomplete provider invalidation | operations exist | no change | no change | restore correct | no new ADR |
| Task toggle error feedback | P1 | uncaught feedback gap | existing use case | no change | no change | no change | no new ADR |
| Relationship endpoint endless loading | P1 | missing Future error state | reads exist | no change | no change | no change | no new ADR |
| Context menus/shortcuts/focus | P1 | absent | reuse accepted operations | no new rules if action exists | no change | no change | dependent on lifecycle/edit gate only |
| Search result activation | P1 | absent | existing Task read/navigation composition usable | no change | no change | no change | must stay within current shell architecture |
| Load retry | P1 | absent | existing providers can invalidate | no change | no change | no change | none |

### Lifecycle / delete architecture gate conclusion

Ниже сохранён вывод DU-01 на момент аудита; выявленная неопределённость впоследствии разрешена принятым ADR-0033 в DU-02.

1. **Task delete:** not yet unambiguous. Common soft delete exists, but Task mutation, allowed source states, no-op/error semantics and active-list behavior are absent.
2. **Note delete:** not yet unambiguous and explicitly deferred by ADR-0030.
3. **Meaning of delete:** ADR-0016 prefers logical `lifecycle -> deleted`; exact typed transition still requires acceptance. Hard delete is not justified for ordinary UI.
4. **Archive:** conceptually distinct and should not be disguised as Delete. Whether Alpha exposes it and its transition/recovery rules needs the same gate.
5. **Trash/Restore:** some recovery path or a deliberately accepted limited policy is needed before removal is safe for daily use. Exact Alpha UX is unresolved.
6. **Outbox:** under current persistence convention a material soft lifecycle change would be normal `UPDATE` with version increment; no production DELETE operation exists. The gate must confirm no-op/base-version/timestamp rules.
7. **Relationships:** must not cascade physically. Whether active Relationships are hidden, retained, deactivated or restored with an endpoint is not fully defined; ADR-0016 explicitly leaves this to lifecycle policy.
8. **ADR:** required. The decision is durable across Domain, repositories, visibility/search, Relationships, UI safety and sync/outbox semantics. Proposed future ADR: `ADR-0033: Task mutation and Task/Note lifecycle/recovery semantics` (exact title/content to be confirmed after DU-02; do not create automatically).
9. **Schema v4:** not intrinsically required if accepted policy uses existing lifecycle/version/updatedAt fields. It becomes a separate gate only if the decision adds durable state such as `deletedAt`, trash metadata or history.
10. **Backup format v4:** not intrinsically required because current v3 already preserves lifecycle and metadata. It is required only if new persisted fields/semantics cannot be represented by v3; do not revise format speculatively.

### Task edit architecture gate conclusion

- Current fields: `title`, `isCompleted` plus common Entity metadata.
- Current mutation: completion toggle only.
- Title update normalization, empty validation, UTC/monotonic timestamp, material/no-op behavior and allowed lifecycle states are not defined for Task.
- ADR-0023 and repository establish atomic UPDATE + Outbox mechanics, not the Domain validity of an edit.
- Existing Task `save()` and schema can persist a valid edited Task without migration; Outbox UPDATE machinery already exists.
- Note edit is a useful implementation precedent (immutable value, normalized title, external UTC clock, no-op skips save), but ADR-0030 is Note-specific and must not be silently copied.
- DU-02 must decide Task edit semantics together with lifecycle interaction before implementation. New dependency, schema v4 and Backup v4 are not expected from title-only edit.

### P0 backlog

1. Architecture gate/accepted decision for Task title edit and Task/Note lifecycle, recovery, visibility, Relationships and Outbox behavior.
2. Implement Task title editing after the gate.
3. Implement safe Task and Note removal/recovery according to the accepted policy; never expose an irreversible unlabeled action.
4. Protect dirty Note content when New/another Note would replace it; add clear dirty/saved state.
5. Add confirmation to Relationship unlink unless the gate explicitly enables a reliable undo/reactivation path.
6. Refresh/invalidate all affected mounted feature projections after successful replace-style Restore, not Tasks alone.

### P1 backlog

- Context menus for Task/Note rows with only real, accepted actions.
- Context-aware Ctrl+N and Note Ctrl+S; safe Delete only after lifecycle decision.
- Focus/selection choreography after create/edit/remove and focused keyboard/dialog tests.
- Localized feedback for Task toggle failure; retry actions for primary load errors.
- Relationship endpoint error state and clearer invariant failure copy where useful.
- Open a Task from Task Search without adding routing or Unified Search.
- Verify desktop layouts and focus visibility at existing tested window widths after menus/dialogs are added.
- Clarify recovery after choosing an existing Backup/Export target.

### P2 and deferred backlog

P2:

- Search clear affordance and optional search-focus shortcut.
- Extra arrow/double-click/hover conveniences proven useful by dogfooding.
- Small Home getting-started/status content only if observed useful; no dashboard architecture.
- Minor visual/status consistency after P0/P1 flows stabilize.

Deferred outside DU:

- Note/Unified/semantic Search, FTS and embeddings.
- Sync, Workspace/Projects, AI, graph visualization, richer Relationship kinds.
- Rich text/Markdown semantics, attachments and autosave architecture.
- Mobile/tablet shell, persistent navigation history/deep links.
- Hard-delete maintenance, retention policy and lifecycle history unless a future accepted gate requires them.

### Definition of Done

- Current user journeys and desktop interaction behavior are evidence-backed from production code/tests.
- P0/P1 gaps identify the missing architectural layer rather than treating every gap as Presentation-only.
- Task edit and Task/Note lifecycle ambiguity is isolated into a next architecture gate.
- Milestone checkpoints, validation and user-oriented Alpha acceptance criteria are recorded.
- No production/test/schema/dependency/generated/ADR file is changed.

### Validation

- Baseline `flutter analyze` and full `flutter test` before audit.
- `git diff --check` after plan creation.
- Diff/status prove only this plan was added apart from the pre-existing user-owned Obsidian change.

### Result / evidence

Completed. Baseline is green (analyze PASS; 184 tests PASS). The audit found five direct P0 usability/safety areas and one mandatory architecture gate. Existing storage fields appear sufficient for the expected title edit and soft lifecycle direction, but no implementation is authorized until DU-02 resolves typed mutations, recovery, visibility and Relationship consequences. No baseline blocker prevents forming the milestone plan.

## DU-02 — Task edit and Task/Note lifecycle architecture gate

Статус: done

### Goal

Produce an architecture-ready decision proposal for Task title editing and Task/Note archive/delete/restore semantics, including active collection visibility, Relationship endpoint policy, Outbox/version/no-op/timestamp rules, Alpha recovery UX, schema and Backup compatibility consequences.

### Relevant ADRs

ADR-0016, ADR-0019, ADR-0023, ADR-0026, ADR-0028, ADR-0030, ADR-0031, ADR-0032 and current repositories/search/backup contracts.

### Allowed scope

Read-only architecture analysis and execution-plan evidence. Propose a narrowly scoped ADR if required; create/accept it only after explicit user instruction.

### Explicit non-goals

No production implementation, UI, schema/Backup changes or hidden lifecycle decision.

### Definition of Done

- Task edit invariants and immutable mutation semantics are unambiguous.
- Task/Note lifecycle state machine and visible collection/search behavior are unambiguous.
- Relationship behavior, recovery UX and Outbox semantics are unambiguous.
- Schema/Backup impact is explicitly `none` or gated with evidence.
- ADR requirement and exact blocker/resume instruction are recorded.

### Validation

Read-only import/code/ADR consistency checks and `git diff --check` for documentation changes.

### Result / evidence

Architecture investigation выполнено; implementation не начиналась.

#### Reconciliation

- DU-01 находится в HEAD и имеет статус `done`; DU-02 до этого запуска был `pending`.
- Audit revision: `27a4d4e70a222cd69df4f3584457de0a0b0220b3`, branch `main`, divergence с `origin/main` — `0 0`.
- Исходное рабочее дерево содержало только user-owned `M .obsidian/workspace.json`.
- ADR-0032 имеет статус `Принято` в HEAD.
- Baseline DU-01 остаётся применим: production/tests после него не изменены; повторный analyze/test для architecture-only plan delta не требуется.

#### Что уже установлено принятыми решениями и кодом

- Common lifecycle enum физически и в Domain содержит `active`, `archived`, `deleted`, но ADR-0016 прямо не фиксирует точные state machines.
- ADR-0016 различает Archive и Delete, предпочитает soft delete, исключает deleted из обычного Search и оставляет endpoint Relationship policy отдельному решению.
- ADR-0030 полностью определяет Note create/edit, но явно откладывает Note archive/delete/restore до lifecycle gate.
- ADR-0032 запрещает автоматические cascade mutations Relationship при lifecycle change endpoint. Relationship unlink — собственная `active -> deleted` mutation Relationship, не модель удаления endpoint.
- Normal local material mutation должна атомарно сохранить Domain state и Outbox full snapshot по ADR-0023. Current repositories используют `CREATE` или `UPDATE`; Relationship unlink использует `UPDATE`.
- `Task` сейчас имеет только `title`, `isCompleted` и common metadata. Creation trims/rejects empty title; единственная mutation — completion toggle. Title edit и inactive-state restrictions не определены.
- `Note.edit` является atomic immutable title/content mutation: title trim, exact content, external UTC timestamp, `updatedAt >= previous`, version +1 только для material change, no-op возвращает тот же instance.
- Task/Note `getAll()` сейчас возвращают все lifecycle states; Presentation и Backup/Export используют один и тот же метод. Task Search уже фильтрует только active. `getById()` возвращает Entity независимо от lifecycle.
- Relationship `getForEntity()` фильтрует lifecycle самой Relationship как active, но не lifecycle endpoints. Relationship creation проверяет existence/type, но не active lifecycle endpoint.
- Backup/Export v3 получает Task/Note/Relationship через all-state `getAll()` и сериализует lifecycle каждого record. Restore v3 проверяет existence/type/canonical Relationship endpoints, но не требует active endpoints, и восстанавливает lifecycle exactly.
- SQLite schema v3 уже хранит lifecycle/version/timestamps. FK используют `NO ACTION`; physical cascade отсутствует.

#### Task edit semantics — принято ADR-0033

1. В Alpha пользователь редактирует только `title`; `isCompleted` остаётся отдельной completion mutation.
2. Domain API — узкий `editTitle(title, updatedAt)`, а не generic `edit`, чтобы не смешивать независимые actions.
3. Title сохраняется после `trim()`; empty/whitespace-only запрещены; arbitrary maximum length не вводится.
4. Material edit создаёт новую immutable `LifeOsTask`, сохраняет identity/creation/source/lifecycle/completion, увеличивает version на 1 и ставит supplied UTC `updatedAt`.
5. Monotonic rule — `updatedAt >= current.updatedAt`, не strict `>`. Равенство допустимо при coarse/deterministic clock и остаётся material versioned mutation.
6. Same normalized title — no-op: тот же instance, прежние version/updatedAt, без repository save и Outbox.
7. Timestamp validation выполняется до no-op: UTC обязателен, движение назад запрещено.
8. Edit title разрешён только active Task. Archived/deleted Task сначала должна вернуться в active соответствующей lifecycle operation.
9. Completion toggle также разрешён только active Task; completed Task остаётся lifecycle-active.
10. Hydrated Task должна проверять typed non-empty ID, normalized non-empty title, UTC timestamps, `updatedAt >= createdAt` и positive version, аналогично остальным typed Entity, без зависимости от persistence.
11. Material edit сохраняется текущим `save()` как Outbox `UPDATE`: `baseVersion = previous.version`, `newVersion = previous + 1`, full Task snapshot включая lifecycle.
12. Schema change не требуется: `tasks.title` и common metadata уже существуют.
13. Mutation repository method не требуется: `save()` остаётся persistence boundary. Для visibility потребуется один новый typed read contract, описанный ниже.
14. Application получает отдельный `EditLifeOsTaskTitle`: load by ID, Domain mutation, skip save for no-op, save material result; clock внедряется через текущую boundary.

#### Common Task/Note lifecycle state machine — принято ADR-0033

| Transition | Proposal | User meaning | Outbox |
|---|---|---|---|
| `active -> archived` | allow | Archive, скрыть из ordinary work | material UPDATE |
| `active -> deleted` | allow | Move to Trash | material UPDATE |
| `archived -> active` | allow | Unarchive | material UPDATE |
| `archived -> deleted` | allow | Move archived item to Trash | material UPDATE |
| `deleted -> active` | allow | Restore deleted Entity | material UPDATE |
| `deleted -> archived` | forbid | Restore сначала возвращает в active; скрытый compound transition не нужен | none/error |
| повтор целевого action (`archive` archived, `delete` deleted, `restore` active, `unarchive` active) | no-op | idempotent retry | none |

Rules for every material lifecycle transition:

- immutable typed Entity result; Entity typed state, ID, `createdAt` и `source` сохраняются;
- Task completion и Note title/content сохраняются exactly;
- supplied time must be UTC and `>= current.updatedAt`;
- `version += 1`, `updatedAt = supplied timestamp`;
- forbidden cross-state action is rejected, not silently coerced;
- ordinary edit/completion is forbidden while archived/deleted;
- no hard delete, physical row removal or new lifecycle enum value.

Предлагаемые explicit Domain names: `archive`, `unarchive`, `delete`, `restore`. `restore` означает только `deleted -> active`; `unarchive` отдельно означает `archived -> active`.

#### Archive vs Delete and minimal Alpha UX — принято ADR-0033

- Archive — сохранённое, не удалённое состояние для исключения из ordinary context.
- Delete — soft lifecycle transition в `deleted`, пользовательски формулируемый как Move to Trash.
- Наличие enum `archived` не обязывает немедленно exposing Archive UI.

Option comparison:

- **A — Delete + per-feature Trash + Restore; Archive UI deferred:** минимальный безопасный CRUD loop и ясное recovery; existing archived records сохраняются, но не создаются обычным Alpha UI. Recommended.
- **B — Archive + Delete + Trash + Restore:** наиболее полный lifecycle UX, но удваивает actions/filters и не нужен для устранения текущего blocker.
- **C — Delete/Restore без discoverable Trash surface:** меньше кода, но Restore трудно обнаружить; не является coherent daily-use UX.

Recommendation: Option A. Trash реализуется как явно доступный secondary view/filter внутри Tasks и Notes, без нового NavigationRail destination. Archive/unarchive semantics фиксируются для совместимости, но user-facing Archive action откладывается.

#### Visibility policy — принято ADR-0033

| Consumer | active | archived | deleted |
|---|---:|---:|---:|
| Ordinary Task list | include, including completed | exclude | exclude |
| Ordinary Note list | include | exclude | exclude |
| Task Search | include | exclude | exclude |
| Relationship picker | selectable | exclude | exclude |
| Contextual Related section | show only if Relationship and both endpoints are active | hide | hide |
| Per-feature Trash | exclude | exclude | include |
| Backup v3 | include | include | include |
| Human-readable Export v3 | include | include | include |
| Backup Restore | restore exact state | restore exact state | restore exact state |

`getById()` остаётся all-state internal read, чтобы lifecycle use cases могли загрузить deleted/archived Entity. Inactive Entity не становится missing на repository boundary; visibility задаётся explicit collection reads/use cases.

#### Relationship endpoint policy — принято ADR-0033

- Lifecycle change Task/Note **не мутирует** связанную Relationship, не меняет её version/updatedAt и не создаёт Relationship Outbox record.
- Relationship и typed row остаются в database; FK `NO ACTION` подходит, потому что endpoint row soft-deleted, а не физически удалён.
- Ordinary Related скрывает active Relationship, если любой endpoint не active. После Restore/Unarchive endpoint та же Relationship автоматически снова видима.
- Picker показывает только active Tasks/Notes и не позволяет создать новую Relationship к inactive endpoint.
- Application creation проверяет не только existence/type, но и active lifecycle; Infrastructure может повторить это как persistence integrity guard, не перенося business rule в widget.
- Скрытая из-за inactive endpoint Relationship продолжает участвовать в uniqueness; новая duplicate pair не создаётся. После Restore появляется исходная identity, а не новая edge.
- Unlink скрытой Relationship для Alpha не нужен: после endpoint Restore она снова доступна для обычного unlink. Explicitly unlinked Relationship остаётся deleted по ADR-0032; re-link/undo такой Relationship остаётся отдельным будущим lifecycle UX gate.
- Cascade unlink/delete, automatic Relationship lifecycle mutation и physical cleanup отклоняются.

#### Entity restore terminology — принято ADR-0033

- Domain `restore()` означает restore deleted Task/Note to active.
- Domain `unarchive()` означает archived to active; generic `reactivate()` отклоняется как скрывающий исходное состояние.
- Presentation всегда использует contextual text: `Restore task` / `Restore note` и отдельно существующее `Restore backup`; общий неоднозначный label `Restore` не используется без контекста.
- Entity Restore сохраняет ID, typed state, completion, timestamps history fields и source; material transition изменяет только lifecycle, updatedAt и version.

#### Outbox mutation matrix — принято ADR-0033

| Mutation | operation | baseVersion | newVersion | payload | atomic |
|---|---|---:|---:|---|---|
| Task title material edit | `UPDATE` | previous | previous + 1 | full Task snapshot | yes |
| Task archive/delete/restore/unarchive | `UPDATE` | previous | previous + 1 | full Task snapshot with lifecycle | yes |
| Note archive/delete/restore/unarchive | `UPDATE` | previous | previous + 1 | full Note snapshot with lifecycle/content | yes |
| Repeated/no-op action | none | unchanged | unchanged | none | no persistence call |

Current local soft delete does not use Outbox `DELETE`: no row is physically deleted, and Relationship unlink already establishes lifecycle removal as `UPDATE`. ADR-0019 conceptual DELETE/tombstone remains a future Sync protocol concern; full deleted snapshot contains stable ID, lifecycle, version and time needed as a tombstone foundation.

#### Repository impact — принято ADR-0033

- Keep typed Task/Note repositories; do not add generic Entity/Lifecycle repository.
- Preserve current `getAll()` as all-lifecycle snapshot read because Backup/Export must not silently lose inactive user state.
- Add one typed `getByLifecycle(LifeOsEntityLifecycle lifecycle)` to Task and Note repositories. Ordinary list use cases request `active`; Trash use cases request `deleted`. This is smaller and clearer than three named methods or a generic query language.
- Keep `getById()` all-state and `save()` as the only normal mutation persistence boundary; no physical `delete()` method.
- Update `getForEntity()` semantics to return active Relationships only when both endpoints are active. No new Relationship repository method is required.
- Application adds explicit typed use cases for Task title edit and Task/Note delete/restore. Archive/unarchive use cases may wait with deferred UI; no generic LifecycleService is justified.

#### Backup / Export / Restore impact

- Format v3 already serializes lifecycle for Task, Note and Relationship and can represent inactive endpoints.
- All-state `getAll()` currently feeds Backup/Export; this behavior must be preserved while ordinary UI switches to lifecycle-filtered reads.
- BackupSnapshotV3 validates endpoint existence/type/canonical identity, not endpoint activity. Proposed unchanged Relationship policy is representable.
- Restore v3 reconstructs all Entity rows before Relationship rows, preserves lifecycle exactly and creates no Outbox; no conflict exists.
- **Backup/Export format v4 is not required.** Historical v1/v2 readers and current v3 writer/reader remain unchanged.

#### Schema and dependency impact

- **Schema v4 is not required.** Existing `entities.lifecycle`, `updated_at`, `version`, typed rows and FK `NO ACTION` represent the proposal.
- Lifecycle predicates require query changes only. New indexes are not justified without measured data; current Alpha volume does not prove a migration requirement.
- No package dependency is required.

#### Future Sync compatibility

- Soft-deleted Entity remains a stable-ID, versioned full snapshot and can act as tombstone foundation.
- Every material transition advances version and emits one atomic Outbox UPDATE; Restore from Trash is a later UPDATE rather than identity recreation.
- Repeated actions are no-op and do not create duplicate changes.
- Relationship identity remains stable and is not spuriously versioned by endpoint lifecycle.
- Future remote operation mapping, conflict resolution, retention/hard purge and deleted-vs-edited concurrency remain explicit Sync gates; proposal does not pre-decide them or create an obvious data-loss dead end.

#### ADR gate

**ADR required and accepted.** Existing ADR deliberately left exact Task mutation, typed lifecycle state machines, visibility, endpoint Relationship policy and Restore semantics unresolved. Эти durable cross-layer rules теперь зафиксированы в `docs/adr/ADR-0033-task-and-note-lifecycle-and-user-mutation-semantics.md` со статусом `Принято`.

Accepted ADR:

`ADR-0033: Task and Note Lifecycle and User Mutation Semantics`

Recorded decision outline:

1. **Context:** current Task/Note/Relationship production state; conceptual lifecycle is insufficient for user-facing mutation.
2. **Decision scope:** Task title edit plus Task/Note lifecycle only; Relationship endpoint consequences, visibility and Outbox.
3. **Task invariants/edit:** title-only `editTitle`, trim/non-empty/no max, immutable material/no-op, active-only edit/completion, external monotonic UTC time.
4. **State transitions:** exact allow/forbid/no-op table above; separate archive/unarchive/delete/restore names; no hard delete.
5. **Visibility:** ordinary lists/search/picker/related active-only; per-feature Trash deleted-only; `getById` and Backup snapshot all-state.
6. **Relationship policy:** no cascade mutation; hide when endpoint inactive; reappear on endpoint active; active-only picker/create; uniqueness remains.
7. **Outbox:** every material action is atomic `UPDATE` with previous baseVersion, version +1 and full snapshot; no-op none; no local DELETE operation.
8. **Repository/Application boundaries:** typed repositories, `getByLifecycle`, existing `save`, explicit typed use cases, no generic LifecycleService.
9. **Backup/Restore:** v3 includes all states and restores exactly; distinguish Entity restore from Backup Restore; no v4.
10. **Schema/dependencies:** schema v3 sufficient, no indexes/migration/package additions.
11. **Alpha UX:** Option A — Delete + per-feature Trash + Restore; Archive UI deferred.
12. **Non-goals:** hard purge/retention, autosave, Unified Search, Sync transport/conflict resolution, Relationship re-link/undo, generic lifecycle framework.
13. **Consequences:** safe recovery and stable identity at cost of retained inactive rows and more explicit filtered reads.
14. **Rejected alternatives:** hard delete/cascade, Relationship auto-mutation, Archive+Delete maximal Alpha, non-discoverable Restore, generic repository/service, Outbox DELETE now, schema/format bump.

#### Expected implementation scope

- **Domain:** strengthen Task hydration invariants; add `editTitle`; enforce active-only Task edit/toggle and Note edit; add accepted typed lifecycle mutations to Task/Note as required by Alpha.
- **Application:** add typed Task edit and Task/Note delete/restore use cases with injected UTC clock; skip no-op saves; use active/deleted reads explicitly.
- **Infrastructure:** add lifecycle-filtered Task/Note queries; preserve all-state reads for Backup; update Relationship active-endpoint filtering/creation guard; retain atomic save + Outbox UPDATE. No migration/codegen expected.
- **Presentation:** later checkpoints add localized Task edit and per-feature Trash/Restore; no new shell destination at lifecycle checkpoint.
- **Localization:** add en/ru actions, dialogs, Trash/empty/error labels; regenerate via `flutter gen-l10n`, never hand-edit generated files.
- **Tests:** Domain transition/edit matrices; Application no-op/clock/save; repository filtering/Outbox/Relationships/reopen; Backup v3 regression; localized widget safety flows.
- **Docs:** ADR-0033 создан после explicit approval; DU-03 остаётся следующим implementation checkpoint.

#### Architecture gate resolution

Human approval получен. ADR-0033 создан со статусом `Принято` и фиксирует Option A lifecycle UX, active-only mutation policy, endpoint Relationship visibility, Outbox UPDATE, отсутствие schema v4/Backup v4/dependency changes и typed repository/Application boundaries. Architecture blocker resolved; DU-02 завершён. DU-03 не начинался.

## DU-03 — Task editing vertical slice

Статус: pending

### Goal

Implement accepted Task title edit semantics through Domain, Application, repository persistence/Outbox and localized Presentation without changing navigation architecture.

### Relevant ADRs

ADR-0023, ADR-0026 and ADR-0033.

### Allowed scope

Only accepted title edit contract, required Task hydration invariants, active-only edit guard, focused UI surface and tests.

### Explicit non-goals

Lifecycle transitions/Trash/Restore, separate completion lifecycle retrofit, details page, generic entity editor or schema change. Lifecycle implementation remains DU-04 scope.

### Definition of Done

Material/no-op/validation/error/reopen/Outbox behavior is tested end-to-end; edit is discoverable by mouse and safely targetable.

### Validation

Focused Domain/Application/repository/widget tests, `flutter analyze`, full `flutter test`, import-boundary scan, localization generation/check and `git diff --check`.

### Result / evidence

Not started; depends on DU-02 accepted decision.

## DU-04 — Safe Task and Note lifecycle vertical slice

Статус: pending

### Goal

Implement only the accepted Alpha lifecycle/removal/recovery policy for Tasks and Notes, including filtering, Relationships and Outbox behavior.

### Allowed scope

Typed Domain mutations/use cases/repository reads and localized Presentation necessary for the accepted policy.

### Explicit non-goals

Hard-delete maintenance, retention/history, generic LifecycleService or schema/Backup revision unless DU-02 explicitly gates it.

### Definition of Done

Removal is safe and recoverable according to the decision; stale selection is impossible; active/search/relationship visibility and persistence/reopen behavior are proven; no unintended cascade occurs.

### Validation

Focused lifecycle/Outbox/relationship/search/widget/persistence/reopen tests, migrations/Backup compatibility checks as applicable, analyze/full tests/import/localization/diff checks.

### Result / evidence

Not started; depends on DU-02.

## DU-05 — Note draft and explicit-save safety

Статус: pending

### Goal

Prevent silent loss of unsaved Note input and make the explicit-save model clear without introducing autosave semantics.

### Allowed scope

Presentation-local dirty tracking, localized save/discard/cancel flow for destructive in-feature transitions, saved/error feedback and Ctrl+S/Ctrl+N where safe.

### Explicit non-goals

Autosave, revision history, editor format, application-global draft singleton or platform close architecture without a separate proven need.

### Definition of Done

New/selection/navigation behaviors cannot silently replace a dirty draft; no-op/material saves remain ADR-0030 compliant; keyboard and mouse flows are focused-tested.

### Validation

Focused Note widget/lifecycle tests, localization check, analyze/full tests/import scan/diff check.

### Result / evidence

Not started.

## DU-06 — Desktop actions, context menus, focus and selection

Статус: pending

### Goal

Expose implemented Task/Note actions through predictable desktop surfaces and context-aware shortcuts with safe item targeting.

### Allowed scope

Presentation-only menus, `Shortcuts`/`Actions` where useful, focus return/traversal and selection behavior using capabilities completed in DU-03/DU-04.

### Explicit non-goals

New business operations, global command framework, routing package or shortcuts without a current action.

### Definition of Done

Right-click actions are discoverable/localized, keyboard actions target the intended feature/item, destructive commands are guarded, and focus remains visible and deterministic.

### Validation

Focused mouse/keyboard/context-menu/desktop-layout widget tests plus standard plan checks.

### Result / evidence

Not started.

## DU-07 — Safety, refresh and error recovery

Статус: pending

### Goal

Close concrete cross-feature correctness and recovery gaps: Relationship unlink protection, post-Restore provider refresh, Task toggle feedback, endpoint-load failure and primary retry actions.

### Allowed scope

Minimal Presentation/provider fixes over existing Application contracts; Relationship reactivation only if accepted earlier.

### Explicit non-goals

New backup format, restore engine, generic error framework or lifecycle redesign.

### Definition of Done

No audited mutation fails silently; Restore cannot leave mounted feature views showing replaced data; unlink is adequately protected; recoverable loads expose bounded retry.

### Validation

Focused Settings/Restore/provider/Relationship/Task tests, existing Backup/Restore tests and standard analyze/full/import/localization/diff checks.

### Result / evidence

Not started.

## DU-08 — Search and bounded daily-use polish

Статус: pending

### Goal

Apply only evidence-backed P1/P2 usability improvements that remain after P0 flows: Task Search result activation, clear/focus affordance, existing-target recovery copy and bounded Home/help polish if still justified.

### Allowed scope

Presentation/composition changes using current shell and Task-only Search.

### Explicit non-goals

Unified/Note Search, dashboard architecture, new destination or routing dependency.

### Definition of Done

Accepted bounded refinements are localized and tested; no deferred feature is pulled into milestone.

### Validation

Focused widget/navigation/layout/localization tests and standard plan checks.

### Result / evidence

Not started.

## DU-09 — Dogfooding Alpha final audit

Статус: pending

### Goal

Run the final user-journey, architecture, persistence, localization, desktop layout and dependency hygiene audit and determine whether the milestone meets the Alpha acceptance criteria.

### Allowed scope

Audit and only minimal concrete defect fixes within already accepted architecture.

### Explicit non-goals

New product scope or next execution plan.

### Definition of Done

Every Alpha acceptance criterion has factual evidence; all required validation passes; plan status becomes completed and deferred scope/final Git state are recorded.

### Validation

All relevant focused tests; `flutter analyze`; full `flutter test`; localization generation/check; import-boundary, routing/dependency and hardcoded-string scans; migration/Backup compatibility checks if touched; `git diff --check`.

### Result / evidence

Not started.

## Validation strategy

1. Run the smallest focused Domain/Application tests before persistence/widget integration tests.
2. Prove every material local mutation creates exactly one correct Outbox change and every no-op creates none.
3. For lifecycle work, test active collection/search visibility, Relationships, restart and Backup v3 round-trip before UI completion.
4. Use provider overrides/fakes for pure Presentation tests; keep real SQLite for repository/atomicity/reopen tests.
5. Test English and Russian for each new user-visible flow, then run `flutter gen-l10n`; never edit generated localization manually.
6. At each implementation checkpoint run `flutter analyze`, full `flutter test`, import-boundary scan and `git diff --check`; add routing/dependency/schema/Backup scans when scope could affect them.
7. Preserve `.obsidian/workspace.json` and reconcile pre-existing changes before every checkpoint.

## Desktop Usable Alpha acceptance criteria

- I can create, rename, complete and reopen a Task, with validation and persistence errors visible.
- I can remove a Task safely and recover or otherwise handle it exactly as the accepted lifecycle policy promises.
- I can create, select, edit and explicitly save a Note without silent loss when starting/selecting another Note.
- I can remove a Note safely and recover or otherwise handle it exactly as the accepted lifecycle policy promises.
- Saved Tasks and Notes, their current lifecycle/completion/content state and Relationships survive application restart.
- I can view, add and safely unlink Relationships; invalid/self/duplicate operations do not corrupt data.
- Lifecycle changes do not produce orphaned/cascaded state contrary to the accepted Relationship policy.
- Expected row actions are discoverable with mouse/context menus, and the highest-value contextual keyboard actions work without targeting the wrong item.
- Focus remains visible and usable through core flows; dialogs have safe cancel/confirm behavior.
- Home, Tasks, Notes, Search and Settings navigation remains clear and preserves intended in-process state.
- Task Search remains clearly Task-only, race-safe and can open the relevant Task without a new routing architecture.
- Backup, Export and replace-style Restore remain available, localized and understandable; Restore confirmation is explicit.
- After Restore, every mounted feature shows restored state rather than stale pre-restore projections.
- Empty/loading/error states never trap the user in indefinite loading or hide a failed core mutation without recovery guidance.
- English and Russian Presentation remain complete; Domain/Application/Infrastructure remain independent of localization.
- Daily local operation needs no network; database/repository ownership remains only in composition root.
- Full validation is green and no schema/dependency/Backup-format change exists unless explicitly accepted by its gate.

## Batching and estimation

- Likely checkpoints: 9 total including this audit and final audit; 8 architecture/implementation/final-audit batches remain.
- Codex implementation effort: approximately 5–9 bounded working runs after DU-01, depending on the accepted lifecycle/recovery UX and whether platform close interception is deferred.
- Likely ADR: yes, one narrowly scoped decision for Task edit plus Task/Note lifecycle/recovery/Relationship consequences.
- Likely schema migration: no. Existing lifecycle/version/timestamps can represent the expected soft lifecycle; any added durable lifecycle metadata must stop at a new gate.
- Likely Backup format revision: no for existing state; v3 already preserves lifecycle. New persistent fields would require a separate compatibility gate.
- Likely dependency changes: none; Flutter SDK/Riverpod/current stack is sufficient.
- Keep architecture, Domain/Application/persistence and Presentation evidence in separate commits only if the user later explicitly requests commits. Do not batch unrelated polish with lifecycle work.

## Exact resume point

Resume with **DU-02 only**. Reconcile this plan with Git and production state; re-read ADR-0016, ADR-0023, ADR-0026, ADR-0028, ADR-0030, ADR-0031 and ADR-0032 plus Task/Note/Relationship repositories and list/search behavior. Mark DU-02 active, perform the read-only architecture gate, and stop with the smallest explicit decision/ADR proposal needed. Do not implement DU-03 and do not create ADR-0033 without user confirmation.
