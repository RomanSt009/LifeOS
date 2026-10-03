# LifeOS 1.0 release / post-release dogfooding checklist

Используйте отдельный временный Windows profile, Windows Sandbox или VM и
распакованный portable ZIP. Не удаляйте существующие данные основного profile.

## Core smoke

- [ ] Fresh launch показывает Home без startup error.
- [ ] Создаётся Workspace.
- [ ] В Workspace создаются Task и Note.
- [ ] Task редактируется, завершается и снова открывается.
- [ ] Note сохраняется; dirty Note при выходе предлагает Save/Discard/Cancel.
- [ ] Task и Note связываются через `related`, затем link удаляется.
- [ ] Unified Search находит Task, Note и Workspace и открывает результат.
- [ ] Backup создаётся; Restore выполняется только после явного подтверждения.
- [ ] После restart данные сохраняются.
- [ ] English и Russian Presentation доступны через locale Windows.

## Local AI smoke

Без Ollama:

- [ ] LifeOS запускается и core features работают.
- [ ] Settings → Local AI показывает недоступный runtime после Refresh.

С локально установленными Ollama и `qwen2.5-coder:7b`:

- [ ] `ollama list` показывает точное имя модели.
- [ ] Refresh показывает ready state.
- [ ] На синтетическом Workspace выполняется один **Ask about this Workspace**.
- [ ] Ответ отображается; LifeOS не предлагает cloud fallback или API key.

STAB-04 завершён; live Ollama smoke остаётся ручной release/maintenance проверкой и не входит в
автоматизированный test suite.
