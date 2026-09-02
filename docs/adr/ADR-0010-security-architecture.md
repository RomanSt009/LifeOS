# ADR-0010: Security Architecture LifeOS


**Статус:** Предварительно принято  
**Дата:** 2026-08-16  
**Версия:** 0.1


## 1. Контекст


LifeOS является персональной системой управления информацией пользователя.


В системе потенциально будут храниться:


- задачи;
- заметки;
- цели;
- проекты;
- события;
- связи между сущностями;
- файлы;
- пользовательские настройки;
- AI-generated данные;
- AI context;
- semantic embeddings;
- история изменений;
- данные синхронизации.


Часть этих данных может иметь высокую степень приватности.


Поэтому безопасность должна быть заложена в архитектуру LifeOS с самого начала, а не добавлена после реализации MVP.


Основные требования:


- защита пользовательских данных;
- безопасная синхронизация;
- безопасная работа AI;
- изоляция устройств;
- контроль доступа;
- безопасное хранение секретов;
- возможность восстановления;
- минимизация собираемых данных;
- возможность дальнейшего внедрения End-to-End Encryption;
- возможность Self-hosted инфраструктуры;
- отсутствие зависимости безопасности от конкретного AI Provider.


---


# 2. Основное решение


LifeOS использует архитектурный принцип:


**Security by Design**


Безопасность должна рассматриваться как свойство всей системы:


```text
                    LifeOS
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
      Local           Sync            AI
       Data          Layer           Layer
        │              │              │
        └──────────────┼──────────────┘
                       ↓
                   Security
```
```

3. Основной принцип приватности

LifeOS должен придерживаться принципа:

Пользовательские данные принадлежат пользователю.

Архитектура не должна предполагать, что LifeOS имеет право использовать пользовательские данные для любых вторичных целей.

4. Data Minimization

Система должна собирать и передавать только те данные, которые необходимы для выполнения конкретной функции.

Например:

Feature
   ↓
Required Data
   ↓
Process
   ↓
Discard unnecessary data

Не следует отправлять AI Provider или Sync Backend данные, которые не нужны для конкретной операции.

---

# 5. Local-first Security

В соответствии с ADR-0009 LifeOS использует Local-first архитектуру.

Основная рабочая копия пользовательских данных находится на устройстве:

Application
     ↓
Local Database

Облако не должно быть обязательным условием для обычной работы с локальными данными.

6. Security Boundaries

Основные границы безопасности:

┌───────────────────────────────┐
│           Device              │
│                               │
│  UI                           │
│   ↓                           │
│  Application                  │
│   ↓                           │
│  Domain                       │
│   ↓                           │
│  Local Database               │
│                               │
└───────────────┬───────────────┘
                │
             Network
                │
                ↓
        ┌───────────────┐
        │ Sync Backend  │
        └───────┬───────┘
                │
                ↓
        External Services

Каждая граница должна рассматриваться как потенциально недоверенная.

7. Zero Trust Principle

Компоненты системы не должны автоматически доверять друг другу.

Например:

Client
   ↓
Server

не означает:

Server trusts client

и:

AI Provider

не получает автоматический доступ ко всем данным пользователя.

Каждый доступ должен быть:

явно разрешён;
ограничен;
проверен.
8. Authentication

Authentication отвечает на вопрос:

Кто этот пользователь?

Концептуально:

User
 ↓
Authentication
 ↓
Identity

Конкретный механизм authentication будет выбран отдельно.

Возможные варианты в будущем:

email/password;
OAuth;
passkeys;
platform authentication;
комбинация нескольких методов.
9. Authorization

Authorization отвечает на другой вопрос:

Что этому пользователю разрешено делать?

Например:

Authenticated User
       ↓
Authorization
       ↓
Read / Write / Delete

Authentication и Authorization не должны смешиваться.

10. Device Identity

Каждый экземпляр LifeOS должен иметь уникальный:

device_id

Это согласуется с ADR-0009.

Пример:

User
 ├── Desktop
 │    └── device_id
 │
 ├── Laptop
 │    └── device_id
 │
 └── Mobile
      └── device_id
11. Device Revocation

Пользователь должен иметь возможность отозвать доступ устройства.

Например:

Lost Phone
     ↓
Revoke Device
     ↓
Device no longer authorized

После отзыва устройство не должно получать новые данные через Sync Backend.

12. Session Management

Сессии должны иметь:

ограниченный срок жизни;
возможность обновления;
возможность отзыва;
безопасное хранение credentials.

Конкретная реализация будет определена при выборе authentication provider.

13. Secrets

Секреты не должны храниться:

в исходном коде;
в Git;
в конфигурационных файлах репозитория;
в логах;
в пользовательском интерфейсе.

Никогда не допускается:

API_KEY = "real-secret"

в исходном коде.

14. Secret Storage

На Desktop и Mobile необходимо использовать системные механизмы безопасного хранения секретов.

Концептуально:

LifeOS
   ↓
Platform Secure Storage
   ↓
OS protected secrets

Конкретная библиотека будет определена при реализации Flutter-стека.

15. Environment Separation

Должны существовать отдельные окружения:

Development
Testing
Staging
Production

Секреты и credentials одного окружения не должны использоваться в другом.

16. Production Secrets

Production secrets никогда не должны находиться в Git repository.

GitHub repository может содержать:

configuration templates

но не реальные секреты.

17. Encryption in Transit

Все сетевые соединения должны использовать защищённый транспорт.

Концептуально:

LifeOS
   ↓
Encrypted Connection
   ↓
Sync Backend

Незашифрованная передача пользовательских данных по сети не допускается.

18. Encryption at Rest

Необходимо предусмотреть защиту данных:

Local Device
   ↓
Local Database

и:

Server
   ↓
Stored Data

Конкретная реализация зависит от выбранных database и platform security mechanisms.

19. Database Security

Прямой доступ UI к базе данных не допускается.

Предпочтительная архитектура:

UI
 ↓
Application
 ↓
Repository
 ↓
Database

Это позволяет централизовать:

validation;
authorization;
transactions;
logging;
security rules.

```
---

# 20. Repository Boundary

Repository layer должен выступать границей между бизнес-логикой и хранилищем.

Например:

Domain
   ↓
Repository Interface
   ↓
Local Repository
   ↓
Database

В будущем возможно:

Domain
   ↓
Repository Interface
   ↓
Sync Repository
- - -
# 21. Input Validation

Все внешние входные данные должны проходить validation.

Источниками потенциально недоверенных данных являются:

пользовательский ввод;
Sync Backend;
AI Provider;
импортированные файлы;
внешние API;
Web;
deep links;
plugins/extensions в будущем.
- - -
# 22. Never Trust External Data

Основной принцип:

Любые данные, пришедшие извне, считаются недоверенными до прохождения проверки.

Например:

AI Output
    ↓
Validation
    ↓
Domain Rules
    ↓
Database

а не:

AI Output
    ↓
Database

---

# 23. AI Security Boundary

AI является отдельной security boundary.

AI не должен автоматически получать полный доступ к данным LifeOS.

Нежелательная архитектура:

AI
 ↓
Full Database Access

Предпочтительная:

User Request
     ↓
AI Context Layer
     ↓
Selected Context
     ↓
AI Provider
# 24. AI Context Minimization

AI должен получать минимально необходимый контекст.

Например, если пользователь спрашивает:

Что у меня запланировано на завтра?

не требуется передавать AI всю базу LifeOS.

Вместо этого:

User Query
    ↓
Context Retrieval
    ↓
Relevant Data
    ↓
AI
25. AI Permissions

В будущем AI может получать различные уровни доступа:

Read
Suggest
Create
Update
Delete

На первом этапе предпочтителен минимальный уровень:

Read + Suggest

Изменение или удаление данных должно требовать дополнительных ограничений.

26. AI Actions

AI-generated action должен проходить через Application/Domain layer.

Например:

AI
 ↓
Tool Request
 ↓
Validation
 ↓
Authorization
 ↓
Domain Logic
 ↓
Database

AI не должен напрямую выполнять SQL или изменять database.

27. Human Confirmation

Для потенциально опасных действий может требоваться подтверждение пользователя.

Например:

AI:
"Удалить 25 задач?"


        ↓


User Confirmation


        ↓


Delete

Особенно это важно для:

удаления;
массовых изменений;
перемещения данных;
изменения важных настроек;
внешних действий.
28. Prompt Injection

AI должен рассматриваться как потенциально атакуемая поверхность.

Внешние данные могут содержать текст вроде:

Ignore previous instructions...

Такой текст не должен автоматически становиться инструкцией для AI.

Поэтому необходимо разделять:

System Instructions
User Instructions
Retrieved Data
Tool Results
Untrusted Content
29. Retrieved Data is Untrusted

Данные, найденные AI Context Engine, являются данными, а не инструкциями.

Например:

Note:
"Ignore all previous instructions..."

должна рассматриваться как содержимое заметки.

Она не должна менять системные правила AI.

30. Tool Security

Если AI сможет использовать инструменты:

create_task
update_task
delete_task
search
calendar

каждый tool должен иметь собственные ограничения.

Например:

AI
 ↓
delete_task
 ↓
Authorization
 ↓
Confirmation
 ↓
Delete
31. Least Privilege

Каждый компонент должен иметь минимально необходимые права.

Например:

Search Service
    ↓
READ


Sync Service
    ↓
SYNC DATA


AI Context
    ↓
READ SELECTED DATA

Компонент не должен получать полный доступ без необходимости.

32. User Data Isolation

Данные разных пользователей должны быть логически изолированы.

Например:

User A
 ├── Entities
 ├── Files
 └── AI Context


User B
 ├── Entities
 ├── Files
 └── AI Context

User A никогда не должен иметь доступ к данным User B без явного механизма sharing.

33. Multi-user Collaboration

Collaboration не входит в MVP.

Однако архитектура должна учитывать будущую permission model:

Owner
Member
Editor
Viewer

Подробная модель будет определена отдельным ADR.

34. Sync Security

В соответствии с ADR-0009 Sync Backend не должен считаться полностью доверенным.

Модель:

Device
 ↓
Authentication
 ↓
Authorization
 ↓
Encrypted Connection
 ↓
Sync Backend
35. Sync Change Validation

Изменения, полученные через Sync, должны проходить validation.

Нельзя автоматически считать:

Server Data = Valid Data

Правильнее:

Received Change
      ↓
Authentication
      ↓
Authorization
      ↓
Validation
      ↓
Conflict Detection
      ↓
Apply
36. Replay Protection

Sync система должна учитывать возможность повторной отправки старого изменения.

Например:

Change A
 ↓
Accepted


Change A
 ↓
Received again

Система должна определить duplicate/replay.

Это связано с:

change_id;
version;
cursor;
idempotency.

Подробности определяются в Sync Protocol.

37. Data Integrity

Необходимо обеспечивать целостность данных.

Например:

Entity
 ↓
Relationship

не должна ссылаться на несуществующую сущность.

Domain layer должен контролировать такие ограничения.

38. Files

Файлы требуют отдельной защиты.

Необходимо учитывать:

размер;
тип;
имя;
содержимое;
hash;
источник;
права доступа.

Файл нельзя считать безопасным только потому, что он находится в пользовательской базе.

39. File Upload

Перед обработкой файла:

File
 ↓
Validation
 ↓
Type check
 ↓
Size check
 ↓
Security checks
 ↓
Storage
40. File Downloads

Доступ к файлу должен проверяться так же, как доступ к Entity.

Наличие URL или file ID не должно автоматически означать право доступа.

41. Import

Импортированные данные должны считаться недоверенными.

Например:

JSON
Markdown
CSV
Database

проходят:

Import
 ↓
Parse
 ↓
Validate
 ↓
Normalize
 ↓
Domain
42. Export

Экспорт является потенциально чувствительной операцией.

Пользователь должен понимать:

What data
Where
Format

будет экспортировано.

43. Backup Security

Backup должен рассматриваться отдельно от Sync.

Sync
 = synchronize


Backup
 = recover

Backup должен иметь собственную модель защиты.

44. Recovery

В будущем пользователь должен иметь возможность восстановить данные.

Например:

Backup
 ↓
Restore
 ↓
Validation
 ↓
Local Database
45. Deletion

Удаление пользовательских данных должно быть предсказуемым.

Необходимо различать:

Archive
Soft Delete
Delete
Permanent Delete

Это особенно важно в Local-first + Sync архитектуре.

46. Secure Deletion

Полное физическое уничтожение данных является отдельной задачей.

Нельзя автоматически утверждать, что:

DELETE FROM database

гарантирует физическое уничтожение всех копий данных.

Это зависит от:

database;
filesystem;
backups;
sync replicas;
caches.
47. Logging

Логи не должны содержать чувствительные пользовательские данные без необходимости.

Плохо:

User note:
"My password is..."

в логах.

Лучше:

Entity update failed
entity_id=...
48. Error Messages

Ошибки для пользователя должны быть понятными, но не раскрывать внутренние секреты.

Плохо:

Database connection:
postgres://user:password@server

Лучше:

Не удалось сохранить данные.
Изменения сохранены локально.
49. Audit

Для критически важных операций в будущем может использоваться audit trail.

Например:

Who
What
When
Device
Result

Но audit не должен автоматически сохранять полный пользовательский контент.

50. Security Events

Потенциально важные события:

Login
Logout
Failed login
New device
Device revoked
Password/passkey change
Security setting change
Large export
Account deletion
51. Rate Limiting

Сетевые API должны защищаться от злоупотребления.

Особенно:

authentication;
password recovery;
Sync;
AI API;
file upload;
export.
52. Abuse Protection

LifeOS должен учитывать возможность:

brute force;
automated requests;
oversized payloads;
malicious files;
API abuse;
prompt injection;
excessive AI requests.
53. Dependency Security

Внешние библиотеки должны регулярно проверяться на известные уязвимости.

Это относится к:

Flutter packages
Dart packages
Backend dependencies
Infrastructure dependencies
54. Dependency Minimization

Не следует добавлять библиотеку только ради одной маленькой функции без необходимости.

Меньше зависимостей:

↓
меньше attack surface

Это согласуется с ранее выбранным принципом:

Добавлять библиотеки по факту необходимости.

55. Supply Chain Security

Необходимо учитывать безопасность:

Developer
 ↓
Package
 ↓
Dependency
 ↓
Application

В будущем проект должен использовать:

lock files;
dependency auditing;
обновление зависимостей;
проверку источников packages.
56. Git Security

Git repository не должен содержать:

API keys;
passwords;
tokens;
private certificates;
production credentials;
personal secrets.

Перед commit необходимо проверять изменения.

57. CI Security

CI/CD в будущем должен использовать:

secret management;
least privilege;
ограниченные permissions;
dependency scanning;
automated tests.
58. Branch Protection

Production code не должен изменяться без контроля.

В будущем GitHub repository может использовать:

protected main branch;
pull requests;
required checks;
review;
status checks.
59. Security Testing

Необходимо тестировать:

Authentication
Authorization
Sync
AI
Database
Files
Import
Export
API
60. Threat Modeling

Перед реализацией критических компонентов необходимо проводить threat modeling.

Основные вопросы:

What are we protecting?
Who could attack?
What can they access?
What happens if component is compromised?
How can attack be detected?
How can system recover?
61. Основные угрозы

Для LifeOS рассматриваются:

1. Потеря устройства
Lost device
2. Компрометация аккаунта
Account takeover
3. Компрометация Sync Backend
Server compromise
4. Утечка AI context
Sensitive data → AI Provider
5. Prompt Injection
Untrusted data → AI
6. Malicious file
File → Application
7. Compromised dependency
Package → LifeOS
8. Data corruption
Database corruption
9. Accidental deletion
User → Delete
10. Malicious user input
Input → Application
11. Security Levels

Для архитектуры можно использовать уровни:

L0 — Public
L1 — Internal
L2 — Private
L3 — Highly Sensitive

Большинство пользовательских данных LifeOS:

L2 — Private

Некоторые данные потенциально:

L3 — Highly Sensitive
63. Data Classification

В будущем каждая категория данных может иметь security classification.

Например:

Task
    → Private


Note
    → Private


Password
    → Highly Sensitive


AI Context
    → Private / Highly Sensitive


System Settings
    → Internal

Конкретная классификация будет уточняться при проектировании модели данных.

64. AI Provider Trust Levels

AI Providers могут иметь разные уровни доверия.

Например:

Local AI
    ↓
Highest privacy


Trusted API
    ↓
External processing


Unknown Provider
    ↓
Not allowed

Но конкретная policy будет определена в AI Security Architecture.

65. Local AI

Local AI потенциально позволяет:

User Data
 ↓
Local Model
 ↓
No external transmission

Преимущества:

высокая приватность;
offline AI;
отсутствие передачи context третьей стороне.

Недостатки:

требования к hardware;
размер моделей;
производительность;
сложность установки;
расход ресурсов.
66. Cloud AI

Cloud AI:

LifeOS
 ↓
Selected Context
 ↓
AI Provider

может дать:

более сильные модели;
меньше требований к hardware;
более простое обновление моделей.

Но требует:

контроля передачи данных;
privacy policy;
provider trust;
защиты API credentials.
67. Hybrid AI

В будущем возможна архитектура:

                    AI Router
                       │
          ┌────────────┴────────────┐
          ↓                         ↓
      Local Model               Cloud Model
          │                         │
       Private                  Powerful

AI Provider должен быть заменяемым.

68. AI Data Policy

Перед отправкой данных внешнему AI Provider система должна определить:

What data?
Why?
Where?
For how long?
69. Consent

Для некоторых функций может потребоваться явное согласие пользователя.

Например:

"Разрешить отправлять содержимое заметок
внешнему AI Provider?"
70. Encryption Keys

Архитектура должна предусматривать возможность использования encryption keys.

Концептуально:

User
 ↓
Key Management
 ↓
Encrypted Data

Конкретная модель ключей пока не фиксируется.

71. Key Management

Ключи могут зависеть от:

устройства;
пользователя;
аккаунта;
recovery mechanism.

Это будет отдельной технической задачей.

72. Recovery vs Security

Безопасность и восстановление находятся в компромиссе.

Например:

Maximum Security
       ↕
Easy Recovery

Если ключ полностью неизвестен системе и пользователь его потерял, восстановление данных может быть невозможно.

Поэтому recovery architecture должна проектироваться отдельно.

73. Passwordless Future

Архитектура не должна требовать обязательного использования password authentication.

В будущем могут использоваться:

Passkeys
Biometrics
Hardware-backed credentials
74. Biometrics

Биометрия не должна автоматически означать, что LifeOS получает биометрические данные.

Предпочтительная модель:

LifeOS
 ↓
OS Authentication
 ↓
Biometric verification by OS

LifeOS получает результат проверки, а не сырые биометрические данные.

75. Platform Security

Flutter предоставляет общий UI/API слой, но безопасность платформы должна учитывать особенности:

Windows
macOS
Linux
Android
iOS
Web

Платформозависимые security mechanisms должны быть изолированы.

76. Security Abstraction

В архитектуре может использоваться:

SecurityService

с platform-specific implementation.

Например:

SecurityService
       │
 ┌─────┼──────────┐
 ↓     ↓          ↓
Windows Mobile    macOS

Конкретная реализация будет определена позже.

77. Web Security

Web имеет дополнительные риски:

XSS;
CSRF;
browser storage;
session theft;
malicious extensions;
browser limitations.

Web не является первичной платформой MVP, но архитектура должна учитывать эти ограничения.

78. Mobile Security

Mobile требует учитывать:

app sandbox;
secure storage;
OS permissions;
backup policies;
background execution;
device compromise.
79. Desktop Security

Desktop требует учитывать:

filesystem permissions;
local database protection;
OS user accounts;
malware;
backups;
multiple OS users.
80. Compromised Device

Нельзя гарантировать абсолютную защиту данных на полностью скомпрометированном устройстве.

Если злоумышленник имеет полный контроль над OS:

OS compromised
    ↓
Application security weakened

Поэтому LifeOS должен защищаться от реалистичных угроз, но не обещать невозможного.

81. Security vs Usability

Безопасность не должна превращать LifeOS в неудобное приложение.

Необходимо искать баланс:

Security
    ↕
Usability

Например, пользователь не должен вводить пароль перед каждой операцией.

82. Secure Defaults

Настройки по умолчанию должны быть безопасными.

Например:

HTTPS;
минимальные permissions;
отсутствие публичных данных;
безопасное хранение credentials;
отключённый опасный AI tool access.
83. Fail Secure

При невозможности проверить безопасность система должна выбирать безопасное поведение.

Например:

Authorization check failed
       ↓
DENY

а не:

Authorization check failed
       ↓
ALLOW
84. Security and Offline Mode

Offline режим не должен означать:

Security disabled

Локальные security policies продолжают действовать без сети.

85. Sync Security During Offline

Offline изменения:

Local Change
 ↓
Local Sync Queue

должны храниться безопасно до момента синхронизации.

86. Security and C+ Lifecycle

Lifecycle сущностей должен учитываться в security model.

Например:

Active
Completed
Archived
Deleted

Удалённая сущность не должна неожиданно становиться снова доступной из-за некорректной синхронизации.

87. Security and Relationships

Связи между сущностями также являются пользовательскими данными.

Например:

Person
 ↓
Project
 ↓
Task

Даже если сами сущности доступны, relationships могут раскрывать чувствительную информацию.

Поэтому permission model должна учитывать не только entities, но и relationships.

88. Security and Search

Search index может содержать копии пользовательских данных.

Поэтому:

Database
Search Index
Cache

должны рассматриваться как потенциальные места хранения чувствительной информации.

89. Security and Embeddings

Embeddings могут содержать информацию, позволяющую косвенно извлекать свойства пользовательских данных.

Поэтому embeddings не следует автоматически считать:

non-sensitive

Они должны иметь соответствующую security policy.

90. Security and Cache

Кэш может содержать пользовательские данные.

Необходимо избегать бессрочного хранения чувствительного контента в cache.

91. Clipboard

Копирование чувствительных данных в clipboard может привести к утечке.

Для некоторых категорий данных в будущем могут использоваться специальные ограничения.

92. Screenshots

Некоторые платформы позволяют ограничивать screenshots или screen capture.

Это может быть актуально для:

highly sensitive data;
credentials;
security screens.

Но это будет отдельной platform-specific функцией.

93. Notifications

Notifications могут раскрывать пользовательские данные.

Плохо:

"Завтра встреча с Иваном по проекту X"

если пользователь не ожидает отображения этих данных на lock screen.

Поэтому notification privacy должна учитываться отдельно.

94. Telemetry

Telemetry должна быть минимальной.

Не следует отправлять:

User Notes
Task Content
AI Context
Private Relationships

для обычной диагностики.

95. Analytics

Если analytics появится, она должна быть:

минимальной;
privacy-aware;
желательно opt-in для чувствительных функций;
отделённой от пользовательского контента.
96. Crash Reports

Crash reporting может потенциально содержать пользовательские данные.

Поэтому:

Crash Report
 ↓
Sanitize
 ↓
Send

Перед отправкой необходимо удалять чувствительные данные, насколько это возможно.

97. Third-party Services

Каждый внешний сервис должен рассматриваться как отдельная trust boundary.

Например:

LifeOS
 ├── AI Provider
 ├── Sync Provider
 ├── Analytics
 └── Crash Reporting

Для каждого необходимо определить:

какие данные передаются;
зачем;
где обрабатываются;
как долго хранятся.
98. Vendor Lock-in

Security Architecture не должна жёстко зависеть от одного внешнего провайдера.

Например:

AIProvider
SyncProvider
AuthProvider

должны иметь абстракции на уровне архитектуры там, где это оправдано.

99. Security Documentation

Security-sensitive решения должны фиксироваться через ADR.

Примеры будущих документов:

ADR-0010
Security Architecture


ADR-0016
Sync Protocol


ADR-00XX
Authentication


ADR-00XX
Encryption / Key Management


ADR-00XX
AI Security
100. Security Testing Strategy

Перед production необходимо иметь:

Unit Tests
Integration Tests
Security Tests
Dependency Scanning
Static Analysis
Penetration Testing

Конкретный набор будет зависеть от стадии проекта.

101. Incident Response

В будущем необходимо определить процедуру:

Incident
 ↓
Detection
 ↓
Containment
 ↓
Investigation
 ↓
Recovery
 ↓
User Notification
 ↓
Prevention
102. Security Updates

Критические security updates должны иметь приоритет над обычными feature updates.

103. Security Architecture Principles

Для LifeOS принимаются следующие принципы:

Security by Design.
Privacy by Design.
Least Privilege.
Zero Trust между компонентами.
Never Trust External Data.
Secure by Default.
Fail Secure.
Data Minimization.
Local-first.
AI является отдельной security boundary.
AI не получает полный доступ к базе автоматически.
AI actions проходят через Domain/Application layer.
Внешние AI Providers получают только необходимый context.
Sync Backend не считается полностью доверенным.
Все сетевые соединения должны быть защищены.
Secrets не хранятся в Git.
Credentials хранятся через защищённые механизмы платформы.
Пользовательские данные разных аккаунтов изолированы.
Device identity является частью security model.
Пользователь может отозвать устройство.
Sync failure не должен приводить к потере локальных данных.
Backup и Sync являются разными системами.
Search и embeddings считаются потенциально чувствительными данными.
Logs не должны содержать пользовательский контент без необходимости.
Third-party services являются отдельными trust boundaries.
Конкретные encryption algorithms будут определены отдельно.
Authentication provider будет выбран отдельно.
AI provider не фиксируется данным ADR.
Security должна учитывать Desktop, Mobile и Web.
Архитектура должна позволять будущий E2EE.
Архитектура должна позволять Self-hosted deployment.
Безопасность не должна необоснованно ухудшать usability.
104. Что не фиксируется этим ADR

Данный документ не выбирает конкретно:

authentication provider;
OAuth provider;
database;
encryption algorithm;
key management system;
cloud provider;
AI provider;
Sync Backend;
E2EE protocol;
password manager;
biometric implementation.

Эти решения будут приниматься отдельными ADR.

105. Последствия решения
Положительные
безопасность закладывается с начала проекта;
уменьшается вероятность архитектурных переделок;
AI получает контролируемый доступ;
Sync не получает автоматического доверия;
появляется возможность Local-first;
сохраняется возможность будущего E2EE;
сохраняется возможность Self-hosted;
уменьшается количество лишних данных, передаваемых внешним сервисам.
Отрицательные
архитектура становится сложнее;
требуется больше тестирования;
потребуется отдельная работа с ключами;
потребуется продуманная authentication system;
AI integration становится сложнее;
Sync становится сложнее;
часть security features потребует platform-specific кода.
106. Следующие документы

После ADR-0010 предлагается перейти к:

ADR-0011:
Backup and Export Architecture

ADR-0012:
Search Architecture

ADR-0013:
AI Context Engine

ADR-0014:
AI Tool Calling and Permissions

ADR-0015:
Semantic Search and Embeddings

ADR-0016:
Sync Protocol

ADR-0017:
Authentication Architecture

ADR-0018:
Encryption and Key Management

Итог

Security Architecture LifeOS строится вокруг:

Privacy by Design
        +
Security by Design
        +
Least Privilege
        +
Zero Trust
        +
Local-first

Основная модель:

                     LIFEOS
                        │
          ┌─────────────┼─────────────┐
          ↓             ↓             ↓
       Local DB       Sync           AI
          │             │             │
          │             │             │
       Protected     Protected      Limited
          │             │             │
          └─────────────┼─────────────┘
                        ↓
                    Security

Главный принцип:

Ни один внешний компонент не должен автоматически получать полный доступ к данным пользователя. Каждый доступ должен быть необходимым, ограниченным и проверяемым.



### Важный момент


После `ADR-0010` у нас уже достаточно архитектурных ограничений, чтобы **не начинать кодирование наугад**.


Следующим логичным шагом я бы сделал **ADR-0011 — Backup and Export Architecture**. Он закроет очень важный вопрос: *«Что произойдёт с моими данными, если я удалю LifeOS, потеряю устройство или захочу полностью забрать свои данные из системы?»*


И только после этого уже имеет смысл переходить к архитектуре поиска и AI Context Engine.