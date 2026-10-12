# AGENTS.md

This file is auto-included in every Kiro session (both IDE and CLI).
Use it for guardrails that apply across all agents.

## Project Guardrails

### Security
- Never commit secrets, API keys, or credentials
- Sanitize all user input before database queries
- Use parameterized queries to prevent SQL injection

### Code Quality
- Follow existing code style and patterns
- Write tests for new functionality
- Keep functions focused and under 50 lines

### Git Practices
- Write descriptive commit messages
- Reference issue numbers in commits
- Never force push to main/master

### Architecture
- Follow the patterns in .kiro/steering/tech.md
- Check .kiro/steering/product.md for feature context
- Respect existing module boundaries

## CLI Tool Usage
When invoking external CLIs (via shell tool), prefer:
- `gh` for GitHub operations
- `npm test` / `pytest` for testing
- `git` for version control

## Spec Workflow
1. Start with `kspec spec` to define work
2. Use `kspec tasks` to break into subtasks
3. Use `kspec build` for TDD implementation
4. Use `kspec verify` to validate completion
