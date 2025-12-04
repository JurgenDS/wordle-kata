# Key Differences: upmng-service-train-planning → wordle-kata/backend

## Architecture

| | upmng-service | wordle-kata |
|--|--------------|-------------|
| **Structure** | Multi-module Maven (19+ modules) | Single module |
| **Framework** | Spring Boot 3.x + Spring Cloud | Spring Boot 3.4.1 (minimal) |
| **Database** | Oracle + Liquibase + Hibernate | None (stateless) |
| **Messaging** | Kafka (producers/consumers) | None |
| **Caching** | Hazelcast | None |

## What You'll Miss Coming from upmng-service

- **No multi-module Maven** - single `pom.xml`, no parent POM hierarchy
- **No database** - purely in-memory, stateless
- **No Kafka** - REST API only
- **No security** - no OAuth2/ADFS/Keycloak
- **No WireMock** - simpler test setup (but PITest mutation testing is included!)
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
| Multi-level (Unit/E2E/Mutation) | Unit + Integration + ArchUnit + Mutation |
| PIT mutation (50% threshold) | PITest mutation (90% achieved) |
| WireMock for external APIs | No mocking needed |
| Aggregated coverage | Single module coverage (100% JaCoCo) |
| SpotBugs integrated | SpotBugs + FindSecBugs |

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

# Run all quality checks (from project root)
./quality-check.sh

# Run with mutation testing
./quality-check.sh --mutation
```

## Transition Tips

1. **Single module simplicity** - no module dependencies to manage
2. **Focus on architecture tests** - 13 ArchUnit rules enforce hexagonal boundaries
3. **100% coverage required** - JaCoCo enforced, plus PITest mutation testing
4. **No infrastructure** - pure business logic kata
5. **Same Either pattern** - Vavr error handling works identically
6. **Quality check script** - run `./quality-check.sh` for comprehensive validation

## Summary

wordle-kata/backend is an **educational kata** demonstrating clean hexagonal architecture in its purest form. It strips away all enterprise concerns (database, messaging, security, multi-module) to focus on:

- Clean layer separation
- ArchUnit-enforced boundaries
- 100% test coverage + mutation testing
- SpotBugs static analysis
- Vavr Either error handling

If you understand upmng-service-train-planning, wordle-kata will feel like a simplified version focusing purely on the architectural patterns without the infrastructure complexity.
