# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `bundle exec rspec` - Run the full test suite
- `bundle exec rspec spec/path/to/specific_spec.rb` - Run specific test file
- `bundle exec rspec spec/path/to/specific_spec.rb:line_number` - Run specific test by line number

### Linting and Code Quality
- `bundle exec rubocop` - Run RuboCop linter
- `bundle exec rubocop --autocorrect` - Run RuboCop with safe autocorrect
- `bundle exec rubocop --autocorrect-all` - Run RuboCop with all autocorrect (safe and unsafe)

### Documentation
- `bundle exec yard doc` - Generate documentation
- `bundle exec yard server` - Start documentation server

### Installation and Setup
- `bundle install` - Install dependencies
- `bin/ComputerTools` - Run the CLI application
- `exe/ComputerTools` - Alternative executable path

## Architecture

This is a Ruby CLI application built with the Sublayer framework and Thor, following a modular autoloaded architecture using Zeitwerk.

### Core Components

**CLI Framework**: Built on Thor with dynamic command registration. Commands are automatically discovered and registered from nested module structures using metaprogramming (cli.rb:36-42).

**Zeitwerk Autoloading**: Uses Zeitwerk for automatic code loading with custom inflections (computertools.rb:7-11). The loader is made available globally via `ComputerTools.loader` for eager loading when needed.

**Sublayer Integration**: AI-powered text generation through Sublayer framework with configurable providers (currently Gemini via config/sublayer.yml).

**Modular Structure**:
- `Commands/` - Organized by category (Analysis, ContentManagement, Interface, MediaProcessing)
- `Actions/` - Organized by domain (Blueprints, Deepgram, Utilities, VersionControl)  
- `Generators/` - AI-powered content generators using Sublayer
- `Wrappers/` - External tool integrations (Audio, Backup, Database, Documents, VersionControl)

### Key Architecture Patterns

**Namespace Organization**: All components are properly namespaced under domain-specific modules:
- `Commands::Analysis::*` - Analysis commands
- `Commands::ContentManagement::*` - Content management commands
- `Commands::Interface::*` - Interface commands (Base, Menu)
- `Commands::MediaProcessing::*` - Media processing commands
- `Actions::Blueprints::*` - Blueprint-related actions
- `Actions::Deepgram::*` - Deepgram audio processing actions
- `Actions::Utilities::*` - General utility actions
- `Actions::VersionControl::*` - Version control actions

**Command Discovery**: CLI dynamically discovers command classes by:
1. Eager loading all classes via Zeitwerk
2. Scanning nested modules in `Commands` namespace
3. Excluding base classes (BaseCommand, MenuCommand)
4. Auto-registering found commands with Thor

**Interactive Mode**: When no arguments provided, launches TTY-based interactive menu system with guided parameter collection.

### Directory Structure

```
lib/
├── computertools.rb              # Main entry point with Zeitwerk setup
├── computertools/
│   ├── cli.rb                   # Thor CLI with dynamic command registration
│   ├── commands.rb              # Commands namespace holder
│   ├── commands/
│   │   ├── analysis.rb          # Analysis namespace
│   │   ├── analysis/
│   │   │   └── latest_changes.rb
│   │   ├── content_management.rb # Content management namespace
│   │   ├── content_management/
│   │   │   ├── blueprint.rb
│   │   │   └── overview.rb
│   │   ├── interface.rb         # Interface namespace
│   │   ├── interface/
│   │   │   ├── base.rb          # Base command class
│   │   │   └── menu.rb          # Interactive menu
│   │   └── media_processing.rb  # Media processing namespace
│   ├── actions/                 # Domain-specific business logic
│   ├── generators/              # AI-powered content generation
│   ├── wrappers/                # External tool integrations
│   ├── config/                  # Configuration files
│   └── prompts/                 # AI prompt templates
```

### Configuration

- `config/sublayer.yml` - AI provider configuration (Gemini with gemini-1.5-flash-latest)
- `config/blueprints.yml` - Blueprint management settings
- `config/deepgram.yml` - Deepgram audio processing settings
- Logging configured to `log/sublayer.log` with JSON format

### External Dependencies

The application integrates with external tools:
- **Docling**: Document processing (requires `pip install docling`)
- **Trafilatura**: Web content extraction (requires `pip install trafilatura`)
- **PostgreSQL + pgvector**: For blueprint database with vector embeddings
- **TTY Toolkit**: Rich terminal interfaces (tty-prompt, tty-table, etc.)

### Key Implementation Details

**Command Registration**: Commands are dynamically registered at runtime in `CLI.start()` method. Each command class must implement:
- `self.command_name` - Thor command name
- `self.description` - Command description
- `#execute(*args)` - Command execution logic

**Autoloading**: Zeitwerk handles automatic loading of all classes. The loader is configured with custom inflections and made available globally for eager loading during command discovery.

**Error Handling**: Graceful degradation when optional dependencies (like TTY::Prompt) are missing, with helpful error messages guiding users to install required gems.

## Important Notes

- Main executable is located at `exe/ComputerTools`
- The codebase uses `computertools/` (no underscore) as the directory name  
- All new classes should follow the established namespace patterns
- Command classes should inherit from appropriate base classes in the Interface module
- AI integration happens through Sublayer generators, configured via YAML files

## Recent Restructuring

The codebase has undergone major restructuring with:
- Migration from manual requires to Zeitwerk autoloading
- Proper namespace organization by domain
- Dynamic command discovery replacing static registration
- Enhanced modularity and separation of concerns

When adding new functionality, follow the established patterns and ensure proper namespacing within the domain-specific modules.