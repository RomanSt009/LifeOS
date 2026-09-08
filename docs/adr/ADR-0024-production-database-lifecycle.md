# ADR-0024: Production Database Location and Lifecycle

Status: Accepted

## Context

LifeOS uses SQLite through Drift as its local-first persistence layer.

The existing architecture defines the persistence technology, schema, repository boundaries, and atomic Domain State + Outbox behavior, but does not yet define the production database file location or lifecycle ownership.

The Windows application now requires a production database bootstrap so the real Task vertical slice can persist data across application restarts.

The application must not hardcode machine-specific filesystem paths.

The database lifecycle must remain isolated from Domain, Application, and Presentation layers.

## Decision

### Database location

The production SQLite database is stored in the operating system's application-support directory.

The database filename is:

`lifeos.db`

The final filesystem path is therefore:

`<platform application-support directory>/lifeos.db`

The application must obtain the application-support directory through an appropriate Flutter platform abstraction rather than through hardcoded operating-system paths.

For the initial Flutter implementation, a focused platform-path dependency such as `path_provider` may be used.

A path utility dependency may be used when required to construct the final database path safely.

### Ownership

The production database instance is created at the application composition boundary.

The composition root owns the database lifecycle.

Infrastructure repositories receive or otherwise use the owned database instance through composition.

Presentation and Application must not construct or import the concrete Drift database.

### Lifetime

The production application uses one logical database instance per application process unless a future accepted ADR defines otherwise.

The database remains open while the application requires persistence access.

The owning composition layer is responsible for closing the database when the application persistence lifecycle ends.

### Testing

Tests must not depend on the production filesystem path unless specifically testing production path behavior.

Persistence tests may continue to use in-memory or explicitly temporary databases where appropriate.

Lifecycle tests should verify that a file-backed database can be closed, reopened, and retain persisted data.

### Scope

This ADR decides only:

- production SQLite location;
- mechanism category for resolving the platform-safe path;
- database ownership;
- database lifecycle responsibility.

It does not define:

- backup location;
- export location;
- multiple database profiles;
- portable mode;
- user-selectable database paths;
- cloud storage;
- Sync transport;
- device identity lifecycle.

These remain deferred.

## Consequences

Production persistence can now be composed without hardcoded machine-specific paths.

Infrastructure remains responsible for SQLite/Drift concerns.

The composition root becomes the explicit owner of the database lifecycle.

A small Flutter platform-path dependency is allowed for production bootstrap.

Future backup/export decisions must not assume that the application-support directory is itself a backup mechanism.

## Precedence

This ADR supplements the accepted persistence and composition ADRs.

If earlier documentation leaves the production SQLite file location or lifecycle ownership unspecified, this ADR governs those decisions.