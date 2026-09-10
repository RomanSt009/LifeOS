# LifeOS Desktop Shell / Navigation — план выполнения

Статус: completed

## Цель

Создать первую стабильную desktop-оболочку приложения LifeOS.

Оболочка должна предоставить масштабируемую структуру навигации для существующих и будущих функций LifeOS, сохраняя принятые архитектурные границы.

После завершения этого плана Windows-приложение должно иметь:

- постоянную desktop-оболочку;
- основную навигацию;
- полноценный раздел Tasks, использующий уже реализованную функциональность;
- минимальные placeholder-разделы для будущих основных областей продукта там, где они действительно нужны для проверки архитектуры оболочки;
- корректное поведение интерфейса при разумных размерах desktop-окна;
- локализованный интерфейс оболочки на английском и русском языках;
- чёткое разделение ответственности между shell/navigation и Presentation конкретных функций.

Этот план не изменяет Domain, persistence, Sync, AI или бизнес-логику Tasks.

---

## Основная архитектура

Реализация должна соответствовать:

- `AGENTS.md`;
- ADR-0022 — Flutter project architecture;
- ADR-0027 — localization strategy;
- всем другим ADR, относящимся к Presentation и composition.

Существующая архитектура сохраняется:

Presentation -> Application -> Domain

Infrastructure -> Domain abstractions

Desktop shell относится к Presentation.

Application composition остаётся в `app/`.

Навигация не должна переносить persistence, repositories, Domain mutations или бизнес-логику в routing/navigation код Presentation.

---

## Направление развития продукта

Начальная информационная архитектура desktop-приложения должна позволять в дальнейшем развивать основные области LifeOS, например:

- Home;
- Tasks;
- Notes;
- Projects;
- Search;
- AI;
- Settings.

Однако этот план не должен придумывать полноценную реализацию функций, которых пока не существует.

Разделы, для которых ещё нет принятой реализации, могут использовать минимальные локализованные Presentation-only placeholders только тогда, когда они необходимы для построения и проверки архитектуры оболочки.

Для placeholder-разделов запрещено создавать спекулятивные Domain/Application/Infrastructure слои.

---

## Общие ограничения

### Локализация

Все новые видимые пользователю статические строки должны использовать принятую систему локализации.

Для каждого нового localization key должны существовать значения:

- English;
- Russian.

Нельзя добавлять hardcoded пользовательские строки в shell/navigation.

### Зависимости

Предпочитать возможности Flutter SDK.

Не добавлять отдельный routing/navigation package, если текущие требования можно разумно реализовать существующим Flutter stack.

Любая новая зависимость должна иметь явное обоснование относительно существующих ADR и фактических требований проекта.

### Существующая функциональность Tasks

Существующий Task vertical slice должен использоваться повторно.

Запрещено дублировать:

- Task repositories;
- Task providers;
- Task use cases;
- persistence;
- Task business rules.

Shell/navigation может размещать или открывать существующий Task Presentation.

### Контроль scope

В рамках этого плана не реализовывать:

- полноценную функциональность Notes;
- полноценную функциональность Projects;
- Search engine;
- AI-функциональность;
- persistence настроек;
- account/profile system;
- remote Sync;
- notification system;
- полноценную систему тем сверх уже необходимых возможностей приложения;
- сложные анимации;
- спекулятивную mobile navigation.

---

# Checkpoints

## DS-01 — Аудит текущего Presentation и навигации

Статус: done

### Цель

Изучить текущую структуру Presentation и определить минимальную архитектуру shell/navigation, совместимую с существующим репозиторием и принятыми ADR.

### Обязательное изучение

Проверить:

- текущий `lib/app/`;
- текущий `lib/presentation/`;
- существующий Task Presentation;
- текущую конфигурацию корневого `MaterialApp`;
- конфигурацию локализации;
- относящиеся к этому тесты;
- соответствующие ADR.

### Architecture gate

До начала реализации shell/navigation определить:

- существует ли уже navigation infrastructure, которую следует расширить;
- достаточно ли стандартных средств Flutter SDK;
- где должно находиться состояние выбранного раздела навигации;
- какие destinations действительно нужны для первой версии shell;
- требуется ли какое-либо новое архитектурное решение или ADR.

Не выбирать сторонний router только ради предполагаемой будущей гибкости.

### Definition of Done

- текущая структура зафиксирована в этом execution plan;
- предложена минимальная структура shell/navigation;
- зафиксировано решение по зависимостям;
- определён владелец navigation state;
- перед DS-02 не осталось нерешённых архитектурных вопросов.

### Проверка

- сверка состояния репозитория и Git;
- проверка архитектуры/import boundaries;
- `git diff --check`, если execution plan был изменён.

### Результат / доказательства

Architecture gate: PASS. Нерешённых архитектурных вопросов перед DS-02 нет.

#### Сверка репозитория и Git

- На момент аудита `HEAD` = `09e9e81` (`main`, на 3 commits впереди `origin/main`).
- `desktop-shell-navigation.md` является единственным active execution plan; DS-01 был первым незавершённым checkpoint.
- До изменений checkpoint рабочее дерево содержало только пользовательское изменение `.obsidian/workspace.json`; оно не затрагивалось.
- Завершённый MVP vertical slice присутствует в репозитории и предоставляет рабочие Task Presentation, Application use cases, Domain contracts и production composition.

#### Фактическая текущая структура Presentation/navigation

- `lib/main.dart` инициализирует Flutter binding, создаёт production dependencies и запускает `LifeOSApp`.
- `lib/app/dependencies.dart` является composition root для database, repository и Task use case; Presentation не создаёт persistence.
- `lib/app/app.dart` владеет application/database lifecycle, `ProviderScope`, localization configuration и корневым `MaterialApp`.
- `MaterialApp.home` напрямую открывает `LifeosShellPage`; `MaterialApp.router`, route table, `Navigator` и отдельная navigation infrastructure отсутствуют.
- `lib/presentation/shell/lifeos_shell_page.dart` сейчас является stateless `Scaffold`, который одновременно показывает общую шапку приложения и непосредственно размещает `TaskList`. Постоянной области навигации, модели destinations и состояния выбранного раздела пока нет.
- `lib/presentation/tasks/` содержит существующие Task widgets и Riverpod presentation state. Создание, чтение и completion проходят через существующие Application use cases и Domain repository abstraction.
- `lib/l10n/` содержит English/Russian ARB и generated localization classes; `LifeOSApp` выбирает platform locale и безопасно откатывается на English.
- Существующие widget tests покрывают shell identity, Task UI/use-case boundary, production composition lifecycle и localization, но пока не содержат navigation assertions.
- `pubspec.yaml` не содержит `go_router` или другой routing dependency.

#### Решение по navigation capability и зависимостям

- Для текущего требования достаточно Flutter SDK: `NavigationRail` для основной desktop-навигации и `IndexedStack` либо эквивалентная widget-композиция для области content.
- Новый routing package в DS-02 не требуется и добавляться не должен. Переключение верхнеуровневого destination внутри одной shell не требует route graph, URL routing, deep links или navigation history.
- Предварительный выбор GoRouter из ADR-0002 не отменяется: он остаётся допустимым решением для будущей route-level навигации, когда появится подтверждённая необходимость. ADR-0022 не фиксирует конкретную navigation library.
- Riverpod продолжает обслуживать meaningful Task state, но отдельный provider только для простого выбранного индекса не нужен.

#### Владелец navigation state

- Выбранный destination является локальным ephemeral Presentation state и принадлежит `State<LifeosShellPage>`.
- Shell меняет только выбранный destination и визуальную композицию. Она не вызывает Domain mutations, не создаёт repositories/database и не владеет application persistence lifecycle.
- Состояние не сохраняется между запусками и не синхронизируется; persistence navigation history явно отложена.
- Feature subtree следует сохранять при переключении через `IndexedStack`, чтобы возврат в Tasks не создавал случайный lifecycle reset.

#### Минимально обоснованный набор destinations

1. `Tasks` — существующий реальный feature destination и начальный выбранный destination, что сохраняет текущее полезное startup-поведение.
2. `Home` — единственный Presentation-only placeholder, необходимый для проверки реального переключения destination и расширяемости shell.

`Notes`, `Projects`, `Search`, `AI` и `Settings` не нужны для проверки основы shell и не должны создаваться в DS-02. Их необходимость повторно оценивается в DS-04; отсутствие feature implementation не является основанием создавать дополнительные placeholders.

#### Предлагаемая структура файлов и ответственности

```text
lib/presentation/
├── navigation/
│   └── lifeos_destination.dart
├── shell/
│   └── lifeos_shell_page.dart
├── home/
│   └── home_placeholder.dart
└── tasks/
    ├── task_page.dart
    └── existing Task widgets/providers

test/presentation/
├── shell/
│   └── lifeos_shell_page_test.dart
└── tasks/
    └── existing Task tests
```

- `lifeos_destination.dart`: только Presentation enum/identity destinations; без localized strings, routes, repositories или business rules.
- `lifeos_shell_page.dart`: persistent frame, `NavigationRail`, выбранный destination, localized label resolution и content composition.
- `home_placeholder.dart`: минимальный локализованный Presentation-only placeholder без других слоёв.
- `task_page.dart`: feature-owned layout, переиспользующий существующий `TaskList`; Task providers/use cases/repository composition не дублируются.
- `app/app.dart`: сохраняет только root application configuration, Provider overrides, localization и lifecycle; shell state туда не переносится.
- Новые строки добавляются в `app_en.arb` и `app_ru.arb`; generated localization files вручную не редактируются.

#### Решение по ADR

Новый ADR не требуется. ADR-0022 уже закрепляет navigation за Presentation и оставляет конкретную библиотеку открытой; ADR-0027 покрывает localization; ADR-0007 и ADR-0024 сохраняют composition/persistence ownership в `app/`. Выбор локального widget state и Flutter SDK для двух in-shell destinations является обратимым implementation decision, а не новым архитектурным контрактом.

Если позднее реально потребуются deep links, URL routing, persistent navigation history или независимые route stacks, DS-06 должен остановиться на architecture gate и определить необходимость отдельного navigation ADR до подключения GoRouter.

#### Ограниченная проверка

- Git/repository reconciliation: PASS.
- Import-boundary scan: PASS — запрещённых Domain/Application/Presentation imports не найдено; persistence construction остаётся в `app/`.
- `git diff --check`: PASS.

---

## DS-02 — Основа desktop shell

Статус: done

Зависит от: DS-01

### Цель

Создать переиспользуемую desktop-оболочку LifeOS без изменения существующего поведения бизнес-функций.

### Ответственность shell

Shell должен предоставлять:

- постоянную рамку приложения;
- область основной навигации;
- основную область контента;
- состояние выбранного destination;
- локализованные navigation labels;
- подходящую desktop-компоновку.

### Архитектурные требования

Shell-код относится к Presentation.

Navigation state не должен проникать в Domain или Infrastructure.

Каждый feature destination остаётся ответственным за собственный Presentation.

### Definition of Done

- приложение запускается внутри новой desktop shell;
- shell имеет стабильную структуру navigation/content;
- выбранный destination визуально обозначен;
- shell navigation не создаёт persistence dependencies;
- для всех новых строк shell существуют английские и русские локализации;
- существующие Task tests продолжают проходить.

### Проверка

- focused shell widget tests;
- localization tests;
- `flutter analyze`;
- `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate повторно пройден против ADR-0002, ADR-0007, ADR-0022, ADR-0024 и ADR-0027; новое решение или ADR не потребовались.
- `LifeosShellPage` преобразован в stateful Presentation shell; выбранный destination хранится только в `State<LifeosShellPage>` и по умолчанию равен `Tasks`.
- Постоянная desktop-рамка содержит `NavigationRail`, визуально выбранный destination, разделитель и расширяемую content area на основе `IndexedStack`.
- Добавлены только два согласованных destination: реальный `Tasks`, повторно использующий существующий `TaskList`, и минимальный Presentation-only `Home` placeholder.
- `IndexedStack` сохраняет Task subtree при переключении destination; Task providers, use cases, repositories и database composition не дублировались и не изменялись.
- Navigation identity изолирована в `lib/presentation/navigation/lifeos_destination.dart`; shell/layout остаются в Presentation.
- В ARB добавлены семантические ключи `navigationHome` и `navigationTasks` для English/Russian; generated localization sources получены через `flutter gen-l10n` и не редактировались вручную.
- Новая routing dependency не добавлена; shell использует только Flutter SDK.
- Focused shell/localization/Task widget tests: PASS — 15 tests; проверены initial selection, localized English/Russian labels, визуальное переключение и сохранение Task subtree.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 42 tests.
- Import-boundary scan: PASS — shell не ввёл Infrastructure/persistence dependencies, localization не вышла за Presentation/composition, Domain и Application остались framework-independent.
- Routing dependency scan: PASS — сторонний router отсутствует.
- `git diff --check`: PASS.

---

## DS-03 — Интеграция Tasks в навигацию

Статус: done

Зависит от: DS-02

### Цель

Интегрировать существующий Task Presentation в desktop shell как настоящий navigation destination.

### Требования

- использовать существующие Task list/create/completion;
- Tasks должны быть доступны через основную навигацию;
- переход из Tasks в другой раздел и обратно должен работать корректно;
- не должно появляться дублирующей repository/database composition;
- persistence и Outbox не должны получить регрессий.

### Definition of Done

- Tasks destination отображает сохранённые Tasks;
- создание Task продолжает работать;
- completion toggle продолжает работать;
- состояние Tasks сохраняется;
- navigation не обходит Application/Domain boundaries;
- существующий Task vertical slice остаётся функциональным.

### Проверка

- focused shell + Task navigation tests;
- существующие Task tests;
- persistence tests при необходимости;
- `flutter analyze`;
- `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate пройден против ADR-0022, ADR-0023, ADR-0024, ADR-0025, ADR-0026 и ADR-0027; нового решения не потребовалось.
- На старте DS-03 `HEAD` = `4ab3f5f` (`main`, на 5 commits впереди `origin/main`); единственным рабочим изменением был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- Добавлен feature-owned `TaskPage`, который только композирует прежние локализованные Task header и существующий `TaskList`.
- Desktop shell теперь отображает `TaskPage` как content для `LifeOsDestination.tasks`; shell не содержит Task mutation logic и не создаёт Task providers, use cases, repositories или database.
- Existing `TaskList`, `TaskListController`, `CreateLifeOsTask` и `ToggleStoredTaskCompletion` переиспользованы без изменения.
- Focused navigation test подтверждает последовательность `Home -> Tasks -> Home -> Tasks`, отображение ранее загруженной Task, создание новой Task, completion toggle и сохранение обоих состояний после повторного переключения destination.
- Domain, Application, Infrastructure, production database composition, Drift schema и Outbox implementation не изменялись.
- Focused shell + Tasks + persistence tests: PASS — 30 tests.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 43 tests.
- Import-boundary scan: PASS — Presentation не импортирует Infrastructure/Drift, Application и Domain не получили framework/platform dependencies, persistence construction остаётся вне Presentation/Application.
- Routing dependency scan: PASS — новые routing packages отсутствуют.
- `git diff --check`: PASS.

---

## DS-04 — Начальная структура разделов LifeOS

Статус: done

Зависит от: DS-03

### Цель

Сформировать начальную информационную архитектуру LifeOS без преждевременной реализации будущих функций.

### Кандидаты на начальные destinations

Оценить и реализовать минимально обоснованный набор из:

- Home;
- Tasks;
- Notes;
- Projects;
- Search;
- AI;
- Settings.

Tasks является настоящим функциональным destination.

Остальные destinations могут быть минимальными локализованными Presentation-only placeholders, если их наличие полезно для формирования структуры shell.

### Требования к placeholders

Placeholder destinations:

- не содержат спекулятивной бизнес-логики;
- не содержат repositories;
- не содержат persistence;
- не создают фиктивную feature architecture;
- явно остаются Presentation-only placeholders.

### Definition of Done

- начальный набор destinations явно зафиксирован;
- навигация между destinations работает;
- границы placeholders понятны;
- весь видимый текст локализован на английский и русский;
- добавление настоящей реализации будущей функции не требует переделки shell.

### Проверка

- navigation widget tests;
- localization tests;
- `flutter analyze`;
- `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. Существующая shell уже предоставляет минимально достаточную информационную архитектуру; нового ADR или изменения принятой navigation architecture не требуется.
- На старте DS-04 `HEAD` = `1af9d74` (`main`, на 6 commits впереди `origin/main`); единственным рабочим изменением был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- Итоговый начальный набор destinations зафиксирован как `Home` + `Tasks`:
  - `Tasks` остаётся реальным feature destination с существующим Presentation/Application/Domain/persistence vertical slice;
  - `Home` остаётся единственным минимальным Presentation-only placeholder, необходимым для устойчивой рамки shell и проверки переключения destinations.
- `Notes`, `Projects`, `Search`, `AI` и `Settings` не добавлены: для них пока нет реализованных пользовательских сценариев или иного фактического требования, а дополнительные placeholders не усиливают уже проверенную архитектуру shell и создали бы спекулятивную поверхность продукта.
- Production-код и localization resources не потребовали изменений: `LifeOsDestination`, `NavigationRail` и `IndexedStack` уже содержат ровно выбранные `Home`/`Tasks`, а все видимые строки имеют English/Russian ARB resources.
- Граница placeholder остаётся явной: `HomePlaceholder` находится только в Presentation и не создаёт Domain/Application/Infrastructure, repositories, persistence или fake business logic.
- Текущие extension points позволяют позднее добавить подтверждённый feature destination аддитивно через navigation identity, rail destination и content child, без изменения ownership shell state или переделки shell.
- Добавлен focused widget test, который фиксирует точный набор enum/`NavigationRail` destinations и исключает преждевременное расширение начальной IA.
- Focused navigation + Tasks navigation + localization tests: PASS — 10 tests; проверены точный состав destinations, переключение, сохранение Task subtree и English/Russian UI.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 44 tests.
- Import-boundary scan: PASS — Domain/Application не получили framework/platform dependencies, Presentation не импортирует Infrastructure/Drift, localization не вышла за Presentation/composition, persistence construction не появилось вне composition.
- Routing dependency scan: PASS — `go_router`, `auto_route` и `beamer` отсутствуют в dependencies/imports.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.

---

## DS-05 — Устойчивость desktop layout

Статус: done

Зависит от: DS-04

### Цель

Убедиться, что shell остаётся пригодным для использования при разумном изменении размеров Windows-окна.

### Требования

Проверить:

- navigation остаётся доступной при уменьшении ширины desktop-окна;
- основной контент не создаёт overflow при ожидаемом resize;
- Task UI остаётся пригодным для использования внутри shell;
- shell не рассчитан только на одно фиксированное разрешение;
- layout остаётся ориентированным на desktop.

Не реализовывать спекулятивную mobile application shell.

### Definition of Done

- representative width scenarios покрыты focused widget tests там, где это практически оправдано;
- отсутствуют соответствующие RenderFlex/overflow ошибки;
- primary navigation остаётся доступной;
- Task content остаётся пригодным для использования;
- не добавлена ненужная responsive-layout dependency.

### Проверка

- focused layout/widget tests;
- `flutter analyze`;
- `flutter test`;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. ADR-0022 оставляет layout в Presentation, Flutter SDK покрывает текущие требования, а изменение navigation architecture или новый ADR не требуются.
- На старте DS-05 `HEAD` = `664696e` (`main` синхронизирован с `origin/main`); единственным рабочим изменением был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- Существующая production-компоновка `Row` + `NavigationRail` + `Expanded` + `IndexedStack`, а также ограниченный `TaskPage` с прокручиваемым `TaskList` удовлетворяют Definition of Done без изменений production-кода.
- Добавлены focused widget scenarios для logical window sizes `1280x800` (достаточно широкое desktop-окно, English) и `640x600` (умеренно узкое desktop-окно, Russian).
- В обоих сценариях подтверждены отсутствие Flutter layout exceptions, доступность и hit-testability `NavigationRail`, Task title field и локализованной Task action; ввод в Task field остаётся рабочим.
- Проверка двух representative размеров подтверждает, что shell не зависит от одного фиксированного разрешения и сохраняет desktop-oriented navigation при сужении окна.
- Mobile/tablet shell, новые destinations, сторонняя responsive-layout dependency и изменения navigation state не добавлялись; `pubspec.yaml` и production sources не изменялись.
- Focused shell layout/widget tests: PASS — 6 tests, включая 2 новых size scenarios.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 46 tests.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.

---

## DS-06 — Аудит navigation state и lifecycle

Статус: done

Зависит от: DS-05

### Цель

Проверить navigation state и lifecycle feature-компонентов перед признанием desktop shell стабильной.

### Проверить

- поведение выбранного destination;
- ownership navigation state;
- lifecycle Task Presentation;
- lifecycle providers там, где это относится к задаче;
- database/repository lifecycle остаётся во владении composition;
- navigation не создаёт несколько production database instances;
- локализация работает во всех shell destinations;
- тесты не зависят от случайного widget state.

### Architecture gate

Если будет обнаружено, что сейчас действительно необходимы:

- persistent navigation history;
- deep linking;
- URL routing;
- другая более сложная navigation capability,

остановиться и определить, требуется ли отдельный navigation ADR или решение по router.

Не добавлять эти возможности спекулятивно.

### Definition of Done

- navigation/state behavior понятен и протестирован;
- отсутствует дублирование infrastructure ownership;
- нет нерешённых lifecycle-проблем;
- нет необоснованной routing dependency.

### Проверка

- focused lifecycle/navigation tests;
- `flutter analyze`;
- `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Результат / доказательства

- Architecture gate: PASS. Фактической необходимости в persistent navigation history, deep links, URL routing, независимых route stacks или отдельном router package не обнаружено; новое navigation-решение и ADR не требуются.
- На старте DS-06 `HEAD` = `ffa0c85` (`main`, на 1 commit впереди `origin/main`); единственным рабочим изменением был пользовательский `.obsidian/workspace.json`, который не затрагивался.
- Выбранный destination остаётся приватным ephemeral state в `State<LifeosShellPage>`, по умолчанию равным `Tasks`; navigation state не вынесен в Riverpod, Application, Domain или Infrastructure.
- `NavigationRail` изменяет только shell-local enum state, а `IndexedStack` сохраняет смонтированные `Home` и `Tasks` subtrees при переключении.
- Добавлен focused lifecycle test: несохранённый текст Task creation form сохраняется после `Tasks -> Home -> Tasks`, а `taskListControllerProvider` загружает repository ровно один раз. Это подтверждает сохранение необходимого Task Presentation/provider state без зависимости от случайного состояния между тестами.
- Task providers создаются внутри app-owned `ProviderScope`: production composition передаёт один и тот же `LifeOsTaskRepository` в provider override и `CreateLifeOsTask`; shell/navigation не создают providers, repositories или persistence.
- `main()` вызывает `createProductionDependencies()` один раз до `runApp`; composition создаёт один `LifeOsDatabase`, один `DriftLifeOsTaskRepository` и связанные use cases. Повторное переключение destinations не проходит через composition и не может открыть новую production database.
- `LifeOsAppDependencies` является единственным владельцем production database и идемпотентно кэширует `close()` future; `LifeOSApp` закрывает owned dependencies при exit request/dispose. Существующие composition/lifecycle tests подтверждают закрытие database и передачу того же repository instance в Presentation.
- English/Russian shell destination labels и locale behavior продолжают покрываться localization/widget tests; localization не вышла за Presentation/composition.
- Production sources и dependencies не изменялись; изменение ограничено focused test и execution-plan evidence.
- Focused lifecycle/navigation/composition/localization tests: PASS — 16 tests.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 47 tests.
- Import-boundary scan: PASS — Domain/Application не получили framework/platform dependencies, Presentation не импортирует Infrastructure/Drift, localization не проникла в Domain/Application/Infrastructure, persistence construction отсутствует в Presentation/Application.
- Routing dependency scan: PASS — `go_router`, `auto_route` и `beamer` отсутствуют в dependencies/imports.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.

---

## DS-07 — Финальный аудит desktop shell

Статус: done

Зависит от: DS-06

### Цель

Выполнить итоговый архитектурный и интеграционный аудит milestone desktop shell.

### End-to-end проверка

Подтвердить, что LifeOS может:

1. запуститься с production desktop shell;
2. показать локализованную основную навигацию;
3. переключаться между настроенными destinations;
4. открыть Tasks;
5. создать Task;
6. показать сохранённые Tasks;
7. переключить completion;
8. сохранить Task state через существующий persistence lifecycle;
9. сохранить принятые архитектурные границы.

### Архитектурный аудит

Подтвердить:

- Presentation владеет shell/navigation;
- Application продолжает отвечать за координацию use cases;
- Domain остаётся независимым от framework;
- Infrastructure остаётся за Domain abstractions;
- localization остаётся только в Presentation;
- persistence lifecycle остаётся во владении composition;
- будущие features не были искусственно реализованы только ради navigation;
- generated files не редактировались вручную.

### Обязательная проверка

- соответствующие focused tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- проверка/generation локализации;
- проверка Drift generation, если относится к изменениям;
- dependency hygiene;
- `git diff --check`.

### Definition of Done

- DS-01 — DS-07 имеют статус `done`;
- desktop shell пригодна для использования на Windows;
- существующий Task vertical slice остаётся функциональным;
- английский и русский UI продолжают поддерживаться;
- architecture audit проходит;
- отсутствуют нерешённые blockers;
- этот execution plan имеет статус `completed`.

### Результат / доказательства

- Architecture gate: PASS. Нерешённых архитектурных вопросов и необходимости нового ADR не обнаружено; production-код не потребовал исправлений.
- Перед DS-07 отдельный DS-06 commit `037faa1` (`test: verify shell navigation lifecycle`) содержал только execution plan и focused shell lifecycle test. На старте DS-07 единственным незакоммиченным пользовательским файлом был `.obsidian/workspace.json`, который не затрагивался.
- End-to-end audit подтверждает production bootstrap через `main()` и `createProductionDependencies()`, запуск `LifeOSApp` с desktop shell, локализованный `NavigationRail`, переключение `Home <-> Tasks`, отображение persisted Tasks, создание Task и completion toggle через Application/Domain boundaries.
- File-backed persistence tests подтверждают закрытие/reopen `lifeos.db` без потери Task state; repository tests подтверждают атомарную запись Entity/Task state и Outbox change.
- `IndexedStack` сохраняет Task Presentation subtree: несохранённый draft и provider state переживают переключение destinations, а repository load не повторяется.
- Architecture audit: PASS — Presentation владеет shell/navigation и локальным destination state; Application координирует use cases; Domain не зависит от Flutter, Drift, UUID, localization или platform APIs; Infrastructure реализует Domain repository abstraction; composition root единолично создаёт и закрывает production database/repository lifecycle.
- Navigation не создаёт repositories/database; localization не проникла в Domain/Application/Infrastructure; `Home` остаётся минимальным Presentation-only placeholder; destinations ограничены `Home` и `Tasks`.
- `Notes`, `Projects`, `Search`, `AI` и `Settings` не создавались; routing/responsive dependencies не добавлялись; dependency manifests не изменены.
- Focused shell/navigation/Task/Application/composition/persistence/localization tests: PASS — 38 tests.
- `flutter analyze`: PASS — no issues.
- `flutter test`: PASS — 47 tests.
- Import-boundary scan: PASS — все проверенные dependency boundaries соблюдены, persistence construction отсутствует в Presentation/Application.
- Routing dependency scan: PASS — `go_router`, `auto_route` и `beamer` отсутствуют в dependencies/imports.
- `flutter gen-l10n`: PASS; повторная генерация не изменила ARB/generated localization files.
- Drift generation: not applicable — schema и Drift source/generated files не затрагивались; generated Drift diff отсутствует, repository и file-backed tests проходят.
- Dependency hygiene: PASS — `dart pub deps --style=compact` успешно разрешил текущий dependency graph; `pubspec.yaml`/`pubspec.lock` не изменены. Попытка эквивалентной проверки через `flutter pub deps` зависла без вывода и была остановлена без изменения файлов.
- Generated-file check: PASS — diff в localization и `*.g.dart` отсутствует; generated files вручную не редактировались.
- Scope audit: PASS — production sources не изменены, преждевременные feature directories отсутствуют, явно отложенный scope ниже остаётся без изменений.
- `git diff --check`: PASS; выведены только информационные предупреждения Git о преобразовании LF/CRLF.
- Итоговый Git ref на момент завершения validation: `HEAD` = `037faa1`, `origin/main` = `037faa1`, divergence `0/0`. После DS-07 изменён только этот execution plan; пользовательский `.obsidian/workspace.json` остаётся отдельным незакоммиченным изменением.

---

# Явно отложено

За пределами этого execution plan остаются:

- полноценный Home dashboard;
- реализация Notes;
- реализация Projects;
- production Search;
- AI assistant;
- persistence Settings;
- ручной выбор языка пользователем;
- advanced routing/deep links;
- восстановление navigation history;
- multi-window;
- mobile/tablet shell;
- remote Sync;
- backup/export;
- semantic search;
- полный redesign визуальной системы.

---

# Точка возобновления

Текущий checkpoint: отсутствует — execution plan completed

Следующее действие:

Остановиться для пользовательского review. Не начинать новый execution plan автоматически.

DS-07 завершён и валидирован. Desktop Shell / Navigation execution plan завершён.

---

# Состояние выполнения плана

Статус: completed

Завершённые checkpoints: DS-01, DS-02, DS-03, DS-04, DS-05, DS-06, DS-07

Текущий checkpoint: отсутствует

Blockers: отсутствуют
