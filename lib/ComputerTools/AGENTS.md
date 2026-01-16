# COMPUTERTOOLS CORE MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/

## OVERVIEW

The `lib/ComputerTools/` directory contains the core module implementation with 47 Ruby files organized into subdirectories for different functional areas.

## STRUCTURE

```
lib/ComputerTools/
├── actions/            # Business logic (9 files)
├── commands/           # CLI commands (6 files)
├── configuration/      # Configuration (7 files)
├── generators/         # AI generators (3 files)
├── interfaces/         # Type definitions (8 files)
├── providers/          # Service providers (2 files)
├── wrappers/           # External tool wrappers (5 files)
├── cli.rb              # Main CLI router
└── ComputerTools.rb    # Module loader
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Add new action** | `actions/` | Business logic implementation |
| **Add CLI command** | `commands/` | Thor-based command classes |
| **Add configuration** | `configuration/` | YAML/JSON config handling |
| **Add AI generator** | `generators/` | Prompt generation logic |
| **Add interface** | `interfaces/` | Type contracts and schemas |
| **Add provider** | `providers/` | External service integrations |
| **Add wrapper** | `wrappers/` | External tool adapters |

## CONVENTIONS

- **File Naming**: Snake_case for Ruby files (e.g., `file_operations.rb`)
- **Class Structure**: Each file typically contains one main class
- **Dependency Injection**: Components accept dependencies via constructor
- **Error Handling**: Consistent error classes and patterns

## ANTI-PATTERNS

- None documented in this module
- Follow parent project conventions

## UNIQUE STYLES

- **Action/Command Separation**: Clear distinction between business logic (actions) and CLI interface (commands)
- **Wrapper Pattern**: Consistent approach to external tool integration
- **Configuration Centralization**: All config-related code in dedicated directory
