# Language Patterns Skill

Language-specific DDD implementation patterns for detecting and applying DDD concepts across different programming languages and frameworks.

## Overview

DDD concepts are universal, but their implementation varies by language and framework. This skill provides:

- Language-specific pattern recognition
- Framework integration patterns
- Idiomatic implementations for each language
- Common pitfalls per language/framework

## Supported Languages

| Language | Framework | Reference |
|----------|-----------|-----------|
| TypeScript | NestJS, Express | [typescript.md](references/typescript.md) |
| Java | Spring Boot | [java-spring.md](references/java-spring.md) |
| Kotlin | Spring, Ktor | [kotlin.md](references/kotlin.md) |
| Python | Django, FastAPI | (coming soon) |
| Go | Standard library | (coming soon) |
| C# | .NET Core | (coming soon) |

## Usage

This skill is automatically invoked when:
- `/ddd analyze` detects the project language
- `/ddd health` evaluates patterns
- `/ddd refactor` generates language-specific examples

## Key Detection Patterns

### Aggregate Root Detection

| Language | Pattern |
|----------|---------|
| TypeScript | Class with identity, contains entities, has methods |
| Java/Kotlin | `@AggregateRoot` annotation or naming convention |
| C# | Inherits from `AggregateRoot<TId>` base |

### Value Object Detection

| Language | Pattern |
|----------|---------|
| TypeScript | Readonly class, no identity, `equals()` method |
| Java | Record or class with `equals()`/`hashCode()` |
| Kotlin | `data class` with `val` only |
| C# | Record type or `struct` |

### Domain Event Detection

| Language | Pattern |
|----------|---------|
| TypeScript | Class implementing `DomainEvent` interface |
| Java/Kotlin | Class with `@DomainEvent` or ending in "Event" |
| C# | Record implementing `IDomainEvent` |

### Repository Detection

| Language | Pattern |
|----------|---------|
| TypeScript | Interface with `find`, `save` methods |
| Java | Interface extending `Repository<T, ID>` |
| Kotlin | Interface with suspend functions |
| C# | Interface `IRepository<T>` |

## Language-Specific Concerns

### TypeScript/JavaScript
- No native value object support (need custom equals)
- Optional typing can hide domain concepts
- Framework decorators may pollute domain

### Java
- Verbose syntax for value objects (use Records in Java 16+)
- ORM annotations commonly in domain (avoid)
- Spring's DI can encourage anemic models

### Kotlin
- Data classes great for value objects
- Null safety aligns with DDD invariants
- Suspend functions for async repository

### Python
- Duck typing makes interfaces implicit
- dataclasses good for value objects
- Django ORM tightly coupled (use repository pattern)

### Go
- No classes, use structs + methods
- Interfaces are implicit
- No inheritance, use composition

### C#
- Records (C# 9+) excellent for value objects
- Entity Framework can pollute domain
- Strong async/await support
