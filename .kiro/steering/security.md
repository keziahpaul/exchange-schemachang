---
inclusion_mode: always
description: Security requirements and practices
---
# Security Guidelines

## Authentication
[Auth approach: OAuth, JWT, sessions]

## Data Protection
- Sanitize all user input
- Use parameterized queries
- Encrypt sensitive data at rest

## Secrets Management
- Never commit secrets to git
- Use environment variables
- Reference .env.example for required vars