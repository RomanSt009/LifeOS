# LifeOS — Codex Execution Guide

Эта страница — шпаргалка владельца проекта.

Не нужно искать старые промпты в ChatGPT.

## Где Codex хранит прогресс

Текущий основной активный план:

```text
docs/exec-plans/active/workspace-vertical-slice.md
```

Milestone: Workspace Vertical Slice.

Текущая точка возобновления: WS-02 — Schema v4 migration foundation. WS-01
завершён как documentation/reconciliation и quick-create transaction gate.

Структура каталогов:

```text
docs/exec-plans/
├── README.md
├── active/
│   └── workspace-vertical-slice.md
└── completed/
    ├── backup-export.md
    ├── documentation-reconciliation.md
    ├── desktop-shell-navigation.md
    ├── local-search.md
    ├── lifeos-mvp.md
    ├── notes-vertical-slice.md
    ├── relationships-vertical-slice.md
    ├── desktop-usability-dogfooding-alpha.md
    └── dogfooding-ux-improvements-1.md
```

- `active/` содержит планы, которые Codex может выполнять сейчас;
- `completed/` содержит завершённые исторические планы, которые нельзя случайно продолжать;
- одновременно в `active/` должен находиться только один основной execution plan, если отдельным решением явно не установлено иное.

В нём смотри:

- Current milestone
- Current checkpoint
- Resume checkpoint
- Known blockers
- Result / evidence

Фактическое состояние Git всегда важнее текста checkpoint.

---

## Стандартный режим validation для milestone

LifeOS использует risk-based validation cadence.

### Investigation / architecture gate

- обычно docs-only;
- полный тестовый прогон не выполняется только ради формальности;
- запускаются лишь проверки, необходимые для принятия архитектурного решения.

### Implementation checkpoints

- checkpoint должен давать содержательный архитектурный или vertical результат;
- выполняется минимальная focused validation, необходимая для доказательства его
  contract и безопасного перехода к следующему checkpoint;
- полный `flutter test`, широкие regressions, `flutter analyze` и большие аудиты
  обычно накапливаются до финала milestone;
- перед отчётом всегда выполняется `git diff --check` и проверяется Git status/scope;
- промежуточный отчёт остаётся коротким.

Проверку нельзя откладывать, если её результат влияет на архитектурную безопасность
или возможность продолжить работу. В частности, сразу проверяются:

- query plan, определяющий необходимость schema/index;
- migration, на которой строится следующий checkpoint;
- atomic transaction boundary до построения Application/UI поверх неё;
- data-loss и dirty-state safety;
- ADR/architecture gate.

### Final integration checkpoint

Финальный checkpoint выполняет полный аудит milestone:

- все новые focused tests;
- все релевантные regression suites;
- `flutter analyze`;
- полный `flutter test --reporter compact`;
- architecture/import scans;
- localization validation;
- responsive/accessibility checks, когда применимо;
- schema/Backup/dependency/generated guards;
- `git diff --check` и точный Git status/scope.

Главный принцип:

> В середине milestone проверяется только то, что влияет на архитектурную
> безопасность и возможность двигаться дальше. Остальное накапливается и полноценно
> проверяется в финальном integration checkpoint.

---

## Как начать или продолжить автономную работу

Открыть проект LifeOS в Codex и отправить:

> Continue the active LifeOS execution plan. Follow AGENTS.md. Reconcile the active checkpoint with the repository state before making changes. Continue through ready checkpoints while validation passes. Stop on an unresolved architecture decision, unsafe assumption, unrecoverable validation failure, or permission boundary requiring user review.

Это основной prompt.

Не требуется описывать Codex предыдущую историю разработки.

---

## После исчерпания лимита Codex

После восстановления лимита:

1. открыть тот же LifeOS repository;
2. желательно продолжить существующий Codex thread;
3. отправить:

> Resume the active LifeOS execution plan from the repository checkpoint. Reconcile the plan with Git and continue from the first incomplete action.

Codex должен восстановить состояние из:

1. AGENTS.md;
2. active execution plan;
3. Git status/diff/history;
4. существующего кода и тестов.

Не нужно вручную вспоминать, на каком действии остановился агент.

---

## Если Codex сообщает BLOCKED

Не просить его «просто выбрать вариант».

Скопировать:

- checkpoint;
- blocker;
- ADR references;
- requested architecture decision;

и обсудить решение отдельно.

После принятия решения сначала зафиксировать его в подходящем ADR, если решение архитектурное.

Затем:

> Re-read the accepted architecture decision and resume the blocked checkpoint.

---

## Разрешения

Обычно допустимо выдавать `Allow once` для:

- flutter analyze;
- flutter test;
- flutter pub get;
- dart run build_runner build;
- read-only Git inspection;
- normal SDK/package cache access required by these commands.

Проверить отдельно перед разрешением:

- удаления файлов;
- изменения Git config;
- reset/restore/checkout/clean;
- commit;
- push;
- системных изменений;
- широкого доступа за пределами проекта, не объяснённого validation/toolchain.

---

## Git policy

По умолчанию Codex:

- может менять файлы в scope активного checkpoint;
- может обновлять active execution plan;
- может запускать validation;
- НЕ делает commit;
- НЕ делает push.

После milestone изменения проверяются владельцем проекта и фиксируются отдельно.

---

## Быстрая ручная проверка

```powershell
git status --short --branch
git diff --stat
flutter analyze
flutter test
git diff --check
```

## Главное правило

Не определять прогресс по памяти разговора.

Использовать:

AGENTS.md + active execution plan + Git + tests


Теперь даже если через месяц ты забудешь весь наш сегодняшний разговор, достаточно открыть:

```text
docs/exec-plans/README.md

Там будет и команда запуска, и команда восстановления после лимита.
```

---
## Как безопасно закончить рабочую сессию

Prepare to stop the current LifeOS execution session.

Do not start another checkpoint.

Finish only the current safe atomic action if one is already in progress.

Then:
- stop implementation;
- inspect git status and the relevant diff;
- update the active execution plan;
- record the exact current checkpoint and its status;
- record what has actually been completed;
- record what remains;
- record the latest validation results;
- record any blockers;
- record relevant working-tree state;
- leave incomplete work as active, never done;
- do not commit or push.

Run validation only if it is safe and reasonably bounded at the current state.

Finish with a concise RESUME POINT describing exactly where the next Codex session should continue.

After recording the checkpoint, stop. Do not begin additional work.

### Тогда у тебя будут фактически **три команды управления Codex**:

| Ситуация                           | Команда                                                                     |
| ---------------------------------- | --------------------------------------------------------------------------- |
| Начать обычную работу              | `Continue the active LifeOS execution plan...`                              |
| Продолжить после прерывания/лимита | `Resume the active LifeOS execution plan from the repository checkpoint...` |
| Нужно выключать ПК                 | `Prepare to stop the current LifeOS execution session...`                   |
После следующего запуска используй:

```
Resume the active LifeOS execution plan from the repository checkpoint.

The previous session may have been interrupted unexpectedly.
Do not assume the checkpoint file is current.
First reconcile AGENTS.md, the active execution plan, git status, git diff, existing implementation, and tests.
Determine the first incomplete safe action and continue from there.
Do not discard or overwrite existing work merely because it is not recorded in the execution plan.
```


---

И ещё я бы **не делал Git commit после каждого checkpoint автоматически**. Пусть Codex работает внутри нескольких checkpoints, а мы после логически законченного блока смотрим:

```
git status --short --branch
git diff --stat
git diff
flutter analyze
flutter test
```

---
