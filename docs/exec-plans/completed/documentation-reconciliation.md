# LifeOS Documentation Reconciliation — план выполнения

Статус: completed

## Цель

Привести текущую документацию LifeOS в соответствие с фактическим repository state и поздними принятыми ADR, сохранив исторический контекст, vision и явно отложенный scope.

Milestone является docs-only: production code, tests, dependencies, generated files и `.obsidian/workspace.json` не изменяются.

## Источники истины

- `AGENTS.md`;
- текущий Git/repository state;
- ADR-0001 — ADR-0028 с приоритетом более поздних принятых решений;
- completed execution plans;
- текущий production code и tests как evidence implementation state.

## Общие ограничения

- не менять product architecture;
- не создавать новый product ADR без blocker;
- не начинать Notes, schema v2 или следующий product milestone;
- не менять `pubspec.yaml`, production code, tests или generated files;
- не объявлять formal LifeOS v1.0 boundary;
- не переписывать исторические решения так, будто их не существовало;
- не выполнять commit или push.

---

## DR-01 — Documentation drift inventory

Статус: done

### Goal

Повторно сопоставить root/docs/ADR/execution-plan statements с текущим repository state и классифицировать подтверждённый drift до редактирования project documents.

### Definition of Done

- проверены root README, vision/product/architecture/database/UI/roadmap docs, AGENTS и все ADR;
- inventory содержит current statement, repository reality, classification и planned action;
- repository и Git state зафиксированы.

### Validation

- recursive documentation inventory;
- ADR numbering/status scan;
- Git status/history;
- `lib/` и `test/` inventory.

### Drift inventory

| ID | Document | Current statement | Repository reality | Classification | Planned action |
|---|---|---|---|---|---|
| DRIFT-01 | `README.md` | Код приложения ещё не реализован; версия проекта `0.1.0` | Работает Flutter desktop implementation; `pubspec.yaml` содержит `1.0.0+1` | STALE | Кратко обновить current status без объявления formal 1.0 |
| DRIFT-02 | `docs/00-vision/vision.md` | Production code пока не реализуется | Завершены четыре implementation milestones | STALE | Добавить current-state clarification, сохранив vision |
| DRIFT-03 | `docs/00-vision/lifeos_core_concept.md` | Vision описывает Workspace как сердце LifeOS | Workspace не реализован и его точный Domain status не определён | FUTURE | Добавить явную current-state note; не менять vision |
| DRIFT-04 | `docs/01-product/product-overview.md` | Перечисляет широкий продукт без current implementation boundary | Production поддерживает только Task Entity | FUTURE | Добавить current-state clarification |
| DRIFT-05 | ADR-0002 и `AGENTS.md` | GoRouter назван выбранным stack | Production shell использует Flutter SDK `NavigationRail` + `IndexedStack`; dependency отсутствует | REFINED | Сохранить preliminary history и сослаться на Desktop Shell plan; GoRouter не считать текущей обязательной dependency |
| DRIFT-06 | ADR-0002 | Freezed/json_serializable перечислены как выбранный stack | Packages отсутствуют, текущим моделям не потребовались | HISTORICAL | Уточнить, что это preliminary/optional choices, вводимые только при необходимости |
| DRIFT-07 | ADR-0007/0022 | Concrete DI framework оставался open | Используются manual composition + constructor injection + Riverpod overrides | REFINED | Добавить current implementation note |
| DRIFT-08 | Technical/UI/roadmap docs и `lifeos-mvp.md` | `MVP` обозначает разные scopes | Completed plan — первый Task vertical slice; широкий product MVP не завершён | REFINED | Явно разделить термины |
| DRIFT-09 | `pubspec.yaml`, README и roadmap | `1.0.0+1`, `0.1.0` и отсутствие release criteria | Package version существует; formal LifeOS v1.0 boundary не документирована | UNRESOLVED | Не менять pubspec; добавить release clarification |
| DRIFT-10 | `lib/app/dependencies.dart` | Application version отдельно задан строкой | Значение вручную дублирует `pubspec.yaml` | CONSISTENT | Записать confirmed follow-up debt; code не менять |
| DRIFT-11 | Architecture/database open questions | SQLite package/ORM остаются нерешёнными | Drift + SQLite приняты ADR-0021 и реализованы | STALE | Пометить `Resolved by ADR-0021` |
| DRIFT-12 | Architecture/database open questions | Production DB location/lifecycle не отражены | Решены ADR-0024 | STALE | Добавить ссылку на ADR-0024 |
| DRIFT-13 | Database/sync open questions | Device/change identity не отражены | Решены ADR-0025; Entity defaults — ADR-0026 | STALE | Добавить traceability и сохранить remote identity scope unresolved |
| DRIFT-14 | UI/architecture docs | Localization не отражена в current state | en/ru + English fallback приняты ADR-0027 и реализованы | STALE | Добавить current-state note |
| DRIFT-15 | Backup/database open questions | Backup format/Restore semantics названы open | v1 contract принят ADR-0028 и реализован | STALE | Пометить resolved for v1; future versions остаются deferred |
| DRIFT-16 | Early schema docs | Conceptual Relationships/files/sync tables могут выглядеть как current schema | Production schema v1 содержит только `entities`, `tasks`, `outbox` | REFINED | Добавить explicit conceptual/current schema distinction |
| DRIFT-17 | ADR-0001 — ADR-0022 | Статус «Предварительно принято» | Поздние ADR и implementation конкретизируют часть решений | HISTORICAL | Не массово менять статусы; добавить refinement notes только там, где нужен current context |
| DRIFT-18 | Sync/AI docs | Описывают целевые architectures | Sync и AI production capabilities отсутствуют | FUTURE | Сохранить как future architecture и явно отделить от current state |

### Result / evidence

PASS. Проверены root docs, весь `docs/`, ADR-0001 — ADR-0028, четыре completed plans, пустой initial `active/`, `pubspec.yaml`, структуры `lib/` и `test/`. Нумерация ADR непрерывна. На исходном `HEAD` `f65d842517deb98d412a951afed17eda62dd6924` единственным working-tree change был пользовательский `.obsidian/workspace.json`.

---

## DR-02 — Root/project status reconciliation

Статус: done

### Goal

Обновить краткое описание фактически реализованного LifeOS в root README и устранить stale current-status statement в vision без изменения vision.

### Definition of Done

- README перечисляет реализованные и отсутствующие capabilities без превращения в roadmap;
- vision сохраняет историческую цель и содержит честное current-state clarification.

### Result / evidence

PASS. Root `README.md` теперь кратко отражает working Windows-first Flutter implementation, реализованные capabilities и отсутствующие Sync/AI/Notes/Projects/Relationships/Documents. Package version отделена от formal release criteria. В `vision.md`, `lifeos_core_concept.md` и `product-overview.md` добавлены current-state clarifications; исходная долгосрочная vision сохранена.

---

## DR-03 — Architecture/technology decision reconciliation

Статус: done

### Goal

Различить ранние preliminary stack choices и фактический production stack, особенно Flutter SDK navigation вместо GoRouter.

### Definition of Done

- navigation divergence объяснён без изменения implementation;
- текущие и optional/deferred packages описаны фактически;
- historical ADR context сохранён.

### Result / evidence

PASS. `AGENTS.md`, ADR-0002, ADR-0007, ADR-0022 и `technical-architecture.md` теперь различают preliminary stack и current production choices. Текущая navigation зафиксирована как Flutter SDK `NavigationRail` + `IndexedStack` + shell-local state; GoRouter не используется и может быть пересмотрен только по concrete future requirements. Freezed/json_serializable не выдаются за установленные dependencies. Manual composition, Riverpod boundary и Drift/SQLite отражены фактически. Historical ADR statuses и исходные решения сохранены; новый ADR не требуется.

---

## DR-04 — MVP/version/release terminology reconciliation

Статус: done

### Goal

Разделить Task vertical-slice milestone, широкий product MVP, package version metadata и отсутствующую formal v1.0 boundary.

### Definition of Done

- термины больше не выдают текущий narrow milestone за полный product MVP;
- package version не объявляется release criterion;
- ручное дублирование application version записано как follow-up debt без code change.

### Result / evidence

PASS. Root README, roadmap, technical/UI architecture и completed `lifeos-mvp.md` теперь явно различают первый Task vertical-slice milestone и широкую future product MVP boundary. `pubspec.yaml` не изменён; `1.0.0+1` обозначен только как package/application metadata. Зафиксировано, что formal LifeOS v1.0 release criteria не документированы. Ручное повторение версии в `lib/app/dependencies.dart` остаётся confirmed follow-up technical debt без production-code change.

---

## DR-05 — Historical/open-question reconciliation

Статус: done

### Goal

Пометить исторические open questions, позже закрытые ADR-0021 — ADR-0028, и отделить conceptual schema от production schema v1.

### Definition of Done

- resolved questions имеют traceability к поздним ADR;
- частично unresolved вопросы сохраняют остаточный scope;
- future tables не описаны как существующие production tables.

### Result / evidence

PASS. В early architecture/database/sync docs и ADR-0005/0006/0007/0011/0017/0020/0021/0022 добавлены малые historical-resolution notes. Они ссылаются на ADR-0021 — ADR-0028 и не удаляют исходные open questions. Conceptual/future schema явно отделена от production schema v1 (`entities`, `tasks`, `outbox`). Drift, production DB lifecycle, identity/defaults, localization и Backup/Restore v1 больше не выглядят нерешёнными; remote Sync, conflicts, encryption, files, FTS/semantic Search и future schema остаются открытыми.

---

## DR-06 — Cross-document consistency audit

Статус: done

### Goal

Повторно проверить изменённые документы на согласованное описание current implementation и future vision.

### Definition of Done

- current/future distinction согласован;
- ссылки и пути проверены;
- новые противоречия не внесены.

### Result / evidence

PASS. Совместно проверены все изменённые документы. Current implementation согласован как Windows-first Flutter desktop, Riverpod, layered architecture, Drift/SQLite, единственная production Domain Entity Task, destinations Home/Tasks/Search/Settings, Task-specific Search, en/ru localization, local device identity, Outbox foundation и Backup/Export/Restore v1. Future vision не выдаётся за implementation. Markdown links и ADR references проходят scan; исправлена stale wiki-link на `docs/04-ai/ai-architecture.md`. Sync и AI явно отсутствуют.

---

## DR-07 — Final documentation audit

Статус: done

### Goal

Завершить docs-only milestone, подтвердить отсутствие production changes и зафиксировать factual validation.

### Definition of Done

- DR-01 — DR-06 выполнены;
- documentation/reference/stale/reference/path scans проходят;
- `git diff --check` проходит;
- `lib/`, `test/`, pubspec/lock и generated files не изменены;
- план перенесён в `completed/`, а `active/` снова пуст.

### Result / evidence

PASS. Финальный docs-only audit подтвердил:

- root README и vision/product clarifications соответствуют repository reality;
- navigation divergence объяснён без изменения production navigation или нового ADR;
- Task vertical-slice MVP, product-wide MVP, package version и отсутствующая formal v1.0 boundary разделены;
- preliminary ADR-0001 — ADR-0022 и их historical statements сохранены;
- resolved open questions имеют traceability к ADR-0021 — ADR-0028;
- conceptual schema не выдаётся за production schema v1;
- Sync/AI/Notes/Projects/Documents/Relationships и дополнительные платформы остаются future, а не implemented capabilities;
- stale current-state scan: PASS;
- ADR reference scan: PASS, все 28 ADR identifiers разрешаются;
- Markdown local-reference scan: PASS;
- Obsidian wiki-link scan: PASS после исправления ссылки на `ai-architecture`;
- execution-plan consistency scan: PASS;
- `git diff --check`: PASS, whitespace errors отсутствуют; вывод содержит только informational LF/CRLF warnings;
- production scope guard: PASS — `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, `l10n.yaml`, generated и platform files не изменены;
- Flutter tests/analyze, code generation и dependency resolution не запускались, поскольку milestone docs-only.

Confirmed follow-up debt без изменения code: `lifeOsApplicationVersion` вручную повторяет package version. Нерешёнными остаются formal LifeOS v1.0 criteria, точная Domain-семантика Workspace, schema migration beyond v1, contracts будущих Entity/Relationships, remote Sync/auth/conflicts, encryption/key management, unified/semantic Search и AI implementation. Они не блокируют documentation reconciliation и требуют будущих product/architecture gates.

Новый ADR для этого milestone не потребовался.

Итоговое repository state:

- `HEAD`: `f65d842517deb98d412a951afed17eda62dd6924` (`docs: complete backup export milestone`);
- branch/upstream: `main` / `origin/main`, ahead `0`, behind `0`;
- `docs/exec-plans/active/` пуст; этот план находится в `docs/exec-plans/completed/documentation-reconciliation.md`;
- `docs/exec-plans/README.md` сообщает, что active primary plan отсутствует;
- working tree содержит только перечисленные documentation changes и исходный пользовательский `M .obsidian/workspace.json`;
- commit и push не выполнялись.

---

# Точка возобновления

Resume point: milestone completed. Активный основной execution plan отсутствует. Рекомендуемое следующее действие — обсудить Notes + schema-v2 milestone, но не создавать и не начинать его автоматически.

# Состояние выполнения плана

Статус: completed
