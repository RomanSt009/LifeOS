# ADR-0031: Backup and Export Format Versioning for Notes

**Статус:** Принято  
**Дата:** 2026-09-12  
**Версия:** 0.1

## Контекст

LifeOS уже имеет versioned logical Backup и human-readable Export, определённые ADR-0028.

Backup является логическим архивом пользовательских данных и намеренно не является копией SQLite database. Версия Backup format независима от версии локальной SQLite schema.

До появления production Note существующий Backup/Export format v1 описывал фактически поддерживаемый набор пользовательских Entity, основанный на Task.

После реализации Note Domain и persistence в LifeOS появляется второй production Entity type:

- Task;
- Note.

`Note` содержит собственное пользовательское состояние:

- `title`;
- `content`;

а также использует общий Entity metadata contract:

- stable Entity ID;
- entity type;
- `createdAt`;
- `updatedAt`;
- lifecycle;
- version;
- source.

Production Note должна участвовать в Backup и Export. В противном случае replace-style Restore может привести к потере пользовательских Notes.

Возникают два возможных подхода:

1. расширить существующий format v1 optional-полем `notes`;
2. сохранить v1 неизменным и ввести format v2.

Добавление optional-поля в v1 позволило бы новому приложению читать старые v1-файлы, однако изменило бы семантическое значение уже опубликованной версии формата.

Особенно опасен обратный сценарий: старый reader может распознать новый файл как поддерживаемый `v1`, не знать о Notes и выполнить неполное восстановление.

Для Backup/Restore silent data loss является неприемлемым поведением.

## Решение

LifeOS вводит **Backup/Export format v2** для поддержки production Notes.

Существующий format v1 остаётся неизменным историческим контрактом.

### 1. Format v1

Backup/Export format v1 сохраняет исходную семантику.

Он не расширяется optional-полем `notes`.

Format v1 считается историческим форматом, не содержащим Note state.

Новое приложение должно продолжать поддерживать чтение совместимых v1 Backup согласно существующим правилам совместимости.

### 2. Format v2

Format v2 является текущим форматом после появления production Notes.

Он поддерживает:

- Tasks;
- Notes;
- общий Entity metadata необходимый для полного восстановления соответствующих Entity.

Note representation должна сохранять как минимум:

- Entity ID;
- entity type;
- `createdAt`;
- `updatedAt`;
- lifecycle;
- version;
- source;
- title;
- content.

Note content должен сохраняться без потери значимых whitespace/content semantics, определённых ADR-0030.

### 3. Политика записи

После введения format v2 текущая версия LifeOS создаёт новые Backup и Export в формате v2.

Новые файлы не должны маркироваться как v1 только ради backward compatibility со старым reader.

### 4. Политика чтения

Текущая версия LifeOS должна распознавать поддерживаемые:

- format v1;
- format v2.

Version dispatch должен происходить до destructive Restore mutation.

Reader не должен интерпретировать неизвестную версию как ближайшую известную версию.

### 5. Future/unsupported versions

Backup с неизвестной или более новой неподдерживаемой format version должен быть отклонён до изменения локальных пользовательских данных.

Запрещены:

- best-effort Restore;
- partial Restore;
- silent ignoring неизвестных Entity sections;
- автоматический downgrade Backup format;
- интерпретация future format как v1 или v2.

Fail-safe rejection предпочтительнее частичного восстановления.

### 6. Restore v1

Поддерживаемый Backup v1 продолжает восстанавливаться согласно историческому контракту.

Отсутствие Notes в v1 является свойством формата, а не malformed input.

Конкретная политика взаимодействия Restore старого Task-only v1 с уже существующими локальными Notes должна быть реализована в соответствии с replace-style semantics ADR-0028: Restore заменяет поддерживаемое локальное пользовательское состояние, а не выполняет merge.

Restore не должен создавать синтетические Notes для v1.

### 7. Restore v2

Restore v2 является полной replace-style операцией для поддерживаемого v2 пользовательского состояния.

До начала mutation должны быть полностью проверены:

- format version;
- manifest;
- checksums;
- Entity representations;
- Task representations;
- Note representations;
- ссылки между common Entity metadata и typed state;
- Domain invariants, необходимые для безопасного восстановления.

Malformed Note должна приводить к отказу всего Restore до mutation.

### 8. Atomicity

Restore v2 должен оставаться атомарным.

Все изменения локальной SQLite state выполняются в одной transaction после полной предварительной validation.

Ошибка Restore не должна оставлять частично восстановленное состояние.

### 9. FK-safe replace order

При replace-style Restore физический порядок должен учитывать typed tables.

Удаление выполняется в FK-safe порядке концептуально:

```
Outbox
→ typed Entity tables (Tasks, Notes)
→ Entities
```

Восстановление:

```
Entities
→ corresponding typed Entity rows
```

Конкретная Infrastructure реализация может отличаться, если сохраняет те же invariants и atomicity.

### 10. Outbox

Backup по-прежнему не содержит active local Outbox как восстанавливаемое пользовательское состояние.

Restore:

- не использует обычные repository mutations, создающие Outbox;
- не создаёт CREATE/UPDATE Changes для восстановленных Tasks или Notes;
- очищает локальный Outbox согласно ADR-0028;
- завершает успешный Restore с пустым active Outbox.

Migration database schema и Restore Backup остаются разными механизмами.

### 11. Device identity

Installation `device_id` не входит в Backup/Export format v2.

Restore не заменяет installation-local `device_id`.

Это сохраняет разделение между:

- переносимым пользовательским состоянием;
- identity конкретной установки приложения.

### 12. Export

Human-readable Export также получает format v2 и включает Notes.

Export остаётся отдельным от Backup пользовательским представлением данных.

Export v2 не становится автоматически Import format.

Поддержка Import from Export данным ADR не вводится.

### 13. Backup version и database schema version

Backup/Export format version и SQLite schema version являются независимыми version spaces.

Например:

```
SQLite schemaVersion = 2
Backup formatVersion = 2
```

Совпадение чисел в текущем состоянии является случайным и не создаёт зависимости.

Будущая SQLite schema v3 не требует автоматически Backup v3.

И наоборот, изменение Backup format не требует автоматически изменения SQLite schema.

### 14. Compatibility principle

Backup format version должна изменяться, когда новый writer создаёт файл с такой семантикой пользовательского состояния, которую старый reader не может безопасно и полностью интерпретировать.

Главный критерий — безопасность полного восстановления, а не максимальное сохранение номера версии.

Additive JSON compatibility сама по себе недостаточна, если старый reader может потерять неизвестные пользовательские данные.

### 15. Неизменность исторических форматов

После принятия нового format version предыдущая версия рассматривается как frozen compatibility contract.

Новые Entity sections не должны добавляться в исторический format только потому, что serialization технически допускает optional fields.

Это позволяет version number оставаться надёжным индикатором возможностей reader/writer.

## Последствия

### Положительные

- исключается неоднозначность значения Backup v1;
- старый reader не получает новый Note-aware файл, ошибочно маркированный как знакомый v1;
- снижается риск silent Note loss;
- Restore может безопасно dispatch по версии до mutation;
- сохраняется возможность восстанавливать исторические v1 Backup;
- появляется явная политика для будущих Entity additions;
- SQLite migrations и Backup compatibility остаются независимыми механизмами.

### Отрицательные

- необходимо поддерживать минимум два reader paths: v1 и v2;
- увеличивается объём compatibility tests;
- DTO/codecs требуют version-aware организации;
- future Backup evolution требует сознательно оценивать необходимость следующей версии.

Эта сложность принимается как цена безопасного восстановления пользовательских данных.