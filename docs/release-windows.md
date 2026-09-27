# Windows release and portable package

LifeOS 1.0 использует portable ZIP полного Flutter Windows Release-каталога.
Это не installer и не portable-data mode: пользовательская SQLite database
остаётся в Windows application-support directory, а не рядом с executable.

## Требования

- Windows desktop;
- Flutter SDK, совместимый с ограничениями в `pubspec.yaml`;
- Visual Studio с workload **Desktop development with C++**;
- Windows 10/11 SDK;
- PowerShell 5.1 или новее.

Ollama не требуется для запуска основных функций. Для Local AI пользователь
отдельно устанавливает Ollama и модель `qwen2.5-coder:7b`.

## Release build

Из корня repository:

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --reporter compact
flutter build windows --release
powershell -ExecutionPolicy Bypass -File tool/package_windows_release.ps1
```

Стандартный build output:

```text
build/windows/x64/runner/Release/
```

На старых Flutter layouts script также распознаёт
`build/windows/runner/Release/`.

Script читает `version` из `pubspec.yaml`, проверяет полный runtime и создаёт:

```text
build/distributions/LifeOS-<version>-windows-x64.zip
```

Существующий ZIP не перезаписывается. Для нового artifact удалите или
переместите предыдущий файл вручную либо укажите другой пустой
`-OutputDirectory`.

## Package contract

ZIP содержит верхнеуровневый каталог `LifeOS/` со всем Windows runtime:
`LifeOS.exe`, Flutter DLL, plugin DLL, ICU data, assets и AOT library.
Нельзя распространять один `.exe` без соседних runtime-файлов.

ZIP не содержит repository sources, tests, локальную database, `device_id`,
Backup/Export files, `.obsidian`, Ollama, model weights, credentials или
developer configuration.

## Clean-directory smoke

1. Распакуйте ZIP в новый пустой каталог вне repository.
2. Убедитесь, что рядом с `LifeOS.exe` находятся DLL и каталог `data`.
3. Запустите `LifeOS.exe`; source checkout и Flutter SDK не должны требоваться.
4. Без Ollama приложение должно запуститься, а Settings → Local AI должно
   показать недоступный runtime без влияния на Workspaces, Tasks, Notes,
   Relationships, Search или Backup.
5. Закройте приложение штатно и удалите только временный распакованный каталог.

## Clean-profile smoke для STAB-04

Не удаляйте и не переименовывайте реальный application-support profile.
Безопасный RC smoke выполняется из отдельной временной Windows user account
или Windows Sandbox/VM:

1. распаковать проверенный ZIP;
2. пройти checklist из `docs/dogfooding-rc-checklist.md`;
3. закрыть и повторно открыть LifeOS, проверив сохранённые данные;
4. удалить только временный account/sandbox после сохранения evidence.

Portable ZIP переносит приложение, но не делает пользовательские данные
portable. Перед обновлением рекомендуется создать Backup в Settings.
Downgrade на приложение с более старой SQLite schema не поддерживается.

## Подпись и предупреждения Windows

LifeOS 1.0 package не содержит installer и не подписывается. Unsigned private
build может вызвать Windows reputation/security warning. MSI, MSIX, Inno Setup,
NSIS, winget, code signing и auto-update остаются отдельным будущим scope.
