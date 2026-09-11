# LifeOS MVP — активный план выполнения

Статус: завершён

> **Историческое уточнение:** `MVP` в названии этого execution plan означает первый ограниченный local-first Task vertical slice. Это не утверждение о завершении более широкой product MVP boundary из `docs/07-roadmap/roadmap.md`, `technical-architecture.md` или `ui-ux-architecture.md`.

Последняя проверка: 2026-09-10

## 1. Цель

Реализовать первый действительно пригодный для использования local-first vertical slice LifeOS для Windows.

Milestone завершён, когда пользователь может:

1. запустить LifeOS;
2. создать Task;
3. увидеть Task в UI;
4. переключить её состояние completion;
5. закрыть LifeOS;
6. повторно открыть LifeOS;
7. увидеть сохранённую Task и её состояние;
8. выполнить эти операции через принятую архитектуру:

Presentation
→ Application
→ Domain repository abstraction
← Infrastructure
→ Drift
→ SQLite

Каждая локальная синхронизируемая мутация Entity должна продолжать создавать требуемое изменение Outbox атомарно с Domain State.

Remote Sync не входит в этот milestone.

---

## 2. Существующая основа

До начала этого плана уже были созданы:

- каркас Flutter Windows application;
- набор принятых ADR по ADR-0023 включительно;
- контракт Domain Entity;
- типизированная Entity identity;
- Domain Entity `LifeOsTask`;
- Domain-поведение Task completion;
- Application use cases;
- принадлежащий Domain `LifeOsTaskRepository`;
- реализация Drift в Infrastructure;
- schema entities + tasks + outbox;
- явный mapping Domain/Persistence;
- атомарная transaction Domain State + Outbox;
- детерминированные persistence tests;
- привязка Riverpod в Presentation;
- минимальный UI Task completion;
- `ProviderScope` и provider overrides;
- тесты/scans архитектурных границ;
- успешно проходящие `flutter analyze`/`flutter test` на foundation checkpoint.

Не пересоздавать эти компоненты только потому, что план начинается после их реализации.

Перед использованием этого описания сверяться с фактическим состоянием репозитория.

---

## 3. Руководящие документы

Всегда сначала читать `AGENTS.md`.

К относящимся к плану ADR относятся, помимо прочих:

- ADR-0002 — стек приложения
- ADR-0003 — структура проекта
- ADR-0005 — Local-First Data Architecture
- ADR-0006 — Database Schema, если решение не заменено более поздним
- ADR-0007 — стратегия Dependency Injection
- ADR-0016 — Domain Model и архитектура Entity
- ADR-0017 — архитектура database и persistence
- ADR-0019 — модель отслеживания изменений и Sync data
- ADR-0020 — persistence schema SQLite
- ADR-0021 — Flutter Persistence Stack
- ADR-0022 — архитектура Flutter-проекта
- ADR-0023 — начальные решения по persistence Entity и Outbox
- ADR-0027 — стратегия локализации

Более поздние явные решения с приоритетом имеют преимущество перед более ранними противоречащими рекомендациями.

---

# 4. Текущий milestone

Milestone: локальный сохраняемый Task vertical slice

Статус: завершён

Текущий checkpoint: CP-08

Следующий готовый checkpoint: отсутствует — план завершён

Blockers: отсутствуют.

---

# 5. Контрольные точки

## CP-01 — Решение о жизненном цикле production database

Статус: выполнен

### Цель

Определить необходимые Windows-приложению расположение, открытие, владение и жизненный цикл закрытия production SQLite database.

### Относящиеся ADR

Прочитать все ADR по persistence/composition, особенно:

- ADR-0005
- ADR-0007
- ADR-0017
- ADR-0020
- ADR-0021
- ADR-0022
- ADR-0023
- ADR-0024

### Разрешённая область

- провести аудит существующих ADR;
- определить, достаточно ли в них описан жизненный цикл;
- если он описан достаточно, реализовать минимальный соответствующий требованиям bootstrap database;
- если описания недостаточно, остановиться и запросить минимально необходимое архитектурное решение.

### Не входит в цель

Не реализовывать:

- Sync;
- регистрацию устройств;
- backup;
- migrations сверх требований текущей schema;
- универсальный database framework;
- несколько профилей database.

### Критерии завершения

Один из вариантов:

A. Жизненный цикл production database уже архитектурно определён, реализован и протестирован.

ИЛИ

B. Checkpoint отмечен как blocked с точным описанием нерешённого архитектурного решения.

Не придумывать произвольный путь файловой системы.

### Проверка

При выполнении реализации:

- flutter analyze
- flutter test
- относящиеся к задаче database lifecycle tests
- git diff --check

### Результат / доказательства

Завершено 2026-09-08.

Доказательства:

- ADR-0007 определяет один экземпляр database на время жизни приложения, создаваемый и закрываемый через composition root;
- ADR-0024 принят и закрывает architecture gate по расположению и жизненному циклу production database;
- production database использует каталог application-support операционной системы и имя файла `lifeos.db`;
- каталог application-support определяется через подходящую платформенную абстракцию Flutter, а не жёстко заданный путь ОС;
- composition root владеет одним экземпляром production database на процесс приложения и закрывает его при завершении жизненного цикла persistence;
- `openProductionDatabase` получает каталог application-support через `path_provider`, добавляет `lifeos.db` с помощью `path` и открывает Drift в фоновом native executor;
- `LifeOsAppDependencies` владеет database и обеспечивает идемпотентное асинхронное закрытие;
- `LifeOSApp` закрывает принадлежащие ему зависимости по запросу выхода и при удалении root widget;
- focused file-backed test сохраняет Task и изменение Outbox, закрывает database, повторно открывает тот же файл и проверяет сохранённое состояние;
- app lifecycle test проверяет, что удаление root app закрывает принадлежащую ему database.

Проверка:

- focused database/app lifecycle tests: PASS — 2 теста;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 18 тестов;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-02 — Сборка production repository

Статус: выполнен

Зависит от: CP-01

### Цель

Подключить production-реализацию `LifeOsTaskRepository` через composition root приложения, не раскрывая Infrastructure слоям Presentation или Application.

### Относящиеся ADR

- ADR-0007
- ADR-0021
- ADR-0022
- ADR-0023
- ADR-0025

### Разрешённая область

- composition приложения;
- providers зависимостей Riverpod;
- создание конкретной Infrastructure на границе composition;
- безопасное для lifecycle закрытие зависимостей.

### Не входит в цель

- service locator;
- GetIt;
- глобальный изменяемый singleton;
- новая abstraction repository;
- переработка UI.

### Критерии завершения

- production composition может предоставить Application behavior на основе Domain repository;
- Presentation не импортирует Infrastructure;
- Application не импортирует Infrastructure;
- сохраняется возможность тестирования через provider override.

### Проверка

- flutter analyze
- flutter test
- import-boundary scan
- git diff --check

### Результат / доказательства

Завершено 2026-09-08.

Доказательства:

- ADR-0025 закрыл composition gate для production identity;
- Infrastructure теперь предоставляет внедряемый генератор UUID v4;
- file-backed хранилище device identity создаёт один идентификатор в application-support storage и повторно использует его после открытия;
- composition root получает стабильный device ID, открывает принадлежащую ему database и создаёт `DriftLifeOsTaskRepository` с генератором UUID;
- `LifeOsAppDependencies` предоставляет repository через Domain interface и сохраняет владение закрытием database;
- `LifeOSApp` переопределяет provider Domain repository на границе приложения;
- производный от Application toggle use case доступен без импортов Infrastructure в Presentation или Application;
- сохраняется поддержка прямых provider overrides, используемых существующими widget tests.

Проверка:

- focused identity/composition/app tests: PASS — 5 тестов;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 22 теста;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-03 — Чтение коллекции Task

Статус: выполнен

Зависит от: CP-02

### Цель

Добавить минимальные возможности Domain/Application/Infrastructure, необходимые для загрузки коллекции Task в UI.

### Архитектурная проверка

До редактирования определить минимальный контракт repository/query, соответствующий текущим ADR.

Не добавлять универсальный `Repository<T>`.

### Разрешённая область

- контракт Domain repository, если он действительно необходим;
- Application query/use case;
- реализация query в Infrastructure;
- тесты.

### Не входит в цель

- pagination, если она не требуется сейчас;
- фильтры;
- framework сортировки;
- поиск;
- проекты/теги.

### Критерии завершения

- Application может запрашивать сохранённые Task через принадлежащую Domain abstraction;
- реализация Drift возвращает преобразованные Domain Task;
- поведение пустой database определено и протестировано;
- границы слоёв остаются корректными.

### Проверка

- тесты Domain/Application, где применимо;
- тесты Infrastructure;
- flutter analyze
- flutter test
- git diff --check

### Результат / доказательства

Завершено 2026-09-08.

Доказательства:

- architecture gate выбрал одну focused-операцию `getAll` в существующем принадлежащем Domain `LifeOsTaskRepository`;
- универсальный repository, pagination, filtering, search и framework сортировки не добавлялись;
- `GetLifeOsTasks` предоставляет query коллекции через Application;
- `DriftLifeOsTaskRepository` загружает metadata Task Entity и типизированные поля Task через объединённый Drift query и преобразует их в Domain Entity;
- пустая database возвращает пустую коллекцию;
- поведение коллекции в Application и Infrastructure покрыто focused tests.

Проверка:

- focused Application/Infrastructure tests: PASS — 7 тестов;
- `flutter analyze`: PASS — замечаний нет после устранения двух локальных style findings;
- `flutter test`: PASS — 25 тестов;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-04 — Presentation списка Task

Статус: выполнен

Зависит от: CP-03

### Цель

Отображать сохранённые Task через Riverpod и Application behavior.

### Разрешённая область

- минимальный UI списка Task;
- состояние загрузки;
- пустое состояние;
- ограниченное состояние ошибки;
- controller/provider Presentation.

### Не входит в цель

- окончательный визуальный дизайн;
- сложная navigation;
- фильтрация;
- поиск;
- анимации.

### Критерии завершения

- UI отображает пустое состояние Task;
- UI отображает сохранённые Task;
- Presentation не импортирует ни Infrastructure, ни Drift;
- widget tests используют provider overrides там, где это уместно.

### Проверка

- widget tests
- flutter analyze
- flutter test
- import-boundary scan
- git diff --check

### Результат / доказательства

Завершено 2026-09-09.

Доказательства:

- `TaskListController` загружает сохранённые Task через Application use case `GetLifeOsTasks`;
- production composition приложения предоставляет существующий provider Domain repository;
- shell отображает список Task без импорта Infrastructure или Drift;
- UI имеет явные состояния загрузки, пустого и заполненного списка, а также ограниченной ошибки;
- заполненные строки отображают названия Task и состояние completion без реализации mutation behavior CP-06;
- widget tests используют provider override и покрывают все требуемые состояния.

Проверка:

- focused widget tests: PASS — 4 теста;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 28 тестов;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-05 — Вертикальный путь создания Task

Статус: выполнен

Зависит от: CP-04

### Цель

Обеспечить создание минимальной Task из UI и её сохранение через принятую архитектуру.

### Архитектурная проверка

До реализации проверить, как создаются Entity ID, timestamps, version, lifecycle, source, `change_id` и `device_id`.

Если генерация production identity не определена принятыми ADR, не придумывать package или lifecycle.

Отметить checkpoint как blocked и запросить минимально необходимое решение.

### Разрешённая область

- минимальный UI создания;
- Domain creation behavior/factory, если это архитектурно уместно;
- Application use case;
- использование repository;
- persistence в Infrastructure;
- поведение Outbox;
- тесты.

### Не входит в цель

- сроки выполнения;
- приоритет;
- теги;
- проекты;
- повторение;
- расширенный редактор.

### Критерии завершения

- пользователь может ввести название Task;
- создаётся валидная Task;
- Task сохраняется;
- обязательные metadata Entity валидны;
- запись Outbox создаётся атомарно;
- UI отображает созданную Task.

### Проверка

- Domain/Application tests
- persistence tests
- widget tests
- flutter analyze
- flutter test
- git diff --check

### Результат / доказательства

Завершено 2026-09-09.

Доказательства:

- ADR-0026 принят и закрывает architecture gate создания Entity;
- production Entity ID используют UUID v4 через внедряемый generator на границе Application composition;
- production-время UTC предоставляется через внедряемые clock;
- новая пользовательская Task создаётся с lifecycle `active`, version 1 и source `user`;
- создание получает одну временную метку UTC и использует её для `createdAt` и `updatedAt`;
- `LifeOsTask.createUserTask` владеет инвариантами title, typed ID, UTC и начальных metadata;
- `CreateLifeOsTask` получает один внедрённый ID и временную метку UTC, сохраняет через Domain repository и возвращает сохранённую Task;
- production composition предоставляет Entity ID UUID v4 и production UTC clock;
- UI списка Task принимает название и сразу отображает сохранённую Task;
- focused tests Domain, Application, composition, persistence и widgets покрывают vertical path.

Проверка:

- focused tests CP-05: PASS — 19 тестов;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 33 теста;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-06 — Сохраняемое переключение completion

Статус: выполнен

Зависит от: CP-05

### Цель

Подключить существующее поведение Task completion к реальному сохраняемому списку Task.

### Разрешённая область

- существующее Domain toggle behavior;
- существующий Application use case сохраняемого переключения;
- обновление Presentation refresh/state;
- тесты.

### Не входит в цель

- пакетное завершение;
- framework отмены действий;
- event sourcing;
- Sync.

### Критерии завершения

- переход incomplete → complete сохраняется;
- переход complete → incomplete сохраняется;
- UI обновляется корректно;
- состояние сохраняется после перезапуска;
- каждая мутация создаёт требуемое изменение Outbox.

### Проверка

- Application tests
- persistence tests
- widget tests
- flutter analyze
- flutter test
- git diff --check

### Результат / доказательства

Завершено 2026-09-09.

Доказательства:

- сохраняемый список Task вызывает существующий Application toggle use case через Riverpod;
- переходы incomplete-to-complete и complete-to-incomplete обновляют UI и persistence;
- Domain completion behavior остаётся immutable и увеличивает metadata версии Entity;
- каждая мутация completion создаёт собственное атомарное изменение Outbox `UPDATE`;
- focused file-backed test проверяет оба перехода, три изменения Outbox с учётом создания и итоговое состояние после повторного открытия database.

Проверка:

- focused tests CP-06: PASS — 16 тестов;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 34 теста;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-06A — Основа локализации

Статус: выполнен

Зависит от: CP-06

### Цель

Создать локализацию Flutter для существующей поверхности Presentation без изменения завершённого поведения Task.

### Относящиеся ADR

- ADR-0022
- ADR-0027

### Разрешённая область

- инфраструктура локализации Flutter с использованием `flutter_localizations`, `gen_l10n` и ресурсов ARB;
- ресурсы локализации на английском и русском в `lib/l10n/`;
- перенос существующих видимых пользователю статических строк Presentation;
- настройка поддерживаемых locale и fallback;
- focused tests локализации и Presentation.

### Не входит в цель

- UI ручного выбора языка;
- синхронизация языка пользователя;
- платформа управления переводами;
- перевод с помощью AI;
- настройки даты/времени для конкретного locale;
- redesign UI для RTL;
- изменения завершённого поведения Task.

### Критерии завершения

- загружаются английские и русские ресурсы;
- поддерживаемые locale настроены;
- платформенный locale выбирает английский или русский язык, если он поддерживается;
- неподдерживаемые locale используют английский язык без нарушения запуска;
- существующие видимые пользователю статические строки Presentation используют ресурсы локализации;
- Domain, Application и Infrastructure не зависят от Flutter localization APIs;
- generated code локализации не редактируется вручную.

### Проверка

- focused localization and Presentation tests
- flutter analyze
- flutter test
- import-boundary scan
- git diff --check

### Результат / доказательства

Завершено 2026-09-10.

Доказательства:

- стандартный механизм Flutter `flutter_localizations` и `gen_l10n` включён с ресурсами ARB в `lib/l10n/`;
- английские и русские ресурсы определяют каждую текущую видимую статическую строку Presentation;
- generated sources локализации созданы командой `flutter gen-l10n` и не редактировались вручную;
- production `MaterialApp` использует сгенерированные delegates и список поддерживаемых locale;
- платформенные английский и русский locale разрешаются в соответствующие ресурсы, а неподдерживаемые locale явно используют английский язык;
- shell, состояния списка Task, действия completion, labels формы, feedback валидации и ограниченные ошибки используют ресурсы локализации;
- зависимости локализации остаются за пределами Domain, Application и Infrastructure.

Проверка:

- focused localization/Presentation tests: PASS — 14 тестов;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 39 тестов;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-07 — Проверка persistence после перезапуска

Статус: выполнен

Зависит от: CP-06A

### Цель

Проверить основную local-first гарантию MVP при перезапуске приложения/database.

### Разрешённая область

- integration test или минимальный надёжный эквивалент;
- исправления lifecycle, непосредственно необходимые тесту.

### Критерии завершения

Task, записанная с использованием эквивалентного production жизненного цикла database, загружается после закрытия и повторного открытия границы persistence database/application.

Состояние completion и обязательные metadata Entity сохраняются после повторного открытия.

### Проверка

- focused restart persistence test
- полный `flutter test`
- flutter analyze
- git diff --check

### Результат / доказательства

Завершено 2026-09-10.

Доказательства:

- architecture gate подтвердил, что существующие focused file-backed tests являются минимальным надёжным эквивалентом, необходимым этому checkpoint;
- `openProductionDatabase` использует production filename и эквивалентную production границу каталога application-support;
- завершённая Task записывается, database закрывается, тот же файл открывается повторно, а преобразованная Domain Task загружается без изменений;
- typed identity, title, состояние completion, `createdAt`, `updatedAt`, lifecycle, version и source сохраняются после повторного открытия;
- второй путь перезапуска проверяет переходы complete и incomplete через повторные закрытия и открытия, включая итоговые metadata version и timestamp;
- требуемые записи Outbox сохраняются на протяжении той же последовательности перезапусков;
- для CP-07 не потребовалось изменять production-код или тесты.

Проверка:

- focused restart persistence tests: PASS — 2 теста;
- `flutter analyze`: PASS — замечаний нет;
- `flutter test`: PASS — 39 тестов;
- import-boundary scan: PASS;
- `git diff --check`: PASS.

---

## CP-08 — Финальный аудит MVP vertical slice

Статус: выполнен

Зависит от: CP-07

### Цель

Провести аудит полного локального сохраняемого Task vertical slice.

### Проверить

- архитектурные границы;
- соответствие ADR;
- жизненный цикл production DB;
- сборку repository;
- чтение Task;
- создание Task;
- completion Task;
- persistence после повторного открытия;
- атомарность Outbox;
- согласованность generated Drift;
- чистоту зависимостей;
- тесты.

### Не входит в цель

Не добавлять следующую feature во время аудита.

### Критерии завершения

- `flutter analyze` проходит;
- `flutter test` проходит;
- `git diff --check` проходит;
- в реализованном vertical slice нет нерешённых дефектов;
- отложенная архитектура задокументирована;
- статус плана изменён на completed.

### Результат / доказательства

- Architecture gate пройден с учётом регулирующих Task, persistence, composition, identity и localization ADR; нерешённых решений не обнаружено.
- Production composition получает каталог application-support ОС, открывает одну file-backed `lifeos.db`, предоставляет Drift repository и Application create use case и владеет идемпотентным закрытием database.
- Существующие focused tests проверяют создание Task с обязательными metadata Entity, чтение repository, отображение в Presentation, переключение completion через Application и Domain, атомарную запись и rollback Domain State + Outbox, стабильную device identity и сохранение состояния после повторного открытия file-backed database.
- Английские и русские ресурсы ARB, generated delegates, разрешение платформенного locale и безопасный fallback на английский остаются покрытыми focused localization/widget tests.
- Import-boundary scan пройден: Domain не содержит импортов Flutter, Drift, UUID, localization или platform; Application не содержит импортов Infrastructure/framework/platform; Presentation не содержит импортов Infrastructure/Drift или создания persistence; localization отсутствует в Domain, Application и Infrastructure; Infrastructure реализует abstraction Domain repository.
- `flutter gen-l10n`: PASS; отслеживаемый diff generated localization отсутствует.
- `dart run build_runner build`: PASS; отслеживаемый diff generated Drift отсутствует.
- чистота зависимостей: PASS — разрешённый граф зависимостей содержит только принятый runtime и generation stack; аудит не добавил зависимостей.
- focused vertical-slice tests: PASS — 37 тестов.
- `flutter analyze`: PASS — замечаний нет.
- `flutter test`: PASS — 39 тестов.
- `git diff --check`: PASS.
- Исправления production-кода или тестов не потребовались; нерешённых дефектов не обнаружено.

---

# 6. Явно отложено за пределы этого milestone

Не реализовывать в рамках этого плана, пока принятое архитектурное решение явно не включит это в scope:

- редактирование Task;
- UI удаления/lifecycle Task;
- расширенные поля Task;
- navigation architecture сверх необходимой;
- локальный поиск;
- backup/export;
- дополнительные типы Entity;
- интеграция AI provider;
- AI context engine;
- tool calling;
- embeddings;
- семантический поиск;
- production Sync;
- Sync Worker;
- сетевой transport;
- server/API;
- разрешение конфликтов;
- production-регистрация устройств;
- подтверждение/очистка Outbox;
- политика повторных сетевых запросов.

---

# 7. Точка возобновления

Этот раздел поддерживается Codex.

Последнее обновление checkpoint: 2026-09-10 — CP-08 выполнен; execution plan завершён

Текущий checkpoint: CP-08

Статус текущего checkpoint: выполнен

Последняя успешная проверка:

- Foundation `flutter analyze`: PASS
- Foundation `flutter test`: PASS — 16 тестов
- Foundation `git diff --check`: PASS
- CP-01 focused lifecycle tests: PASS — 2 теста
- CP-01 `flutter analyze`: PASS — замечаний нет
- CP-01 `flutter test`: PASS — 18 тестов
- CP-01 import-boundary scan: PASS
- CP-01 `git diff --check`: PASS
- CP-02 focused identity/composition/app tests: PASS — 5 тестов
- CP-02 `flutter analyze`: PASS — замечаний нет
- CP-02 `flutter test`: PASS — 22 теста
- CP-02 import-boundary scan: PASS
- CP-02 `git diff --check`: PASS
- CP-03 focused Application/Infrastructure tests: PASS — 7 тестов
- CP-03 `flutter analyze`: PASS — замечаний нет
- CP-03 `flutter test`: PASS — 25 тестов
- CP-03 import-boundary scan: PASS
- CP-03 `git diff --check`: PASS
- CP-04 focused widget tests: PASS — 4 теста
- CP-04 `flutter analyze`: PASS — замечаний нет
- CP-04 `flutter test`: PASS — 28 тестов
- CP-04 import-boundary scan: PASS
- CP-04 `git diff --check`: PASS
- CP-05 focused tests: PASS — 19 тестов
- CP-05 `flutter analyze`: PASS — замечаний нет
- CP-05 `flutter test`: PASS — 33 теста
- CP-05 import-boundary scan: PASS
- CP-05 `git diff --check`: PASS
- CP-06 focused tests: PASS — 16 тестов
- CP-06 `flutter analyze`: PASS — замечаний нет
- CP-06 `flutter test`: PASS — 34 теста
- CP-06 import-boundary scan: PASS
- CP-06 `git diff --check`: PASS
- CP-06A focused localization/Presentation tests: PASS — 14 тестов
- CP-06A `flutter analyze`: PASS — замечаний нет
- CP-06A `flutter test`: PASS — 39 тестов
- CP-06A import-boundary scan: PASS
- CP-06A `git diff --check`: PASS
- CP-07 focused restart persistence tests: PASS — 2 теста
- CP-07 `flutter analyze`: PASS — замечаний нет
- CP-07 `flutter test`: PASS — 39 тестов
- CP-07 import-boundary scan: PASS
- CP-07 `git diff --check`: PASS
- CP-08 focused vertical-slice tests: PASS — 37 тестов
- CP-08 проверка согласованности `flutter gen-l10n`: PASS — отслеживаемый diff generated localization отсутствует
- CP-08 проверка согласованности Drift `build_runner`: PASS — отслеживаемый diff generated Drift отсутствует
- CP-08 проверка чистоты зависимостей: PASS
- CP-08 `flutter analyze`: PASS — замечаний нет
- CP-08 `flutter test`: PASS — 39 тестов
- CP-08 import-boundary scan: PASS
- CP-08 `git diff --check`: PASS

Работа, выполненная в текущем checkpoint:

- CP-01 — CP-06 выполнены и проверены;
- в CP-06 завершены сохраняемое completion, состояние UI, Outbox и поведение при перезапуске.
- ADR-0027 принят и определяет архитектуру локализации.
- Architecture gate CP-06A пройден с учётом ADR-0022 и ADR-0027.
- В CP-06A завершены ресурсы локализации, production configuration, миграция Presentation и focused tests.
- Architecture gate CP-07 подтвердил, что существующие file-backed restart tests соответствуют принятым решениям по production lifecycle и persistence.
- Проверка restart persistence CP-07 завершена без дополнительных изменений production-кода или тестов.
- CP-08 провёл аудит полного локального сохраняемого Task vertical slice относительно состояния репозитория и регулирующих ADR.
- CP-08 не обнаружил нерешённых архитектурных решений или дефектов реализации и не потребовал изменений production-кода или тестов.
- Все критерии завершения checkpoint и плана выполнены; этот execution plan завершён.

Оставшаяся работа в текущем checkpoint:

- отсутствует; остановиться для пользовательской проверки и не начинать другой execution plan.

Известные blockers:

- отсутствуют.

Архитектурные решения:

- ADR-0024 принят: production DB использует каталог application-support ОС / `lifeos.db`; composition root владеет одним экземпляром production database и закрывает его в конце lifecycle.
- ADR-0025 принят.
- Production `change_id` = UUID v4, генерируемый в Infrastructure через внедряемый generator.
- Production `device_id` = UUID v4, однократно генерируемый, сохраняемый в application-support storage и повторно используемый между запусками.
- ADR-0026 принят.
- Production Entity ID = UUID v4 через внедряемый generator на границе Application composition.
- Production UTC time = внедряемые clock, предоставляемые composition.
- Начальные значения новой пользовательской Task:
  - lifecycle = active
  - version = 1
  - source = user
  - createdAt = updatedAt = одна внедрённая временная метка UTC

Примечания о working tree:

- до этого bookkeeping update файл `.obsidian/workspace.json` был изменён, а ADR-0026 был неотслеживаемой пользовательской работой;
- изменение агента: только bookkeeping этого execution plan;
- `.obsidian/workspace.json` и ADR-0026 не изменялись агентом;
- в CP-05 агент изменял production-код, тесты и этот план;
- в CP-06 агент изменял production-код, тесты и этот план;
- в CP-06A агент изменял production localization, тесты, generated sources и этот план;
- CP-07 потребовал только bookkeeping этого execution plan, поскольку его Definition of Done уже был покрыт тестами репозитория;
- в начале CP-08 `HEAD` был `23a4a46` в `main`, на один commit впереди `origin/main`, и был изменён только пользовательский `.obsidian/workspace.json`;
- CP-08 изменил только bookkeeping этого execution plan; запуски generator не создали отслеживаемых изменений source, а `.obsidian/workspace.json` не изменялся агентом;
- CP-08 завершён;
- никогда не считать этот раздел более актуальным, чем фактическое состояние репозитория.

---

# 8. Критерии завершения плана

Этот execution plan завершён только тогда, когда:

- CP-01 — CP-06, CP-06A, CP-07 и CP-08 выполнены;
- LifeOS использует реальный production lifecycle SQLite;
- пользователь может создать Task;
- сохранённые Task отображаются;
- completion можно переключать и сохранять;
- состояние сохраняется после перезапуска persistence;
- обязательное поведение Outbox остаётся атомарным;
- архитектурные границы соблюдены;
- `flutter analyze` проходит;
- `flutter test` проходит;
- `git diff --check` проходит.

После завершения остановиться для пользовательской проверки.

Не начинать следующий milestone автоматически.
