# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-15
**Commit:** adcc802
**Branch:** main

## OVERVIEW

ComputerTools is a Ruby-based CLI toolkit that provides AI-powered command-line utilities and modular architecture for building custom CLI tools. The project uses a modular design with clear separation of concerns between commands, actions, generators, and wrappers.

## STRUCTURE

```
./
├── bin/            # Standard gem executables (console, setup)
├── exe/            # Main CLI executable (ComputerTools)
├── lib/            # Core library code
│   └── ComputerTools/
│       ├── actions/        # Business logic and core functionality
│       ├── commands/       # CLI command implementations
│       ├── configuration/  # Configuration management
│       ├── generators/     # AI prompt generation
│       ├── interfaces/     # Type definitions and contracts
│       ├── providers/      # External service integrations
│       ├── wrappers/       # External tool wrappers
│       └── cli.rb          # Main CLI router
├── config/          # Configuration files
└── Gemfile          # Ruby dependencies
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Add new CLI command** | `lib/ComputerTools/commands/` | Create new command class, register in `cli.rb` |
| **Add business logic** | `lib/ComputerTools/actions/` | Implement core functionality here |
| **Add external integration** | `lib/ComputerTools/wrappers/` | Create wrapper classes for external tools |
| **Add AI functionality** | `lib/ComputerTools/generators/` | Implement prompt generation and AI interactions |
| **Add configuration** | `lib/ComputerTools/configuration/` | Define configuration schemas and defaults |
| **Modify CLI routing** | `lib/ComputerTools/cli.rb` | Update Thor-based command routing |
| **Add type definitions** | `lib/ComputerTools/interfaces/` | Define interfaces and contracts |

## CODE MAP

### Key Modules

| Module | Location | Role |
|--------|----------|------|
| `ComputerTools` | `lib/ComputerTools.rb` | Main module loader |
| `ComputerTools::CLI` | `lib/ComputerTools/cli.rb` | CLI command router |
| `ComputerTools::Actions` | `lib/ComputerTools/actions/` | Business logic |
| `ComputerTools::Commands` | `lib/ComputerTools/commands/` | CLI command implementations |
| `ComputerTools::Wrappers` | `lib/ComputerTools/wrappers/` | External tool integrations |
| `ComputerTools::Generators` | `lib/ComputerTools/generators/` | AI prompt generation |

### Key Classes

| Class | Location | Role |
|-------|----------|------|
| `ComputerTools::CLI` | `lib/ComputerTools/cli.rb` | Main CLI entry point |
| Various Action classes | `lib/ComputerTools/actions/` | Core business logic |
| Various Command classes | `lib/ComputerTools/commands/` | CLI command handlers |
| Various Wrapper classes | `lib/ComputerTools/wrappers/` | External tool adapters |

## CONVENTIONS

### Project-Specific Conventions

- **Executable Location**: Main executable in `exe/` instead of standard `bin/` (gemspec specifies `bin/`)
- **AI Integration**: Uses Sublayer framework with Gemini AI model for AI-powered features
- **Configuration**: Uses `.ctignore` for custom ignore patterns
- **CLI Framework**: Built on Thor for command-line interface

### Ruby Conventions

- **Linting**: RuboCop with strict rules (method length: 18, ABC size: 20)
- **Style**: Single quotes for strings, specific layout styles
- **Testing**: Minitest framework (configured but no tests implemented yet)
- **Documentation**: Yard for API documentation

## ANTI-PATTERNS (THIS PROJECT)

- **No documented anti-patterns found** - No 'DO NOT', 'NEVER', 'ALWAYS', or 'DEPRECATED' comments in codebase
- **Follow standard Ruby practices** - No explicit forbidden patterns documented

## UNIQUE STYLES

- **Modular Architecture**: Clear separation between Commands → Actions → Generators/Wrappers
- **Dependency Injection**: Components are designed for easy dependency injection
- **AI-First Design**: Built with AI integration as a core feature
- **Extensible CLI**: Easy to add new commands through Thor-based routing

## COMMANDS

```bash
# Development
bundle install          # Install dependencies
bundle exec rubocop     # Run linter
bundle exec rspec       # Run tests (when implemented)

# CLI Usage
./exe/ComputerTools menu                    # Show available commands
./exe/ComputerTools list_models             # List available AI models
./exe/ComputerTools <command> --help        # Get help for specific command

# Build
rake build              # Build gem (if Rakefile exists)
bundle exec rake install # Install gem locally
```

## NOTES

- **Missing Standard Files**: No test directory despite rspec in Gemfile, no Rakefile, no LICENSE, no CHANGELOG.md
- **Executable Location**: Main executable in `exe/` but gemspec expects `bin/` - consider moving or updating gemspec
- **RuboCop Exclusions**: Many linting rules are excluded in `.rubocop_todo.yml` - consider addressing these
- **Gem Metadata**: Placeholder values in gemspec (author, email, description, homepage)
- **CI Missing**: No GitHub Actions workflows or other CI configuration

## ARCHITECTURE DECISIONS

- **Modular Design**: Separation of concerns between commands, actions, and wrappers promotes maintainability
- **AI Integration**: Built-in support for AI-powered features using Sublayer framework
- **Extensible CLI**: Thor-based routing makes it easy to add new commands
- **Configuration Management**: Centralized configuration system for easy customization
