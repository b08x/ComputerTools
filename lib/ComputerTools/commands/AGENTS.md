# COMMANDS MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/commands/

## OVERVIEW

Thor-based CLI command implementations delegating business logic to actions.

## STRUCTURE

```
commands/
├── base_command.rb      # Base class with shared CLI functionality
├── menu_command.rb      # Interactive TTY menu
├── list_models_command.rb      # AI model listing
├── overview_command.rb        # Project overview generation
├── latest_changes_command.rb   # Recent activity reports
└── config_command.rb          # Configuration management
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Add new command** | New file | Extend `BaseCommand` |
| **Add CLI option** | Command file | Use Thor `option` method |
| **Register in menu** | `menu_command.rb` | Add to command list |
| **Handle user input** | Command file | Thor argument/option parsing |

## CONVENTIONS

- **Thor Framework**: All commands inherit from `BaseCommand` (extends Thor)
- **Delegation Pattern**: Commands delegate to actions via container
- **Help Text**: Comprehensive `desc` strings for all commands
- **Option Naming**: Use snake_case for options, kebab-case for CLI flags

## ANTI-PATTERNS

- **NEVER** implement business logic (belongs in actions/)
- **NEVER** skip option validation
- **NEVER** create commands without corresponding actions

## UNIQUE STYLES

- **Base Command**: Shared functionality in base class
- **Menu Integration**: All commands auto-discoverable in interactive menu
- **Dependency Container**: Commands fetch actions from DI container
