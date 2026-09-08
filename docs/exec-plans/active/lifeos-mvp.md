# LifeOS MVP — Active Execution Plan

Status: active

Last reviewed: 2026-09-08

## 1. Objective

Deliver the first genuinely usable local-first LifeOS vertical slice on Windows.

The milestone is complete when a user can:

1. launch LifeOS;
2. create a Task;
3. see the Task in the UI;
4. toggle its completion state;
5. close LifeOS;
6. reopen LifeOS;
7. see the persisted Task and its state;
8. perform these operations through the accepted architecture:

Presentation
→ Application
→ Domain repository abstraction
← Infrastructure
→ Drift
→ SQLite

Every local syncable Entity mutation must continue to produce the required Outbox change atomically with Domain State.

Remote Sync is not part of this milestone.

---

## 2. Existing foundation

Already established before this plan:

- Flutter Windows application skeleton;
- accepted ADR set through ADR-0023;
- Domain Entity contract;
- typed Entity identity;
- LifeOsTask Domain entity;
- Task completion Domain behavior;
- Application use cases;
- Domain-owned LifeOsTaskRepository;
- Drift Infrastructure implementation;
- entities + tasks + outbox schema;
- explicit Domain/Persistence mapping;
- atomic Domain State + Outbox transaction;
- deterministic persistence tests;
- Riverpod Presentation binding;
- thin Task completion UI;
- ProviderScope and provider overrides;
- architecture boundary tests/scans;
- Flutter analyze/test passing at foundation checkpoint.

Do not rebuild these components merely because this plan starts after them.

Verify repository reality before relying on this summary.

---

## 3. Governing documents

Always read AGENTS.md first.

Relevant ADRs include, but are not limited to:

- ADR-0002 — Application Stack
- ADR-0003 — Project Structure
- ADR-0005 — Local-First Data Architecture
- ADR-0006 — Database Schema, where not superseded
- ADR-0007 — Dependency Injection Strategy
- ADR-0016 — Domain Model and Entity Architecture
- ADR-0017 — Database and Persistence Architecture
- ADR-0019 — Change Tracking and Sync Data Model
- ADR-0020 — SQLite Persistence Schema
- ADR-0021 — Flutter Persistence Stack
- ADR-0022 — Flutter Project Architecture
- ADR-0023 — Initial Entity Persistence and Outbox Decisions

Later explicit precedence decisions govern earlier conflicting recommendations.

---

# 4. Current milestone

Milestone: Local persistent Task vertical slice

Status: active

Current checkpoint: CP-02

Next ready checkpoint: CP-02

Blockers: none.

---

# 5. Checkpoints

## CP-01 — Production database lifecycle decision

Status: done

### Goal

Resolve the production SQLite database location, opening, ownership, and disposal lifecycle required for the Windows application.

### Relevant ADRs

Read all persistence/composition ADRs, especially:

- ADR-0005
- ADR-0007
- ADR-0017
- ADR-0020
- ADR-0021
- ADR-0022
- ADR-0023
- ADR-0024

### Allowed scope

- audit existing ADRs;
- determine whether they already specify the lifecycle sufficiently;
- if sufficiently specified, implement the smallest compliant database bootstrap;
- if not sufficiently specified, stop and request the smallest architecture decision.

### Non-goals

Do not implement:

- Sync;
- device registration;
- backup;
- migrations beyond what current schema requires;
- generic database framework;
- multiple database profiles.

### Definition of Done

One of:

A. Production database lifecycle is already architecturally specified and is implemented/tested.

OR

B. The checkpoint is marked blocked with the exact unresolved architecture decision documented.

Do not invent an arbitrary filesystem path.

### Validation

When implementation occurs:

- flutter analyze
- flutter test
- relevant database lifecycle tests
- git diff --check

### Result / evidence

Completed on 2026-09-08.

Evidence:

- ADR-0007 specifies one database instance for the application lifetime, created and disposed through the composition root;
- ADR-0024 is accepted and resolves the production database location and lifecycle architecture gate;
- the production database uses the OS application-support directory with the filename `lifeos.db`;
- the application-support directory is resolved through an appropriate Flutter platform abstraction rather than a hardcoded OS path;
- the composition root owns one production database instance per application process and closes it when the persistence lifecycle ends;
- `openProductionDatabase` resolves the application-support directory through `path_provider`, appends `lifeos.db` with `path`, and opens Drift on a background native executor;
- `LifeOsAppDependencies` owns the database and provides idempotent asynchronous disposal;
- `LifeOSApp` closes the owned dependencies for an exit request and when the root widget is disposed;
- the focused file-backed test saves a Task and Outbox change, closes the database, reopens the same file, and verifies persisted state;
- the app lifecycle test verifies that removing the root app closes the owned database.

Validation:

- focused database/app lifecycle tests: PASS — 2 tests;
- flutter analyze: PASS — no issues;
- flutter test: PASS — 18 tests;
- import-boundary scan: PASS;
- git diff --check: PASS.

---

## CP-02 — Production repository composition

Status: pending

Depends on: CP-01

### Goal

Wire the production LifeOsTaskRepository implementation through the app composition root without exposing Infrastructure to Presentation or Application.

### Relevant ADRs

- ADR-0007
- ADR-0021
- ADR-0022
- ADR-0023
- ADR-0025

### Allowed scope

- app composition;
- Riverpod dependency providers;
- concrete Infrastructure construction at composition boundary;
- lifecycle-safe dependency disposal.

### Non-goals

- service locator;
- GetIt;
- global mutable singleton;
- new repository abstraction;
- UI redesign.

### Definition of Done

- production composition can provide the Domain repository-backed Application behavior;
- Presentation does not import Infrastructure;
- Application does not import Infrastructure;
- provider override testing remains possible.

### Validation

- flutter analyze
- flutter test
- import-boundary scan
- git diff --check

### Result / evidence

Pending implementation.

Evidence:

- `DriftLifeOsTaskRepository` requires both a `ChangeIdGenerator` and a `deviceId` to construct a repository capable of persisting mutations;
- ADR-0025 is accepted and resolves the production identity composition gate;
- production `change_id` values use UUID v4 generated in Infrastructure through an injectable generator;
- production `device_id` uses UUID v4 generated once, persisted in application-support storage, and reused across launches;
- the composition root resolves the stable `device_id` before constructing syncable repositories;
- deterministic IDs remain injectable for tests.

The architecture gate is resolved. No CP-02 production implementation has been performed yet.

---

## CP-03 — Read Task collection

Status: pending

Depends on: CP-02

### Goal

Add the minimum Domain/Application/Infrastructure capability required to load the Task collection for the UI.

### Architecture gate

Before editing, determine the smallest repository/query contract consistent with current ADRs.

Do not add a generic Repository<T>.

### Allowed scope

- Domain repository contract if genuinely required;
- Application query/use case;
- Infrastructure query implementation;
- tests.

### Non-goals

- pagination unless required now;
- filters;
- sorting framework;
- search;
- projects/tags.

### Definition of Done

- Application can request persisted Tasks through a Domain-owned abstraction;
- Drift implementation returns mapped Domain Tasks;
- empty database behavior is defined and tested;
- layer boundaries remain valid.

### Validation

- Domain/Application tests as applicable;
- Infrastructure tests;
- flutter analyze
- flutter test
- git diff --check

### Result / evidence

Pending.

---

## CP-04 — Task list Presentation

Status: pending

Depends on: CP-03

### Goal

Display persisted Tasks through Riverpod and Application behavior.

### Allowed scope

- minimal Task list UI;
- loading state;
- empty state;
- bounded error state;
- Presentation controller/provider.

### Non-goals

- final visual design;
- complex navigation;
- filtering;
- search;
- animations.

### Definition of Done

- UI renders an empty Task state;
- UI renders persisted Tasks;
- Presentation imports neither Infrastructure nor Drift;
- widget tests use provider overrides where appropriate.

### Validation

- widget tests
- flutter analyze
- flutter test
- import-boundary scan
- git diff --check

### Result / evidence

Pending.

---

## CP-05 — Create Task vertical path

Status: pending

Depends on: CP-04

### Goal

Allow creation of a minimal Task from the UI and persist it through the accepted architecture.

### Architecture gate

Before implementation, verify how Entity ID, timestamps, version, lifecycle, source, change_id, and device_id are produced.

If production identity generation is not resolved by accepted ADRs, do not invent a package or lifecycle.

Mark blocked and request the smallest required decision.

### Allowed scope

- minimal creation UI;
- Domain creation behavior/factory if architecturally appropriate;
- Application use case;
- repository use;
- Infrastructure persistence;
- Outbox behavior;
- tests.

### Non-goals

- due dates;
- priority;
- tags;
- projects;
- recurrence;
- rich editor.

### Definition of Done

- user can enter a Task title;
- valid Task is created;
- Task persists;
- required Entity metadata is valid;
- Outbox entry is created atomically;
- UI reflects the created Task.

### Validation

- Domain/Application tests
- persistence tests
- widget tests
- flutter analyze
- flutter test
- git diff --check

### Result / evidence

Pending.

---

## CP-06 — Persistent completion toggle

Status: pending

Depends on: CP-05

### Goal

Connect the existing Task completion behavior to the real persisted Task list.

### Allowed scope

- existing Domain toggle behavior;
- existing Application stored toggle use case;
- Presentation refresh/state update;
- tests.

### Non-goals

- batch completion;
- undo framework;
- event sourcing;
- Sync.

### Definition of Done

- incomplete → complete persists;
- complete → incomplete persists;
- UI updates correctly;
- restart preserves state;
- each mutation creates the required Outbox change.

### Validation

- Application tests
- persistence tests
- widget tests
- flutter analyze
- flutter test
- git diff --check

### Result / evidence

Pending.

---

## CP-07 — Restart persistence verification

Status: pending

Depends on: CP-06

### Goal

Verify the MVP's core local-first promise across application/database restart.

### Allowed scope

- integration test or the smallest reliable equivalent;
- lifecycle corrections directly required by the test.

### Definition of Done

A Task written using production-equivalent database lifecycle can be loaded after closing and reopening the database/application persistence boundary.

Completion state and mandatory Entity metadata survive the reopen.

### Validation

- focused restart persistence test
- complete flutter test
- flutter analyze
- git diff --check

### Result / evidence

Pending.

---

## CP-08 — MVP vertical slice final audit

Status: pending

Depends on: CP-07

### Goal

Audit the complete local persistent Task vertical slice.

### Verify

- architecture boundaries;
- ADR compliance;
- production DB lifecycle;
- repository composition;
- Task read;
- Task create;
- Task completion;
- persistence across reopen;
- Outbox atomicity;
- generated Drift consistency;
- dependency hygiene;
- tests.

### Non-goals

Do not add the next feature during the audit.

### Definition of Done

- flutter analyze passes;
- flutter test passes;
- git diff --check passes;
- no unresolved defect exists in the implemented vertical slice;
- deferred architecture is documented;
- plan status becomes completed.

### Result / evidence

Pending.

---

# 6. Explicitly deferred beyond this milestone

Do not implement as part of this plan unless an accepted architecture decision explicitly moves it into scope:

- Task editing;
- Task deletion/lifecycle UI;
- advanced Task fields;
- navigation architecture beyond what is required;
- local search;
- backup/export;
- additional Entity types;
- AI provider integration;
- AI context engine;
- tool calling;
- embeddings;
- semantic search;
- production Sync;
- Sync Worker;
- network transport;
- server/API;
- conflict resolution;
- production device registration;
- Outbox acknowledgement/cleanup;
- network retry policy.

---

# 7. Resume checkpoint

This section is maintained by Codex.

Last checkpoint update: 2026-09-08 — ADR-0025 accepted; CP-02 returned to pending

Current checkpoint: CP-02

Current checkpoint status: pending

Last successful validation:

- Foundation flutter analyze: PASS
- Foundation flutter test: PASS — 16 tests
- Foundation git diff --check: PASS
- CP-01 focused lifecycle tests: PASS — 2 tests
- CP-01 flutter analyze: PASS — no issues
- CP-01 flutter test: PASS — 18 tests
- CP-01 import-boundary scan: PASS
- CP-01 git diff --check: PASS

Work completed in current checkpoint:

- CP-01 completed and validated;
- CP-02 marked active before implementation;
- CP-02 governing ADRs were read completely during the immediately preceding CP-01 audit;
- inspected the concrete repository constructor and existing Riverpod provider contracts;
- identified the missing production `change_id` and stable `device_id` lifecycle decision;
- read accepted ADR-0025 and confirmed that it resolves the CP-02 architecture gate.

Work remaining in current checkpoint:

- construct `DriftLifeOsTaskRepository` at the app composition boundary;
- expose repository-backed Application behavior through app-owned Riverpod overrides;
- add composition tests while preserving provider override testing;
- run flutter analyze, flutter test, the import-boundary scan, and git diff --check;
- mark CP-02 done only after its Definition of Done and validation pass.

Known blockers:

- none.

Architecture decision:

- ADR-0024 accepted: production DB uses OS application-support directory / `lifeos.db`; composition root owns one production database instance and closes it at lifecycle end.
- ADR-0025 accepted.
- Production `change_id` = UUID v4 generated in Infrastructure through an injectable generator.
- Production `device_id` = UUID v4 generated once, persisted in application-support storage, reused across launches.

Working-tree notes:

- repository was clean before this bookkeeping update;
- agent change: docs/exec-plans/active/lifeos-mvp.md CP-02 status, ADR-0025 evidence, and resume bookkeeping;
- no CP-02 production code or tests were changed;
- never assume this section is newer than repository evidence.

---

# 8. Plan-level completion criteria

This execution plan is complete only when:

- CP-01 through CP-08 are done;
- LifeOS uses a real production SQLite lifecycle;
- user can create a Task;
- persisted Tasks can be displayed;
- completion can be toggled and persisted;
- state survives persistence restart;
- mandatory Outbox behavior remains atomic;
- architecture boundaries remain compliant;
- flutter analyze passes;
- flutter test passes;
- git diff --check passes.

After completion, stop for user review.

Do not automatically begin the next milestone.
