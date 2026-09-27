# LifeOS

> Персональная цифровая экосистема, призванная объединить информацию, контекст, знания и автоматизацию в одном рабочем пространстве, ориентированном на конфиденциальность.

## Статус проекта

**Фаза:** LifeOS 1.0 dogfooding release candidate / Windows desktop

LifeOS — local-first Windows desktop application на Flutter с layered architecture, Riverpod и file-backed SQLite через Drift.

Реализованы:

- desktop shell и навигация Home / Workspaces / Tasks / Notes / Search / Settings;
- Workspaces с Unassigned, mixed Task/Note members, attach/detach и quick-create;
- создание, редактирование, completion/reopen и recoverable Trash/Restore для Tasks;
- создание, выбор, редактирование и локальное хранение Notes с explicit save, dirty-draft guard и recoverable Trash/Restore;
- production schema v4 для Tasks, Notes, Relationships, Workspaces, memberships и атомарного Outbox;
- постоянная identity локальной installation;
- Unified Local Search по активным Tasks, Notes и Workspaces;
- английская и русская локализация;
- ненаправленные Relationships типа `related` между Tasks/Notes с contextual UI и lifecycle unlink;
- Backup / Export v4 и атомарный Restore совместимых v1/v2/v3/v4 Backup;
- опциональный local AI через Ollama: **Ask about this Workspace** с фиксированной моделью `qwen2.5-coder:7b`.

Sync, Projects, Documents, full Dashboard, advanced Search, cloud AI и graph visualization остаются отложенным scope.

`version: 1.0.0+1` в `pubspec.yaml` является текущей package/application metadata. Private dogfooding distribution использует unsigned portable ZIP полного Windows Release-каталога, без installer.

## Архитектура

Основное направление зависимостей:

```text
Presentation → Application → Domain ← Infrastructure
```

Riverpod принадлежит Presentation/composition, а Drift/SQLite, filesystem и
Ollama HTTP — Infrastructure. Composition root владеет единственным production
database lifecycle. Application AI boundary остаётся provider-neutral; Ollama
adapter не проникает в Domain или Application.

Подробные решения находятся в [ADR](docs/adr/).

## Development setup

Требования:

- Windows 10/11;
- Flutter SDK, совместимый с Dart constraint из `pubspec.yaml`;
- Visual Studio с workload **Desktop development with C++** и Windows SDK.

Из корня repository:

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --reporter compact
flutter run -d windows
```

Release build:

```powershell
flutter build windows --release
powershell -ExecutionPolicy Bypass -File tool/package_windows_release.ps1
```

Подробности packaging и clean-profile smoke:
[Windows release guide](docs/release-windows.md). Короткий ручной RC checklist:
[dogfooding checklist](docs/dogfooding-rc-checklist.md).

## Local AI setup

Local AI опционален и не нужен для Workspaces, Tasks, Notes, Relationships,
Search или Backup.

1. Установите Ollama вручную.
2. Установите фиксированную модель:

   ```powershell
   ollama pull qwen2.5-coder:7b
   ```

3. Запустите Ollama и проверьте Local AI в Settings.

LifeOS обращается только к `http://127.0.0.1:11434`, не устанавливает и не
запускает Ollama, не загружает модель автоматически, не требует API key и не
имеет cloud fallback. В текущем 1.0 bounded Workspace context отправляется
локально установленному Ollama; AI history, tools и mutations не сохраняются
LifeOS. Ollama и model weights не входят в portable ZIP.

## Данные и Backup

Пользовательские данные хранятся локально в SQLite application-support
directory Windows. Portable ZIP переносит executable/runtime, но не переносит
database рядом с `.exe`.

Settings предоставляет:

- logical versioned Backup ZIP;
- human-readable Export JSON;
- атомарный Restore поддерживаемых Backup v1-v4.

Backup — не raw database copy. Active Outbox и `device_id` не экспортируются;
при Restore installation `device_id` сохраняется. Перед обновлением приложения
рекомендуется создать Backup. Downgrade на версию с более старой schema не
поддерживается.

## Отложенный scope

После 1.0 остаются:

- Sync, backend и conflict UI;
- reminders, notifications и tray;
- spellcheck, Markdown/rich text, attachments и Workspace hierarchy;
- новые Entity/Relationship types и graph traversal/visualization;
- semantic/vector/FTS Search, ranking и pagination;
- cloud AI, provider/model selection, AI history, tools и mutations;
- installer, code signing и auto-update.

Сроки для этого scope не обещаются.

## Vision

LifeOS стремится стать персональной цифровой операционной системой: модульной платформой, ориентированной на локальное использование, которая объединяет заметки, задачи, файлы, проекты, знания и помощь искусственного интеллекта, при этом оставляя за пользователем контроль над его данными.

## Основные принципы

- Локальное использование
- Конфиденциальность по умолчанию
- ИИ как помощник
- Модульная архитектура
- Граф знаний
- Кроссплатформенная разработка
- Долгосрочная поддержка

## Философия разработки

Проект разрабатывается до начала реализации. Требования к продукту, архитектура и важные технические решения документируются и пересматриваются по мере развития системы.

## Документация и выполнение

- архитектура и продуктовые документы: [`docs/`](docs/);
- архитектурные решения: [`docs/adr/`](docs/adr/);
- active/completed execution plans: [`docs/exec-plans/`](docs/exec-plans/).

## Лицензия

Проект распространяется как **All Rights Reserved**. Отдельная модель публичного
лицензирования до private dogfooding release не определена.
