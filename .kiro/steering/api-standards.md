---
inclusion_mode: on_demand
description: API design conventions (request when building APIs)
---
# API Standards

## REST Conventions
- Use plural nouns for resources
- HTTP methods: GET (read), POST (create), PUT (update), DELETE (remove)
- Return appropriate status codes

## Response Format
```json
{
  "data": {},
  "meta": { "timestamp": "ISO8601" },
  "errors": []
}
```

## Versioning
[API versioning strategy]