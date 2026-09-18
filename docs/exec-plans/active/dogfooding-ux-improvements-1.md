# Dogfooding UX Improvements #1

Статус плана: active

Текущий checkpoint: DFUX-03 — Compact actions

Точная точка возобновления: DFUX-03 — Compact actions; checkpoint не начат.

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

Статус: pending

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

Не начат.

## DFUX-04 — Task All/Open/Completed filters

Статус: pending

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

Не начат.

## DFUX-05 — Home quick actions

Статус: pending

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

Не начат.

## DFUX-06 — Desktop responsive/accessibility regression

Статус: pending

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

Не начат.

## DFUX-07 — Final audit

Статус: pending

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

Не начат.

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

## Exact resume point

DFUX-03 — Compact actions. DFUX-03 не начат в этом run.
