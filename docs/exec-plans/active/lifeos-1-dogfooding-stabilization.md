# LifeOS 1.0 Dogfooding & Stabilization

Статус: investigation complete; stabilization pending

Дата: 2026-09-27
HEAD: `c7a68a6` (`test: complete context-aware local ai`)
Ветка: `main`; `origin/main...HEAD = 0 0`

## Цель и sources of truth

Довести существующий Windows-first local-first продукт до проверяемого LifeOS
1.0 без превращения stabilization в feature milestone. Investigation docs-only:
production Dart, tests, dependencies, schema, Backup и generated files не меняются.

Проверены `AGENTS.md`, README/roadmap/vision/product/architecture/database/UI
docs, принятые ADR-0023 — ADR-0035, completed plans от MVP/persistence до
Context-aware AI #1, фактические `lib/`, `test/`, `windows/` и pubspec.
Поздние ADR, completed plans и production state имеют приоритет над stale prose.
Последняя final validation: focused 75 PASS, analyze PASS, full suite 417 PASS,
Windows Release build PASS.

## Current product inventory

| Capability | Factual state | 1.0 assessment |
|---|---|---|
| Home | Workspace list, New Workspace, Unassigned, quick actions | Ready; Dashboard не нужен |
| Workspaces / Unassigned | CRUD/Trash, attach/detach, mixed members, quick-create | Ready |
| Tasks | Create/edit/complete/reopen/Trash, filters, shortcuts/context actions | Ready |
| Notes | Plain-text explicit-save editor, dirty guards, Trash | Window-exit blocker |
| Unified Search | Active Task/Note/Workspace, typed open, limit 50 | Ready |
| Relationships / graph | Task/Note `related`, direct active neighbors, unlink | Ready for bounded 1.0 |
| Backup / Export / Restore | Writer v4, Restore v1-v4, atomic replace | Ready by automated evidence |
| Localization | `gen_l10n`, EN/RU, platform locale, EN fallback | 197/197 ARB keys |
| Settings | Data transfer + Local AI | Functional; release/about metadata absent |
| Local AI | Fixed local Ollama `qwen2.5-coder:7b`, explicit status refresh | Automated-ready; live smoke missing |
| Ask about Workspace | Bounded, read-only, single-turn local request | Ready after live smoke |

Not implemented and not required for this boundary: Projects, Documents, Sync,
full Dashboard, files/attachments, semantic/vector Search, cloud AI and graph
visualization.

## Completed roadmap state

Mandatory pre-1.0 milestones are complete: MVP persistence/Task; desktop shell;
Local and Unified Search; Backup/Restore; Notes/schema foundation; Relationships;
Desktop Usability/Dogfooding; Workspace/schema v4/Backup v4; direct-neighbor
Knowledge Graph; AI Foundation; Context-aware AI #1.

No missing feature milestone is required for the accepted product concept. Early
roadmap prose still names Dashboard/Documents in broad MVP and says 1.0 criteria
are undefined, while later completed plans explicitly hand off Context-aware AI
-> stabilization -> LifeOS 1.0. This is a P1 docs inconsistency, not permission
to restore deferred features.

## Deferred / post-1.0 boundary

- tray, notifications/reminders and Task time fields;
- due dates, priority, estimates and richer planning;
- spellcheck, Markdown/rich text, attachments and autosave architecture;
- cloud AI/BYOK, remote Ollama, model selector, auto-install/pull;
- AI history, streaming/cancellation, tools/agents/mutations;
- semantic/vector/FTS/ranked/fuzzy Search and Workspace/graph-aware Search;
- new Entity types, Workspace hierarchy, new Relationship kinds/directions;
- graph visualization and traversal beyond one hop;
- deep links, URL routing, history/router package;
- Sync/backend/conflicts; Archive UI/global Trash/permanent purge;
- public-distribution installer and code signing.

Все перечисленное — P3, если real dogfooding не докажет concrete P0/P1 need.
Installer/signing не блокируют personal dogfooding 1.0.

## Issue matrix

### P0 — release blocker (1)

| ID | Finding | Evidence / required outcome |
|---|---|---|
| RR-P0-01 | Closing the app can silently discard a dirty Note draft | Dirty state private to `NotePage`; in-feature actions guarded, but `LifeOSApp.onExitRequested` closes dependencies and returns exit. Window close needs localized Save/Discard/Cancel; Cancel/failed save veto exit; persistence closes only after decision. |

Persisted Domain data has no other identified P0: repository writes are atomic
with Outbox, migrations transactional, Backup write atomic, Restore validates
before one replace transaction.

### P1 — must fix/prove before 1.0 (5)

| ID | Finding | Required outcome |
|---|---|---|
| RR-P1-01 | Database/migration startup failure occurs before `runApp`, with no user recovery surface | Localized bounded retry/exit guidance; never auto-delete/reset DB |
| RR-P1-02 | Release build exists, but Windows metadata/package is scaffold-like | Replace `com.example`/lowercase metadata after user confirmation; document complete portable bundle; launch smoke outside IDE |
| RR-P1-03 | README/roadmap/overview docs still report schema/Backup v3, Task-only Search and no Workspace/AI | Reconcile current scope and add Windows/run/data/Backup/Ollama guidance |
| RR-P1-04 | No clean-profile packaged RC dogfooding record | Run first-launch -> core flows -> restart using isolated app data |
| RR-P1-05 | Real Ollama path has no recorded live smoke | With installed Ollama/model, prove one bounded Workspace answer and core-data isolation |

### P2 — desirable stabilization

- explicit 1024x768 evidence (1280x800 and 640x600 already pass);
- consolidated keyboard/focus/semantics release audit;
- bounded thousands/low-tens-of-thousands scale measurement before any index;
- two handwritten version owners: pubspec and `lifeOsApplicationVersion`;
- optional About/version surface;
- privacy-safe diagnostics only if startup/dogfooding proves necessary;
- separate decision for recurring `.obsidian/workspace.json` Git noise;
- legacy Task-only Search contract and three handwritten lint suppressions are
  harmless cleanup debt, not release blockers.

### P3 — post-1.0

Everything in the deferred table remains P3 unless later dogfooding proves a
concrete P0/P1 need. Do not pull it into stabilization automatically.

## Core user-flow audit

| Flow | State | Risk/class |
|---|---|---|
| First launch | Empty DB, Home and feature empty states exist | startup failure UI P1 |
| Create/edit/Trash Workspace | Complete with visible errors | Ready |
| Create Task/Note in Workspace | Atomic Entity + Membership | Ready |
| Unassigned -> attach/detach | No Entity or Relationship mutation | Ready |
| Edit/complete Task | Domain through UI, no-op/error/reopen covered | Ready |
| Edit Note | Explicit save and in-app dirty guards | window exit P0 |
| Trash/Restore | Task/Note/Workspace feature Trash | Ready |
| Relationship create/unlink | Endpoint/duplicate/self/confirmation/retry covered | Ready |
| Related navigation | Typed Task/Note and dirty-decision preservation | Ready |
| Unified Search | Typed Task/Note/Workspace, races and lifecycle freshness | Ready |
| Backup / Export / Restore | v4 + historical Restore and refresh | Ready |
| Local AI unavailable | Core app unaffected; localized recovery | P2 docs |
| Local AI ready / Ask | Automated contracts pass | live smoke P1 |
| Restart/reopen | File-backed persistence/migration/round-trip covered | packaged smoke P1 |

## First-run, desktop UX and accessibility

- Home is meaningful on empty DB and exposes New Workspace, Unassigned, New
  Task/Note, Search and Settings; an onboarding wizard is not justified.
- Feature empty/loading/error/retry states are bounded; Backup/Restore and Local
  AI are discoverable in Settings.
- Six labeled `NavigationRail` destinations use shell-local state and
  `IndexedStack`; preservation and typed navigation are tested.
- Standard Material controls, localized tooltips and feature-scoped shortcuts
  are used. Destructive shortcuts ignore text fields, modal routes, Trash and
  inactive destinations.
- Existing tests cover 1280x800 and 640x600 across shell and key screens/dialogs.
  Add 1024x768 evidence; no design-system/mobile rewrite.
- No concrete focus trap, inaccessible essential control or overflow blocker was
  found. Consolidated RC accessibility verification remains P2.

## Data safety, schema and Backup

- Production SQLite uses `schemaVersion = 4`. The complete v1 -> v2 -> v3 -> v4
  migration chain, fresh-v4 creation, frozen historical fixtures, rollback and
  rejection of unsupported future schemas are covered by completed milestones.
- Normal writes preserve the accepted Entity/typed-row/Outbox atomic boundary.
  Restore bypasses normal repositories intentionally, validates before mutation,
  replaces data transactionally, clears Outbox and preserves installation
  `device_id`.
- Backup writer emits logical format v4; Restore accepts supported v1-v4. Checksums,
  manifest/version rejection, malformed input, rollback and fail-if-exists atomic
  file writes have focused evidence. Raw SQLite, active Outbox and `device_id` are
  not exported.
- Export remains human-readable only; it is not an import format. No schema v5,
  Backup v5 or migration work is justified for stabilization.
- Remaining release work is operational proof on a clean packaged profile, not a
  new persistence design. Downgrade between application/schema versions remains
  unsupported and must be stated in release notes rather than improvised.

## Feature-boundary audit

### Tasks and Notes

- Task and Note flows keep Presentation -> Application -> Domain boundaries;
  Drift mapping and transactional persistence stay in Infrastructure.
- Task create/edit/complete/reopen/Trash and Note create/edit/save/Trash have
  focused and restart evidence. Note content whitespace is preserved.
- The only release-blocking Note defect is app-exit handling of a dirty draft.
  Rich text, Markdown semantics, attachments, autosave and revision history stay
  outside 1.0.

### Workspace, Relationships and graph

- Workspace membership is structural and independent from semantic Relationships.
  Unassigned, attach/detach, mixed membership and Workspace Trash are implemented.
- `related` Task/Note Relationships enforce endpoint, self-link and duplicate
  invariants. The graph is intentionally direct-neighbor and read-only in scope;
  multi-hop traversal and visualization remain deferred.
- No generic hierarchy, folder or graph engine is required for release readiness.

### Unified Local Search

- Unified Search covers active Tasks, Notes and Workspaces locally, with literal
  substring semantics, deterministic ordering, a 50-result bound and stale async
  response protection. Typed result navigation is integrated with dirty-state
  decisions.
- The legacy Task-only contract can remain internal compatibility debt. FTS,
  relevance ranking, pagination and Workspace/graph-scoped search require future
  evidence and gates, not stabilization speculation.

## Local AI readiness

- Core LifeOS starts and remains functional without Ollama. No provider call occurs
  during startup; status refresh and Ask are explicit user actions.
- The accepted runtime is local-only Ollama at `127.0.0.1:11434`, fixed model
  `qwen2.5-coder:7b`, DIRECT loopback transport, no cloud fallback, model pull,
  selector, tools or mutation authority.
- Provider-neutral Application contracts and Infrastructure ownership are intact.
  Context assembly is bounded to the selected Workspace and active local members.
- Unavailable/runtime/model/error states are localized and recoverable. Automated
  fake-server coverage is strong, but a real Windows Ollama + fixed-model smoke is
  mandatory P1 release evidence.
- Requiring the user to install Ollama/model externally is acceptable for this
  technical dogfooding release if setup and troubleshooting are documented.

## Localization, errors and lifecycle

- EN/RU ARB parity is 197/197 keys; localization stays in Presentation and the
  platform-locale/English-fallback contract is tested. Generated localization
  files are source-generated and must not be edited manually.
- Feature loading/empty/error/retry states are present. The material remaining
  error gap is pre-`runApp` database/migration/bootstrap failure, which currently
  has no user-visible recovery surface.
- Composition root owns one production database/repository lifecycle. Navigation,
  Search and AI do not create persistence owners. Normal app exit closes owned
  resources, but it must first resolve a dirty Note safely.

## Performance, tests and code health

- Current data volumes and bounded queries do not prove a need for a new index,
  FTS, pagination or caching layer. Stabilization should measure realistic local
  profiles before changing schema or search architecture.
- Repository inventory contains 72 test files and roughly 405 declared test calls;
  the last final suite reported 417 PASS because of parameterized cases. The last
  completed milestone also reports analyze, localization, architecture/schema/
  Backup/dependency/generated guards and Windows Release build PASS.
- No `Future.delayed`/`Timer`-driven test dependency or known flaky suite was found.
  `pumpAndSettle` use should be watched but is not itself a release defect.
- No actionable TODO/FIXME/HACK was found in handwritten production. Three local
  lint suppressions and the retained Task-only Search path are bounded P2 cleanup;
  generated-file suppressions are not handwritten debt.
- There is no evidence supporting a broad refactor, dependency upgrade or dead-code
  purge before 1.0.

## Documentation, installation and Windows distribution

- Root README and product/database/UI/roadmap prose materially lag schema v4,
  Backup v4, Unified Search, Workspace, Relationships and Local AI. A concise
  Windows run/install/Ollama/backup/recovery guide is missing.
- `pubspec.yaml` is `1.0.0+1`, while Windows resource metadata still contains
  template `com.example` identity/lowercase product strings. Application version is
  also duplicated in handwritten Dart. Stabilization must establish one verified
  release value and reconcile package metadata without speculative auto-generation.
- A Windows Release build has succeeded, but there is no recorded clean-profile
  launch/use/restart/backup/restore/AI smoke of the packaged artifact.
- Recommended 1.0 distribution for current personal dogfooding scope: package the
  complete Flutter Windows Release directory as a portable ZIP. Do not distribute
  the `.exe` alone. Installer and code signing are future requirements for public
  distribution, not automatic blockers for a private technical 1.0.
- Exact publisher/legal strings, copyright and final icon are product inputs. If
  absent, STAB-03 must pause only that metadata decision rather than invent values.

## Security, privacy and repository hygiene

- User content remains local. AI sends bounded context only to loopback Ollama;
  there is no cloud fallback, analytics, telemetry or embedded credential path.
- No tracked database, Backup/export archive, model artifact, release binary,
  secret or token was found. Runtime/build outputs remain ignored.
- Privacy-safe diagnostics are optional and require demonstrated support value;
  they must never log Note content, prompts, tokens or other private payloads by
  default.
- `.obsidian/workspace.json` is unrelated user state and must stay outside this
  milestone. Its recurring Git noise is a separate repository-policy decision.

## LifeOS 1.0 Definition of Ready

LifeOS 1.0 is ready only when all of the following are factually true:

1. RR-P0-01 is closed: app/window exit provides localized Save/Discard/Cancel for
   a dirty Note, Cancel or failed save vetoes exit, and persistence closes only
   after a safe decision.
2. Database/bootstrap failures produce a bounded localized recovery/reporting UI;
   no destructive automatic repair is introduced.
3. Windows identity/version metadata and user-confirmed product fields are coherent;
   the complete Release directory is packaged as the chosen portable artifact.
4. README/setup/recovery/Ollama documentation matches schema v4, Backup v4 and the
   actual feature set, including external Ollama/model installation and limitations.
5. A clean-profile packaged smoke proves launch, empty state, Workspace, Task, Note,
   Search, Relationship, Backup/Restore, restart persistence and EN/RU behavior.
6. A real local Ollama smoke proves unavailable recovery, ready state and one
   successful Workspace Ask with `qwen2.5-coder:7b`; core use remains offline-safe.
7. 1280x800, 1024x768 and 640x600 checks show no overflow or inaccessible essential
   action; keyboard/focus/tooltip/accessibility behavior has a consolidated RC pass.
8. Focused stabilization tests, all relevant regressions, `flutter analyze`, full
   `flutter test --reporter compact`, localization, architecture/import, schema,
   Backup, dependency and generated-file guards all pass.
9. Windows Release rebuild succeeds from the reconciled release metadata, and the
   final Git scope contains no private runtime artifacts or unrelated files.

Until these conditions are met, the product is feature-complete for the accepted
boundary but not release-ready.

## Stabilization execution checkpoints

### STAB-01 — Exit and startup safety

Status: done

Goal: close the P0 dirty-Note exit path and P1 bootstrap failure surface without
changing Domain/persistence architecture.

Relevant decisions: ADR-0024, ADR-0027, ADR-0030 and ADR-0033.

Allowed scope:

- inspect Windows close interception and current `onExitRequested` lifecycle;
- add the smallest Presentation-owned localized Save/Discard/Cancel exit flow;
- keep the window open on Cancel or failed save and close dependencies only after
  the decision completes;
- add a bounded localized startup/bootstrap failure surface with retry/exit or a
  factually supported recovery action;
- add focused exit/startup lifecycle tests.

Non-goals: autosave, revision history, database repair/reset, crash reporting,
new persistence ownership or a navigation redesign.

Architecture gate: if safe window veto/save coordination cannot be expressed with
existing Presentation/composition ownership, stop and request an ADR instead of
creating global dirty-state infrastructure implicitly.

Definition of Done: P0 behavior and startup failure recovery are deterministic,
localized, testable and do not close/replace persistence prematurely.

Validation: smallest focused lifecycle/widget tests needed to prove the safety
boundary, then `git diff --check` and exact scope inspection. Broader regression is
reserved for STAB-04 under the project validation cadence.

Result / evidence:

- Flutter's existing `AppLifecycleListener.onExitRequested` remains the Windows
  close/Alt+F4/framework interception point. It now awaits a Note-specific
  Presentation coordinator before closing owned dependencies.
- The mounted `NotePage` registers its existing `_resolveDirtyDraft` flow, so app
  exit and in-app navigation share the same localized Save/Discard/Cancel dialog.
  No Note validation, mutation, timestamp, version or Outbox semantics changed.
- Clean close has no dialog or save. Save is awaited once before exit; a failed or
  invalid save keeps the dialog/app/draft open. Discard permits exit without save;
  Cancel preserves selection and draft and allows a later guarded close.
- Both app lifecycle and Note coordinator retain one in-flight close Future.
  Repeated close requests cannot create duplicate dialogs, saves or shutdowns.
- Dependencies close only after an accepted decision; their existing idempotent
  close owns HTTP-client and database shutdown. Cancel/failure leaves them open.
- Production startup now mounts a localized bootstrap first. Dependency creation
  failure exposes Retry/Exit without error details or destructive reset; a successful
  retry mounts the unchanged composition-owned `LifeOSApp`.
- EN/RU startup strings were added to ARB sources and `flutter gen-l10n` passed.
- Focused app lifecycle + Note suite: 30 PASS. Existing shell dirty-navigation
  selection: 3 PASS. Seven new regressions cover clean close, Save success/failure,
  Discard, Cancel, duplicate dialog/save, shutdown, and startup Retry/Exit.
- No package, schema, migration, Backup, Restore, Domain, Application or
  Infrastructure change. Full analyze/suite remain deferred to STAB-04 by policy.

### STAB-02 — Desktop usability and bounded scale proof

Status: done

Goal: produce missing release evidence without expanding the feature set.

Allowed scope:

- add 1024x768 coverage beside existing 1280x800 and 640x600 checks;
- verify keyboard traversal, focus visibility, tooltips/semantics, dialogs and key
  feature layouts on Windows-oriented sizes;
- exercise a bounded realistic local dataset and record startup/list/search/graph
  observations;
- fix only concrete overflow, focus or blocking performance defects.

Non-goals: mobile/tablet shell, new design system, pagination/FTS/index/cache,
feature redesign or new destinations.

Architecture gate: a measured query/scale issue that needs schema/index changes
must stop for an explicit decision and immediate query/migration proof.

Definition of Done: no essential action is inaccessible at the three target sizes,
keyboard/accessibility behavior is coherent, and observed scale does not reveal an
unresolved release blocker.

Validation: focused responsive/accessibility/scale evidence plus `git diff --check`
and scope inspection; do not run routine broad suites yet.

Result / evidence:

- Audited the production shell, Home, Workspaces/Unassigned, Tasks, Notes,
  Unified Search, Settings/Backup/Restore, Local AI, Workspace AI and startup
  recovery together with their focused widget/lifecycle tests at 1280x800,
  1024x768 and 640x600. The previous 1024x768 gap is now covered in shell,
  Workspace and mixed Search matrices.
- Fixed one release-relevant compact-layout defect: Workspace header actions used
  a non-wrapping Row, placing Unassigned outside the 640x600 shell content area.
  A responsive Wrap keeps New, Unassigned and Trash reachable without a
  viewport-specific branch.
- Fixed one enlarged-text defect: the Workspace AI availability Row could overflow
  while checking status. Its message now receives the remaining width and wraps.
  Representative shell/Home, Workspace, Note and Settings coverage passes at 1.5x
  text scale, and the long-question/long-response AI dialog passes at 640x600 and
  1.5x text scale.
- Existing Material controls, explicit labels/icons and focused tests cover keyboard
  activation, focus-safe Note/Task shortcuts, dirty-state and destructive dialogs,
  Search result activation, Settings actions, Local AI refresh, AI Retry/Close and
  startup Retry/Exit. Completion, lifecycle, result type, AI status and errors are
  not conveyed by color alone. No new accessibility blocker was found.
- Bounded personal-scale evidence passes with 250 Home Workspaces, a Workspace
  containing 252 direct members, mixed Search capped at 50 results, an 80-edge
  adjacency read bounded to 7, and deterministic AI context item/character budgets.
  Scrolling, ordering and bounded reads showed no release blocker or need for an
  index, pagination, cache, FTS or schema decision.
- Focused validation: 156 current tests PASS across shell/responsive, Workspaces,
  Search, Workspace AI, app lifecycle/startup, Tasks, Notes, Related, Settings,
  AI context and Drift Search/Related readers. Full analyze/regression remains
  intentionally deferred to STAB-04.
- Targeted debt scan found no actionable TODO/FIXME/HACK or stale qwen3/OpenAI
  Presentation assumption. Existing documentation drift is STAB-03 work; retained
  Task-specific Search and local lint suppressions remain bounded P2 cleanup.
- No unresolved P0/P1/P2 UX issue was introduced or found. No ARB, dependency,
  schemaVersion 4, migration, Backup v4, Restore, Outbox, generated file or
  architecture boundary changed.

### STAB-03 — Documentation, Windows identity and portable package

Status: done

Goal: make the implemented product installable, understandable and identifiable.

Allowed scope:

- reconcile README/product/database/UI/roadmap facts with current production;
- document Windows prerequisites, run/install/update/backup/recovery, Ollama and
  fixed-model setup, privacy, limitations and unsupported downgrade behavior;
- reconcile user-confirmed Windows product/publisher/version/icon metadata;
- build and assemble the complete Release directory as a portable ZIP candidate;
- record artifact contents and reproducible commands/checksums.

Non-goals: installer, updater, code signing, public store submission, telemetry,
automatic Ollama/model installation or feature changes.

Product gate: do not invent legal publisher/copyright/icon values. If the user does
not provide them, record the exact blocker while completing independent docs/package
work. An installer/public-distribution request requires a separate scope decision.

Definition of Done: documentation matches reality, the artifact has coherent
identity/version, contains every required runtime file and can be handed to a clean
Windows profile for RC smoke.

Validation: docs/link/metadata/dependency/scope checks and one Release build needed
to prove packaging; `git diff --check`. Full regression remains STAB-04.

Result / evidence:

- Reconciled README and the current product, architecture, database, UI and roadmap
  summaries with production schema v4, Workspaces, Unified Local Search, logical
  Backup/Export v4 with historical Restore support, and local-only Ollama AI using
  the fixed `qwen2.5-coder:7b` model. Added bounded Windows release, clean-profile,
  update/recovery, privacy and RC dogfooding procedures.
- Windows Release identity is consistently `LifeOS`: executable and window title,
  ProductName, FileDescription, InternalName and OriginalFilename. No company/legal
  publisher was invented; CompanyName is empty and copyright is the neutral
  `Copyright (C) 2026. All rights reserved.`
- Preserved the accepted application version `1.0.0+1` across `pubspec.yaml`, app
  composition, Windows version resources and artifact naming. No release version
  bump was made.
- The only repository icon is the unchanged Flutter-initialized
  `windows/runner/resources/app_icon.ico` (SHA-256
  `C098D3FC85CACFF98B8E69811B48E9F0D852FCEE278132D794411D978869CBF8`). No approved
  LifeOS brand asset exists, so replacement remains explicit post-1.0 P2 scope.
- `flutter build windows --release` initially exposed a stale generated CMake cache
  that still named the pre-identity target. After deleting only the verified ignored
  `build/windows/x64` cache, the same command passed and produced
  `build/windows/x64/runner/Release/LifeOS.exe` in 133.1 seconds.
- Added `tool/package_windows_release.ps1`. It stages the complete Release directory,
  validates required runtime files, rejects source/runtime/user-data leakage, creates
  a top-level `LifeOS/` portable bundle and uses fail-if-exists output semantics.
- Packaging passed for ignored artifact
  `build/distributions/LifeOS-1.0.0+1-windows-x64.zip`: 13,532,966 bytes, 17 ZIP
  entries, SHA-256
  `86C824190B233D6E7D7E5847CD819C50ED98A2BDB1735D461FEF77309D75CA1F`. A repeated
  packaging attempt failed as required and left the artifact hash unchanged.
- Archive inspection found the executable, Flutter DLL/assets, ICU data, AOT
  `app.so`, SQLite and file-selector runtime DLL, with no database, Backup,
  `.obsidian`, test, source or secret-looking payload. Extraction and hidden launch
  from a fresh temporary directory stayed alive for five seconds; the exact process
  and validated temporary directory were then removed.
- PowerShell syntax, documentation links, stale metadata/model/machine-path scans,
  version consistency, dependency/schema/Backup/generated scope and repository
  ignore behavior passed. `pubspec.lock`, dependencies, schemaVersion 4, migrations,
  Backup v4 contracts and generated files are unchanged. `git diff --check` passed;
  the unrelated user-owned `.obsidian/workspace.json` change remains untouched.
- Installer, updater, signing, public distribution, automatic Ollama/model setup and
  actual clean-profile/core-flow/Ollama RC execution remain outside STAB-03. The
  documented procedures and portable artifact are ready for the STAB-04 final audit.

### STAB-04 — Final release-candidate integration audit

Status: pending; depends on STAB-03

Goal: prove the Definition of Ready and finish the milestone; no new feature work.

Required evidence:

- all new focused STAB tests and relevant feature/persistence/migration/Backup/
  Search/Workspace/Relationship/AI regressions;
- `flutter analyze` and full `flutter test --reporter compact`;
- architecture/import-boundary, routing, localization, responsive/accessibility,
  schema v4/migration, Backup v4/historical Restore, dependency and generated-file
  guards;
- fresh Windows Release build and clean-profile packaged smoke for all core flows;
- real Ollama unavailable/ready/Ask smoke with the fixed model;
- final privacy/security/repository/artifact inspection and `git diff --check`.

Only bounded fixes to concrete RC defects are allowed. Any new architecture,
schema/Backup format, dependency, feature or public-distribution requirement stops
at its applicable gate.

Definition of Done: every LifeOS 1.0 readiness item is evidenced, no P0/P1 remains,
validation passes, the plan records exact artifact/Git state, and this plan moves to
`completed/`. Do not start a post-1.0 milestone automatically.

## ADR gate

No new ADR is required to begin STAB-01. Current findings fit accepted ownership,
localization, lifecycle, persistence, Backup and AI decisions.

A new ADR is required only if evidence later demands a shared/global dirty-state
architecture, a schema/index change, a new diagnostic/privacy contract, or a move
from portable private distribution to installer/public distribution. These are
conditional future gates, not decisions made by this investigation.

## Investigation result and resume point

- Product state: accepted feature boundary complete; stabilization evidence pending.
- Architecture state: coherent; no blocking contradiction found.
- Release state: STAB-01 through STAB-03 are complete; final release-candidate
  integration evidence is still pending.
- Recommended next action: begin
  **STAB-04 — Final release-candidate integration audit** only.
- Resume checkpoint: `STAB-04`, status `pending`.
- Broad analyze/regression, clean-profile/core-flow package smoke and real Ollama
  integration remain reserved for STAB-04 under the milestone validation cadence.
- Deferred scope remains explicitly post-1.0 and must not be pulled into STAB work
  without real dogfooding evidence and the applicable gate.
