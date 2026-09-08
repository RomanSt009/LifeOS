# ADR-0025: Local Change Identity and Device Identity

Status: Accepted

## Context

LifeOS requires every local syncable Entity mutation to create an Outbox record atomically with Domain State.

ADR-0023 requires:

- `change_id` to be supplied at the Infrastructure boundary;
- deterministic `change_id` values in tests;
- `device_id` to be supplied through Infrastructure composition;
- deterministic fixed `device_id` values in tests.

However, the production generation and lifecycle of these identifiers were intentionally deferred.

The production `DriftLifeOsTaskRepository` now needs concrete implementations for both values before it can be composed safely.

## Decision

### Change ID

Every Outbox change receives a globally unique opaque identifier.

For production, LifeOS will use UUID version 4 for `change_id`.

Generation responsibility belongs to Infrastructure.

The repository must depend on an injectable change-id generator abstraction or function.

Tests may inject deterministic values.

Domain and Application layers must not depend on UUID libraries or generation details.

### Device ID

Each local LifeOS installation has one stable opaque device identifier.

The initial production implementation will use UUID version 4.

The device identifier is generated once on first application initialization and then persisted locally.

Subsequent launches reuse the stored identifier.

The device identifier is not regenerated on every process start.

### Device ID storage

The initial device identifier is stored in local application-support storage associated with the LifeOS installation.

The storage mechanism belongs to Infrastructure / composition concerns.

The identifier must survive normal application restarts.

The identifier does not need to survive:

- application data deletion;
- uninstall procedures that remove application-support data;
- deliberate profile reset.

A future Sync architecture may refine device registration or server-issued identity without changing Domain Entity identity.

### Composition

The composition root resolves the stable production `device_id` before constructing syncable repository implementations that require it.

The concrete `DriftLifeOsTaskRepository` receives:

- the owned production database;
- a change-id generator;
- the resolved stable device ID.

Presentation and Application must not generate or store these identifiers.

### Testing

Tests must be able to inject:

- deterministic `change_id` values;
- deterministic fixed `device_id` values.

Tests must not depend on random UUID output unless specifically testing the production generator.

A focused production device-identity test should verify:

1. first resolution creates an ID;
2. subsequent resolution returns the same ID;
3. the value survives reopening the underlying storage.

### Dependency

A focused UUID package may be introduced for production UUID v4 generation.

The dependency must remain confined to Infrastructure/composition implementation.

Do not add ULID or multiple ID strategies unless a future accepted ADR requires them.

## Scope

This ADR defines only:

- production `change_id` generation;
- production local `device_id` generation;
- local persistence and reuse of `device_id`;
- composition responsibility.

It does not define:

- remote device registration;
- server-issued device identity;
- account identity;
- multi-device trust;
- Sync authentication;
- device revocation;
- conflict resolution;
- Outbox acknowledgement.

These remain deferred.

## Consequences

Production repository composition can now satisfy ADR-0023 without hardcoded identifiers.

Tests remain deterministic.

Device identity is stable across normal application restarts.

Sync-specific semantics remain deferred until the Sync milestone.

## Precedence

This ADR supplements ADR-0023.

Where ADR-0023 intentionally deferred production `change_id` and `device_id` lifecycle, this ADR provides the governing production decision.