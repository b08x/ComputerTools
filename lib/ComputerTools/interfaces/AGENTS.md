# INTERFACES MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/interfaces/

## OVERVIEW

Type contracts and interface definitions enforcing dependency injection compatibility across the toolkit.

## STRUCTURE

```
interfaces/
├── validation.rb          # Interface validation helpers
├── git_interface.rb       # Git operations contract
├── backup_interface.rb    # Backup/restore contract
├── processor_interface.rb # Data processing contract
├── parser_interface.rb    # Data parsing contract
├── formatter_interface.rb # Output formatting contract
├── configurable_interface.rb # Configuration contract
└── database_interface.rb  # Database operations contract
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Validate wrapper compliance** | `validation.rb` | Use `Validation.implements_*_interface?` |
| **Define new contract** | New file | Include module with required methods |
| **Check DI compatibility** | `validation.rb` | Use `Validation.validate_di_compatibility` |

## CONVENTIONS

- **Interface Definition**: Modules with `#method_name` raising `NotImplementedError`
- **Validation**: Use `Validation.implements_*_interface?(object)` before DI registration
- **Documentation**: Yard docs with `@abstract` and `@raise NotImplementedError`
- **Method Signature**: All interface methods must be implemented by concrete classes

## ANTI-PATTERNS

- **NEVER** implement interface methods directly in interface module (use as contract only)
- **NEVER** skip validation before dependency injection
- **NEVER** add interface methods without updating validation.rb

## UNIQUE STYLES

- **Validation Module**: Centralized contract validation with helper methods
- **Interface Contracts**: Ruby mixins defining required method signatures
- **DI Safety**: Compatibility checking before container registration
