# DDD Deep Analysis Skill

Deep Domain-Driven Design analysis capabilities for detecting anti-patterns, validating principles, and assessing domain model health.

## Overview

This skill provides the knowledge base for performing deep DDD analysis that goes beyond surface-level pattern matching. It understands:

- The philosophy behind DDD (Eric Evans)
- Common anti-patterns and their detection
- Aggregate design rules (Vaughn Vernon)
- Layer architecture principles
- Domain event patterns
- Bounded context relationships

## References

- [anemic-model.md](references/anemic-model.md) - Anemic Domain Model detection criteria
- [aggregate-rules.md](references/aggregate-rules.md) - Vernon's aggregate design rules and extensions
- [layer-architecture.md](references/layer-architecture.md) - Clean domain layer principles
- [domain-events.md](references/domain-events.md) - Domain event patterns and coverage
- [bounded-context.md](references/bounded-context.md) - Context mapping and relationships
- [anti-patterns.md](references/anti-patterns.md) - Common DDD anti-patterns

## Usage

This skill is automatically invoked by:
- `/ddd health` - For comprehensive health analysis
- `/ddd validate` - For principle compliance checking
- `/ddd refactor` - For improvement guidance

## Key Principles

### 1. Domain Model is the Heart

The domain layer should:
- Contain all business logic
- Be free of infrastructure concerns
- Use ubiquitous language
- Enforce invariants

### 2. Aggregates Define Consistency Boundaries

Aggregates should:
- Be small (prefer single entity)
- Reference other aggregates by ID
- Enforce invariants within boundaries
- Be the unit of transaction

### 3. Events Communicate State Changes

Domain events:
- Represent facts that happened
- Enable loose coupling between contexts
- Named in past tense
- Contain relevant data snapshot

### 4. Contexts Have Clear Boundaries

Bounded contexts:
- Define where a model is valid
- Have explicit relationships
- Use Anti-Corruption Layers for integration
- Own their data

## Detection Capabilities

| Anti-Pattern | Detection Method |
|--------------|------------------|
| Anemic Model | Method analysis, logic location |
| Transaction Script | Service size, entity manipulation |
| God Class | Size metrics, cohesion analysis |
| Layer Violation | Import analysis, annotation detection |
| Aggregate Boundary Violation | Reference analysis |
| Missing Events | State change without event emission |
| Context Leak | Cross-boundary imports |
| Naming Inconsistency | Glossary comparison |
