# ADR-0026: Entity Creation Identity, Clock, and Initial Metadata

Status: Accepted

## Context

LifeOS Entity creation requires mandatory metadata defined by the Domain Entity contract, including:

- stable typed identity;
- createdAt;
- updatedAt;
- lifecycle;
- version;
- creation source.

The initial Task vertical slice now requires a production creation path.

Existing ADRs define Entity metadata requirements but do not yet define:

- production Entity ID format and generation ownership;
- ownership and injection of the current UTC time;
- initial metadata values for a newly user-created Task.

ADR-0025 governs `change_id` and `device_id` only and must not be implicitly extended to Entity identity.

## Decision

### Entity ID

Every newly created LifeOS Entity receives a globally unique opaque identifier.

For the initial production implementation, Entity IDs use UUID version 4.

Entity ID generation belongs to the Application composition boundary through an injectable abstraction or function.

Domain entities receive the already-created typed `LifeOsEntityId`.

The Domain layer must not depend on UUID libraries or randomness.

The Infrastructure persistence layer must not invent Entity IDs during save.

Tests may inject deterministic Entity IDs.

### Clock

The current time used for Entity creation is supplied through an injectable UTC clock abstraction or function.

Application use cases coordinate acquisition of the current UTC timestamp for creation.

Domain entities receive explicit timestamps and must not call the system clock directly.

Production composition supplies the real UTC clock.

Tests may inject deterministic timestamps.

All persisted Entity timestamps are represented in UTC.

### Initial lifecycle

A newly user-created Task starts with:

`LifeOsEntityLifecycle.active`

A Task is not created directly in deleted, archived, or other non-active lifecycle state.

### Initial version

A newly created Entity starts with:

`version = 1`

Every later persisted Domain mutation that participates in Entity versioning must advance the version according to the governing mutation rules.

This ADR does not define remote version reconciliation.

### Initial source

A Task created directly by the user starts with:

`LifeOsEntitySource.user`

Detailed provenance beyond the shared source value is not required for the initial user-created Task.

### Timestamp defaults

For a newly created Task:

- `createdAt` = current injected UTC time;
- `updatedAt` = the same current injected UTC time.

The creation operation obtains one timestamp and uses that same value for both fields.

### Creation responsibility

The Application layer coordinates creation by obtaining:

- a new Entity ID;
- the current UTC time;
- user input;
- initial shared metadata defined by this ADR.

Domain code remains responsible for Entity validity and creation invariants.

Persistence remains responsible only for storing the resulting Domain Entity and producing the required atomic Outbox change.

### Testing

Tests must be able to inject:

- deterministic Entity IDs;
- deterministic UTC timestamps.

Creation tests should verify:

- generated typed ID is used;
- `createdAt == updatedAt` at creation;
- timestamps are UTC;
- lifecycle is active;
- version is 1;
- source is user;
- repository save receives the complete valid Domain Entity.

## Scope

This ADR defines only initial metadata for direct user-created Entities needed by the current Task vertical slice.

It does not define:

- imported Entity identity;
- AI-created Entity provenance;
- deterministic content-derived IDs;
- server-issued Entity IDs;
- Entity cloning;
- remote version reconciliation;
- deletion lifecycle semantics;
- archival;
- account/user identity.

These remain deferred.

## Consequences

The create-Task path becomes deterministic and testable.

Domain code remains independent of clocks, randomness, UUID packages, and platform APIs.

Application coordinates creation without taking persistence ownership.

Infrastructure persists complete Entity identity rather than generating it implicitly.

## Precedence

This ADR supplements ADR-0016, ADR-0022, ADR-0023, and ADR-0025.

Where earlier ADRs define mandatory Entity metadata but leave production creation values or ownership unspecified, this ADR governs those decisions.