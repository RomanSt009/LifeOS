# Dogfooding UX Improvements #1

Статус плана: completed

Текущий checkpoint: отсутствует — milestone завершён

Точная точка возобновления: отсутствует; следующий execution plan не создан.

## Goal

Устранить подтверждённые первым dogfooding UX-проблемы в существующем desktop Presentation: ограничить рост Relationships относительно Note editor, уплотнить только частые и однозначные действия, добавить локальные Task filters и сделать Home полезной точкой входа — без расширения Domain, persistence или navigation architecture.

## Architecture baseline

- Desktop Usability & Dogfooding Alpha завершён и принят.
- Shell использует Flutter SDK `NavigationRail` + `IndexedStack` и shell-local destination state.
- Presentation вызывает существующие Application boundaries через Riverpod wiring; production persistence создаётся только composition root.
- SQLite/Drift `schemaVersion == 3`; current Backup/Export writer использует format v3.
- Localization использует Flutter `gen_l10n` и ARB `en`/`ru`; новые пользовательские строки должны появляться во всех supported locales.
- Единственное исходное working-tree изменение — user-owned `.obsidian/workspace.json`; оно не относится к плану и не изменяется.

## Scope

- Compact frequent Presentation actions с локализованными tooltip/semantics.
- Bounded Note/Relationships layout с явным scroll ownership.
- Task `All / Open / Completed` filters при отдельном Trash lifecycle mode.
- Home quick actions к уже существующим функциям.
- Desktop responsive, keyboard, focus, accessibility и EN/RU regression.

## Explicit non-goals

- System tray, Windows notifications, background lifecycle и startup with Windows.
- Task `dueDate`, Today/reminder/timezone semantics, schema v4 и Backup format v4.
- Spellcheck, Unified/Note Search, AI, Sync, Workspace/Projects.
- New dependencies, routing package, global navigation framework, Dashboard или design system.
- Domain, Application business contract, repository, Drift, migration, Outbox или Backup changes.

## UI-density contract

1. **Primary content priority.** Note editor и Task list/content являются primary content. Secondary UI не должна бесконтрольно уменьшать их рабочую область.
2. **Scroll ownership.** Каждый потенциально растущий region имеет явного scroll owner; nested unbounded scrolling не вводится.
3. **Compact actions.** Icon-only допустим только для частых стандартных однозначных toolbar/row actions при наличии localized tooltip, semantic label, visible focus и keyboard/context alternative там, где это применимо. Destructive, ambiguous, retry и file operations сохраняют text label без отдельного доказательства обратного.
4. **Desktop targets.** Основной размер — `1280x800`; минимальный regression target — `640x600`. Mobile redesign не вводится.
5. **Accessibility/localization.** Keyboard reachability, focus, semantics, tooltip и parity ARB `en`/`ru` сохраняются.

## DFUX-01 — Baseline + UI-density contract

Статус: done

### Goal

Сверить production Presentation и tests с завершённым Alpha milestone, зафиксировать bounded UI-density contract и подтвердить отсутствие architecture blocker для DFUX-02.

### Relevant decisions

- ADR-0022 — layered Flutter architecture и Presentation ownership.
- ADR-0027 — localization остаётся Presentation concern.
- ADR-0030 — Note edit/content semantics.
- ADR-0032 — contextual Relationship semantics.
- ADR-0033 — Task/Note lifecycle, visibility и user mutation semantics.

### Allowed scope

Read-only audit, baseline validation и bookkeeping этого execution plan/guide.

### Explicit non-goals

Production/test changes и начало любого checkpoint кроме DFUX-02 после успешного internal gate.

### Definition of Done

- Current Task/Note/Relationship/Home behavior сверено с code/tests.
- `flutter analyze` и полный baseline `flutter test --reporter compact` проходят.
- UI-density contract и scope guards зафиксированы.
- Подтверждено, что DFUX work не требует Domain/Application business/persistence/schema/Backup/dependency/ADR changes.

### Validation

- `flutter analyze`
- `flutter test --reporter compact`
- Repository/Git reconciliation

### Result / evidence

Pre-flight выполнен на `main`, HEAD `cf27645c972479fb323af39130ca87f7ce705490`, upstream divergence `0 0`. Active plans до создания этого файла отсутствовали; единственное исходное изменение — user-owned `.obsidian/workspace.json`. Completed Alpha plan, ADR-0033 Accepted, `schemaVersion == 3` и `V3BackupExportEncoder` подтверждены.

Current behavior сверено: Tasks сохраняют active list, отдельный Trash, row/context-menu/keyboard targeting, completion/edit/delete/restore; Notes сохраняют sidebar/editor, dirty Save/Discard/Cancel, Trash, `Ctrl+N`/`Ctrl+S`; shared `RelatedEntitiesSection` сохраняет add/unlink confirmation и retry/error states; Home остаётся минимальным Alpha landing.

Baseline validation: `flutter analyze` PASS (`No issues found`); полный `flutter test --reporter compact` PASS (250 тестов).

Internal gate: **PASS**. DFUX-03/04/05/07 остаются bounded Presentation work. Для DFUX-02 достаточно явного optional Presentation layout contract на shared Related component; Domain, Application business contracts, persistence, schema, Backup, dependency и ADR changes не требуются. Материального противоречия docs/production и data-loss defect не обнаружено.

### Blocker

Отсутствует.

## DFUX-02 — Note/Relationships bounded layout

Статус: done

### Goal

Сохранить разумную рабочую область Note editor при любом поддержанном количестве Relationships, ограничив growing relationship list и назначив ему собственный scroll.

### Relevant decisions

- ADR-0022 — Presentation layout ownership.
- ADR-0027 — новые user-visible strings только через localization resources.
- ADR-0030 — Note editor/content behavior не меняется.
- ADR-0032/ADR-0033 — Relationship/lifecycle behavior не меняется.

### Allowed scope

`NotePage`, `RelatedEntitiesSection` и focused widget tests; локализация только при фактическом появлении нового текста.

### Explicit non-goals

Whole-page scrolling, split pane, draggable divider, global layout abstraction, Domain/Application/persistence/dependency changes и DFUX-03.

### Definition of Done

- Related header/actions остаются доступны.
- Relationship entries имеют bounded height и собственный scroll в Note context.
- Note editor остаётся primary `Expanded` region и сохраняет editing/focus/scroll/dirty/save behavior.
- `1280x800` и `640x600` не дают overflow; many-relationship fixture доказывает scroll до последнего элемента.
- Shared Task usage не изменено случайно; add/unlink/error/retry regressions проходят.

### Validation

- Focused Note/Relationship/Task widget tests.
- `dart format` изменённых handwritten Dart files.
- `flutter analyze`.
- Полный `flutter test --reporter compact`.
- Import/localization/routing/dependency/schema/Backup guards.
- `git diff --check`.

### Result / evidence

Current HEAD повторно подтвердил исходную проблему: Note editor является primary `Expanded`, а shared `RelatedEntitiesSection` после него строил все элементы обычным unbounded `Column`. Task использует тот же component внутри `ExpansionTile`.

Принят минимальный явный Presentation contract: `RelatedEntitiesSection.maxListHeight` optional. При отсутствии значения сохраняется прежний Task layout; Note передаёт bounded maximum и получает самостоятельный `ListView` только для relationship entries. Header и Add action остаются вне scroll. Note использует limit `160` в обычном editor width и `80` при локальном compact breakpoint `< 400`, чтобы на regression target сохранить primary editor.

Focused `640x600` fixture дополнительно обнаружил concrete `Delete Note + Save` footer overflow. Он исправлен в рамках того же layout scope: labels/semantics не менялись, wide layout сохраняет `Row`, compact editor использует wrapping footer. Icon-only policy DFUX-03 не реализовывалась.

Files changed: `lib/presentation/notes/note_page.dart`, `lib/presentation/relationships/related_entities_section.dart`, `test/presentation/relationships/related_entities_section_test.dart`; bookkeeping — этот plan и `docs/exec-plans/README.md`. Новых user-visible strings/ARB/generated localization changes нет.

Tests: added many-Relationship fixtures at `1280x800` and `640x600`, proving editor height > 100, bounded list, scroll to final Relationship, accessible Add/Unlink, editor focus/edit/dirty state and absence of rendering exceptions. Existing Task Related test now proves a populated shared default context. Existing zero/several/add/unlink/loading/error/retry/dirty/`Ctrl+S` coverage retained.

Validation: direct SDK `dart format` PASS for 3 changed handwritten Dart files. Focused Note/Relationship/Task suite PASS (49 tests); standalone Relationship suite PASS (8 tests). `flutter analyze` PASS (`No issues found`). Full `flutter test --reporter compact` PASS (252 tests). Domain/Application/Presentation import boundaries, localization boundary and routing dependency scans PASS. `pubspec.yaml`/`pubspec.lock` and generated Drift files have no diff; no dependency/codegen change. `schemaVersion == 3`; current writer remains `V3BackupExportEncoder`. `git diff --check` pending final bookkeeping check.

### Blocker

Отсутствует до architecture gate.

## DFUX-03 — Compact actions

Статус: done

### Goal

Применить UI-density contract к подтверждённым частым однозначным actions без потери clarity и accessibility.

### Relevant decisions

ADR-0022, ADR-0027, ADR-0033.

### Allowed scope

Presentation/localization/widget tests.

### Explicit non-goals

Blanket icon-only redesign, изменение destructive/file/retry semantics и DFUX-04.

### Definition of Done

Точный набор compact actions локализован, доступен мышью/keyboard/semantics и устойчив на desktop targets.

### Validation

Focused widget/localization/layout tests и standard plan checks.

### Result / evidence

Pre-flight подтвердил `main`, HEAD `5c9ac8dc0d9da0e54810c284f522ce1d8a3bd189`, upstream divergence `1 0`, единственный pre-existing diff — user-owned `.obsidian/workspace.json`. Baseline: `flutter analyze` PASS; focused Tasks/Notes/shell/localization/Relationships suite PASS (67 tests).

Аудит Tasks, Notes, Relationships, Search, Home и Settings/Backup подтвердил safe compact candidates: `New Note`, Task/Note Active↔Trash, `Add Relationship` и Task restore. Они переведены на standard Material `IconButton`/`IconButton.filled` с localized tooltip, explicit icon semantic label, native focus/keyboard activation и прежним disabled state. Существующие completion/edit/delete/Note restore/Search clear icon actions уже соответствовали policy. Save, Add Task, destructive confirmations, Retry, Search submit и Backup/Export/Restore остались text actions.

Existing click, context-menu, confirmation, `Ctrl+N`, `Ctrl+S`, Delete-key и narrow `640x600` regressions сохранены; EN/RU tooltip/semantic assertions добавлены. Focused Task/Note/Relationship suite PASS (49 tests). Internal gate PASS: только Presentation/tests, без user-visible string, Domain/Application, navigation architecture, dependency, schema, Backup и ADR changes.

## DFUX-04 — Task All/Open/Completed filters

Статус: done

### Goal

Добавить Presentation-local `All / Open / Completed` filters, сохранив Trash отдельным lifecycle mode и текущий deterministic order.

### Relevant decisions

ADR-0022, ADR-0027, ADR-0033.

### Allowed scope

Task Presentation/localization/widget tests.

### Explicit non-goals

Due-date/Today filters, repository query/index/schema changes, sorting expansion и DFUX-05.

### Definition of Done

Filters корректны при create/toggle/refresh, Trash независим, EN/RU и desktop layout проходят.

### Validation

Focused Task widget/localization tests и standard plan checks.

### Result / evidence

Данные подтверждены: ordinary controller загружает `active`, Trash controller — `deleted`, completion хранится в `LifeOsTask.isCompleted`, controller mutations обновляют list state без смены его порядка.

Добавлен typed Presentation enum `TaskCompletionFilter` и local filtering уже загруженного active list: All, Open (`!isCompleted`) и Completed (`isCompleted`). UI — Material `SegmentedButton`; Trash остаётся отдельным mode. При смене filter selection сбрасывается; Delete-key lookup дополнительно отклоняет Task, скрытую current filter. Create, completion/reopen, Delete, Trash и Restore перерисовывают тот же provider state без нового data path.

Добавлены EN/RU labels и truthful empty states в ARB; `flutter gen-l10n` PASS, generated files выпущены штатно. Tests доказывают default All, filtering, stable ordering, complete/reopen, create, delete/restore/Trash independence, stale-selection keyboard safety, RU и `640x600`. Focused Task suite PASS (25 tests); localization + DFUX-03 Relationship regression PASS (13 tests). Internal gate PASS: repository/API, Domain/Application, schema/index, Search architecture, dependency и ADR не затронуты.

## DFUX-05 — Home quick actions

Статус: done

### Goal

Добавить минимальные Home actions: New Task, New Note, Search и Backup/Settings через существующий shell.

### Relevant decisions

ADR-0022, ADR-0027, completed Desktop Shell/Navigation и Alpha plans.

### Allowed scope

Shell/Home/feature Presentation coordination, localization и widget/navigation tests.

### Explicit non-goals

Global router/event bus, Dashboard, Today/counts без отдельного доказательства, new persistence reads и DFUX-06.

### Definition of Done

Actions используют shell-local navigation, create intents сохраняют Task focus и Note dirty-draft guard, IndexedStack lifecycle не сломан.

### Validation

Focused Home/shell/Task/Note navigation tests и standard plan checks.

### Result / evidence

Home теперь содержит bounded text-labelled Quick actions: New Task, New Note, Search и Settings / Backup. Layout использует responsive `Wrap` с двумя колонками на wide content и одной на compact content; Dashboard, counts и новые data reads не добавлены.

Добавлен minimal typed Presentation-only `LifeOsFeatureCommand` с shell-owned monotonically increasing ID. Shell однократно передаёт `newTask`/`newNote` уже живущим в `IndexedStack` feature widgets; feature немедленно acknowledges ID, и shell очищает command. Global singleton, event bus, router и Application navigation state не введены.

New Task переводит в active Tasks, сбрасывает stale selection/errors и фокусирует existing creation field, но не создаёт Task. New Note вызывает existing dirty-draft guard до transition: Cancel сохраняет draft, Discard отказывается от него, Save дожидается existing save и только затем открывает empty editor. Command не повторяется при rebuild/navigation.

Добавлены EN/RU ARB strings и stable navigation label keys для точного widget targeting при одинаковом label Search на Home и NavigationRail. `flutter gen-l10n` PASS. Focused shell/Home suite PASS (15 tests); Task/Note/localization regression PASS (53 tests). Tests покрывают focus, keyboard activation, all dirty guard paths, one-shot semantics, IndexedStack state, Search/Settings navigation и RU `640x600` no-overflow.

Internal gate PASS: bounded Presentation-local contract достаточен; Domain, Application, Infrastructure, persistence, schema, dependency, global navigation architecture и ADR changes не требуются. Implementation остановлена до DFUX-06.

## DFUX-06 — Desktop responsive/accessibility regression

Статус: done

### Goal

Проверить milestone целиком при `1280x800` и `640x600`, EN/RU, keyboard/focus/tooltips/semantics.

### Relevant decisions

ADR-0022, ADR-0027.

### Allowed scope

Focused regression tests и минимальные Presentation fixes конкретных дефектов.

### Explicit non-goals

Mobile/tablet redesign, design system и новый product scope.

### Definition of Done

Нет overflow или недоступных critical actions; accessibility/localization contract доказан tests.

### Validation

Focused regression suite и standard plan checks.

### Result / evidence

Pre-flight: `main`, HEAD `ddf3ba6b81016869d04e2cad390d988e46c1b28c`, upstream divergence `0 0`; единственный pre-existing diff — user-owned `.obsidian/workspace.json`. `schemaVersion == 3`, composition writer — `V3BackupExportEncoder`.

Responsive regression matrix расширена на Home, Tasks active/Trash, Notes editor/Trash, Search и Settings при `1280x800` EN и `640x600` RU. Critical controls остаются hit-testable; rendering/overflow exceptions отсутствуют. Existing focused coverage сохраняет Task filters, Note/Relationship bounded scrolling, dirty-draft guard, keyboard activation и IndexedStack state.

Аудит semantics выявил один конкретный Presentation-дефект: tooltip-only icon actions completion/edit/delete Task, Note restore, Relationship unlink и Search clear не имели собственных явных localized icon semantic labels. Добавлены только labels из уже существующих localization resources; visual layout, action semantics и business contracts не менялись. Focused Task/Note/Relationship/Search/shell suite PASS (80 tests); полный Presentation suite PASS (99 tests). Новых строк, ARB/codegen, dependencies или architecture decisions не потребовалось. Internal acceptance gate: **PASS**.

## DFUX-07 — Final audit

Статус: done

### Goal

Провести финальный UI, architecture, localization, responsive и dependency/scope audit milestone.

### Relevant decisions

Все ADR, применимые к затронутым Presentation surfaces.

### Allowed scope

Audit и только минимальные исправления доказанных дефектов в принятом scope.

### Explicit non-goals

Следующий execution plan или новый feature scope.

### Definition of Done

Все milestone acceptance criteria имеют evidence; final validation зелёная; план перенесён в completed.

### Validation

Все relevant focused tests, `flutter analyze`, полный `flutter test`, localization/import/routing/dependency/schema/Backup guards и `git diff --check`.

### Result / evidence

Final UI/integration audit: **PASS**. Tasks сохраняют All/Open/Completed filters, отдельный Trash, create/edit/completion/delete/restore и deterministic provider order. Notes сохраняют bounded primary editor, dirty-draft guard, explicit save, Trash/Restore и bounded independently scrollable Relationships. Relationships, Search, Home quick actions и Settings/Backup сохраняют текущие feature contracts и shell-local `NavigationRail` + `IndexedStack` lifecycle.

Responsive/accessibility acceptance доказан при `1280x800` EN и `640x600` RU для Home, Tasks active/Trash, Notes editor/Trash, Search и Settings. Critical icon actions имеют localized tooltip/explicit semantics; text labels сохранены у destructive, retry, file и ambiguous actions. Keyboard/focus, context menus, dirty guards, inactive destination behavior и Search state regressions проходят.

Architecture audit: Domain/Application/Presentation import boundaries PASS; localization не выходит из Presentation; composition root остаётся владельцем database/repository lifecycle; routing dependency не добавлена. Domain/Application business contracts, Infrastructure, persistence, Search semantics, Outbox и Backup production code не менялись этим milestone.

Final validation: changed handwritten Dart format PASS (9 files, 0 further changes); focused DFUX-06 suite PASS (80 tests); Presentation suite PASS (99 tests); Domain/Application/Infrastructure/integration suite PASS (158 tests); `flutter analyze` PASS; полный `flutter test --reporter compact` PASS (261 tests). EN/RU ARB parity PASS (118/118); hardcoded Presentation literal scan PASS; localization sources/generated files unchanged в DFUX-06/07. Import/localization/routing scans PASS; `dart pub deps --style=compact` PASS; `pubspec.yaml`/`pubspec.lock` unchanged; generated Drift unchanged; `schemaVersion == 3`; current writer `V3BackupExportEncoder`; schema/Backup v4 отсутствуют; `git diff --check` PASS.

Documentation reconciliation: root README обновлён только для фактического Home quick-actions behavior; execution guide указывает отсутствие active plan и этот plan в completed. Deferred scope остаётся прежним: system tray/notifications/background startup, Task due-date/Today/reminders/timezone, Note/unified Search, AI, Sync, Projects/Workspace, mobile/tablet redesign, design system, router/deep links/history, schema/Backup v4 без отдельного requirement/gate.

Milestone завершён на `main`, HEAD `ddf3ba6b81016869d04e2cad390d988e46c1b28c`, upstream divergence `0 0`. Следующий execution plan не создан. `.obsidian/workspace.json` остаётся отдельным pre-existing user-owned изменением и этим milestone не изменялся.

## Validation strategy

1. Сначала запускать smallest relevant widget tests, затем полный suite.
2. Проверять оба desktop target размера без хрупких pixel-perfect assertions.
3. Не менять generated localization вручную; `flutter gen-l10n` запускать только при изменении ARB.
4. На каждом checkpoint подтверждать отсутствие Domain/Application business/persistence/schema/Backup/dependency drift.
5. Сохранять `.obsidian/workspace.json` как отдельное pre-existing user-owned изменение.

## Milestone acceptance criteria

- Note editor остаётся пригодным при большом количестве Relationships.
- Compact actions уменьшают горизонтальную плотность без потери clarity/accessibility.
- Tasks фильтруются по All/Open/Completed, а Trash остаётся отдельным lifecycle mode.
- Home предоставляет быстрый путь к существующим функциям без Dashboard/global router.
- `1280x800` и `640x600`, EN/RU, keyboard/focus/semantics проходят regression.
- Domain/Application business contracts, persistence, schema v3, Backup v3 и dependencies не изменены.

## Validation evidence — DFUX-03/04/05 combined run

- Formatting: direct Flutter SDK `dart format` PASS for 11 changed handwritten Dart files; no further changes required.
- Localization: `flutter gen-l10n` PASS after ARB edits; EN/RU parity PASS (118 user-facing keys in each locale); generated localization files changed only through generation.
- Focused DFUX-03: Task/Note/Relationship suite PASS (49 tests).
- Focused DFUX-04: Task suite PASS (25 tests); localization + Relationship compact regression PASS (13 tests).
- Focused DFUX-05: shell/Home suite PASS (15 tests); Task/Note/localization regression PASS (53 tests).
- Static/full: `flutter analyze` PASS (`No issues found`); full `flutter test --reporter compact` PASS (261 tests).
- Architecture: Domain import boundary PASS; Application import boundary PASS; Presentation has no Drift/SQLite/Infrastructure imports; localization remains outside Domain/Application/Infrastructure; routing dependency/import scan PASS.
- Dependency hygiene: `dart pub deps --style=compact` PASS; `pubspec.yaml` and `pubspec.lock` unchanged; no new dependency.
- Persistence guards: `schemaVersion == 3`; no schema v4/migration; generated Drift files unchanged; composition still uses `V3BackupExportEncoder`; no Backup v4.
- Git whitespace: `git diff --check` PASS after final plan bookkeeping (line-ending warnings only).
- Scope: no Domain/Application/Infrastructure, persistence, Backup, Search semantics or navigation architecture changes; `.obsidian/workspace.json` remains separate pre-existing user-owned work.

## Exact resume point

Milestone завершён. Active execution plan отсутствует; следующий plan не создан.
