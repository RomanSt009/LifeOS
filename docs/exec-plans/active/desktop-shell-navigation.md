# LifeOS Desktop Shell / Navigation — план выполнения

Статус: active

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

Статус: pending

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

Pending.

---

## DS-02 — Основа desktop shell

Статус: pending

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

Pending.

---

## DS-03 — Интеграция Tasks в навигацию

Статус: pending

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

Pending.

---

## DS-04 — Начальная структура разделов LifeOS

Статус: pending

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

Pending.

---

## DS-05 — Устойчивость desktop layout

Статус: pending

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

Pending.

---

## DS-06 — Аудит navigation state и lifecycle

Статус: pending

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

Pending.

---

## DS-07 — Финальный аудит desktop shell

Статус: pending

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

Pending.

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

Текущий checkpoint: DS-01

Следующее действие:

Сверить состояние репозитория и Git, прочитать управляющие ADR и изучить текущую структуру Presentation/application до внесения изменений в shell.

Не начинать DS-02, пока architecture gate DS-01 не разрешён.

---

# Состояние выполнения плана

Статус: active

Завершённые checkpoints: отсутствуют

Текущий checkpoint: DS-01

Blockers: неизвестны
