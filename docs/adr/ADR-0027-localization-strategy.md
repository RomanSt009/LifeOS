# ADR-0027: Localization Strategy

Status: Accepted

## Context

LifeOS is intended to support multiple user interface languages.

The initial UI already contains user-visible English strings.

If localization is deferred until later, Presentation code may accumulate hardcoded strings that will require broad cleanup.

The project should therefore establish localization infrastructure before the UI surface grows significantly.

## Decision

### Initial supported locales

LifeOS initially supports:

- English — `en`
- Russian — `ru`

English is the fallback locale.

Additional locales may be added later without changing the overall localization architecture.

### Flutter localization mechanism

LifeOS uses Flutter's standard localization infrastructure based on:

- `flutter_localizations`
- `gen_l10n`
- ARB localization resources

Generated localization code must be treated as generated code and must not be edited manually.

No third-party localization framework is introduced for the initial implementation.

### Resource location

Localization resources live under:

`lib/l10n/`

Initial files:

- `app_en.arb`
- `app_ru.arb`

A project-level `l10n.yaml` may be used to configure Flutter localization generation.

### Presentation responsibility

All user-visible static UI strings must come from localization resources.

Presentation must not introduce new hardcoded user-facing strings when an appropriate localized resource can be used.

Internal identifiers, debug messages, log messages, test descriptions, database values, and Domain enum values are not automatically localized.

Domain, Application, and Infrastructure layers must not depend on Flutter localization APIs.

Localization remains a Presentation concern.

### Locale selection

Initial locale selection follows the operating system / Flutter platform locale when it matches a supported locale.

Supported locales are:

- English
- Russian

If the platform locale is unsupported, LifeOS falls back to English.

Manual in-app language selection is deferred unless explicitly added by a later checkpoint or ADR.

### Localization keys

Localization keys should describe semantic meaning rather than visual position.

Preferred:

- `taskListTitle`
- `taskListEmpty`
- `taskCreateAction`
- `taskCompletionToggle`

Avoid:

- `text1`
- `labelLeft`
- `button2`

Keys should remain stable when wording changes.

### Interpolation and pluralization

Dynamic user-visible text must use ARB placeholders.

Pluralizable content must use Flutter localization pluralization rather than manual string concatenation.

Do not build localized sentences by concatenating separately translated fragments.

### Tests

Presentation tests should not depend unnecessarily on one hardcoded language.

Where text itself is the behavior under test, tests may run with an explicit locale.

At minimum, localization tests should verify:

- English resources load;
- Russian resources load;
- supported locales are configured;
- fallback behavior does not break application startup.

### Scope

This ADR defines:

- localization architecture;
- initial supported languages;
- localization resource format;
- ownership boundaries;
- initial locale resolution.

It does not define:

- manual language settings UI;
- per-user language synchronization;
- translation management platform;
- AI translation;
- locale-specific date/time preferences;
- RTL-specific UI design.

These remain deferred.

## Consequences

User-facing Presentation strings become translatable from the beginning.

Russian and English resources can evolve independently.

Additional locales may be added later without changing the overall localization architecture.

