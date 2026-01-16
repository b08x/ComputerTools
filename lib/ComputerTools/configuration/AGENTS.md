# CONFIGURATION MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/configuration/

## OVERVIEW

Centralized configuration management using factory pattern for all toolkit settings.

## STRUCTURE

```
configuration/
├── configuration_factory.rb        # Factory for config instantiation
├── application_configuration.rb   # Main config orchestrator
├── logging_configuration.rb       # Logging settings
├── path_configuration.rb          # File path settings
├── terminal_configuration.rb      # Terminal command settings
├── display_configuration.rb       # Display formatting settings
└── backup_configuration.rb       # Backup/restic settings
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Create new config** | `configuration_factory.rb` | Add factory method `create_*_config` |
| **Load from YAML** | `application_configuration.rb` | Use `from_yaml_files` |
| **Access settings** | Individual config classes | Each has `config` accessor |
| **Validate configs** | `application_configuration.rb` | Use `validate_all!` |

## CONVENTIONS

- **Factory Pattern**: All config instantiation via `ConfigurationFactory.create_*_config`
- **YAML Loading**: Optional YAML data for initialization, defaults otherwise
- **Validation**: Each config class implements `validate!` method
- **Backward Compatibility**: `ApplicationConfiguration#fetch(*keys)` delegates to sub-configs

## ANTI-PATTERNS

- **NEVER** instantiate config classes directly (use factory)
- **NEVER** modify config after validation without re-validating
- **NEVER** add config without factory method

## UNIQUE STYLES

- **Factory-Centric**: All config creation centralized in factory
- **Sub-Config Delegation**: ApplicationConfiguration composes all sub-configs
- **Validation Chain**: Cascade validation across all configs
