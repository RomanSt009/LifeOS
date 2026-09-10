# LifeOS — Agent Instructions

## 1. Project Overview

LifeOS is a long-term, cross-platform personal operating system application.

The primary target platform is Windows desktop.

Potential future platforms:

- macOS
- Linux
- Android
- iOS
- Web

The project is currently in the early implementation stage.

The repository contains:

- architectural documentation;
- ADRs;
- Flutter project skeleton;
- initial Windows application target.

Do not assume that undocumented functionality already exists.

---

## 2. Source of Truth

The architecture and important technical decisions are documented in:

```text
docs/adr/
````

ADR documents are the primary source of truth for architectural decisions.

Before making an architectural or structural change:

1. Identify the relevant ADR.
2. Read the relevant ADR completely.
3. Check whether the proposed change conflicts with an existing decision.
4. If there is a conflict, stop and explain the conflict before modifying code.

Do not silently override an ADR.

Do not rewrite or modify ADR documents unless the user explicitly asks for it.

If an architectural decision must change, propose a new ADR or an ADR amendment instead of silently changing the implementation.

---

## 3. Architecture

LifeOS follows a layered, domain-centric architecture.

The main dependency direction is:

```
Presentation
     ↓
Application
     ↓
Domain
     ↑
Infrastructure
```

The Domain layer is the architectural core.

Domain must not depend on:

- Flutter
- Flutter widgets
- Riverpod
- GoRouter
- Drift
- SQLite implementation details
- AI providers
- synchronization providers
- platform-specific APIs

Infrastructure may depend on Domain abstractions.

Repository interfaces belong to the appropriate abstraction layer defined by the ADRs.

Repository implementations belong to Infrastructure.

Application coordinates use cases and application-level workflows.

Presentation contains UI and presentation concerns.

The application composition root is responsible for dependency wiring.

Do not introduce dependencies between layers that violate the documented architecture.

---

## 4. Flutter Technology Stack

Flutter is the primary UI framework.

Dart is the primary programming language.

The currently selected supporting technologies include:

- Riverpod — state management
- GoRouter — navigation
- SQLite + Drift — local persistence
- Freezed — immutable/domain-support models where appropriate
- json_serializable — serialization where appropriate

Do not add a package merely because it is popular or convenient.

Before adding a dependency:

1. Explain why it is needed.
2. Check whether existing project capabilities can solve the problem.
3. Check compatibility with the documented architecture.
4. Prefer the smallest reasonable dependency set.
5. Do not add dependencies without user approval when the dependency materially affects architecture.

Avoid dependency bloat.

---

## 5. Local-First Principle

LifeOS follows a local-first architecture.

Local application state and local persistence are primary.

Network services, synchronization, AI providers, and external systems must not become implicit requirements for basic local application functionality unless explicitly documented by an ADR.

Do not introduce architecture that assumes permanent network connectivity.

---

## 6. Domain Rules

Domain logic must remain independent from infrastructure and UI.

Prefer:

- entities;
- value objects;
- domain services where justified;
- repository abstractions;
- explicit business rules.

Avoid putting business rules inside:

- Flutter widgets;
- UI callbacks;
- Riverpod providers;
- database adapters;
- API clients.

Presentation should not contain domain business logic.

Infrastructure should not contain business rules that belong to Domain.

---

## 7. Feature Development

When implementing a feature:

1. Understand the relevant domain requirements.
2. Check existing ADRs.
3. Identify the appropriate layer.
4. Define or reuse domain abstractions where necessary.
5. Implement application/use-case logic.
6. Implement infrastructure only where required.
7. Implement presentation last or after the necessary application contracts exist.
8. Add tests.
9. Run validation commands.

Prefer vertical slices over creating large amounts of unused architecture.

Do not create empty abstractions or speculative systems without a concrete use case.

---

## 8. Project Structure

The project should evolve toward the structure documented in ADR-0022.

The expected architectural areas include:

```
lib/
├── app/
├── presentation/
├── application/
├── domain/
└── infrastructure/
```

Feature organization may be introduced where justified by the architecture.

Do not create large numbers of directories merely to make the project look architectural.

Every new directory should have a clear responsibility.

---

## 9. UI and Presentation

Presentation code is responsible for:

- widgets;
- screens/pages;
- presentation state;
- user interaction;
- navigation integration;
- visual composition.

Do not place database queries directly inside widgets.

Do not place network calls directly inside widgets.

Do not place business rules directly inside widgets.

Keep widgets focused on presentation and user interaction.

---

## 10. State Management

Riverpod is the selected state-management solution.

Use Riverpod where application or presentation state requires reactive management.

Do not introduce another state-management framework without explicit architectural justification.

Avoid creating providers for every trivial value.

Providers should represent meaningful application or presentation dependencies/state.

---

## 11. Navigation

GoRouter is the selected navigation solution.

Navigation configuration belongs to the appropriate application/presentation composition layer.

Do not introduce another routing framework.

Do not scatter navigation configuration throughout unrelated widgets.

---

## 12. Persistence

SQLite with Drift is the selected local persistence stack.

Database-specific code belongs to Infrastructure.

Domain code must not depend directly on Drift-generated classes.

Avoid leaking database implementation details into Domain.

Database schema changes must be handled carefully and consistently with the persistence ADRs.

Do not modify persistence architecture casually.

---

## 13. AI Architecture

AI providers are infrastructure concerns.

The application must depend on stable internal abstractions rather than directly depending on a specific AI provider wherever the architecture requires provider independence.

Do not couple Domain logic directly to an AI vendor SDK.

Changing the AI model or provider should not require rewriting the Domain layer.

Do not add an AI SDK simply to experiment unless the experiment requires it.

---

## 14. Synchronization

Synchronization is an infrastructure/application concern.

Do not make synchronization assumptions part of core Domain logic unless explicitly required by an ADR.

Conflict resolution must follow the documented synchronization architecture.

Do not invent synchronization behavior when the relevant ADR does not define it.

If the existing documentation is insufficient, report the gap before implementing a significant synchronization mechanism.

---

## 15. Security and Privacy

Treat user data as sensitive application data.

Do not log:

- secrets;
- API keys;
- authentication tokens;
- private user content unnecessarily.

Do not hardcode secrets into source code.

Do not commit credentials or API keys.

Use appropriate configuration mechanisms for secrets.

If a task appears to require exposing credentials or private data, stop and ask for clarification.

---

## 16. Git Rules

Git history is important for LifeOS.

Do not create commits unless explicitly requested by the user.

Do not push to remote repositories unless explicitly requested.

Do not force-push.

Do not reset, rebase, or rewrite history unless explicitly requested.

Before significant changes:

```
git status
```

After changes:

```
git diff
git status
```

Before committing, verify that:

- only intended files changed;
- generated files are handled correctly;
- no secrets are present;
- documentation changes are intentional.

Never hide unrelated user changes.

If the working tree already contains user modifications, preserve them.

---

## 17. File Safety

Do not delete files unless deletion is explicitly required.

Do not rename large groups of files without explaining the impact.

Do not overwrite user-authored documentation unnecessarily.

Do not modify `.obsidian/` files unless the task explicitly concerns Obsidian configuration.

Do not modify ADR files during ordinary implementation work.

Do not modify unrelated files simply to "clean up" the repository.

---

## 18. Working With Existing Changes

The working tree may contain changes made by the user or by development tools.

Before modifying files:

1. Inspect `git status`.
2. Inspect relevant diffs when necessary.
3. Preserve unrelated changes.
4. Never assume that an uncommitted change was created by the agent.

Do not revert changes simply because they are unexpected.

Ask the user when ownership or intent is unclear.

---

## 19. Generated Files

Do not manually edit generated Flutter or code-generation output unless there is a specific documented reason.

Prefer modifying the source/configuration that generates the file.

After generation, verify the resulting diff.

---

## 20. Testing and Validation

After making code changes, run the smallest relevant validation first.

For general Flutter changes:

```
flutter analyze
```

For tests:

```
flutter test
```

For Windows application changes when appropriate:

```
flutter run -d windows
```

Do not claim that code works without performing the appropriate validation when the environment allows it.

If a command fails:

1. Report the failure.
2. Explain the likely cause.
3. Do not hide or ignore the failure.
4. Do not make unrelated changes merely to make the command pass.

---

## 21. Development Workflow

For non-trivial tasks, use this workflow:

```
Understand task
      ↓
Inspect repository
      ↓
Read relevant ADRs
      ↓
Explain implementation plan
      ↓
Implement smallest reasonable change
      ↓
Run validation
      ↓
Inspect diff
      ↓
Report result
```

Do not immediately start modifying files for a non-trivial request.

For small, unambiguous changes, the planning step may be brief.

---

## 22. Architectural Restraint

Avoid speculative architecture.

Do not implement systems merely because they may be useful in the future.

Examples:

- do not build a complete sync engine before sync functionality is needed;
- do not build an AI orchestration framework before AI use cases exist;
- do not add multiple database abstraction layers without a concrete reason;
- do not create dozens of empty feature modules;
- do not add dependencies "just in case".

Prefer the smallest implementation that satisfies the current requirement while preserving the documented architecture.

---

## 23. ADR Discipline

ADR documents describe decisions, not implementation details.

When an implementation reveals a genuine architectural problem:

1. Identify the relevant ADR.
2. Explain the problem.
3. Propose alternatives.
4. Ask the user before changing the architecture.
5. If the decision changes, document the new decision through the ADR process.

Never silently invalidate an existing ADR through code.

---

## 24. Communication

When reporting work:

- be concise;
- clearly distinguish completed work from proposed work;
- mention files changed;
- mention validation performed;
- mention failures honestly;
- identify architectural concerns;
- do not claim success without verification.

When there are multiple reasonable implementation choices, explain the trade-offs and recommend one.

---

## 25. Current Project Stage

LifeOS is currently transitioning from architectural documentation to implementation.

Current state:

```
Architecture documentation
        ↓
Flutter project skeleton
        ↓
Windows build verified
        ↓
Implementation begins
```

The current Flutter project is intentionally minimal.

Do not interpret missing functionality as an error.

The project should be developed incrementally.

---

## 26. First Implementation Principle

The first implementation tasks should establish the minimum viable application foundation.

Do not immediately implement all documented subsystems.

Prioritize:

1. application bootstrap;
2. project structure;
3. dependency wiring;
4. navigation foundation;
5. state-management foundation;
6. first domain/application feature;
7. persistence for the first real feature;
8. tests.

Expand the architecture only as real features require it.

---

## 27. Agent Behavior

The agent must:

- read before modifying;
- prefer minimal changes;
- respect ADRs;
- preserve user changes;
- avoid unnecessary dependencies;
- avoid speculative architecture;
- validate changes;
- explain significant decisions;
- never hide failures;
- never commit or push without explicit instruction.

When uncertain, ask rather than guessing.

The goal is not to maximize the amount of code produced.

The goal is to build a maintainable LifeOS architecture incrementally and correctly.

---
## 28. Autonomous execution workflow

LifeOS may use repository-backed execution plans for multi-step implementation work.

### Execution plan location

Active execution plans live under:

`docs/exec-plans/active/`

Before starting autonomous or continuation work, inspect that directory.

If exactly one active execution plan exists, use it unless the user explicitly names another plan.

The execution plan is the persistent source of truth for:

- current milestone;
- completed checkpoints;
- current checkpoint;
- next ready checkpoint;
- validation state;
- known blockers;
- deferred work;
- decisions that require user input.

Do not rely on conversation history alone to determine progress.

### Starting or continuing work

When instructed to start or continue the active execution plan:

1. Read `AGENTS.md`.
2. Read the active execution plan completely.
3. Read every ADR referenced by the current checkpoint.
4. Inspect `git status --short --branch`.
5. Inspect the relevant existing implementation and tests.
6. Reconcile the execution plan with the actual repository state.
7. Select only the next ready unfinished checkpoint.
8. Perform its architecture gate before editing.
9. Implement the smallest complete vertical change for that checkpoint.
10. Run the checkpoint validation.
11. Update the execution plan with factual results.
12. Continue to the next ready checkpoint only when:
    - the previous checkpoint is complete;
    - validation passes;
    - no unresolved architecture decision exists;
    - continuing does not require unsafe assumptions.

Repository state and accepted ADRs take precedence over stale execution-plan text.

Never mark work complete merely because the plan says it should be complete.

### Checkpoint discipline

Keep checkpoints small enough that each checkpoint can normally be:

- understood independently;
- implemented in one bounded work unit;
- validated independently;
- safely resumed after interruption.

For every checkpoint, maintain:

- Status: pending / active / blocked / done
- Goal
- Relevant ADRs
- Allowed scope
- Explicit non-goals
- Definition of Done
- Validation
- Result / evidence
- Blocker, when applicable

Set a checkpoint to `active` before implementation.

Set it to `done` only after its Definition of Done is satisfied and required validation succeeds.

If interrupted by usage limits, tool failure, permission boundary, IDE shutdown, or user stop, leave the checkpoint as `active` and record the latest factual state before stopping whenever possible.

Do not mark partially completed work as `done`.

### Resume protocol

After an interrupted session:

1. Read the active execution plan.
2. Inspect Git status and diff.
3. Inspect the files associated with the `active` checkpoint.
4. Determine which planned actions actually completed.
5. Do not repeat completed destructive or state-changing actions unnecessarily.
6. Continue from the first incomplete action.
7. Re-run validation appropriate to the final state.
8. Update the checkpoint evidence.

If execution-plan state and repository state disagree, stop and reconcile them from repository evidence rather than guessing.

### Architecture gates

Stop before implementation when the next step requires an architectural decision not already resolved by accepted ADRs.

Record the checkpoint as `blocked` and document:

- the exact unresolved question;
- relevant ADRs;
- why proceeding would require guessing;
- the smallest decision needed from the user.

Do not create a temporary architecture merely to continue autonomous execution.

### Failure handling

Do not skip a failing checkpoint and continue with later dependent work.

For a validation failure:

1. determine whether it was caused by the current checkpoint;
2. attempt only a bounded fix supported by existing architecture;
3. validate again;
4. if resolution requires an architecture decision or speculative redesign, mark the checkpoint `blocked` and stop.

### Scope control

Autonomous execution does not grant permission for unrelated cleanup.

Do not use an execution plan as permission to:

- redesign unrelated architecture;
- mass rename files;
- mass format unrelated code;
- replace selected technologies;
- introduce speculative abstractions;
- modify accepted ADRs silently;
- modify user-owned unrelated changes;
- implement later milestones early.

Follow the existing Git safety rules in this file at all times.

### Git during autonomous execution

The execution plan is a progress mechanism, not permission to publish changes.

Unless the user explicitly grants a different policy:

- do not commit;
- do not push;
- do not rewrite history;
- do not reset or clean user work.

The agent may update the active execution-plan file as part of checkpoint bookkeeping.

### Completion

When all checkpoints in an active execution plan are complete:

1. run the plan-level final validation;
2. update the plan status to `completed`;
3. record final validation evidence;
4. stop for user review.

Do not automatically begin a new execution plan.

---

## 29. Localization

LifeOS user-visible Presentation strings must come from localization resources.

Presentation must not introduce new hardcoded user-facing strings when an appropriate localized resource can be used.

Internal identifiers, debug messages, log messages, test descriptions, database values, and Domain enum values are not automatically localized.

Domain, Application, and Infrastructure layers must not depend on Flutter localization APIs.

Localization remains a Presentation concern.

When adding a new user-visible string, update every supported locale resource in the same change.
