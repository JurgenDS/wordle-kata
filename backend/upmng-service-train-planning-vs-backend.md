# Key Differences: upmng-service-train-planning → wordle-kata/backend

## Architecture

| | upmng-service | wordle-kata |
|--|--------------|-------------|
| **Structure** | Multi-module Maven (19+ modules) | Single module |
| **Framework** | Spring Boot 3.x + Spring Cloud | Spring Boot 3.2.0 (minimal) |
| **Database** | Oracle + Liquibase + Hibernate | None (stateless) |
| **Messaging** | Kafka (producers/consumers) | None |
| **Caching** | Hazelcast | None |

## What You'll Miss Coming from upmng-service

- **No multi-module Maven** - single `pom.xml`, no parent POM hierarchy
- **No database** - purely in-memory, stateless
- **No Kafka** - REST API only
- **No security** - no OAuth2/ADFS/Keycloak
- **No WireMock, PIT mutation testing** - simpler test setup
- **No external service adapters** - no TMD, RTC, Itinerary clients

## Project Structure Comparison

**upmng-service** (19 modules):
```
├── train-planning-application-domain
├── train-planning-persistence
├── train-planning-rest
├── train-planning-adapter-tmd-rest
├── train-planning-adapter-rtc-kafka
├── train-planning-messaging-*
└── ... 10+ more
```

**wordle-kata/backend** (single module):
```
src/main/java/com/example/hello/
├── domain/model/
├── application/
│   ├── ports/incoming/
│   └── processors/
├── adapter/incoming/rest/
└── config/
```

## Testing Differences

| upmng-service | wordle-kata |
|--------------|-------------|
| Multi-level (Unit/E2E/Mutation) | Unit + Integration + ArchUnit |
| PIT mutation (50% threshold) | JaCoCo only (100% coverage) |
| WireMock for external APIs | No mocking needed |
| Aggregated coverage | Single module coverage |

## Shared Patterns

Both projects share these patterns:

- **Hexagonal Architecture** - Ports & Adapters pattern
- **Either<Error, T>** from Vavr - same error handling pattern
- **ArchUnit tests** - architecture enforcement
- **Processor pattern** - application layer organization

**wordle-kata application.yaml**:
```yaml
server.port: 8080
spring.application.name: hello-world-backend
cors.allowed-origins: ${CORS_ALLOWED_ORIGINS:http://localhost:4200}
logging.level: DEBUG/INFO
```

## Quick Commands

```bash
# Run application
mvn -Prun

# Run tests
mvn test
```

## Transition Tips

1. **Single module simplicity** - no module dependencies to manage
2. **Focus on architecture tests** - 13 ArchUnit rules enforce hexagonal boundaries
3. **100% coverage required** - stricter than upmng's mutation testing
4. **No infrastructure** - pure business logic kata
5. **Same Either pattern** - Vavr error handling works identically

## Summary

wordle-kata/backend is an **educational kata** demonstrating clean hexagonal architecture in its purest form. It strips away all enterprise concerns (database, messaging, security, multi-module) to focus on:

- Clean layer separation
- ArchUnit-enforced boundaries
- 100% test coverage
- Vavr Either error handling

If you understand upmng-service-train-planning, wordle-kata will feel like a simplified version focusing purely on the architectural patterns without the infrastructure complexity.
