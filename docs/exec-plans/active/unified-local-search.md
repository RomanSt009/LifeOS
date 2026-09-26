# Unified Local Search — Execution Plan

## Статус плана

- Milestone: Unified Local Search
- Status: active
- Investigation: completed
- Architecture readiness: ready
- Current checkpoint: US-01 — pending
- Resume point: начать US-01 с Application contract и focused contract tests
- ADR gate: новый ADR не требуется
- Production implementation: не начата

## 1. Текущее состояние

### DOCUMENTED

- LifeOS является local-first системой; базовый локальный поиск не должен зависеть от сети.
- `Entity` задаёт общую identity и metadata для typed entities.
- В production существуют `Task`, `Note` и `Workspace`; `Relationship` и `WorkspaceMembership` представляют связи, а не самостоятельный пользовательский текстовый контент.
- Текущий Search — Task-specific: `SearchLifeOsTasks` нормализует query, а `LifeOsTaskRepository.searchByTitle` возвращает `LifeOsTask`.
- Search остаётся read-only и не создаёт Outbox changes.
- Presentation использует Flutter localization и текущую shell architecture на `NavigationRail` + `IndexedStack`.
- ADR-0012 описывает широкое направление Search, но не обязывает текущий milestone вводить FTS, ranking или generic index.
- ADR-0015 отделяет semantic/vector search от обычного локального keyword search.
- Завершённый Knowledge Graph milestone не расширяет Search через graph traversal.

### Фактическая реализация

- `SearchLifeOsTasks` выполняет `trim`; empty и whitespace-only query возвращают пустой список без обращения к repository.
- `DriftLifeOsTaskRepository.searchByTitle` читает active Tasks, выполняет literal substring match через Dart `toLowerCase().contains`, затем сортирует по `updatedAt DESC`, `id ASC`.
- `%`, `_` и `\` не имеют wildcard semantics, потому что matching выполняется не через SQL `LIKE`.
- Case behavior поддерживает практические English/Cyrillic варианты Dart lowercase, но не обещает полную Unicode normalization/case folding/collation.
- `TaskSearchPage` имеет initial/loading/no-results/error states и request-token protection от stale async result/error.
- Search destination встроен в существующий shell и сохраняет state через `IndexedStack`.
- `LifeOsNoteRepository` и `LifeOsWorkspaceRepository` не содержат search operations.
- Schema v4 уже содержит `entities`, `tasks`, `notes`, `workspaces`, `relationships`, `workspaceMemberships`, `outbox`; отдельного search index нет.
- Composition root владеет единственным production database/repository lifecycle.

### INFERRED

- После появления production Notes и Workspaces Task-only Search больше не соответствует минимальной полезной product surface.
- Один bounded mixed result set нужен будущему AI как стабильный Application-level retrieval primitive, но не должен зависеть от AI architecture.
- При текущем ожидаемом локальном масштабе полный просмотр active Task/Note/Workspace rows допустим до появления измеренного performance defect.

### PROPOSED

- Unified Local Search 1.0 ищет `Task`, `Note` и `Workspace` и возвращает typed mixed results.
- `Relationship` и `WorkspaceMembership` не становятся самостоятельными search results.
- Реализация использует specialised Application read port и один Drift adapter без schema change.

## 2. Product goal

Дать пользователю один локальный Search destination, который находит существующие Tasks, Notes и Workspaces по понятным текстовым полям, открывает найденный объект через текущую shell navigation и сохраняет архитектурные границы LifeOS.

Milestone не является реализацией knowledge retrieval, semantic search или universal command palette.

## 3. Searchable entity types и поля

| Тип | Searchable fields | Причина |
| --- | --- | --- |
| `Task` | `title` | Сохраняет действующий Task Search contract. |
| `Note` | `title`, `content` | Оба поля являются пользовательским текстом Note; поиск только по title сделал бы содержимое Note практически недоступным. |
| `Workspace` | `title`, nullable `description` | Даёт доступ к пользовательским context containers без поиска по structural membership. |
| `Relationship` | не является result | Семантическая связь не имеет самостоятельного пользовательского title/content. |
| `WorkspaceMembership` | не является result | Это structural membership edge, а не searchable content entity. |

Не выполняется free-text search по ID, entity type, lifecycle, timestamps, source, version, relationship endpoints или membership metadata.

## 4. Matching semantics

- Query normalization принадлежит Application: один `trim` leading/trailing whitespace.
- Empty и whitespace-only query возвращают пустой результат и не превращаются в `match everything`.
- Matching — literal substring по каждому разрешённому полю.
- `%`, `_` и `\` остаются literal characters.
- Comparison использует locale-independent Dart lowercase semantics, совместимые с текущим Task Search.
- Ожидаются обычные English и Cyrillic case variants, но contract не обещает Unicode normalization, accent folding, locale-specific collation или linguistic stemming.
- Совпадение хотя бы в одном поле создаёт ровно один result для entity; совпадение в нескольких полях не создаёт duplicates.
- Fuzzy, prefix boost, tokenization, stemming, typo correction, relevance score и highlighting не входят в 1.0.

## 5. Mixed result model

Application вводит sealed typed result family, например `LifeOsSearchResult`, с вариантами:

- Task result, содержащий `LifeOsTask`;
- Note result, содержащий `LifeOsNote`;
- Workspace result, содержащий `LifeOsWorkspace`.

Общие `id`, `entityType` и `updatedAt` могут быть доступны через typed getters базового результата. Presentation получает typed Domain entities и сама формирует локализованный type marker и компактный preview.

Не используются `dynamic`, untyped maps, Drift rows или generic `EntityRepository`. Score, matched-field metadata и persisted snippets не нужны для первой версии.

## 6. Ordering и limit

- Все типы объединяются в один список.
- Глобальный deterministic order: `updatedAt DESC`, затем entity `id ASC`.
- Нет type priority, grouping или relevance ranking.
- Use case принимает обязательный положительный global `limit`.
- Presentation 1.0 передаёт явный limit `50`.
- Limit применяется после matching и глобальной сортировки, а не отдельно на каждый entity type.
- Pagination и infinite scroll отложены.

## 7. Query architecture

### Рекомендуемый вариант

- Application port: специализированный read-only `LifeOsUnifiedSearchReader`.
- Application use case: `SearchLifeOsEntities`.
- Infrastructure: один Drift adapter, использующий существующую production database.
- Adapter одним mixed read получает active Task/Note/Workspace candidates через `entities` и typed tables, затем выполняет literal matching, global sort и global limit.
- Typed mapping переиспользует существующие entity conventions; inconsistent typed rows считаются data corruption и не замалчиваются.
- Composition root создаёт use case из уже существующего database lifecycle.

Это Application read projection, а не новый generic Domain repository. Domain contracts Task/Note/Workspace не расширяются cross-entity search concern.

### Отклонённые варианты

- Три repository search methods с merge в Application: дублируют semantics, переносят storage-oriented aggregation вверх и усложняют корректный global limit.
- Один SQL `UNION` с `LIKE/NOCASE`: меняет literal/wildcard и Cyrillic semantics текущего Search и усложняет typed mapping.
- Persisted search index или FTS5: не обоснованы текущим scale evidence и потребовали бы schema/migration/Backup decisions.
- Generic `SearchEngine`/`EntityRepository`: преждевременная abstraction без второго backend или отдельной domain invariant.

Запрос не должен создавать N+1 reads. Один candidate read допустим; hydration отдельными запросами на каждый result — нет.

## 8. Schema и index assessment

- Schema v4 достаточна.
- `schemaVersion` остаётся `4`; schema v5 и migration не требуются.
- Обычный B-tree index не ускоряет general leading-substring search.
- FTS/FTS5, shadow table и persisted search index не вводятся.
- Full scan active Task/Note/Workspace text допустим для локального масштаба в сотни и небольшие тысячи entities.
- Gate для пересмотра: измеренная неприемлемая latency или подтверждённый product scale в десятки тысяч текстовых entities.
- До такого evidence нужен отдельный architecture checkpoint с benchmark/query-plan evidence и compatibility analysis.

## 9. Lifecycle semantics

- Search видит только entities с active lifecycle.
- Completed Task остаётся active entity, поэтому находится и отображает актуальный completion state.
- Archived/deleted entities исключены.
- Trash/recovery search является отдельным будущим use case.
- Search read не изменяет entity version, timestamps, lifecycle или Outbox.

## 10. Navigation integration

- Сохраняется текущая shell-local navigation architecture без router package, deep links и persistent history.
- Task result открывает Task по typed ID.
- Note result открывает Note по typed ID.
- Workspace result открывает Workspace по typed ID.
- Navigation command передаёт identity, а не hydrated entity или repository.
- При implementation следует нормализовать существующий Workspace command до явного typed constructor/callback и проверять соответствие entity type, не вводя новый navigation framework.

## 11. Presentation direction

- Существующий Task-only Search Presentation эволюционирует в unified Search, без второго Search destination.
- Сохраняются input, clear, initial/loading/no-results/error states и stale request protection.
- Mixed list row показывает локализованный type marker/icon, primary label и bounded secondary preview.
- Task: title и completion state.
- Note: title и компактный plain-text preview content; whitespace для preview может визуально схлопываться, Domain content не изменяется.
- Workspace: title и optional description preview.
- Result активируется мышью и клавиатурой через существующую desktop interaction model.
- Query/result state сохраняется через текущий `IndexedStack` lifecycle.
- Matched-substring snippets и highlighting отложены: они потребовали бы дополнительного matched-field contract.

## 12. Workspace scope

- Unified Search 1.0 является глобальным по локальной installation.
- Workspace membership не фильтрует результаты.
- Workspace-scoped Search и context-aware ranking требуют отдельного product/architecture gate.
- Появление Workspace result не меняет ownership или membership semantics ADR-0034.

## 13. Graph boundary

- Search не выполняет graph traversal.
- Relationship не является отдельным result и не повышает ranking.
- WorkspaceMembership не является result и не расширяет scope.
- Related entities, backlinks и one-hop exploration остаются в Knowledge Graph/Application use cases.

## 14. Backup, Outbox и persistence boundary

- Search полностью read-only и не создаёт Outbox records.
- Search не сохраняет query, history, cache или index.
- Backup format v4 не меняется, потому что Search не добавляет persisted state.
- Restore behavior не меняется.
- Production database lifecycle остаётся только в composition root.

## 15. AI implications

- `SearchLifeOsEntities` создаёт bounded, deterministic, typed retrieval primitive, который будущие AI Application workflows смогут вызывать без прямого доступа к Drift.
- Это не AI search API и не context assembly contract.
- Embeddings, vector storage, semantic similarity, reranking, prompt construction, provider SDK и autonomous graph expansion не входят в milestone.
- Roadmap сохраняется: Unified Local Search → AI Foundation → Context-aware AI → stabilization.

## 16. ADR decision

**Решение: новый ADR не требуется.**

Обоснование:

- ADR-0012 уже задаёт локальное Search direction, оставляя конкретный engine/index открытым.
- ADR-0015 отделяет semantic/vector search от текущего keyword search.
- ADR-0016, ADR-0022, ADR-0023, ADR-0030, ADR-0033 и ADR-0034 задают entity, layer, persistence и Workspace boundaries.
- Выбранное решение является специализированной, reversible Application read projection без schema, persisted index, ranking policy или нового долговременного cross-layer invariant.

Новый ADR gate нужен, если implementation потребует FTS/index/schema migration, persistent history, relevance ranking, workspace-scoped semantics, generic search platform или semantic/vector search.

## 17. Риски и mitigations

- Full scan может деградировать на больших Note bodies: bounded result, локальный scale assumption и будущий measured performance gate.
- Unicode matching ограничен Dart lowercase semantics: ограничение явно входит в contract и tests.
- Чтение больших content payloads увеличивает memory cost: допустимо для 1.0; не вводить index без evidence.
- Async races могут показывать stale state: сохранить request-token protection для result и error.
- Workspace navigation command сейчас менее строго типизирован: исправить минимально в Presentation integration.
- Corrupt typed rows нельзя молча скрывать: adapter должен завершаться typed failure до показа частичного misleading result.
- Mixed result contract может разрастись: не добавлять scoring/snippets/filter DSL до конкретного use case.

## 18. Validation policy

Применяется стандартный LifeOS режим:

- Investigation checkpoint: docs-only; без `flutter analyze`, full `flutter test` и broad audits.
- Implementation checkpoints: только минимальная focused validation, необходимая для архитектурной безопасности и следующего шага; всегда `git diff --check` и scope/status inspection.
- Final integration checkpoint: все новые focused tests, relevant regressions, `flutter analyze`, полный `flutter test --reporter compact`, architecture/import scans, localization, responsive/accessibility, schema/Backup/dependency/generated guards и Git checks.
- Нельзя откладывать проверку query semantics, global limit, corruption handling, read-only/Outbox safety или async race behavior, если следующий checkpoint строится на этом результате.

## 19. Checkpoints

### US-01 — Unified Application contract и Infrastructure query

- Status: pending
- Goal: создать typed mixed Application search path и один Drift read adapter.
- Relevant ADRs: ADR-0012, ADR-0015, ADR-0016, ADR-0022, ADR-0023, ADR-0030, ADR-0033, ADR-0034.
- Allowed scope:
  - `LifeOsSearchResult`, `LifeOsUnifiedSearchReader`, `SearchLifeOsEntities`;
  - Drift candidate read, typed mapping, matching, ordering и global limit;
  - composition/provider wiring;
  - миграция действующего Task-only caller на новый contract там, где нужна compile consistency;
  - focused Application/Infrastructure tests.
- Explicit non-goals: Presentation redesign, navigation integration, schema/index/FTS, Backup, graph traversal, AI, generic repositories.
- Architecture gate: остановиться, если корректность требует schema/index/FTS, persisted state, benchmark-driven redesign или нового ADR.
- Definition of Done:
  - Task/Note/Workspace возвращаются typed results;
  - fields, trim/empty, literal characters, English/Cyrillic case, deduplication, active lifecycle, ordering и global limit соответствуют этому плану;
  - query не создаёт N+1 и не меняет database/Outbox;
  - composition переиспользует единственный production database lifecycle.
- Focused validation:
  - deterministic contract/use-case tests;
  - temporary Drift database tests для mixed types, corruption boundary, ordering/limit и read-only/Outbox evidence;
  - relevant existing Task Search tests;
  - `git diff --check`, status и scope inspection.
- Result / evidence: pending.

### US-02 — Unified Search Presentation и typed navigation

- Status: pending
- Goal: заменить Task-only list единым локализованным Search UI и открыть каждый result через текущий shell.
- Relevant ADRs: ADR-0022, ADR-0027, ADR-0030, ADR-0033, ADR-0034.
- Allowed scope:
  - unified Search page/provider;
  - mixed rows и bounded previews;
  - typed Task/Note/Workspace navigation command integration;
  - localization en/ru;
  - focused widget/navigation tests.
- Explicit non-goals: новый destination, router, global navigation state, workspace filtering, highlighting, ranking, persistence changes.
- Architecture gate: остановиться, если нужен router, новый long-lived state owner, cross-feature mutable state или изменение dirty-state contract.
- Definition of Done:
  - initial/loading/no-results/error/result states работают;
  - stale result/error не заменяет новый query;
  - Task/Note/Workspace визуально различимы и открываются typed navigation;
  - keyboard/mouse activation, clear и `IndexedStack` state preservation работают;
  - весь новый статический текст локализован en/ru.
- Focused validation:
  - focused Search widget tests, включая race/error recovery и mixed rows;
  - focused shell navigation tests для трёх result types;
  - localization generation/check только при изменении ARB;
  - `git diff --check`, status и scope inspection.
- Result / evidence: pending.

### US-03 — Final integration audit

- Status: pending
- Goal: доказать завершённый local-first Unified Search vertical slice и закрыть milestone.
- Allowed scope: minimal defect fixes в принятой architecture, final evidence и перенос плана в completed.
- Explicit non-goals: новый search engine, FTS, semantic/AI search, workspace scoping, graph expansion, следующий milestone.
- Architecture gate: любой unresolved long-lived decision блокирует completion.
- Definition of Done:
  - end-to-end Search открывает актуальные Task/Note/Workspace и соблюдает весь contract;
  - architecture, lifecycle, localization, desktop UX, read-only safety и dependency hygiene подтверждены;
  - schema v4, Backup v4, dependencies и generated ownership не изменены без отдельного gate;
  - план имеет status `completed` и точный final Git state.
- Final validation:
  - все новые focused tests;
  - relevant Task/Note/Workspace/Search/navigation/persistence regressions;
  - `flutter analyze`;
  - `flutter test --reporter compact`;
  - import/architecture и routing dependency scans;
  - `flutter gen-l10n` и localization checks;
  - desktop responsive/accessibility checks;
  - schema/Backup/dependency/generated guards;
  - `git diff --check`, diff scope и exact status.
- Result / evidence: pending.

## 20. Plan Definition of Done

- Один Search destination локально ищет active Tasks, Notes и Workspaces по утверждённым полям.
- Matching, Unicode limitation, ordering и bounded result contract документированы и протестированы.
- Results typed на Application boundary и не раскрывают Drift/SQLite.
- Search остаётся read-only, не меняет Outbox и не создаёт нового persistence lifecycle.
- Result activation переиспользует shell-local navigation.
- Domain repositories не превращены в generic search abstraction.
- Schema v4, Backup v4 и dependency set остаются неизменными, если новый gate не принят отдельно.
- Final milestone validation проходит полностью.

## 21. Deferred scope

- FTS/FTS5, persisted search index и schema migration.
- Unicode normalization, locale-aware collation, stemming и typo tolerance.
- Ranking, scoring, boosts, grouping, filters, facets и query language.
- Match highlighting и contextual matched snippets.
- Pagination и infinite scroll.
- Search history, saved searches и command palette.
- Workspace-scoped Search и membership-aware filtering/ranking.
- Relationship/Membership results, graph expansion, backlinks и related-result ranking.
- Trash/archived search.
- Attachments/files/image OCR.
- Unified remote/cloud search.
- Semantic/vector/embedding search и AI context assembly.

## 22. Investigation evidence

- Pre-flight HEAD: `ecd8c51` (`New pravila`).
- Branch: `main`.
- Upstream relation at investigation start: `origin/main...HEAD = 0 1`.
- Pre-existing unrelated working-tree change: `.obsidian/workspace.json`; не изменён этим investigation.
- До создания этого файла active execution plans отсутствовали.
- Investigation не изменяет production Dart, tests, schema, Backup, dependencies или generated files.
