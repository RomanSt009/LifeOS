# UI/UX архитектура LifeOS

**Статус:** Черновик  
**Версия:** 0.1  
**Дата:** 2026-08-11

---

# 1. Назначение

Этот документ описывает принципы пользовательского интерфейса и пользовательского опыта LifeOS.

Цель UI/UX:

> Сделать сложную систему управления личной информацией максимально простой для человека.

LifeOS может содержать:

- задачи;
- проекты;
- заметки;
- людей;
- события;
- файлы;
- связи;
- AI-контекст;
- историю;
- синхронизацию.

Но пользователь не должен постоянно думать о внутренней архитектуре системы.

---

# 2. Главный UX-принцип

LifeOS должен скрывать сложность.

Пользователь должен думать:

```text
"Что мне нужно сделать?"
````

а не:

```
"В какой сущности это сохранить?"
```

Например:

Пользователь вводит:

> "В пятницу нужно обсудить с Иваном бюджет проекта."

LifeOS может самостоятельно определить:

```
Person
    ↓
Иван

Project
    ↓
Бюджет

Task
    ↓
Обсудить бюджет

Date
    ↓
Пятница
```

Пользователь может принять предложенную структуру или исправить её.

---

# 3. UX-модель

Основная модель взаимодействия:

```
Capture
   ↓
Understand
   ↓
Organize
   ↓
Connect
   ↓
Act
   ↓
Review
```

Пользователь:

1. быстро фиксирует информацию;
2. LifeOS помогает её понять;
3. система предлагает структуру;
4. создаются связи;
5. информация превращается в действия;
6. пользователь периодически пересматривает состояние системы.

---

# 4. Capture First

Первый принцип:

> Добавление информации должно быть максимально быстрым.

Пользователь не должен сначала выбирать:

```
Task?
Note?
Project?
Event?
Person?
```

Он может просто написать:

```
"Позвонить Ивану завтра насчёт проекта."
```

LifeOS затем предложит структуру.

---

# 5. Command / Capture Bar

Основной элемент интерфейса:

```
┌─────────────────────────────────────────────┐
│ Что нужно сделать?                          │
│                                             │
│ Позвонить Ивану завтра насчёт проекта...   │
└─────────────────────────────────────────────┘
```

Это является одной из центральных точек взаимодействия с LifeOS.

В будущем Capture Bar может поддерживать:

- текст;
- голос;
- drag & drop;
- файлы;
- изображения;
- clipboard;
- быстрые команды.

---

# 6. Main Workspace

Основной экран Desktop-версии:

```
┌────────────────────────────────────────────────────────────┐
│ LifeOS                                      Search   User   │
├──────────────┬─────────────────────────────────────────────┤
│              │                                             │
│ Home         │                                             │
│ Today        │              Main Workspace                 │
│ Tasks        │                                             │
│ Projects     │                                             │
│ Notes        │                                             │
│ People       │                                             │
│ Calendar     │                                             │
│              │                                             │
│ ───────────  │                                             │
│ AI           │                                             │
│              │                                             │
│ Settings     │                                             │
└──────────────┴─────────────────────────────────────────────┘
```

---

# 7. Navigation

Основная навигация должна быть простой.

Предварительно:

```
Home
Today
Tasks
Projects
Notes
People
Calendar
Search
AI
Settings
```

Количество пунктов может измениться после тестирования прототипа.

---

# 8. Home

Home является обзором состояния пользователя.

Он не должен превращаться в dashboard из десятков виджетов.

Предварительно:

```
Home

Good evening, Roman

Today
├── 3 important tasks
├── 1 event
└── 2 things waiting

Projects
├── LifeOS
└── Personal

AI Suggestions
└── ...
```

Информация должна быть приоритетной, а не просто многочисленной.

---

# 9. Today

Today показывает актуальный контекст текущего дня.

```
Today

Morning
├── Task
├── Event

Afternoon
├── Task

Evening
└── Task
```

AI может дополнительно предложить:

```
"На сегодня у тебя слишком много задач.
Предлагаю перенести 2 задачи."
```

Но решение остаётся за пользователем.

---

# 10. Tasks

Tasks должны отображаться в нескольких режимах:

```
List
Board
Calendar
Timeline
```

На MVP достаточно:

```
List
```

Остальные представления добавляются позже.

---

# 11. Task

Минимальная задача:

```
┌─────────────────────────────────────┐
│ □ Купить билеты                     │
│                                     │
│ Friday                              │
│ Project: Berlin Trip                │
│ Priority: High                      │
└─────────────────────────────────────┘
```

Дополнительная информация открывается только при необходимости.

---

# 12. Progressive Disclosure

Не нужно показывать пользователю все поля сразу.

Сначала:

```
Title
Status
Date
```

После раскрытия:

```
Priority
Project
People
Relationships
Notes
Attachments
AI Context
History
```

Это уменьшает когнитивную нагрузку.

---

# 13. Projects

Project является контейнером более высокого уровня.

Пример:

```
LifeOS
│
├── Tasks
├── Notes
├── People
├── Files
└── Events
```

Проект не должен быть просто папкой.

Он представляет контекст.

---

# 14. Entity View

Каждая сущность должна иметь единый принцип отображения.

Например:

```
┌─────────────────────────────────────────────┐
│ Project: LifeOS                             │
│                                             │
│ Status                                      │
│ Active                                      │
│                                             │
│ Tasks                                       │
│ ├── ...                                     │
│                                             │
│ Related                                     │
│ ├── People                                  │
│ ├── Notes                                   │
│ └── Files                                   │
│                                             │
│ AI                                          │
│ └── Ask about this                          │
└─────────────────────────────────────────────┘
```

---

# 15. Relationships

Связи должны быть видимыми, но не перегружать интерфейс.

Например:

```
Project
   │
   ├── Tasks
   ├── People
   ├── Notes
   └── Events
```

Пользователь может открыть раздел:

```
Relationships
```

и увидеть связанные сущности.

---

# 16. AI Suggested Relationships

AI может предлагать связи.

Например:

```
Possible relationship

"Купить билеты"
        ↓
related to
        ↓
"Поездка в Берлин"

[Accept] [Edit] [Ignore]
```

Пользователь может изменить предложение.

---

# 17. Graph View

В будущем возможен отдельный Graph View.

Пример:

```
                 Person
                    │
                    │
Note ─────── Project ───── Task
              │             │
              │             │
            Event       Dependency
```

Graph View не является основным способом работы.

Он используется для:

- исследования;
- поиска скрытых связей;
- анализа проекта;
- AI-assisted exploration.

---

# 18. Search

Search является одним из центральных инструментов LifeOS.

Он должен поддерживать:

```
Keyword Search
Semantic Search
Filters
Relationships
Date
Lifecycle
Entity Type
```

Пример:

```
Search:
"Берлин"
```

Результаты могут включать:

```
Projects
Tasks
Notes
People
Events
Files
```

---

# 19. Global Search

Search должен быть доступен из любого места.

Desktop:

```
Ctrl + K
```

предварительно используется как shortcut.

Мобильная версия получит собственный UX.

---

# 20. Search Results

Результаты должны показывать:

```
Title
Entity Type
Relevant Context
Date
Relationships
```

Например:

```
Berlin Trip
Project
3 related tasks
2 events
Last updated yesterday
```

---

# 21. Filters

Фильтры:

```
Type
Status
Date
Project
Person
Priority
Lifecycle
```

Фильтры должны быть легко сбрасываемыми.

---

# 22. AI Search

Пользователь может использовать естественный язык:

```
"Покажи всё, что связано с поездкой в Берлин."
```

LifeOS:

```
Search
    ↓
Context Engine
    ↓
Relevant Entities
```

AI не должен быть единственным механизмом поиска.

Обычный поиск должен работать независимо от AI.

---

# 23. AI Workspace

AI должен иметь отдельное пространство.

Предварительно:

```
┌─────────────────────────────────────────────┐
│ AI                                          │
├─────────────────────────────────────────────┤
│                                             │
│ Ask LifeOS                                  │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ Что мне сегодня важно сделать?          │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ Context                                     │
│ Today                                       │
│ LifeOS Project                              │
│                                             │
└─────────────────────────────────────────────┘
```

---

# 24. Context Indicator

Пользователь должен понимать, какой контекст используется AI.

Например:

```
AI Context

✓ Today
✓ LifeOS Project
✓ 5 related tasks
✓ 2 notes

12 entities included
```

Это повышает прозрачность системы.

---

# 25. AI Sources

Ответ AI должен по возможности показывать источники.

```
Based on:

Project: LifeOS
Task: Database architecture
Note: Architecture discussion
```

Пользователь может открыть источник.

---

# 26. AI Actions

Если AI предлагает изменение:

```
AI Suggestion

Move:
"Prepare documentation"

From:
Tuesday

To:
Thursday

[Apply] [Edit] [Cancel]
```

Изменение не применяется незаметно.

---

# 27. AI Confirmation

Для потенциально опасных действий используется подтверждение.

Например:

```
Delete 8 tasks?

[Cancel] [Delete]
```

AI не должен скрывать важные последствия действия.

---

# 28. Undo

Для обратимых действий желательно поддерживать:

```
Action completed.

[Undo]
```

Undo особенно важен для AI-assisted действий.

---

# 29. Notifications

Уведомления не должны становиться постоянным источником отвлечения.

Приоритет:

```
Critical
Important
Normal
Informational
```

Пользователь должен иметь возможность контролировать уведомления.

---

# 30. Empty States

Пустые экраны должны помогать пользователю.

Плохо:

```
No data.
```

Лучше:

```
У тебя пока нет проектов.

Создай первый проект
или просто напиши в Capture Bar, чем занимаешься.
```

---

# 31. Loading States

Loading должен быть понятным.

Для быстрых операций:

```
Loading...
```

Для долгих:

```
Индексируем заметки...
```

или:

```
Синхронизируем данные...
```

---

# 32. Error States

Ошибка должна объяснять:

1. что произошло;
2. повлияло ли это на данные;
3. что делать дальше.

Например:

```
Не удалось синхронизировать данные.

Локальные изменения сохранены.

[Повторить]
[Подробнее]
```

---

# 33. Offline Mode

Пользователь должен видеть состояние сети.

Например:

```
● Offline
```

Но приложение продолжает работать.

Главный принцип:

> Offline не должен выглядеть как поломка приложения.

---

# 34. Sync Status

Для синхронизации:

```
Synced
Syncing...
Changes pending
Conflict detected
Sync error
```

При конфликте пользователь должен иметь возможность его открыть.

---

# 35. Conflict UI

Пример:

```
Conflict detected

Due date

This device:
Tuesday

Other device:
Friday

[Keep Tuesday]
[Keep Friday]
[Edit manually]
```

Если AI предлагает решение:

```
AI suggestion:
Friday

Reason:
Event exists on Friday.
```

Пользователь всё равно принимает решение.

---

# 36. Desktop UX

Desktop должен использовать преимущества большого экрана:

```
Navigation
+
Main Workspace
+
Context Panel
```

Предварительно:

```
┌──────────┬─────────────────────────┬──────────────┐
│ Sidebar  │ Main                    │ Context      │
│          │                         │              │
│          │                         │              │
└──────────┴─────────────────────────┴──────────────┘
```

Context Panel может показывать:

- relationships;
- details;
- AI;
- history.

---

# 37. Tablet UX

Tablet может использовать:

```
Sidebar
+
Main Content
```

Context Panel открывается отдельно.

---

# 38. Mobile UX

Mobile использует другой принцип:

```
┌─────────────────────┐
│ Header              │
├─────────────────────┤
│                     │
│ Main Content        │
│                     │
│                     │
├─────────────────────┤
│ Home Tasks AI More  │
└─────────────────────┘
```

Desktop layout не должен просто уменьшаться.

---

# 39. Responsive Architecture

Flutter UI должен использовать адаптивные layout patterns.

Логика:

```
Screen Width
     ↓
Layout Strategy
     ↓
Desktop / Tablet / Mobile
```

Business Logic при этом остаётся общей.

---

# 40. Keyboard First

Desktop версия должна поддерживать клавиатуру.

Предварительные shortcuts:

```
Ctrl + K
Search

Ctrl + N
New

Ctrl + Shift + A
AI

Esc
Close

Enter
Confirm
```

Полный список shortcuts будет отдельным документом.

---

# 41. Mouse and Touch

UI должен поддерживать:

```
Mouse
Keyboard
Touch
Trackpad
```

Mobile:

```
Touch
Swipe
Long Press
```

---

# 42. Drag & Drop

Desktop должен поддерживать Drag & Drop там, где это естественно.

Например:

```
File
 ↓
Project
```

или:

```
Task
 ↓
Project
```

Drag & Drop не должен быть единственным способом выполнения действия.

---

# 43. Visual Hierarchy

UI должен иметь чёткую визуальную иерархию.

Приоритет:

```
Primary
Secondary
Metadata
Actions
```

Необходимо избегать:

- чрезмерного количества цветов;
- множества карточек;
- постоянных badges;
- визуального шума.

---

# 44. Design Language

LifeOS должен иметь собственную дизайн-систему.

Она будет определять:

```
Typography
Colors
Spacing
Radius
Elevation
Icons
Buttons
Inputs
Cards
Dialogs
Navigation
```

---

# 45. Design Tokens

Основные параметры должны быть централизованы.

Например:

```
Spacing
Typography
Colors
Radius
Elevation
Motion
```

Это позволит изменить внешний вид приложения без переписывания каждого экрана.

---

# 46. Dark Mode

LifeOS должен поддерживать:

```
Light
Dark
System
```

Dark Mode не должен быть просто инверсией цветов.

Он должен иметь собственную систему контраста.

---

# 47. Accessibility

UI должен учитывать:

- размер текста;
- контраст;
- keyboard navigation;
- screen readers;
- focus states;
- touch target size;
- reduced motion.

Accessibility рассматривается как часть архитектуры, а не как финальная доработка.

---

# 48. Motion

Анимации должны помогать пониманию интерфейса.

Использовать:

```
Transition
Feedback
State Change
Navigation
```

Не использовать анимацию только ради визуального эффекта.

---

# 49. Performance UX

UI должен оставаться отзывчивым.

Цель:

> Пользователь не должен чувствовать работу SQLite, Sync или AI.

Тяжёлые операции:

```
Database
Search Index
Embeddings
AI
Sync
File Processing
```

не должны блокировать основной UI thread.

---

# 50. Information Density

LifeOS потенциально работает с большим количеством данных.

Поэтому необходимо поддерживать несколько уровней плотности интерфейса:

```
Comfortable
Compact
Dense
```

Desktop может использовать более высокую плотность.

Mobile — более свободную.

---

# 51. Personalization

В будущем пользователь может настраивать:

```
Dashboard
Navigation
Density
Theme
Shortcuts
Notifications
AI behavior
```

Однако MVP не должен перегружаться настройками.

---

# 52. User Control

Автоматизация не должна лишать пользователя контроля.

Особенно это относится к AI.

Основной принцип:

```
AI suggests
User decides
LifeOS executes
```

---

# 53. Trust

Пользователь должен понимать:

```
Что произошло?
Почему это произошло?
Что сделал AI?
Какие данные использовались?
Можно ли отменить действие?
```

Это особенно важно для AI-powered функций.

---

# 54. Onboarding

Первый запуск не должен быть длинным tutorial.

Предварительный сценарий:

```
Welcome
   ↓
Create first item
   ↓
Explore Today
   ↓
Optional AI setup
```

Пользователь должен начать пользоваться системой максимально быстро.

---

# 55. Progressive Onboarding

Новые возможности показываются постепенно.

Например:

Первый день:

```
Tasks
Notes
Projects
```

Позже:

```
Relationships
AI
Semantic Search
Sync
```

Пользователь не должен изучать всю систему сразу.

---

# 56. First Run

После первого запуска:

```
┌──────────────────────────────────────┐
│ Welcome to LifeOS                    │
│                                      │
│ Просто напиши, что у тебя сейчас     │
│ в голове.                            │
│                                      │
│ [ Что нужно сделать? ]               │
│                                      │
└──────────────────────────────────────┘
```

Это демонстрирует главную идею продукта.

---

# 57. Core User Flow

Основной сценарий:

```
Capture
   ↓
AI Understanding
   ↓
Suggested Structure
   ↓
User Confirmation
   ↓
Entity Creation
   ↓
Relationships
   ↓
Task / Project
   ↓
Review
```

---

# 58. Example

Пользователь вводит:

```
"В пятницу встретиться с Иваном по поводу бюджета LifeOS."
```

LifeOS предлагает:

```
Event:
Встреча с Иваном

Person:
Иван

Project:
LifeOS

Topic:
Бюджет

Date:
Friday
```

Пользователь:

```
[Accept]
```

Создаются сущности и связи.

---

# 59. Correction Flow

Пользователь может исправить:

```
Project:
LifeOS
```

на:

```
Project:
Personal Finance
```

После изменения:

```
User Correction
      ↓
Relationship Updated
      ↓
AI Feedback
```

---

# 60. UX Architecture Summary

Основная модель:

```
                 USER
                   │
                   ↓
                CAPTURE
                   │
                   ↓
              LIFEOS CORE
                   │
         ┌─────────┴─────────┐
         ↓                   ↓
       Search              AI
         │                   │
         └─────────┬─────────┘
                   ↓
              CONTEXT
                   ↓
             SUGGESTION
                   ↓
              USER CONTROL
                   ↓
                ACTION
```

---

# 61. Основные UX-принципы

1. LifeOS скрывает техническую сложность.
2. Пользователь может сначала просто вводить информацию.
3. Система предлагает структуру.
4. AI не должен заставлять пользователя изучать модель данных.
5. Пользователь всегда может исправить предложение AI.
6. AI Suggestions отделены от User Decisions.
7. Критические действия требуют подтверждения.
8. Search работает независимо от AI.
9. Context Engine работает независимо от UI.
10. Desktop и Mobile используют общий Application/Domain слой.
11. Desktop использует преимущества большого экрана.
12. Mobile имеет отдельную UX-композицию.
13. Интерфейс использует Progressive Disclosure.
14. Главный экран не должен превращаться в перегруженный dashboard.
15. Пользователь должен понимать состояние синхронизации.
16. Offline режим является нормальным состоянием.
17. Ошибки должны быть понятными и восстанавливаемыми.
18. AI должен показывать источники, когда это возможно.
19. Пользователь должен понимать, какие данные использует AI.
20. Undo предпочтителен для обратимых действий.
21. Accessibility является частью архитектуры.
22. Performance является частью UX.
23. Настройки не должны перегружать MVP.
24. Автоматизация не должна лишать пользователя контроля.
25. Основной принцип взаимодействия:

AI suggests → User decides → LifeOS executes.

---

# 62. MVP UI

Первая версия интерфейса должна содержать:

```
✓ Main Navigation
✓ Home
✓ Today
✓ Tasks
✓ Projects
✓ Notes
✓ Entity View
✓ Capture Bar
✓ Basic Search
✓ Basic Relationships
✓ Basic Settings
✓ Dark Mode
✓ Responsive Desktop Layout
```

Пока не требуется:

```
✕ Graph View
✕ Advanced AI Workspace
✕ Semantic Search
✕ Voice Input
✕ Advanced Calendar
✕ Agent Mode
✕ Complex Personalization
```

---

# 63. UI/UX Development Order

Разработка интерфейса:

```
1. Design Tokens
      ↓
2. App Shell
      ↓
3. Navigation
      ↓
4. Home
      ↓
5. Today
      ↓
6. Entity View
      ↓
7. Tasks
      ↓
8. Projects
      ↓
9. Notes
      ↓
10. Search
      ↓
11. Relationships
      ↓
12. AI Integration
```

---

# 64. Следующий этап

После завершения UI/UX архитектуры необходимо:

1. Провести UI/UX ревью.
2. Проверить архитектуру на соответствие Domain и AI.
3. Определить Design Tokens.
4. Определить компонентную систему.
5. Выбрать State Management.
6. Выбрать SQLite/Dart библиотеку.
7. Выбрать Dependency Injection.
8. Создать ADR по техническому стеку.
9. Создать Flutter prototype.
10. Реализовать App Shell.
11. Реализовать первый пользовательский сценарий Capture → Entity.

Следующий важный этап:

```
Technical Decisions
        ↓
ADRs
        ↓
Flutter Prototype
        ↓
Domain Model
        ↓
First Working Feature
```
