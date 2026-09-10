# ADR-0028: Контракт Backup, Export и Restore

Статус: Принято

Дата: 2026-09-11

## Контекст

LifeOS уже хранит локальный Domain State в file-backed SQLite database через Drift. Текущая production schema содержит общий metadata Entity, типизированные данные Task и Outbox для будущей синхронизации. Stable `device_id` хранится отдельно от database в application-support storage.

ADR-0011 разделяет Sync, Backup и Export, требует versioning, manifest, integrity и безопасный Restore, но намеренно не фиксирует начальный serialization contract, семантику Outbox/device identity при восстановлении и concrete encryption policy.

Перед реализацией Backup / Export необходимо определить внешний контракт, который:

- не превращает внутреннюю SQLite schema в публичный формат;
- не воспроизводит старую transport queue на новой installation;
- сохраняет Domain identity и metadata;
- позволяет безопасно развивать формат;
- не требует cloud, аккаунта или сети.

## Решение

### 1. Backup и Export — разные пользовательские сценарии

LifeOS предоставляет два разных внешних сценария.

**Backup** предназначен для полного переноса и восстановления поддерживаемого пользовательского состояния LifeOS. Он оптимизирован для recovery, целостности и compatibility.

**Export** предназначен для portability, просмотра и выхода пользователя из LifeOS. Он оптимизирован для открытости и human readability и не обязан быть достаточным для полного Restore.

Backup и Export могут использовать общий внутренний logical snapshot/read pipeline, если это не смешивает их внешние contracts. Они не являются одним неразличимым artifact или Presentation flow.

Sync, Outbox replication, Backup, Export, Restore и Import сохраняют отдельные ответственности.

### 2. Backup format v1

Backup v1 использует versioned archive/container со следующей логической структурой:

```text
backup container
├── manifest
└── logical data snapshot
```

Формат не является raw SQLite copy и не публикует Drift tables как Backup contract.

Manifest должен содержать как минимум:

- kind содержимого, однозначно обозначающий LifeOS Backup;
- backup format version;
- `created_at` в UTC;
- список required sections;
- application version как информационную metadata;
- source database schema version как диагностическую/compatibility metadata;
- информацию, достаточную для integrity validation содержимого.

Application version и source database schema version не определяют структуру Backup сами по себе. Публичный контракт определяется backup format version.

Logical data snapshot представляет поддерживаемые user/Domain records независимо от физической SQLite schema. Для текущей реализации это Entity metadata и типизированные Task data.

Точная archive technology, JSON schema, имена полей, checksum algorithm и file extension определяются BE-02 в пределах этого решения.

### 3. Export format v1

Export v1 является отдельным human-readable logical JSON document.

Он:

- содержит пользовательские/Domain records в переносимом представлении;
- имеет собственный export format version;
- не зависит от Drift rows или внутренней SQLite schema;
- не включает installation/runtime/transport state;
- не заявляется как полноценный Backup или достаточный input для Restore.

Markdown, CSV, HTML, ZIP export и обратный Import могут быть добавлены позднее отдельными расширениями.

### 4. Независимые версии

LifeOS различает:

1. database schema version — физическую версию локальной Drift/SQLite schema;
2. backup format version — версию внешнего Backup contract;
3. export format version — версию внешнего Export contract;
4. Entity version — версию Domain State конкретной Entity;
5. Outbox payload schema version — версию serialized Change payload;
6. application version — версию приложения.

Ни одна из этих версий не подменяет другую.

### 5. Domain identity и metadata

Backup/Restore сохраняет без регенерации:

- Entity UUID;
- Entity type;
- `createdAt`;
- `updatedAt`;
- lifecycle;
- Entity version;
- source/provenance;
- типизированное Domain state, включая текущие Task fields.

Entity UUID является identity пользовательской Entity. `change_id` не является identity Entity или пользовательских данных.

Полный Export текущего Domain State также представляет Entity UUID и перечисленные metadata, чтобы сохранить смысл и provenance данных. Export contract может маркировать technical fields явно, но не должен незаметно изменять их значение.

### 6. Device identity

`device_id` является identity installation/device, а не пользовательскими данными.

Backup v1 и Export v1 не включают operational `device_id` как восстанавливаемое поле. В v1 он также не включается как диагностическая metadata: это минимальный вариант, исключающий случайное использование source identity при Restore.

При Restore:

- если текущая installation уже имеет `device_id`, он сохраняется;
- новая installation создаёт и сохраняет собственный новый `device_id` существующим production mechanism;
- Restore не заменяет текущий `device_id` идентификатором исходной installation;
- новая installation не должна представляться будущему Sync как старое устройство.

Неидентифицирующая информация об источнике Backup может быть добавлена в будущей версии manifest только отдельным явным решением.

### 7. Outbox policy v1

Active Outbox полностью исключается из Backup v1 и Export v1.

Он не включается даже как diagnostic/non-restorable payload. Это предотвращает двусмысленность, случайное восстановление queue и утечку transport metadata в portable artifacts.

Restore v1:

- не восстанавливает pending Outbox entries исходной installation;
- не replay/send старые Changes;
- не переносит старые `change_id` как активную delivery queue;
- не создаёт обычную Outbox mutation на каждую восстановленную Entity;
- восстанавливает logical user state отдельно от transport/sync state.

ADR-0020 считает pending Outbox critical non-rebuildable data для непрерывности работающей Sync installation. Это остаётся верно для operational recovery текущей live system. Настоящий ADR уточняет, что portable Backup/Restore v1 сознательно не переносит эту queue между installations, поскольку registration, acknowledgement и remote reconciliation ещё не определены.

Когда Sync будет реализован, restored logical state считается локальной истиной текущей installation. Sync layer обязан использовать отдельный reconciliation/bootstrap protocol, а не replay Outbox исходного устройства. Конкретный protocol остаётся будущим Sync decision.

### 8. Restore semantics v1

Restore v1 использует replace-style semantics.

Он не выполняет:

- merge двух локальных наборов данных;
- selective restore;
- duplicate-resolution workflow;
- conflict resolution;
- Import из Export.

До изменения текущего состояния Backup полностью проходит structural, integrity и compatibility validation. Corrupted, incomplete и unsupported Backup отклоняется до mutation текущей database.

Неуспешная проверка или Restore не должны оставлять текущую database частично изменённой. Restore не должен молча уничтожать рабочую копию. Требования к explicit confirmation, safety backup, closed-database replacement или transactional rebuild определяются architecture gate BE-05 и implementation BE-06.

### 9. Compatibility v1

Reader явно проверяет backup format version.

- Backup с отсутствующей, malformed или unknown version отклоняется;
- unsupported newer version отклоняется понятной ошибкой;
- reader v1 не обязан читать arbitrary future formats;
- поддержка старых версий добавляется только явно через документированные readers/migrations;
- application/database version metadata может помочь диагностике, но не разрешает неявное чтение несовместимого format.

Аналогичные правила применяются к export format version для потребителей Export contract.

### 10. Encryption policy v1

Encryption и password protection не являются обязательной частью Backup v1.

Backup v1 остаётся полностью локальным. Network/cloud upload, account authentication и remote storage не входят в scope.

Backup содержит чувствительные данные. Presentation должна ясно сообщать пользователю scope, destination и отсутствие защиты, если artifact не зашифрован. Файловые permissions и безопасное обращение с temporary artifacts остаются обязательными Infrastructure concerns.

Container/manifest design не должен препятствовать добавлению encryption/password protection в будущей версии. Concrete algorithm, key management и crypto dependencies требуют отдельного решения.

Это уточняет, но не отменяет ADR-0011: требование «Backup должен поддерживать encryption» трактуется как обязательная архитектурная расширяемость, а не обязательное шифрование первого local-only format v1.

### 11. Consistency и atomicity

Backup/Export создаётся из consistent logical snapshot поддерживаемого состояния.

Чтение нескольких persistence records должно происходить через controlled snapshot/transaction boundary, предоставляемую Infrastructure, а не через независимые несогласованные UI queries.

Финальный artifact не должен выглядеть успешно созданным, если запись, validation или finalization не завершены.

Допустимый implementation pattern:

```text
consistent logical snapshot
    ↓
temporary artifact
    ↓
write + flush + validate
    ↓
atomic rename/replace, если filesystem позволяет
    ↓
final artifact
```

Конкретные filesystem guarantees, cleanup и cancellation принадлежат Infrastructure и определяются BE-04.

### 12. Validation boundary

Backup validation должна как минимум уметь обнаруживать:

- отсутствующий или malformed manifest;
- unsupported format version;
- отсутствующие required sections;
- нарушение integrity/checksum;
- malformed logical data;
- duplicate Entity IDs;
- Task без соответствующего Entity metadata;
- несовместимый Entity type;
- invalid lifecycle/source/version/timestamp representation;
- unknown required content;
- truncated/corrupted archive.

Точный validation API и error model определяются BE-02/BE-03. Validation не размещается в Presentation и не изменяет Domain rules.

### 13. Layer boundaries

**Domain**

- не знает о JSON, archive/ZIP, manifest, filesystem, Drift или Backup files;
- существующие Domain entities и invariants остаются источником бизнес-смысла данных;
- Backup format не становится Domain Entity.

**Application**

- координирует отдельные use cases `CreateBackup`, `ExportLifeOsData` и позднее `RestoreBackup`;
- работает через abstractions;
- определяет workflow и orchestration validation;
- не зависит от Drift implementation или platform file APIs.

**Infrastructure**

- получает consistent persistence snapshot;
- выполняет logical mapping/serialization;
- реализует archive/container и manifest;
- читает и пишет Backup/Export files;
- реализует atomic filesystem finalization;
- реализует разрешённую BE-05 persistence replacement strategy.

**Presentation**

- позволяет пользователю выбрать действие и destination;
- отображает scope, progress, result и errors;
- не сериализует данные и не обращается напрямую к database/filesystem implementation.

**Composition root**

- связывает Application abstractions с Infrastructure implementations;
- остаётся владельцем production database и identity lifecycle;
- координирует закрытие/возобновление database, если Restore implementation этого потребует.

## Отклонённые варианты

### Raw SQLite copy как публичный Backup contract

Отклонено, потому что:

- формат жёстко связан с внутренней schema и migration history;
- безопасная копия открытой SQLite database требует специальных snapshot/checkpoint semantics;
- текущий `device_id` расположен вне database;
- raw tables не являются portable logical contract;
- Outbox переносился бы неявно;
- такой файл непригоден как human-readable Export.

Raw SQLite snapshot может когда-либо использоваться как внутренний implementation artifact только после отдельного решения и не становится публичным Backup/Export format.

### Один artifact для Backup и Export

Отклонено: recovery и portability имеют разные completeness, validation и privacy requirements.

### Перенос старого device_id

Отклонено: новая installation не должна выдавать себя за старое устройство перед будущим Sync.

### Восстановление active Outbox

Отклонено: старые pending Changes могут вызвать duplicate remote mutations, неверную device attribution или конфликт с будущей registration/acknowledgement model.

### Merge Restore v1

Отклонено: merge требует duplicate/conflict policy и фактически вводит часть Sync architecture. Replace-style Restore имеет меньшую поверхность ошибок и проверяемый результат.

## Future / deferred

- cloud и self-hosted Backup;
- scheduled/automatic Backup, retention и rotation;
- encrypted/password-protected Backup;
- concrete encryption algorithm и key management;
- merge Restore;
- selective/partial Restore;
- Import из Export;
- conflict-aware Restore;
- remote Sync reconciliation/bootstrap implementation;
- device registration/revocation/pairing;
- cross-version migration framework за пределами явно поддерживаемых format versions;
- дополнительные Export formats;
- files/relationships/другие Entity sections после появления соответствующих vertical slices.

## Последствия и компромиссы

### Положительные

- Logical format переносим и не зависит от Drift schema.
- Manifest и независимая version делают compatibility явной.
- Новый `device_id` сохраняет корректную installation identity для будущего Sync.
- Исключение active Outbox уменьшает риск duplicate mutations и неверного replay.
- Replace-style Restore v1 не требует преждевременного merge/conflict engine.
- Backup и Export остаются local-first и provider-independent.
- Формат можно расширить files, relationships и encryption без превращения SQLite schema в публичный API.

### Отрицательные

- Необходимо поддерживать logical mappers, serializers и versioned readers отдельно от Drift mappings.
- Restore требует rebuild/mapping Domain State, а не простого копирования database file.
- Backup v1 не сохраняет непрерывность pending Sync delivery исходной installation.
- Unencrypted Backup v1 требует ясного предупреждения и аккуратного обращения с чувствительным файлом.
- Replace-style Restore не решает перенос выбранной части данных или объединение двух installations.

## Приоритет

ADR-0028 конкретизирует ADR-0011 для начального Backup / Export milestone.

Если ранние предварительные ADR допускают raw database export, перенос operational Outbox/device identity либо смешивают Backup и Export, для Backup/Export/Restore v1 применяется настоящий ADR.

ADR-0023 и ADR-0025 продолжают регулировать live local mutation, Outbox и installation identity. Настоящий ADR регулирует только их поведение на Backup/Export/Restore boundary.
