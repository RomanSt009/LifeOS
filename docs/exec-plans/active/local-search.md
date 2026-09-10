# LifeOS Local Search — план выполнения

Статус: active

## Цель

Реализовать первый настоящий local-first поиск по уже существующим Tasks, не создавая преждевременную универсальную поисковую подсистему.

После завершения milestone пользователь должен иметь возможность:

- открыть Search из desktop shell;
- ввести текстовый запрос;
- получить локально найденные Tasks из текущей SQLite database;
- использовать поиск без сети, аккаунта, AI или внешнего сервиса;
- работать с English и Russian интерфейсом.

## Архитектурная основа

Реализация должна соответствовать:

- `AGENTS.md`;
- ADR-0005 — local-first data architecture;
- ADR-0006 — database schema и постепенное развитие Search;
- ADR-0007 — dependency injection и composition root;
- ADR-0010 — security boundary пользовательских данных;
- ADR-0012 — общая Search Architecture;
- ADR-0015 — отделение deterministic keyword search от semantic search;
- ADR-0016 — Domain Entity, lifecycle и repository abstractions;
- ADR-0017, ADR-0020 и ADR-0021 — controlled repository queries, SQLite/Drift и обоснованные индексы;
- ADR-0022 — Flutter project architecture;
- ADR-0024 — production database lifecycle;
- ADR-0027 — localization strategy.

Сохраняется направление зависимостей:

```text
Presentation -> Application -> Domain
Infrastructure -> Domain abstractions
```

Production persistence создаётся и закрывается только composition root в `app/`.

## Scope milestone

- keyword search только по существующим `LifeOsTask`;
- поиск по `title`;
- локальное чтение из существующей SQLite database через Drift repository implementation;
- Application use case для координации запроса;
- Search destination в существующей desktop shell;
- Presentation state и локализованный English/Russian UI;
- focused, architecture-boundary и persistence tests.

## Явно не входит

- semantic search, vector search, embeddings и hybrid ranking;
- AI-assisted search и удалённый поиск;
- fuzzy matching, typo correction и query expansion;
- поиск по внешним файлам, OCR или PDF;
- Notes, Projects и другие ещё не реализованные Entity types;
- command palette, keyboard shortcut и search history;
- deep links, URL routing и новый router package;
- background indexing или отдельная search database;
- отдельный `SearchEngine`, `SearchRepository`, `SearchProvider` или универсальная `SearchResult` model без второго реального типа данных;
- FTS5, schema migration и новые indexes без подтверждённой необходимости;
- изменение Task write path, Outbox или sync behavior.

---

# Checkpoints

## LS-01 — Аудит текущего состояния и architecture gate

Статус: done

### Цель

Сверить ADR, Git, текущий Task vertical slice и desktop shell; определить минимальный контракт и точную семантику первого поиска без изменения production-кода.

### Relevant ADRs

- ADR-0005;
- ADR-0006;
- ADR-0007;
- ADR-0010;
- ADR-0012;
- ADR-0015;
- ADR-0016;
- ADR-0017;
- ADR-0020;
- ADR-0021;
- ADR-0022;
- ADR-0024;
- ADR-0027.

### Разрешённый scope

- read-only аудит ADR, кода, tests, dependency manifests и Git;
- перенос завершённого Desktop Shell plan в `completed/`;
- создание этого execution plan и обновление `docs/exec-plans/README.md`;
- фиксация минимальных решений и последующих checkpoints.

### Явно не входит

- изменение файлов под `lib/` или `test/`;
- добавление Search destination;
- изменение repository contracts или schema;
- реализация LS-02 и последующих checkpoints.

### Architecture gate

Определить:

- какие данные реально доступны для поиска сейчас;
- нужен Task-specific contract или общая Search abstraction;
- требуется ли изменение существующего repository contract;
- где Application координирует запрос;
- где располагается Drift query;
- нужны ли новые tables, indexes или FTS5;
- минимальную query semantics, lifecycle scope и порядок результатов;
- поведение empty/whitespace query;
- case-insensitive behavior и ограничения SQLite/Unicode;
- путь Presentation -> Application -> Domain abstraction без доступа Presentation к Infrastructure;
- как Search позднее добавляется в desktop shell;
- требуется ли новый ADR.

### Definition of Done

- фактическое состояние репозитория и Git зафиксировано;
- завершённый Desktop Shell plan перенесён в `completed/`;
- этот plan является единственным основным active execution plan;
- перечисленные architecture gate вопросы получили однозначные ответы;
- нерешённых архитектурных вопросов перед LS-02 нет либо checkpoint отмечен `blocked` с точным blocker;
- baseline validation завершена и записана.

### Validation

- `flutter analyze`;
- полный `flutter test` как baseline;
- import-boundary scan;
- dependency/routing scan;
- `git diff --check`.

### Результат / доказательства

Architecture gate: PASS. Для LS-02 не требуется новый ADR и не осталось нерешённых архитектурных вопросов.

#### Сверка Git и repository

- На старте LS-01 `HEAD` = `32292b8` (`main`, на 2 commits впереди `origin/main`).
- Завершённый Desktop Shell plan имел статус `completed`, все DS-01 — DS-07 имели статус `done`, blockers отсутствовали; файл перенесён из `active/` в `completed/` без изменения его содержимого.
- `docs/exec-plans/active/local-search.md` создан как единственный основной active execution plan; `docs/exec-plans/README.md` отражает новое расположение планов.
- До LS-01 единственным незакоммиченным файлом был пользовательский `.obsidian/workspace.json`; он не редактировался и не включён в scope.
- Production implementation и tests в LS-01 не изменялись.
- Полный набор ADR-0001 — ADR-0027 повторно проаудирован; конкретные управляющие Search/Task/persistence/composition/Presentation решения перечислены в `Relevant ADRs`. Противоречий, требующих изменения принятого ADR, не обнаружено.

#### Фактическое состояние vertical slice

- Сейчас существует только один настоящий тип пользовательских Domain-данных: `LifeOsTask`.
- Единственное содержательное текстовое поле Task — `title`; completion и обязательные Entity metadata доступны как состояние результата, но не являются текстовыми полями поиска.
- `LifeOsTaskRepository` принадлежит Domain и предоставляет `getAll`, `getById` и `save`; `DriftLifeOsTaskRepository` реализует controlled queries и mapping через join `entities` + `tasks`.
- Application содержит отдельные use cases для list/create/toggle; Presentation вызывает их через app-owned Riverpod overrides и не импортирует Infrastructure.
- Composition root создаёт один file-backed `LifeOsDatabase`, один `DriftLifeOsTaskRepository` и владеет lifecycle database.
- Desktop shell использует Flutter SDK `NavigationRail` + `IndexedStack`, shell-local destination state и ровно `Home`/`Tasks`; routing dependency отсутствует.

#### Минимальное архитектурное решение

- Первый поиск является Task-specific vertical slice. В Domain расширяется существующий `LifeOsTaskRepository` методом `searchByTitle(String query)`; отдельные `SearchEngine`, `SearchRepository`, `SearchProvider` и generic `SearchResult` не создаются.
- Application получает один use case `SearchLifeOsTasks`. Он принимает пользовательский query, выполняет `trim` и немедленно возвращает пустой список для empty/whitespace input; Presentation не знает repository или Drift.
- Infrastructure реализует contract в `DriftLifeOsTaskRepository`. Controlled Drift read выбирает Task rows с `entityType == task` и `lifecycle == active`, после mapping выполняется ограниченное текущим набором данных literal substring matching и deterministic sorting.
- Completion не исключает Task из результатов: completed Task остаётся active Entity. Archived и deleted Tasks в обычный поиск не входят; отдельного archive/trash search в milestone нет.
- Порядок результатов: `updatedAt` по убыванию, затем `id.value` по возрастанию для стабильного tie-break. Ranking/score отсутствуют.

#### Query semantics и Unicode

- Сопоставление выполняется по literal substring в `title`; `%`, `_`, `\\` и другие символы пользовательского запроса не получают SQL wildcard semantics.
- Для English и Russian применяется locale-independent simple lowercase comparison в Dart внутри Infrastructure после controlled SQLite read. Это обеспечивает ожидаемое сопоставление обычных ASCII/Cyrillic case variants без schema change.
- Встроенные SQLite `LIKE`, `NOCASE` и `lower()` без дополнительной ICU-конфигурации не дают полноценный Unicode case folding; поэтому они не выбираются как единственный механизм case-insensitive matching.
- Текущая семантика не обещает locale-specific collation, Unicode normalization, grapheme-aware matching или полное case folding для всех языков. Такие требования, как и масштабируемость за пределами небольшого Task slice, должны повторно открыть architecture/performance gate.

#### Tables, indexes и FTS

- Новые tables, schema version, indexes и FTS5 не нужны: поиск ограничен одним коротким полем единственного реализованного типа, а performance evidence для дополнительного индекса отсутствует.
- ADR-0006 прямо допускает обычный SQL на первом этапе и требует добавлять indexes только по реальным query patterns; ADR-0012 оставляет конкретный Search API/engine открытым. ADR-0015 описывает более широкий будущий semantic/hybrid milestone, который явно исключён текущим scope.
- Если объём Tasks сделает bounded read + Dart matching недостаточным либо появится второй searchable Entity type, дальнейшая работа должна измерить поведение и отдельно решить вопрос FTS/shared Search abstraction, а не расширять текущий contract скрытно.

#### Presentation и shell integration path

- В LS-04 Search Presentation будет владеть query/input/async display state и зависеть только от `SearchLifeOsTasks` через Riverpod wiring.
- В LS-05 `Search` будет добавлен третьим реальным значением `LifeOsDestination` и child существующего `IndexedStack`; shell-local navigation architecture не меняется.
- Composition root передаст тот же repository/use case в app-owned provider scope; Search не создаёт database или repository и не меняет persistence lifecycle.
- Все новые видимые строки появятся одновременно в English/Russian ARB; generated localization files будут изменяться только через `flutter gen-l10n`.

#### Решение по ADR

- Новый ADR не требуется. Решение является минимальным обратимым расширением существующего Task repository/use-case vertical slice и конкретизирует первый keyword query, не меняя долгосрочную Search Architecture.
- Концептуальные generic interfaces в предварительных ADR-0012/ADR-0015 не имеют зафиксированного concrete API и не требуют создавать универсальную подсистему до второго реального consumer. Local-first, provider independence и Domain/persistence boundaries сохраняются.

#### Baseline validation

- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 47 tests.
- Import-boundary scan: PASS — Domain/Application не импортируют Flutter/Drift/Infrastructure/Presentation; Presentation не импортирует Infrastructure/Drift.
- Routing dependency scan: PASS — `go_router`, `auto_route`, `beamer`, `routemaster`, `MaterialApp.router` и `GoRouter` отсутствуют в manifests/source/tests.
- Dependency manifest scan: PASS — новых dependencies нет, текущий Flutter/Riverpod/Drift stack соответствует repository state. `dart pub deps --style=compact` не выдал результата за 60 секунд и был остановлен; файловых изменений команда не внесла.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.

### Blocker

Отсутствует на момент начала checkpoint.

---

## LS-02 — Task search contract и Application use case

Статус: done

Зависит от: LS-01

### Цель

Добавить минимальный Task-specific read contract и Application use case для поиска Tasks.

### Relevant ADRs

- ADR-0007;
- ADR-0012;
- ADR-0016;
- ADR-0017;
- ADR-0022.

### Разрешённый scope

- расширение `LifeOsTaskRepository` согласованным read method;
- `SearchLifeOsTasks` в Application;
- unit tests контракта use case и query normalization;
- обновление существующих test doubles.

### Явно не входит

- Drift implementation;
- Presentation и shell;
- общий Search subsystem;
- schema или dependencies.

### Definition of Done

- Presentation сможет зависеть от одного Application use case;
- Application зависит только от Domain repository abstraction;
- empty/whitespace behavior и нормализация закреплены tests;
- generic search abstractions не добавлены.

### Validation

- focused Domain/Application tests;
- `flutter analyze`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. `searchByTitle(String query)` однозначно выражает Task-specific semantics LS-01; новый ADR или generic Search abstraction не потребовались.
- На старте checkpoint `HEAD` = `adcf4b0`; LS-01 был `done`, LS-02 — первым pending checkpoint. Единственным исходным рабочим изменением был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- `LifeOsTaskRepository` расширен одной read operation `searchByTitle`, возвращающей `Future<List<LifeOsTask>>`. Contract не содержит UI state и не импортирует Flutter, Drift или SQLite.
- Добавлен Application use case `SearchLifeOsTasks`, зависящий только от `LifeOsTaskRepository`.
- Application является единственным владельцем входной нормализации: выполняет `trim`, не вызывает repository для empty/whitespace-only query и возвращает пустой typed `List<LifeOsTask>`.
- Непустой нормализованный query передаётся repository без дополнительного преобразования; returned Domain Task collection возвращается вызывающей стороне без Presentation/Infrastructure model.
- Все существующие deterministic fake repositories обновлены новым contract method. Реальная SQLite database в Application tests не поднималась.
- Для сохранения компилируемого repository implementation в `DriftLifeOsTaskRepository` добавлена только явная временная сигнатура, бросающая `UnimplementedError`; Drift/SQLite query отсутствует и остаётся первой задачей LS-03. Schema, indexes, generated files, dependencies, composition и providers не изменялись.
- Focused Domain/Application Task/search tests: PASS — 16 tests, включая 4 новых search scenarios.
- Existing relevant Task/persistence/shell/composition tests: PASS — 25 tests.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 51 tests.
- Import-boundary scan: PASS — Application search импортирует только Domain; Domain не получил framework/persistence imports; Presentation не импортирует Infrastructure.
- Dependency validation: not applicable — manifests и packages не изменялись; зависающий dependency command из LS-01 не запускался повторно.
- `dart format` не выдал результата за 60 секунд и был остановлен без файловых изменений; итоговое форматирование проверено `flutter analyze` и diff review.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.
- Итоговый Git ref: `HEAD` = `adcf4b0`, `origin/main` = `adcf4b0`, divergence `0/0`. Рабочее дерево содержит только LS-02 files и отдельное исходное пользовательское изменение `.obsidian/workspace.json`.

### Blocker

Отсутствует.

---

## LS-03 — Локальный поиск в Drift repository

Статус: done

Зависит от: LS-02

### Цель

Реализовать согласованный Task search contract поверх существующей SQLite/Drift persistence и проверить file-backed behavior.

### Relevant ADRs

- ADR-0005;
- ADR-0006;
- ADR-0010;
- ADR-0012;
- ADR-0016;
- ADR-0017;
- ADR-0020;
- ADR-0021;
- ADR-0023;
- ADR-0024.

### Разрешённый scope

- controlled read query в `DriftLifeOsTaskRepository`;
- literal title matching, lifecycle filter и deterministic ordering из LS-01;
- focused in-memory и file-backed persistence tests;
- schema/index change только если LS-01 evidence доказал необходимость.

### Явно не входит

- изменение Task write path или Outbox;
- FTS5, отдельный indexer или search database;
- semantic/fuzzy search;
- Presentation.

### Definition of Done

- сохранённые Tasks находятся через repository contract после database reopen;
- фильтрация и порядок соответствуют LS-01;
- query parameterized и не интерпретирует пользовательские `%`/`_` как wildcard;
- write/Outbox behavior не изменён;
- новые schema/index artifacts отсутствуют без измеренной необходимости.

### Validation

- focused Drift repository tests;
- focused file-backed database tests;
- Drift generation/check, только если затронут schema source;
- `flutter analyze`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. Реализация укладывается в решения LS-01 и существующую schema; migration, FTS5, search index, dependency или новый ADR не требуются.
- На старте checkpoint `HEAD` = `be33200` (`main`, на 1 commit впереди `origin/main`); LS-01/LS-02 были `done`, LS-03 — первым pending checkpoint. Единственным исходным незакоммиченным файлом был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- `DriftLifeOsTaskRepository.searchByTitle` теперь выполняет controlled read через существующий join `entities` + `tasks`, ограничивая строки `entityType == task` и `lifecycle == active`.
- Existing `LifeOsTaskMapper.toDomain` переиспользуется через приватный `_mapTask`; отдельный Persistence/Domain mapping для Search не создан.
- После Drift read Infrastructure применяет принятую LS-01 literal substring semantics: `query.toLowerCase()` сравнивается с `task.title.toLowerCase()`. `%`, `_` и `\\` остаются обычными символами, а не SQL wildcards.
- Такая locale-independent simple lowercase обработка подтверждена для обычных English и Cyrillic case variants. Она намеренно не обещает SQLite ICU collation, locale-specific case folding или Unicode normalization; новые dependencies и собственная Unicode subsystem не добавлялись.
- Результаты сортируются детерминированно: `updatedAt` descending, затем `id.value` ascending. Join по primary/foreign keys возвращает каждую Task один раз; отсутствие duplicates закреплено focused test.
- Возвращаются существующие `LifeOsTask` Domain entities со всеми mapped metadata (`id`, timestamps, lifecycle, version, source) и Task state.
- Completed Task остаётся searchable, пока lifecycle равен `active`; completion проверен через существующий `ToggleStoredTaskCompletion` path.
- Search является read-only: focused tests сравнивают Outbox до/после поиска и подтверждают отсутствие новых Outbox rows. Create/list/get/toggle/save code paths не изменялись.
- File-backed test подтверждает поиск сохранённой Cyrillic Task после закрытия и повторного открытия production-shaped database; Outbox остаётся с единственной исходной write entry.
- Focused Drift repository + file-backed persistence tests: PASS — 12 tests, включая 4 новых search scenarios.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 55 tests.
- Import-boundary scan: PASS — изменение ограничено Infrastructure и использует существующие Domain abstractions/mapping; Domain/Application/Presentation imports не изменялись.
- Drift generation/check: not applicable — `lifeos_database.dart`, schema version и `lifeos_database.g.dart` не изменялись; generated-file diff отсутствует.
- Dependency validation: not applicable — `pubspec.yaml`, lockfile и packages не изменялись.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.
- Итоговый Git ref: `HEAD` = `be33200`, `origin/main` = `adcf4b0`, divergence `1/0`. Рабочее дерево содержит четыре LS-03 files и отдельное исходное пользовательское изменение `.obsidian/workspace.json`.

### Blocker

Отсутствует.

---

## LS-04 — Search Presentation

Статус: done

Зависит от: LS-03

### Цель

Создать минимальный локализованный Search UI и Presentation state, использующие Application use case.

### Relevant ADRs

- ADR-0012;
- ADR-0022;
- ADR-0027.

### Разрешённый scope

- Search page, query input, loading/error/empty/no-results/results states;
- Riverpod wiring, если оно представляет meaningful asynchronous Presentation state;
- English/Russian ARB resources и generation;
- focused widget/localization tests.

### Явно не входит

- shell destination;
- direct Drift/repository construction в Presentation;
- Task mutations из Search;
- debounce/caching/history без фактической необходимости;
- navigation к отдельной Task details page, которой пока нет.

### Definition of Done

- UI передаёт запрос только через Application boundary;
- все состояния понятны и локализованы;
- empty query не показывает полный список Tasks;
- результаты отображают существующие Domain Tasks без новой generic result model;
- English/Russian tests проходят.

### Validation

- focused Search widget/provider tests;
- localization generation/check;
- `flutter analyze`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. Для локального query/input/async-result state достаточно feature-owned `ConsumerStatefulWidget` и существующего Riverpod dependency injection; новый глобальный state contract, singleton или ADR не требуются.
- На старте checkpoint `HEAD` = `7adf12a` (`main`, на 2 commits впереди `origin/main`); LS-01 — LS-03 были `done`, LS-04 — первым pending checkpoint. Единственным исходным незакоммиченным файлом был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- Добавлен standalone `TaskSearchPage` в `lib/presentation/search/`; он не интегрирован в shell и не изменяет текущие `LifeOsDestination`/`NavigationRail`.
- Query принадлежит локальному `TextEditingController`, а nullable `AsyncValue<List<LifeOsTask>>` внутри `State<TaskSearchPage>` различает initial, loading, error, no-results и results без глобального application state.
- `searchLifeOsTasksProvider` предоставляет единственную Presentation dependency типа `SearchLifeOsTasks` и требует override от app composition. Он не создаёт repository/database и не импортирует Infrastructure.
- Presentation передаёт пользовательский input в `SearchLifeOsTasks` без `trim` или собственной empty-query логики. Focused test подтверждает, что repository получает нормализованный query через Application, а whitespace-only input не вызывает repository и не показывает полный список.
- Результаты отображаются в порядке, возвращённом Application. UI использует существующие `LifeOsTask` напрямую, без generic `SearchResult` и fake Notes/Projects/all-entities behavior.
- Completed Task визуально отличается `Icons.check_circle` и зачёркнутым title; incomplete active Task использует `Icons.radio_button_unchecked` без зачёркивания. Search остаётся read-only.
- Добавлены localized initial/no-results/error states, page title, query label и action. English/Russian ARB изменены вместе; generated `app_localizations*.dart` обновлены только командой `flutter gen-l10n`.
- Focused Search Presentation + localization tests: PASS — 11 tests, включая 6 новых widget scenarios.
- Первая focused попытка обнаружила неверное ожидание количества Russian `Поиск`: кнопка корректно локализована как `Найти`. Исправлен только test assertion; повторный focused suite прошёл.
- `flutter gen-l10n`: PASS.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 61 test.
- Import-boundary scan: PASS — Search Presentation импортирует Flutter/Riverpod, Application use case и Domain Task только; direct Drift/SQLite/Infrastructure imports отсутствуют.
- Scope audit: PASS — Domain, Infrastructure, app composition, shell/navigation, dependencies и persistence не изменялись; Search destination остаётся LS-05.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.
- Итоговый Git ref: `HEAD` = `7adf12a`, `origin/main` = `adcf4b0`, divergence `2/0`. Рабочее дерево содержит только LS-04 files и отдельное исходное пользовательское изменение `.obsidian/workspace.json`.

### Blocker

Отсутствует.

---

## LS-05 — Интеграция Search в desktop shell

Статус: pending

Зависит от: LS-04

### Цель

Добавить Search как третий реальный destination существующей desktop shell без изменения принятой navigation architecture.

### Relevant ADRs

- ADR-0022;
- ADR-0024;
- ADR-0027;
- завершённый Desktop Shell / Navigation plan.

### Разрешённый scope

- новый `LifeOsDestination.search`;
- локализованный `NavigationRailDestination`;
- Search page в существующем `IndexedStack`;
- app composition/provider overrides для уже созданного use case, если нужны;
- focused shell/navigation tests.

### Явно не входит

- routing package, deep links или URL routes;
- новые destinations кроме Search;
- дублирование database/repository/use case ownership;
- изменение Home или Tasks behavior.

### Definition of Done

- Search доступен из `NavigationRail`;
- переключение `Home -> Tasks -> Search` и обратно сохраняет предусмотренное widget state;
- production database/repository создаются один раз composition root;
- English/Russian navigation labels существуют;
- существующий Task vertical slice не регрессировал.

### Validation

- focused shell + Search navigation tests;
- existing shell/Task tests;
- localization tests;
- `flutter analyze`;
- routing/dependency scan;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

Ожидает выполнения.

### Blocker

Отсутствует.

---

## LS-06 — Edge cases, persistence и UX audit

Статус: pending

Зависит от: LS-05

### Цель

Проверить первую Search slice на пограничных запросах, persistence reopen, resize и стабильность Presentation state.

### Relevant ADRs

- ADR-0005;
- ADR-0010;
- ADR-0012;
- ADR-0016;
- ADR-0017;
- ADR-0021;
- ADR-0024;
- ADR-0027.

### Разрешённый scope

- focused tests и минимальные исправления конкретных дефектов;
- empty/whitespace, literal wildcard characters, case variants, Cyrillic, no-results, active/completed Tasks и deterministic order;
- reopen database и desktop layout checks.

### Явно не входит

- расширение search scope;
- performance architecture без evidence;
- FTS5/index migration без измеренной проблемы;
- semantic/fuzzy search.

### Definition of Done

- согласованные query semantics подтверждены tests;
- file-backed reopen не меняет результаты;
- Search UI устойчив на representative desktop widths;
- errors не раскрывают пользовательский content в logs/UI;
- нет случайной зависимости tests от widget/database state.

### Validation

- focused edge/persistence/widget tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- dependency/routing scan;
- `git diff --check`.

### Результат / доказательства

Ожидает выполнения.

### Blocker

Отсутствует.

---

## LS-07 — Финальный архитектурный и интеграционный аудит

Статус: pending

Зависит от: LS-06

### Цель

Подтвердить end-to-end local-first Search milestone и отсутствие architecture/scope regressions.

### Relevant ADRs

- все ADR, управляющие Search, Task vertical slice, persistence, composition, Presentation и localization.

### Разрешённый scope

- read-only аудит и полный validation;
- только минимальные исправления конкретных дефектов, не требующие нового архитектурного решения;
- финальная factual evidence и перевод plan в `completed` после успеха.

### Явно не входит

- новый feature milestone;
- любой отложенный scope этого plan;
- новый ADR без отдельного пользовательского решения.

### Definition of Done

- Search работает end-to-end с production file-backed SQLite composition;
- Task title search работает offline после database reopen;
- UI и navigation локализованы на English/Russian;
- Presentation -> Application -> Domain boundary и Infrastructure implementation подтверждены;
- composition root единолично владеет production persistence lifecycle;
- Task writes и Outbox не получили регрессий;
- dependency, generated-file и scope hygiene проходят;
- LS-01 — LS-07 имеют статус `done`, blockers отсутствуют, plan отмечен `completed`.

### Validation

- все relevant focused tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- routing/dependency scan;
- localization generation/check;
- Drift generation/check, если применимо;
- generated-file и scope audit;
- `git diff --check`.

### Результат / доказательства

Ожидает выполнения.

### Blocker

Отсутствует.

---

# Точка возобновления

Текущий checkpoint: LS-05 — pending

Resume checkpoint: LS-05, начать с повторной сверки Git/plan и отметить LS-05 `active` перед интеграцией Search в desktop shell.

Не начинать LS-05 в текущем запуске.

# Состояние выполнения плана

Статус: active

Завершённые checkpoints: LS-01, LS-02, LS-03, LS-04

Текущий checkpoint: LS-05 — pending

Следующий pending checkpoint: LS-05

Blockers: отсутствуют
