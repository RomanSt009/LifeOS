# LifeOS Backup / Export — план выполнения

Статус: active

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
- ADR-0027 — localization strategy;
- ADR-0028 — Backup, Export и Restore contract.

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

Статус: done

### Goal

Сверить документацию, ADR, Git и текущую persistence implementation; определить границы Backup/Export и выявить долгоживущие решения, необходимые до проектирования формата.

### Связанные ADR

- ADR-0005;
- ADR-0007;
- ADR-0009;
- ADR-0010;
- ADR-0011;
- ADR-0016 — ADR-0028.

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

Architecture gate: PASS после принятия ADR-0028. Первичный аудит корректно остановил BE-01 как `blocked`, потому что существующие ADR намеренно не определяли несколько связанных долгоживущих решений, непосредственно формирующих внешний Backup contract. ADR-0028 теперь закрывает эти вопросы и снимает blocker перед BE-02.

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

**C. Требовало нового ADR до BE-02; снято ADR-0028**

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

#### Исторический blocker и рассмотренные варианты

Нужен новый ADR с вопросом: **каков начальный versioned Backup/Export artifact contract LifeOS и как он обращается с pending Outbox, installation `device_id`, compatibility и encryption при восстановлении на той же или новой installation?**

1. **Raw SQLite Backup.** Плюсы: простой exact-state restore текущей schema. Минусы: небезопасная active copy, schema coupling, отсутствие отдельного `device_id`, нечитабельность, не подходит Export, неявный перенос Outbox. Для будущего Sync риск высокий.
2. **Logical JSON для Backup и Export.** Плюсы: portability, явные версии, отличная тестируемость. Минусы: сложнее full recovery/files, нужно явно решить system state. Sync-risk контролируемый только при явной Outbox/device policy.
3. **Versioned archive с manifest + logical Domain data; отдельный Export artifact.** Плюсы: соответствует ADR-0011, расширяется до files, checksums и encryption, не зависит от Drift schema. Минусы: больше initial contract и restore mapping. Для Sync наиболее безопасен, потому что Outbox/device sections можно сделать явными и policy-driven.
4. **Archive с raw SQLite payload.** Плюсы: container metadata и быстрый same-version recovery. Минусы: сохраняет schema coupling и не решает identity semantics; для cross-version/new-device restore риск остаётся.

ADR-0028 принял вариант 3: versioned archive/container с manifest и logical Domain data для Backup; отдельный human-readable logical JSON для Export. Active Outbox полностью исключён из Backup/Export v1 и не восстанавливается; новая installation сохраняет собственный новый `device_id`, а существующая — свой текущий. Entity UUID и Domain metadata сохраняются. Restore v1 является replace-style, initial Backup v1 может быть локальным незашифрованным artifact, а future encryption остаётся обязательной точкой расширения формата.

#### Закрытие architecture gate ADR-0028

- Backup и Export закреплены как разные пользовательские scenarios и внешние contracts; общий внутренний logical snapshot/read pipeline разрешён без смешения artifacts.
- Backup v1 — не raw SQLite copy, а versioned logical archive/container с manifest и logical data snapshot.
- Export v1 — отдельный versioned human-readable logical JSON, не обязанный обеспечивать full Restore.
- Database schema version, backup/export format versions, Entity version, Outbox payload schema version и application version разделены.
- Entity UUID, timestamps, lifecycle, Entity version, source/provenance и typed Domain state сохраняются.
- Operational `device_id` не включается в v1 artifacts и не заменяется при Restore.
- Active Outbox полностью исключается из Backup/Export v1; Restore не replay старые Changes и не создаёт обычную Outbox mutation на каждую restored Entity.
- Future Sync обязан выполнять отдельный reconciliation/bootstrap restored state.
- Restore v1 выбран как replace-style; merge, selective Import и conflict-aware Restore отложены.
- Reader v1 явно отклоняет malformed/unknown/unsupported versions до mutation.
- Encryption/password protection не обязательны в local-only v1, но format не должен блокировать их будущее добавление.
- Consistent logical snapshot, validation и crash-safe finalization закреплены; concrete I/O остаётся Infrastructure responsibility.
- Нерешённых architecture questions, блокирующих BE-02, после ADR-0028 не осталось.

#### Validation evidence

- `flutter analyze`: PASS — no issues.
- полный `flutter test`: PASS — 67 tests.
- Import-boundary scan: PASS — Domain/Application не импортируют Flutter/Drift/UUID/platform/Infrastructure, Presentation не импортирует Infrastructure, persistence construction отсутствует в Presentation/Application.
- Dependency manifest/lock scan: PASS — production dependencies остаются `flutter_localizations`, Drift, Riverpod, `intl`, `path_provider`, `path`, `uuid`; новых dependencies нет.
- `dart pub deps --style=compact` и offline-вариант в текущей среде дважды зависли без вывода и были остановлены; файлов они не изменили. Результат не выдан и не заявляется как PASS.
- Drift generation: not applicable — schema/API/generated files не менялись.
- `git diff --check`: PASS; только информационные LF/CRLF warnings для существующего пользовательского `.obsidian/workspace.json` и изменённого README.
- Итоговый Git ref первоначального аудита BE-01: `HEAD` = `abceff3fdbe90ceb48d76ae753dc24d434078f55`, `main` синхронизирован с `origin/main`; commit/push не выполнялись.
- Итоговый working tree: пользовательский `M .obsidian/workspace.json`; milestone changes — `M docs/exec-plans/README.md`, перенос `docs/exec-plans/active/local-search.md` в `docs/exec-plans/completed/local-search.md` с идентичным Git blob `a4a11083c72844acf33e8138d8e27558893dfe4f`, новый `docs/exec-plans/active/backup-export.md`. До staging Git показывает перенос как deleted + untracked.

Docs-only closure после ADR-0028:

- создан `docs/adr/ADR-0028-backup-export-restore-contract.md` со статусом `Принято`;
- production code, tests, Drift schema, generated files и dependencies не изменялись;
- Flutter validation не повторялась, поскольку изменение ограничено ADR и execution-plan bookkeeping;
- `git diff --check`: PASS; только информационные LF/CRLF warnings для пользовательского `.obsidian/workspace.json` и этого execution plan;
- Markdown/ADR reference scan: PASS — все ADR, указанные планом, существуют;
- Git ref при снятии gate: `HEAD` = `bc21bd4aa5995b40d48b4d729973bce9871bb35d`, `main` синхронизирован с `origin/main`;
- Working tree при снятии gate: пользовательский `M .obsidian/workspace.json`; milestone changes — `M docs/exec-plans/active/backup-export.md` и новый `docs/adr/ADR-0028-backup-export-restore-contract.md`;
- BE-01 Definition of Done выполнен, checkpoint переведён в `done`;
- BE-02 остаётся `pending` и в этом запуске не начинался.

---

## BE-02 — Backup/export format и versioning contract

Статус: done

### Goal

После принятия блокирующего ADR определить точный начальный logical format, manifest, независимые версии и compatibility contract.

### Связанные ADR

- ADR-0010;
- ADR-0011;
- ADR-0019;
- ADR-0020;
- ADR-0028.

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

Architecture gate: PASS. ADR-0028 полностью определяет необходимые долгоживущие границы; нового ADR для конкретизации чистого v1 format contract не требуется.

#### Сверка Git и repository

- На старте BE-02 `HEAD` = `d974d43eb81e7e6544d4030cd4ad5ef24558e00c`, branch `main` синхронизирован с `origin/main`.
- Единственным исходным незакоммиченным файлом был пользовательский `.obsidian/workspace.json`; он не читался и не изменялся.
- ADR-0028 уже находился в `HEAD`, BE-01 имел статус `done`, BE-02 — `pending`; расхождений с фактическим repository state не обнаружено.
- Существующих Backup/Export format DTO или serializers не было. Текущий `LifeOsTaskMapper.toJsonSnapshot` обслуживает Outbox payload и намеренно не переиспользован как публичный Backup/Export contract.

#### Backup v1 logical structure

- Public Backup contract представляет versioned logical archive/container, но конкретная archive technology на BE-02 не выбиралась.
- Обязательные logical entries:

```text
backup/
├── manifest.json
└── data.json
```

- Optional sections в v1 отсутствуют.
- `data.json` является source of truth для восстанавливаемого logical Domain State; `manifest.json` описывает kind/version, compatibility metadata, required sections и integrity digest.
- В v1 запрещены raw `lifeos.db`, active Outbox/change records, `device_id`, runtime/cache/UI state и derived indexes.

#### Manifest v1

Точный JSON contract:

- `format` = `lifeos-backup`;
- `formatVersion` = `1`;
- `createdAt` — ISO-8601 UTC;
- `applicationId` = `lifeos`;
- `applicationVersion` — диагностическая metadata;
- `sourceDatabaseSchemaVersion` — диагностическая/compatibility metadata, не определяющая Backup format;
- `requiredSections` = ровно `["data.json"]` для v1;
- `dataSha256` — lowercase 64-character SHA-256 digest точных bytes будущего `data.json` artifact.

Отдельная logical data version не добавлена: структура `data.json` в v1 управляется `formatVersion`. Database schema version, Backup format version, Export format version, Entity version и Outbox payload schema version остаются независимыми.

#### Logical Task snapshot

`data.json` является object envelope с обязательным массивом `tasks`. Каждая запись содержит:

- `id` — canonical UUID string;
- `entityType` = `task`;
- `createdAt` и `updatedAt` — ISO-8601 UTC;
- `lifecycle` — stable serialized name `active`/`archived`/`deleted`;
- `version` — positive integer Entity version;
- `source` — stable serialized name `user`/`ai`/`import`/`sync`/`system`;
- `title` — non-empty string;
- `isCompleted` — JSON boolean.

Все lifecycle states включаются: Backup/Export не ограничиваются только active Tasks. `change_id`, Outbox и `device_id` отсутствуют по структуре DTO.

#### Export JSON v1

- Export является отдельным human-readable object envelope, а не bare list.
- Обязательные top-level fields: `format = lifeos-export`, `formatVersion = 1`, `createdAt`, `applicationId`, `applicationVersion`, `tasks`.
- Export не содержит database schema metadata, checksum, required archive sections или installation/runtime state и не заявляется как Restore input.
- Полные Entity UUID, lifecycle, Entity version, source/provenance и Task state сохранены, поскольку они полезны для переносимости и не являются transport state.

#### Canonical representation и ordering

- Writer принимает только UTC `DateTime` и кодирует canonical `toIso8601String()` с `Z`; reader отклоняет timestamps без UTC `Z`.
- UUID представлены строками canonical `8-4-4-4-12`; enum values сериализуются явными stable names; booleans — JSON `true`/`false`; обязательные fields не nullable.
- JSON object field order не является semantic requirement. Writer использует стабильный порядок для repeatable output.
- Tasks всегда сортируются по Entity UUID ascending. Порядок SQLite или входной collection не влияет на encoded result.
- Export кодируется с indentation для human readability; Backup data — compact JSON для будущего container artifact.

#### Versioning и validation

- Текущие writers создают только Backup v1 и Export v1.
- Readers принимают только явно поддерживаемую version `1`; absent/malformed/unknown/newer versions дают typed `unsupportedVersion`/structural error без silent best-effort parsing.
- Migration framework и speculative future readers не добавлены.
- Typed `LifeOsDataFormatException` различает `malformedJson`, `missingField`, `invalidField`, `unsupportedVersion` и `duplicateEntityId`.
- Validation отклоняет malformed/non-object JSON, missing/null required fields, неверные primitive types, invalid UUID/UTC timestamp/enum/entity type, non-positive version, empty title, `updatedAt < createdAt`, duplicate Entity UUID, неверный application/format identifier, invalid required sections и malformed SHA-256 digest.
- Unknown JSON fields игнорируются как optional extensions. Unknown required section и unknown Entity type отклоняются, поэтому новая обязательная semantics не принимается молча.
- Archive existence, checksum computation/comparison и corruption of physical container остаются BE-04/BE-08: BE-02 фиксирует logical contract и digest field, но не выполняет filesystem I/O.

#### Реализация и boundaries

- Добавлен `lib/infrastructure/backup/formats/backup_export_format_v1.dart` с небольшими immutable structures `BackupManifestV1`, `BackupSnapshotV1`, `BackupTaskRecordV1`, `ExportDocumentV1` и pure in-memory codec `LifeOsDataFormatV1`.
- DTO/JSON находятся в Infrastructure как external format concern. Domain не получил JSON/archive/filesystem concepts; format mapper принимает/возвращает существующий `LifeOsTask` без изменения Domain contract.
- Не создавались generic DTO framework, Application use cases, repository/database reads, filesystem APIs, ZIP/archive implementation, Restore writes или Presentation.
- Drift schema/generated API, Outbox, device identity, localization и dependencies не менялись.

#### Validation evidence

- Focused `backup_export_format_v1_test.dart`: PASS — 12 tests; покрыты manifest, Task/Domain round-trip, UTC/UUID/enums, deterministic ordering, Export envelope, forbidden operational state, malformed/missing fields, unknown enums/types, duplicate IDs, unsupported versions и unknown optional fields.
- `flutter analyze`: PASS — no issues.
- Полный `flutter test`: PASS — 79 tests.
- Import-boundary scan: PASS — Domain/Application не получили framework/Infrastructure dependencies, Presentation не импортирует Infrastructure; новый format layer зависит только от `dart:convert` и Domain entities.
- BE-02 filesystem/database guard scan: PASS — production format source не импортирует `dart:io`, Drift/database, Outbox или device identity.
- Dependency scan: not applicable — `pubspec.yaml` и `pubspec.lock` не изменялись, новые packages не добавлены.
- Drift generation: not applicable — schema/API/generated files не менялись.
- `git diff --check`: PASS; только информационные LF/CRLF warnings для пользовательского `.obsidian/workspace.json` и execution plan.
- Итоговый Git ref: `HEAD` = `d974d43eb81e7e6544d4030cd4ad5ef24558e00c`, `main` синхронизирован с `origin/main`.
- Итоговый working tree: пользовательский `M .obsidian/workspace.json`; BE-02 changes — `M docs/exec-plans/active/backup-export.md`, новые `lib/infrastructure/backup/formats/backup_export_format_v1.dart` и `test/infrastructure/backup/formats/backup_export_format_v1_test.dart`.

BE-02 Definition of Done выполнен. BE-03 остаётся `pending` и не начинался.

---

## BE-03 — Application backup/export path

Статус: done

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

Architecture gate: PASS. ADR-0007 и ADR-0028 уже определяют необходимое dependency inversion: Application координирует use cases через abstractions, Infrastructure выполняет logical mapping/serialization, а composition root связывает их. Новый ADR не требуется.

- На возобновлении repository state сверено с Git: `HEAD` = `f328fe5cd0973e024eee6e6e25f507aa5b9e2e53` (`feat: define backup export format v1`), branch `main` опережает `origin/main` на один существующий коммит. Execution plan отставал только в resume point: фактическая BE-03 implementation уже присутствовала, поэтому работа продолжена с первой незавершённой validation action.
- Добавлены Application contracts `LifeOsDataSnapshot`, `LifeOsBackupDraft` и `LifeOsBackupExportEncoder`. Snapshot содержит immutable список всех возвращённых repository Tasks и детерминированно сортирует его по Entity UUID ascending.
- Добавлены отдельные use cases `CreateLifeOsBackup` и `ExportLifeOsData`. Оба зависят только от Domain `LifeOsTaskRepository`, Application encoder abstraction, injected UTC clock и application version; filesystem, Drift, SQLite и platform APIs в Application отсутствуют.
- `CreateLifeOsBackup` возвращает in-memory draft с единым UTC `createdAt`, application version и serialized logical `data.json`, готовый для filesystem/container orchestration BE-04. `ExportLifeOsData` возвращает отдельный human-readable v1 Export JSON. Manifest/archive/file writing намеренно не реализованы.
- `V1BackupExportEncoder` в Infrastructure адаптирует Application snapshot к принятому BE-02 codec и переиспользует его Domain mapping/validation без дублирования format contract.
- Production composition создаёт один v1 encoder и передаёт его обоим use cases вместе с уже существующим singleton repository/database lifecycle. Текущая application version `1.0.0+1` совпадает с `pubspec.yaml` и передаётся как overridable composition input.
- Текущий `LifeOsTaskRepository.getAll()` читает Entity metadata и Task state одним Drift join query; Application не выполняет независимые UI queries. Все текущие lifecycle states сохраняются, Outbox и `device_id` не читаются и не сериализуются.
- Deterministic Application fakes покрывают несколько Tasks, ID ordering, пустой repository, lifecycle/completion/metadata preservation, один clock read, repository failure propagation и отказ от non-UTC timestamp до чтения данных.
- Production composition test подтверждает, что оба новых use cases видят сохранённый Task, не содержат Outbox/device identity в output и не изменяют единственную существующую Outbox entry.
- Focused BE-03/BE-02/composition/lifecycle validation: PASS — 20 tests.
- `flutter analyze`: PASS — no issues.
- Полный `flutter test`: PASS — 84 tests.
- Import-boundary scan: PASS — Domain/Application не импортируют Flutter, Drift, SQLite, platform или Infrastructure; Presentation не импортирует Infrastructure; concrete v1 encoder создаётся только composition root.
- `git diff --check`: PASS; dependency и Drift generation не требуются, поскольку `pubspec.yaml`, `pubspec.lock`, schema/API и generated files не изменялись.
- Пользовательский `.obsidian/workspace.json` сохранён без изменений со стороны checkpoint. Commit и push не выполнялись.

BE-03 Definition of Done выполнен. BE-04 не начинался.

---

## BE-04 — Desktop file I/O implementation

Статус: done

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

Architecture gate: PASS после явного подтверждения пользователя. Решение зафиксировано непосредственно в execution plan; новый ADR не создаётся.

Принято для Backup v1:

- physical archive format — ZIP;
- `archive` и `crypto` добавляются как direct dependencies; использование транзитивных packages запрещено;
- absolute destination path передаётся извне, Infrastructure writer не открывает file picker;
- existing target policy — fail-if-exists для Backup и Export без молчаливой перезаписи;
- writer создаёт temporary sibling file, записывает и flush/close handles, выполняет validation/finalization и только затем rename в final destination;
- при ошибке temporary file удаляется best-effort, а cleanup failure не скрывает исходную ошибку;
- Backup ZIP v1 содержит ровно `manifest.json` и `data.json`; raw SQLite, Outbox, `device_id`, cache/runtime state запрещены;
- `dataSha256` вычисляется через direct dependency `crypto` строго по точным UTF-8 bytes `data.json`, как определено BE-02.

Destination naming и file picker остаются BE-07; Restore/Import не входят в BE-04.

#### Сверка Git и repository

- На старте BE-04 `HEAD` = `dacd37aba3cbb1e27d0701372bb6ad7457eb49f6`, branch `main` синхронизирован с `origin/main`.
- BE-03 полностью находится в `HEAD` отдельным commit `dacd37a` (`feat: add backup export application path`); Application use cases возвращают готовые in-memory Backup/Export результаты и не зависят от filesystem/Infrastructure.
- Единственное исходное незакоммиченное изменение — пользовательский `.obsidian/workspace.json`; оно не читалось и не изменялось.
- BE-02 прямо фиксирует обязательные logical entries `manifest.json` и `data.json`, SHA-256 точных UTF-8 bytes `data.json`, но также прямо говорит, что concrete archive technology не выбиралась.
- В direct dependencies уже есть `path` и `path_provider`, но нет archive или checksum package. `crypto` присутствует только транзитивно в `pubspec.lock`, поэтому использовать его как production API без direct dependency нельзя.
- Локальный Dart SDK предоставляет `ZLibCodec`/`GZipCodec`, но не multi-entry archive API с именованными `manifest.json` и `data.json`. GZip сам по себе не реализует принятый container contract.

#### Исторический blocker

До подтверждения требовалось принять concrete physical representation Backup v1 и разрешённые direct dependencies. Без этого было невозможно однозначно определить bytes artifact, file extension, reader compatibility и тесты physical container. Выбор нельзя было спрятать внутри Infrastructure как заменяемую деталь: созданные Backup-файлы должны читаться будущим Restore и потому являются стабильным внешним contract.

#### Минимальные варианты

1. **ZIP container через прямую dependency `archive`; SHA-256 через прямую dependency `crypto`.** Стандартный cross-platform archive с именованными entries, хорошо соответствует `manifest.json` + `data.json`, расширяется будущими sections/files и тестируется без platform process. Цена — две явные production dependencies и необходимость закрепить ZIP как representation Backup v1.
2. **Самописный ZIP/TAR и SHA-256.** Не добавляет packages, но вводит собственную реализацию binary archive/crypto primitives, повышает риск corruption, Windows incompatibility и ошибок будущего reader. Не рекомендуется.
3. **Custom JSON/binary envelope либо GZip stream.** Можно реализовать средствами SDK, но это новый proprietary container/framing contract; GZip не имеет двух именованных entries. Потребуется изменить/уточнить BE-02 physical contract. Не рекомендуется.
4. **Directory container.** Не требует archive dependency, но не является единым переносимым Backup file, усложняет atomic finalization/copy и расходится с ожидаемым desktop artifact. Не рекомендуется.

#### Принятое решение пользователя

Подтверждён ZIP container с entries `manifest.json` и `data.json`, direct dependencies `archive`/`crypto`, fail-if-exists policy и передаваемый извне absolute destination path. Решение фиксируется этим execution plan без нового ADR. BE-04 продолжен с минимальной Infrastructure implementation.

#### Реализация

- Добавлены узкие Infrastructure components `LifeOsBackupFileWriter` и `LifeOsExportFileWriter`; они принимают готовые in-memory BE-03 результаты и absolute destination path, не читают database/Outbox/device identity и не открывают file picker.
- Backup writer вычисляет SHA-256 точных UTF-8 bytes `data.json`, создаёт BE-02 `BackupManifestV1` и ZIP ровно с двумя root entries: `manifest.json` и `data.json`.
- До final rename временный ZIP повторно читается с CRC verification, проверяется точный набор entries, BE-02 manifest/data codecs, source schema metadata, SHA-256 и byte identity исходного `data.json`.
- Export writer записывает точные UTF-8 bytes готового human-readable v1 JSON и до finalization повторно читает, декодирует через BE-02 codec и сравнивает bytes с input.
- Общий приватный atomic writer требует absolute path и существующий destination directory, дважды применяет fail-if-exists, создаёт уникальный temporary sibling через exclusive create, выполняет write/flush/close/validation и затем rename.
- При любой ошибке после создания temp выполняется best-effort cleanup; cleanup/close failure не скрывает первоначальную ошибку. Filesystem failures преобразуются в `LifeOsArtifactWriteException` с отдельными codes для invalid/missing/inaccessible destination, existing target, temp creation, write, validation и finalization.
- `pubspec.yaml`: `archive: ^3.6.1` и `crypto: ^3.0.7` добавлены как direct main dependencies. `pubspec.lock`: `archive 3.6.1` добавлен, `crypto 3.0.7` переведён из transitive в direct main. Offline dependency resolution завершён успешно.
- Не изменялись Application/Domain/Presentation, composition/database lifecycle, Drift schema/generated files, Outbox или device identity. Naming и file picker остаются BE-07; Restore/Import не начинались.

#### Validation evidence

- documentation/repository consistency scan: PASS — отсутствие concrete archive choice и direct dependencies подтверждено фактическими BE-02 sources, `pubspec.yaml`, `pubspec.lock` и локальным Dart SDK;
- focused filesystem/format/Application tests: PASS — 24 tests; покрыты exact ZIP entries, manifest/data content, SHA-256, UTF-8 Export, successful finalization без temp, fail-if-exists с сохранением старого файла, malformed input cleanup, relative path и missing directory;
- `flutter analyze`: PASS — no issues;
- полный `flutter test`: PASS — 91 tests;
- import-boundary scan: PASS — Domain/Application не получили `dart:io`, archive/crypto, Infrastructure или framework dependencies; Presentation не импортирует Infrastructure; filesystem остается в Infrastructure;
- BE-04 database/runtime-state guard: PASS — writer не импортирует database/Drift/path provider и не обращается к raw SQLite, Outbox, change/device identity или file picker;
- `dart pub deps --style=compact`: PASS — `archive 3.6.1` и `crypto 3.0.7` отображаются как direct dependencies;
- `git diff --check`: PASS; только информационные LF/CRLF warnings для пользовательского `.obsidian/workspace.json`, execution plan и `pubspec.yaml`;
- Drift generation: not applicable — schema/API/generated files не затрагивались;
- итоговый Git ref: `HEAD` = `dacd37aba3cbb1e27d0701372bb6ad7457eb49f6`, branch `main` синхронизирован с `origin/main`;
- итоговый `git status --short`: пользовательский `M .obsidian/workspace.json`; BE-04 — `M docs/exec-plans/active/backup-export.md`, `M pubspec.yaml`, `M pubspec.lock`, новые `lib/infrastructure/backup/files/lifeos_backup_export_file_writers.dart` и `test/infrastructure/backup/files/lifeos_backup_export_file_writers_test.dart`.

BE-04 Definition of Done выполнен. BE-05 остаётся `pending` и не начинался.

---

## BE-05 — Restore/import strategy и architecture gate

Статус: done

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

Architecture gate: PASS. Новый ADR не требуется: решения ниже конкретизируют уже принятый ADR-0028 и не вводят новую Sync/conflict architecture. BE-06 разрешён только в этих границах.

#### Сверка Git и repository

- На старте BE-05 `HEAD` = `5d074ba0e2dd3f7c6ab6bf132a6eb16cb1a4f10f` (`feat: add backup export file writers`), branch `main` синхронизирован с `origin/main`.
- BE-02 — BE-04 полностью находятся в `HEAD`; единственное исходное незакоммиченное изменение — пользовательский `.obsidian/workspace.json`, оно не читалось и не изменялось.
- Текущая schema version = `1`; реализованы `entities`, `tasks` и `outbox`. `tasks.entity_id` и `outbox.entity_id` имеют foreign key на `entities.id` без cascade delete.
- Каждый обычный `DriftLifeOsTaskRepository.save()` в одной transaction сохраняет Entity/Task и создаёт immutable Outbox Change `CREATE`/`UPDATE` с full Task snapshot, base/new Entity versions и текущим `device_id`.
- Production `device_id` хранится отдельным файлом `<application-support>/device_id`, создаётся до repository composition и не является частью SQLite или Backup ZIP.

#### Restore и Import

- **Backup Restore v1** — destructive full replace всего поддерживаемого logical user/Domain state текущей installation из валидного Backup v1. Entity UUID, type, timestamps, lifecycle, Entity version, source/provenance и Task state сохраняются буквально.
- **Import** — потенциальное добавление/merge/selective применение внешних данных в существующий state. Оно требует duplicate/conflict/provenance policy и не является Restore.
- Import из Export JSON полностью deferred. Export остаётся one-way portability capability текущего milestone; preview, parse-only Import и mutation Import не реализуются в BE-06/BE-07.

#### Текущий Outbox при replace

Принята policy **B: текущий Outbox очищается атомарно вместе с заменой Domain State**.

- Policy A (разрешать Restore только при пустом Outbox) отвергнута: сейчас каждая mutation создаёт `PENDING` entry, а Sync worker/acknowledgement ещё не реализованы, поэтому практически любая непустая installation навсегда блокировала бы Restore.
- Policy C (сохранить текущий Outbox) отвергнута: entries описывают pre-restore Entity state и могут ссылаться на удалённые после replace Entities либо позднее отправить старые snapshots, нарушив restored local truth.
- Отдельное inert/archive-хранение Outbox отвергнуто для v1: текущая schema не имеет такой semantics, а её добавление потребовало бы migration и преждевременной Sync/history architecture.
- Очистка Outbox соответствует ADR-0028: restored logical snapshot становится локальной истиной текущей installation; старые Changes не replay, а будущий Sync обязан использовать отдельный reconciliation/bootstrap protocol.
- Restore path не вызывает обычный repository `save()` и не создаёт новый Outbox Change на каждую restored Entity. Это техническая replacement operation, а не набор пользовательских синхронизируемых mutations.
- Пользовательский destructive confirmation должен явно предупреждать, что текущие данные и pending unsynchronized Changes будут заменены. Presentation реализует это позднее, но Application contract считает подтверждение обязательной precondition.

#### Transactionality и persistence boundary

- Полностью validated in-memory snapshot передаётся отдельному Application-level persistence port для atomic replace; concrete Drift implementation принадлежит Infrastructure. Текущий `LifeOsTaskRepository` не расширяется restore-specific semantics.
- Application restore orchestration зависит от abstractions и Domain Tasks; оно не импортирует `dart:io`, `archive`, Drift/SQLite или concrete Infrastructure.
- Infrastructure reader отвечает за ZIP, exact entries, CRC/checksum, manifest/data decoding и mapping в полностью validated logical snapshot. Он завершает всю проверку до вызова persistence port.
- Persistence implementation выполняет одну SQLite transaction. Для текущих foreign keys порядок удаления: `outbox` → `tasks` → `entities`; порядок вставки: `entities` → `tasks`. Outbox после replace остаётся пустым.
- Любая ошибка delete/insert откатывает transaction целиком, включая очистку Outbox: после failure остаётся полный pre-restore state, а не смесь старых и новых records.
- Database может оставаться открытой под ownership существующего composition root; отдельный database instance, raw file replacement и новый persistence lifecycle не требуются. Когда появится Sync worker, composition обязан приостановить его на время restore и запустить отдельный bootstrap/reconciliation после commit; сам Sync protocol остаётся deferred.

#### Validation до mutation

До первой SQLite mutation должны успешно завершиться:

1. чтение ZIP и проверка, что container содержит ровно `manifest.json` и `data.json`;
2. CRC/archive structural validation;
3. parse и validation manifest, `format = lifeos-backup`, `formatVersion = 1`, application metadata и required sections;
4. SHA-256 exact bytes `data.json` и сравнение с `dataSha256`;
5. parse полного `data.json`, required fields, canonical UUID, UTC timestamps, enums, positive Entity version и Task invariants;
6. duplicate Entity ID, supported Entity type и logical consistency validation;
7. построение immutable validated in-memory snapshot.

Malformed container/JSON, checksum mismatch, unsupported format version, unknown required section/entity type или любая logical inconsistency отклоняют весь Restore до persistence call. Silent partial restore запрещён.

`sourceDatabaseSchemaVersion` является diagnostic/compatibility metadata. Restore читает logical Backup v1 и записывает его через текущую supported persistence schema; физическое равенство source/current SQLite schema не требуется. Backup format version, database schema version и Entity version не смешиваются.

#### Existing installation и safety

- Replace разрешён как для пустой, так и для непустой current database; отдельная fresh-install-only precondition не вводится.
- Для непустого state требуется явное destructive confirmation до mutation. Отсутствие confirmation является precondition failure.
- SQLite transaction обеспечивает автоматический rollback при техническом failure. Автоматический второй safety Backup не является обязательной частью Restore v1: он потребовал бы отдельного destination/overwrite workflow и не заменяет transaction safety. BE-07 должна предложить пользователю заранее создать Backup текущего state и ясно объяснить необратимый успешный replace.
- `device_id` не читается из Backup и не изменяется restore persistence path. Существующая installation сохраняет текущий файл `device_id`; новая installation использует новый ID, уже созданный production composition.

#### Future component boundaries и error model

BE-06 должен минимально предоставить:

- Infrastructure Backup v1 reader, возвращающий validated logical snapshot/metadata через Application abstraction;
- Application Restore use case с explicit destructive-confirmation precondition;
- отдельный Application persistence replacement port;
- Drift implementation atomic replace без обычного `save()`/Outbox generation;
- composition wiring без второго database owner.

Будущие errors должны различать: invalid/unreadable file or ZIP, unsupported format version, checksum mismatch, logical validation failure, unsupported required entity/section, destructive confirmation/precondition failure и persistence transaction failure. Raw `IOException`, archive exception или Drift exception не должны выходить непосредственно в Presentation contract.

#### Validation evidence

- Documentation/ADR consistency scan: PASS — Restore/Import, Outbox, device identity, compatibility и layer decisions согласованы с ADR-0011, ADR-0018 — ADR-0020, ADR-0024 — ADR-0026 и приоритетным ADR-0028.
- Schema/repository audit: PASS — фактические foreign keys, transaction-bound `save()` + Outbox и отсутствие cascade подтверждают отдельный restore port и указанный delete/insert order.
- Lifecycle audit: PASS — production database принадлежит единственному composition root, а `device_id` физически расположен вне SQLite.
- Production code, tests, schema, generated files и dependencies в BE-05 не изменялись; Flutter/Drift generation не запускались как не относящиеся к docs-only gate.
- Итоговый Git ref: `HEAD` = `5d074ba0e2dd3f7c6ab6bf132a6eb16cb1a4f10f`, branch `main` синхронизирован с `origin/main`.
- Итоговый `git status --short`: пользовательский `M .obsidian/workspace.json`; BE-05 — `M docs/exec-plans/active/backup-export.md`. Commit и push не выполнялись.

BE-05 Definition of Done выполнен. BE-06 является следующим `pending` checkpoint и в этом запуске не начинался.

---

## BE-06 — Restore/import implementation

Статус: done

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

Architecture gate: PASS — текущие таблицы `entities`, `tasks` и `outbox`, их foreign keys и единый composition-owned `LifeOsDatabase` позволили реализовать validated Restore через отдельный Application port и одну Drift transaction без schema migration или нового ADR.

Реализован полный Backup Restore v1 в разрешённых BE-05 границах:

- Application получил `LifeOsBackupReader`, `LifeOsBackupRestoreStore`, typed `LifeOsBackupRestoreException` и use case `RestoreLifeOsBackup`; Application не импортирует filesystem, ZIP, crypto, Drift/SQLite или concrete Infrastructure;
- use case сначала получает полностью validated in-memory `LifeOsDataSnapshot`, затем проверяет наличие restorable state и требует `destructiveReplaceConfirmed` только для непустого current state; до успешной validation persistence boundary не вызывается;
- `LifeOsBackupFileReader` читает ZIP с CRC verification, проверяет raw central-directory names (включая duplicate entries), exact entries `manifest.json`/`data.json`, UTF-8, manifest/version, SHA-256 exact bytes и переиспользует `LifeOsDataFormatV1` для logical validation/mapping;
- reader разделяет typed categories unreadable file, invalid container, unsupported format, checksum mismatch и invalid logical data без выхода raw `FileSystemException`/archive errors;
- `DriftLifeOsBackupRestoreStore` не использует `LifeOsTaskRepository.save()`: в одной transaction удаляет `outbox` → `tasks` → `entities`, затем напрямую вставляет `entities` → `tasks`, сохраняя UUID, type, timestamps, lifecycle, version, source, title и completion буквально; новые Outbox rows не создаются;
- transaction failure через реальный SQLite trigger доказал rollback исходных Domain State и Outbox; successful replace удаляет старое состояние и очищает current Outbox атомарно;
- file-backed close/reopen test подтвердил persistence restored Task/metadata и пустого Outbox; отдельный `device_id` до и после Restore совпадает;
- пустая database принимает Restore без confirmation; пустой validated Backup заменяет подтверждённое текущее состояние пустым;
- production composition связывает reader/use case/restore store с тем же принадлежащим composition `LifeOsDatabase`; второй database/repository lifecycle не создаётся;
- Import из Export, Presentation/file picker, Settings, Sync reconciliation и прочий deferred scope не начинались.

Validation evidence:

- focused reader/Application/Drift/composition/lifecycle tests: PASS, 18 tests;
- invalid-before-mutation integration coverage: PASS для unsupported version, checksum mismatch, malformed JSON, duplicate ID, invalid UUID, invalid timestamp, unknown Entity type, invalid enum и malformed ZIP; исходные state/Outbox сохраняются после каждого случая;
- `flutter analyze`: PASS, no issues;
- полный `flutter test`: PASS, 106 tests;
- import-boundary scan: PASS для Domain, Application и Presentation; Application не импортирует Infrastructure/Drift/`dart:io`/`archive`/`crypto`;
- routing dependency scan: PASS;
- dependency/schema/generated guard: PASS — `pubspec.yaml`, `pubspec.lock`, Drift schema и `lifeos_database.g.dart` не изменены; новые dependencies отсутствуют, Drift generation не требуется;
- `dart pub deps --style=compact` не завершился и был остановлен без вывода; dependency hygiene подтверждена неизменными manifest/lockfile и уже успешными analyze/test resolution;
- `git diff --check`: PASS (только штатные предупреждения Git о CRLF conversion для существующих файлов);
- итоговый `HEAD` = `246e5797ed56f8c0223e420d5f8ffc5ef768038a`, branch `main` синхронизирован с `origin/main`; commit/push не выполнялись;
- `.obsidian/workspace.json` остаётся отдельным пользовательским изменением и не читался/не изменялся.

BE-06 Definition of Done выполнен. BE-07 является следующим `pending` checkpoint и не начинался.

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

Resume point: BE-06 завершён. BE-07 является следующим `pending` checkpoint; перед его началом перечитать ADR-0010, ADR-0011, ADR-0022, ADR-0027, ADR-0028, решения BE-01 — BE-06 и сверить Git/repository state. BE-07 в этом запуске не начинать.

# Состояние выполнения плана

Статус: active
