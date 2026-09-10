# LifeOS Backup / Export — план выполнения

Статус: blocked

## Цель

Дать пользователю безопасный локальный способ создать восстанавливаемую копию данных LifeOS и получить переносимое представление собственных данных, сохранив независимость Backup, Export, Restore, Import, Sync и Outbox replication.

Milestone не должен связывать пользовательский формат с внутренней Drift schema, дублировать production database lifecycle или превращать Backup в скрытый Sync.

## Архитектурная основа

- `AGENTS.md`;
- ADR-0005 — local-first data architecture;
- ADR-0007 — dependency injection и composition root;
- ADR-0009 — synchronization architecture;
- ADR-0010 — security architecture;
- ADR-0011 — Backup and Export Architecture;
- ADR-0016 — Domain Model and Entity Architecture;
- ADR-0017 — Database and Persistence Architecture;
- ADR-0018 — Sync and Conflict Resolution Architecture;
- ADR-0019 — Change Tracking and Sync Data Model;
- ADR-0020 — SQLite Persistence Schema;
- ADR-0021 — Flutter Persistence Stack;
- ADR-0022 — Flutter Project Architecture;
- ADR-0023 — initial Entity persistence и Outbox;
- ADR-0024 — production database lifecycle;
- ADR-0025 — local change и device identity;
- ADR-0026 — Entity creation identity/defaults;
- ADR-0027 — localization strategy.

Сохраняется направление зависимостей:

```text
Presentation -> Application -> Domain
Infrastructure -> внутренние abstractions
Composition root -> concrete Infrastructure lifecycle
```

## Общие ограничения

- Backup, Export, Restore, Import, Sync и Outbox replication рассматриваются как разные ответственности;
- базовые локальные операции не требуют сети, аккаунта или cloud provider;
- Presentation не обращается напрямую к Drift, SQLite или platform filesystem;
- внутренний SQLite schema не становится публичным Export contract;
- production database и device identity продолжают принадлежать существующему composition lifecycle;
- новые package dependencies требуют отдельного обоснования и approval;
- generated files не редактируются вручную;
- cloud backup, Sync, Settings destination и encryption implementation не вводятся неявно.

---

# Checkpoints

## BE-01 — Аудит требований и architecture gate

Статус: blocked

### Goal

Сверить документацию, ADR, Git и текущую persistence implementation; определить границы Backup/Export и выявить долгоживущие решения, необходимые до проектирования формата.

### Связанные ADR

- ADR-0005;
- ADR-0007;
- ADR-0009;
- ADR-0010;
- ADR-0011;
- ADR-0016 — ADR-0027.

### Scope

- организация execution plans;
- read-only аудит Domain/Application/Infrastructure/Presentation, Drift schema, composition, identity и persistence tests;
- анализ Backup, Export, Restore, Import, Outbox, device identity, format/versioning, compatibility, atomicity, validation, security и filesystem boundaries;
- фиксация architecture gate и точной точки возобновления.

### Non-goals

- production-код и tests;
- Drift schema, migrations и generation;
- реализация Backup, Export, Restore или Import;
- file picker, Settings, cloud, encryption dependency;
- изменение Outbox или device identity;
- BE-02.

### Definition of Done

- plans организованы и этот файл является единственным primary active plan;
- фактическое состояние данных и lifecycle зафиксировано;
- варианты формата сравнены;
- решения классифицированы как существующие, локальные, требующие ADR или отложенные;
- blocking architecture questions явно записаны;
- выполнена уместная baseline validation;
- указан точный Git state и resume point.

### Validation

- `flutter analyze`;
- полный `flutter test` либо достаточный persistence-focused baseline;
- import-boundary scan;
- `dart pub deps --style=compact`;
- `git diff --check`.

### Result / blocker

Architecture gate: BLOCKED. До BE-02 требуется новый принятый ADR, потому что существующие ADR намеренно не определяют несколько связанных долгоживущих решений, непосредственно формирующих внешний Backup contract.

#### Сверка Git, планов и repository

- На старте BE-01 `HEAD` = `abceff3fdbe90ceb48d76ae753dc24d434078f55`, branch `main` был синхронизирован с `origin/main`.
- Единственным исходным незакоммиченным файлом был пользовательский `.obsidian/workspace.json`; он не читался, не редактировался и не включён в scope.
- Завершённый `local-search.md` перенесён из `active/` в `completed/` без изменения содержимого.
- Этот файл создан как единственный primary active execution plan; `docs/exec-plans/README.md` обновлён соответственно.
- Production sources, tests, Drift schema, generated files и dependencies не изменялись.
- Проаудированы ADR-0001 — ADR-0027, completed plans, текущие Domain/Application/Infrastructure/Presentation, composition, database/device lifecycle и persistence/reopen tests.

#### Границы понятий

- **Backup** — независимая от Sync восстанавливаемая копия, оптимизированная для recovery полного необходимого внутреннего состояния после потери, повреждения или удаления рабочей копии. Она должна быть versioned, проверяемой, crash-safe и учитывать непроизводные system data.
- **Export** — независимый пользовательский сценарий portability и выхода из LifeOS, использующий открытый логический формат, пригодный для чтения/миграции и не связанный с внутренней Drift/SQLite schema.
- **Restore** — отдельная контролируемая операция восстановления Backup с validation, compatibility check, возможной migration и safety copy; она не должна молча уничтожать текущую рабочую копию.
- **Import** — обработка недоверенного внешнего logical data через parse/validate/normalize и отдельную duplicate/conflict policy.
- **Sync/Outbox replication** — доставка Domain Changes между копиями приложения; Sync не является Backup, а восстановление файла не должно неявно становиться Sync operation.
- Backup и Export являются двумя пользовательскими сценариями и двумя внешними contracts. Они могут позднее переиспользовать общий Application snapshot/read pipeline, но не должны иметь один неразличимый artifact или flow.

#### Фактические production data и lifecycle

- `lifeos.db` находится в `<platform application-support directory>/lifeos.db` и открывается через `NativeDatabase.createInBackground`.
- Composition root создаёт один логический `LifeOsDatabase`, один `DriftLifeOsTaskRepository`, use cases и закрывает database через `LifeOsAppDependencies.close()`.
- SQLite schema version = `1`; таблицы: `entities`, `tasks`, `outbox`.
- `entities` содержит UUID Entity identity, type, UTC `createdAt`/`updatedAt`, lifecycle, Entity version и source/provenance.
- `tasks` содержит `entityId`, title и completion state.
- `outbox` содержит change UUID, entity ID, device ID, operation, base/new Entity versions, full JSON snapshot payload, payload schema version, status, attempts и timestamps.
- Production `device_id` хранится отдельным файлом `<application-support>/device_id`, а не в `lifeos.db`. Поэтому raw database file не является полной копией installation state.
- Сейчас нет files/attachments, relationships, settings, search indexes, embeddings, Sync State или tombstones; будущий формат должен позволять добавить их без привязки к текущим Drift rows.

#### Identity и version requirements

- Entity UUID, UTC timestamps, lifecycle, Entity version и source/provenance являются частью текущего Domain State и должны сохраняться в восстанавливаемом Backup. Полный Export должен явно представлять их либо документированно определить, какие technical metadata опускаются; это часть format contract BE-02.
- `change_id` идентифицирует immutable Sync Change и обеспечивает будущую idempotency; его нельзя регенерировать или переносить без принятой Outbox restore policy.
- `device_id` является stable installation/device identity, не user identity. ADR-0025 гарантирует reuse внутри установки, но не определяет перенос на новый компьютер.
- Различаются четыре независимые версии:
  1. database schema version — физическая Drift/SQLite schema;
  2. Backup/Export format version — внешний artifact contract;
  3. Entity version — последовательность Domain State конкретной Entity;
  4. Outbox payload schema version — формат сериализованного Change payload.
- Application version также является metadata compatibility, но не заменяет ни одну из этих версий.

#### Outbox и device identity gate

- ADR-0020 относит pending Outbox Changes к non-rebuildable critical state, а ADR-0011 требует, чтобы Backup сохранял необходимое internal/system state. Это указывает, что pending Outbox нельзя молча потерять.
- Одновременно ADR-0019 связывает Change с `device_id` и будущей Sync idempotency, а ADR-0025 не определяет restore/migration device identity. Простое восстановление Outbox на новой installation может повторно отправить старые pending Changes под прежней identity либо создать несовместимость с будущей registration/revocation model.
- Export не должен содержать delivery queue как пользовательские portable data: Outbox является sync/persistence metadata, а не Domain Entity. Но это исключение должно быть зафиксировано внешним contract.
- Existing ADR не дают однозначного ответа, должен ли Backup содержать Outbox как активную очередь, как inert diagnostic/history data либо не содержать её; также не определено, сохраняется ли old `device_id` при disaster recovery той же installation и при переносе на новый компьютер.

#### Безопасность active SQLite и raw copy

- В коде отсутствует Backup API, SQLite online backup API, `VACUUM INTO`, explicit checkpoint или controlled close-for-copy flow.
- Database используется background executor и может иметь незавершённую transaction/journal state. Простое filesystem-копирование открытого `lifeos.db` не гарантирует согласованный snapshot.
- ADR-0020 прямо указывает, что SQLite file не является единственным Backup mechanism, а Persistence должна предоставить безопасный snapshot. ADR-0021 запрещает связывать Export с произвольными Drift tables.
- Следовательно, raw copy текущего `lifeos.db` не является допустимым portable Export и не может считаться корректным Backup по умолчанию. Даже при закрытой database он исключает отдельный `device_id` и жёстко связан с schema version.

#### Сравнение форматов

| Вариант | Portability / readability | Versioning / compatibility | Atomicity / validation | Future schema/entities | Restore и Outbox/device | Тестируемость |
|---|---|---|---|---|---|---|
| A. Raw SQLite copy | Низкая / отсутствует | Жёстко связан с database schema | Требует controlled close или SQLite snapshot API; `integrity_check` не решает полноту installation | Автоматически копирует tables, но плохо переносит schema evolution | Outbox попадает неявно, `device_id` отсутствует; высокий Sync-risk | Средняя, platform/SQLite-specific |
| B. Logical JSON snapshot | Высокая / высокая | Явная format version и converters | Consistent read + schema validation + checksum; легко выявлять malformed/duplicate/inconsistent records | Расширяемый contract, независимый от Drift rows | Требует явной policy для Outbox/device | Высокая и deterministic |
| C. Archive/container + manifest + logical data | Высокая / средняя; JSON внутри читаем | Независимые manifest/format/schema versions | Temp artifact, checksums, verify, atomic finalization | Лучший путь для future files/relationships и feature metadata | Явные optional sections и policy; restore сложнее JSON-only | Высокая, включая corruption/partial artifact |
| D. Container + raw SQLite payload | Средняя / низкая | Manifest помогает, но payload остаётся schema-coupled | Нужен безопасный SQLite snapshot | Удобен только для exact-state recovery | Всё ещё не решает `device_id`; Outbox переносится неявно | Средняя |

ADR-0011 уже задаёт высокоуровневое направление C — container с manifest/data/files/metadata — и открытые logical formats для Export. Рекомендуемый вариант для нового ADR: versioned archive + manifest + logical Domain data как Backup contract; Export — отдельный logical JSON flow, с возможным Markdown позднее. Shared internal snapshot допустим, внешние artifacts и цели различны. Это рекомендация, а не принятое решение.

#### Compatibility, atomicity и validation requirements

- Каждый artifact обязан иметь собственную format version; initial implementation может читать только текущую версию, но должна детерминированно отклонять отсутствующую/неподдерживаемую версию без частичного результата.
- Future backward readers/migrations не реализуются заранее; extension/migration points должны быть явными в format contract.
- Согласованный logical snapshot нескольких таблиц должен читаться в одной controlled persistence transaction или эквивалентном snapshot boundary; ответственность принадлежит Infrastructure adapter, а не Presentation.
- Запись принадлежит filesystem Infrastructure: temporary sibling artifact → flush/close → structural/checksum verification → atomic rename/replace в final destination. Ошибка, cancel или crash не должны оставлять partial file с final name и не должны заменять предыдущий валидный artifact.
- Manifest должен как минимум фиксировать format kind/version, creation UTC, application version, source database schema version, feature/section compatibility, counts и checksums.
- Validation должна проверять manifest/version, required fields, checksum, malformed JSON/archive, duplicate Entity/change IDs, typed Task без Entity metadata, type mismatch, invalid lifecycle/source/version/timestamps, unknown required Entity types и truncated/corrupted artifact.
- Unknown optional future sections могут быть отклонены или безопасно пропущены только согласно явно versioned compatibility policy; silently accepting unknown required data недопустимо.

#### Restore/Import requirements

- Restore и Import не реализуются до BE-05 gate.
- ADR-0011 требует validation, compatibility check, safety backup и отсутствие молчаливого уничтожения текущей копии.
- Replace existing database, merge, selective restore, duplicate handling и conflict resolution не определены. Сложный merge не выбирается автоматически.
- Рекомендация для обсуждения BE-05: первый Restore поддерживает только проверенный full replace в новую/пустую installation либо explicit replace после safety backup; Import/merge/selective restore остаются отдельным будущим scope. Решение не принято.

#### Security/privacy boundary

- Все операции local-first и offline; network/cloud upload отсутствует.
- Backup и Export являются чувствительными копиями пользовательских данных; UI в будущем должен показывать scope, destination и отсутствие encryption, если artifact не защищён.
- ADR-0011 требует архитектурной поддержки encryption, но намеренно откладывает algorithm/key management; ADR-0010 также не выбирает concrete crypto.
- Документация не определяет принятую LifeOS 1.0 boundary и не отвечает, разрешён ли initial unencrypted Backup. Это часть блокирующего ADR; crypto dependency на BE-01 не добавляется.

#### Layer и filesystem boundaries

- Backup/Export format не является Domain concept. Domain предоставляет Entity semantics и invariants, но не зависит от manifest, JSON/archive, filesystem или Drift.
- Application должна координировать отдельные use cases уровня `CreateBackup` и `ExportLifeOsData`; `RestoreBackup`/`ImportLifeOsData` определяются только после BE-05. Общий internal snapshot abstraction допустим после принятия format policy.
- Infrastructure читает согласованный persistence snapshot, сериализует, проверяет и атомарно пишет filesystem artifact.
- Presentation выбирает пользовательский сценарий и запрашивает destination через platform-capability boundary, отображает progress/result/error и не знает SQLite.
- `path_provider` умеет получать application-support path, но не предоставляет desktop save-file picker. Для произвольного выбранного пользователем destination, вероятно, потребуется новая узкая platform dependency; конкретный package требует отдельного обоснования/approval в BE-04/BE-07.
- Settings destination не требуется автоматически. Минимальный entry point должен быть определён в BE-07 на основании готовых capabilities; placeholder Settings на BE-01 не добавляется.

#### Architecture gate classification

**A. Уже однозначно определено ADR**

- Backup, Export и Sync независимы;
- Backup служит recovery, Export — portability/user ownership;
- операции работают offline и не требуют cloud;
- Backup имеет manifest, собственную version, integrity и crash-safe finalization;
- Export использует logical open format через Application boundary, а не raw Drift tables;
- Domain не зависит от format/filesystem; composition остаётся владельцем production database;
- search indexes/cache/embeddings являются rebuildable и не обязательны для Backup.

**B. Можно локально определить execution plan после снятия blocker**

- имена use cases и внутреннее разбиение adapters;
- initial current-version-only reader с explicit unsupported-version error;
- конкретный набор validation tests;
- минимальный Presentation entry point без Settings;
- необходимость узкой file-picker dependency после отдельного approval.

**C. Требует нового ADR до BE-02**

- точный initial Backup artifact contract и его отношение к Export/shared logical snapshot;
- включение и restore semantics pending Outbox;
- перенос либо regeneration `device_id` для same-device recovery и new-device migration;
- initial encryption policy: обязательна ли защита первого Backup или допустим явно обозначенный unencrypted local artifact;
- граница backward compatibility первой версии формата.

**D. Сознательно отложено до BE-05 или будущего milestone**

- full replace vs merge/selective Restore и duplicate/conflict policy;
- Import из Export;
- partial restore;
- cloud/self-hosted/automatic Backup, retention и rotation;
- files/relationships/other Entity implementations, пока их нет;
- encryption algorithm/key management implementation после отдельного решения;
- Sync transport, registration, acknowledgement и conflict engine.

#### Точный blocker и варианты

Нужен новый ADR с вопросом: **каков начальный versioned Backup/Export artifact contract LifeOS и как он обращается с pending Outbox, installation `device_id`, compatibility и encryption при восстановлении на той же или новой installation?**

1. **Raw SQLite Backup.** Плюсы: простой exact-state restore текущей schema. Минусы: небезопасная active copy, schema coupling, отсутствие отдельного `device_id`, нечитабельность, не подходит Export, неявный перенос Outbox. Для будущего Sync риск высокий.
2. **Logical JSON для Backup и Export.** Плюсы: portability, явные версии, отличная тестируемость. Минусы: сложнее full recovery/files, нужно явно решить system state. Sync-risk контролируемый только при явной Outbox/device policy.
3. **Versioned archive с manifest + logical Domain data; отдельный Export artifact.** Плюсы: соответствует ADR-0011, расширяется до files, checksums и encryption, не зависит от Drift schema. Минусы: больше initial contract и restore mapping. Для Sync наиболее безопасен, потому что Outbox/device sections можно сделать явными и policy-driven.
4. **Archive с raw SQLite payload.** Плюсы: container metadata и быстрый same-version recovery. Минусы: сохраняет schema coupling и не решает identity semantics; для cross-version/new-device restore риск остаётся.

Рекомендация: вариант 3; Export — отдельный open logical JSON contract; pending Outbox не включать в portable Export, а Backup включать только согласно явно принятой recovery policy; на новом компьютере создавать новый installation `device_id`, не меняя Entity UUID, но судьбу старых pending Changes зафиксировать ADR. Эта рекомендация не считается принятой.

#### Validation evidence

- `flutter analyze`: PASS — no issues.
- полный `flutter test`: PASS — 67 tests.
- Import-boundary scan: PASS — Domain/Application не импортируют Flutter/Drift/UUID/platform/Infrastructure, Presentation не импортирует Infrastructure, persistence construction отсутствует в Presentation/Application.
- Dependency manifest/lock scan: PASS — production dependencies остаются `flutter_localizations`, Drift, Riverpod, `intl`, `path_provider`, `path`, `uuid`; новых dependencies нет.
- `dart pub deps --style=compact` и offline-вариант в текущей среде дважды зависли без вывода и были остановлены; файлов они не изменили. Результат не выдан и не заявляется как PASS.
- Drift generation: not applicable — schema/API/generated files не менялись.
- `git diff --check`: PASS; только информационные LF/CRLF warnings для существующего пользовательского `.obsidian/workspace.json` и изменённого README.
- Итоговый Git ref BE-01: `HEAD` = `abceff3fdbe90ceb48d76ae753dc24d434078f55`, `main` синхронизирован с `origin/main`; commit/push не выполнялись.
- Итоговый working tree: пользовательский `M .obsidian/workspace.json`; milestone changes — `M docs/exec-plans/README.md`, перенос `docs/exec-plans/active/local-search.md` в `docs/exec-plans/completed/local-search.md` с идентичным Git blob `a4a11083c72844acf33e8138d8e27558893dfe4f`, новый `docs/exec-plans/active/backup-export.md`. До staging Git показывает перенос как deleted + untracked.

BE-01 не выполнен как `done`, потому что категория C блокирует безопасное начало BE-02.

---

## BE-02 — Backup/export format и versioning contract

Статус: pending

### Goal

После принятия блокирующего ADR определить точный начальный logical format, manifest, независимые версии и compatibility contract.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0019;
- ADR-0020;
- новый принятый Backup/Export implementation ADR, если потребован BE-01.

### Scope

- format schema и manifest;
- backup/export format version;
- required fields, integrity и unsupported-version behavior;
- representation текущих Entity/Task metadata;
- format-level tests без desktop filesystem integration.

### Non-goals

- Presentation, file picker, cloud, Sync;
- restore/merge implementation;
- raw production DB copying;
- encryption implementation без принятого решения.

### Definition of Done

- format не зависит от Drift rows;
- версии database, backup/export, Entity и Outbox payload разделены;
- compatibility и validation rules тестируемы;
- blocker BE-01 снят принятым решением.

### Validation

- focused format tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Result / blocker

Не начато. Зависит от architecture gate BE-01.

---

## BE-03 — Application backup/export path

Статус: pending

### Goal

Создать минимальные Application use cases и внутренние abstractions для согласованного snapshot/export без filesystem и Drift leakage.

### Связанные ADR

- ADR-0007;
- ADR-0011;
- ADR-0020 — ADR-0022;
- решение BE-01/BE-02.

### Scope

- Application orchestration;
- abstractions snapshot writer/target там, где они доказанно нужны;
- deterministic test doubles.

### Non-goals

- desktop path selection;
- Presentation;
- Restore/Import;
- новая Domain backup model без Domain semantics.

### Definition of Done

- Application не знает Drift, SQLite или platform paths;
- snapshot получает согласованный набор данных;
- focused tests проходят.

### Validation

- focused Application tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Result / blocker

Не начато.

---

## BE-04 — Desktop file I/O implementation

Статус: pending

### Goal

Реализовать локальную Infrastructure запись выбранного формата с crash-safe завершением и без дублирования database lifecycle.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0022;
- ADR-0024;
- решение BE-01/BE-02.

### Scope

- filesystem adapter;
- temp file, flush/verify и final rename semantics;
- cleanup незавершённых artifacts;
- platform-focused tests.

### Non-goals

- UI;
- cloud upload;
- Sync;
- Restore/Import;
- package dependency без approval.

### Definition of Done

- частичный файл не выглядит валидным результатом;
- ошибки/отмена не повреждают существующий output;
- path/filesystem остаются Infrastructure concern.

### Validation

- focused filesystem tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- dependency scan;
- `git diff --check`.

### Result / blocker

Не начато.

---

## BE-05 — Restore/import strategy и architecture gate

Статус: pending

### Goal

Разделить Restore и Import и принять отдельное решение о replace/merge/selective semantics, duplicate IDs, Outbox и device identity до изменения данных.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0018 — ADR-0020;
- ADR-0024 — ADR-0026;
- решение BE-01/BE-02.

### Scope

- read-only strategy audit;
- existing/new installation scenarios;
- compatibility/migration/safety backup requirements;
- решение, разрешена ли BE-06.

### Non-goals

- изменение production data;
- сложный merge или conflict engine;
- Sync implementation.

### Definition of Done

- Restore и Import имеют однозначные contracts;
- destructive behavior не скрыт;
- unresolved long-lived decisions оформлены через ADR gate;
- BE-06 либо разблокирована, либо явно исключена/заблокирована.

### Validation

- documentation consistency scan;
- architecture/import-boundary scan;
- `git diff --check`.

### Result / blocker

Не начато.

---

## BE-06 — Restore/import implementation

Статус: pending

### Goal

Реализовать только тот минимальный Restore/Import path, который явно разрешён BE-05.

### Связанные ADR

- ADR-0011;
- ADR-0019 — ADR-0022;
- ADR-0024 — ADR-0026;
- принятое решение BE-05.

### Scope

- parse/validate/compatibility;
- разрешённая mutation strategy;
- integrity и rollback tests.

### Non-goals

- неподтверждённый merge;
- partial restore без решения;
- remote Sync/conflict resolution.

### Definition of Done

- операция следует BE-05;
- corruption/unsupported version не изменяют текущие данные;
- lifecycle и architecture boundaries доказаны тестами.

### Validation

- focused restore/import tests;
- reopen/round-trip tests;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Result / blocker

Не начато; условный checkpoint, зависит от BE-05.

---

## BE-07 — Presentation и desktop integration

Статус: pending

### Goal

Добавить минимальный локализованный desktop flow для реализованных Backup/Export capabilities без преждевременного Settings feature.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0022;
- ADR-0027;
- решения BE-01 — BE-06.

### Scope

- entry point, path selection и progress/error/success UX;
- English/Russian ARB resources;
- provider/composition wiring без нового persistence owner.

### Non-goals

- fake Settings module;
- cloud, account, Sync;
- новые destinations без architecture gate.

### Definition of Done

- Presentation вызывает Application path;
- пользователь понимает scope, destination и чувствительность операции;
- весь статический текст локализован;
- production persistence не создаётся повторно.

### Validation

- focused widget/localization tests;
- `flutter gen-l10n`;
- `flutter analyze`;
- полный `flutter test`;
- import-boundary scan;
- `git diff --check`.

### Result / blocker

Не начато.

---

## BE-08 — Round-trip, corruption и compatibility verification

Статус: pending

### Goal

Доказать целостность, crash safety, compatibility и разрешённый round-trip на реальной file-backed persistence.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0017 — ADR-0021;
- ADR-0024 — ADR-0026;
- решения milestone.

### Scope

- current/unsupported version;
- malformed/corrupted/partial files;
- duplicate/inconsistent records;
- close/reopen и Outbox/device invariants согласно принятому contract.

### Non-goals

- Sync server;
- cloud backup;
- undocumented backward compatibility.

### Definition of Done

- валидный round-trip сохраняет утверждённые данные;
- corrupted/partial/unsupported input безопасно отклоняется;
- validation не оставляет частично изменённого состояния.

### Validation

- focused round-trip/corruption tests;
- persistence/reopen tests;
- `flutter analyze`;
- полный `flutter test`;
- `git diff --check`.

### Result / blocker

Не начато.

---

## BE-09 — Финальный архитектурный и интеграционный аудит

Статус: pending

### Goal

Подтвердить завершённый local-first Backup/Export vertical slice, architecture boundaries, scope discipline и factual repository state.

### Связанные ADR

- все ADR, управляющие реализованным milestone;
- все принятые решения BE-01 — BE-08.

### Scope

- end-to-end audit;
- final validation;
- completion evidence и deferred scope.

### Non-goals

- новый milestone;
- cloud/Sync/encryption scope без отдельного решения;
- speculative cleanup.

### Definition of Done

- все обязательные checkpoints завершены либо условные checkpoints явно исключены принятым gate;
- Backup/Export semantics и пользовательские flows доказаны;
- архитектурные границы и persistence lifecycle сохранены;
- план отмечен `completed` без unresolved blocker.

### Validation

- все focused tests milestone;
- `flutter analyze`;
- полный `flutter test`;
- localization check;
- import-boundary scan;
- dependency scan;
- `git diff --check`.

### Result / blocker

Не начато.

---

# Точка возобновления

Resume point: принять новый Backup/Export implementation ADR, закрывающий format, Outbox, device identity, compatibility и initial encryption policy. После принятия ADR перечитать его, перевести BE-01 из `blocked` в `done` только после подтверждения снятия всех blockers и затем начать BE-02. BE-02 сейчас не начинать.

# Состояние выполнения плана

Статус: blocked
