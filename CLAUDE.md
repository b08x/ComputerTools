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
- `exe/ComputerTools` - Run the CLI application (interactive mode)
- `exe/ComputerTools command_name args` - Run specific command directly

## Architecture

This is a Ruby CLI application built with the Sublayer framework, following a modular architecture with heavy use of TTY gems for rich terminal interfaces.

### Core Components

**CLI Framework**: Built on Thor for command-line interface management with dynamic command registration from the Commands module. Commands are automatically discovered and registered via metaprogramming in cli.rb:18-29.

**Interactive Menu System**: When launched without arguments, the application provides an interactive menu system using TTY::Prompt for command discovery and guided parameter collection.

**Sublayer Integration**: Uses Sublayer framework for AI-powered text generation with configurable AI providers (currently configured for Gemini 2.0 Flash).

**Unified Logging**: Custom logging system using TTY::Logger with emoji-enhanced console output and optional structured JSON file logging. Logger supports custom log types (success, failure, tip, step) with visual symbols.

**Configuration Management**: Uses TTY::Config for managing application settings with interactive setup, environment variable support, and validation.

### Modular Structure

- `Commands/` - CLI command implementations inheriting from BaseCommand
- `Actions/` - Reusable action classes for common operations (blueprint, deepgram, file_activity)
- `Generators/` - AI-powered content generators using Sublayer
- `Agents/` - AI agent implementations for complex workflows
- `Wrappers/` - External tool wrappers with fluent interfaces:
  - `Docling` - Document processing and conversion
  - `Trafilatura` - Web content extraction
  - `BlueprintDatabase` - PostgreSQL with pgvector for semantic search
  - `GitWrapper`, `ResticWrapper` - Version control and backup integration
  - `DeepgramParser/Analyzer/Formatter` - Audio transcription processing

### Key Architecture Patterns

**Command Pattern**: Commands are automatically registered via metaprogramming in cli.rb:18-29, scanning all classes in the Commands module and dynamically creating Thor methods.

**Builder Pattern**: Wrapper classes (Docling, Trafilatura) use fluent interfaces for configuring external CLI tools with method chaining.

**Template Method**: BaseCommand provides common structure with logging methods while concrete commands implement specific execute methods.

**Configuration as Code**: TTY::Config with interactive setup, validators, and environment variable mappings for flexible deployment.

### Configuration

- `config/sublayer.yml` - AI provider configuration (Gemini with gemini-2.0-flash model)
- `config/blueprints.yml` - Blueprint management database and AI settings
- `config/deepgram.yml` - Deepgram API configuration
- `~/.config/computertools/config.yml` - User configuration (paths, terminal, logging)
- Environment variables with `COMPUTERTOOLS_` prefix for all settings

### External Dependencies

The application integrates with external tools:
- **Python Tools**: Docling (document processing), Trafilatura (web extraction) - require pip installation
- **System Tools**: git, yadm, restic, fd for file activity tracking
- **Database**: PostgreSQL with pgvector extension for semantic search in blueprints
- **AI Provider**: Google Gemini API for text generation and embeddings

### Logger Architecture

The logging system provides both user-friendly console output and structured debugging:
- **Console Output**: Emoji-enhanced messages with colors (✅ success, ❌ failure, ⚠️ warning, 💡 tip, 🚀 step, ℹ️ info, 🐞 debug)
- **File Logging**: Optional JSON-structured logging for debugging and analysis
- **Configuration**: Separate log levels for console vs file output
- **Custom Types**: Extended TTY::Logger with application-specific log types

### Command Registration

Commands are discovered automatically via metaprogramming. To add a new command:
1. Create a class in `lib/ComputerTools/commands/` inheriting from BaseCommand
2. Override the `execute` method and optionally `self.description`
3. The command will be automatically registered based on the class name (e.g., `NewToolCommand` becomes `newtool`)

### Wrapper Pattern

External tools are wrapped with fluent interfaces. Example structure:
```ruby
class ToolWrapper
  def initialize
    @line = Terrapin::CommandLine.new('tool', ':options :input')
    @options = {}
  end
  
  def option_name(value)
    @options[:option] = value
    self  # Return self for chaining
  end
  
  def run(input)
    @line.run(options: build_options_string, input: input)
  end
end
```

## Project Structure

- `exe/ComputerTools` - Main executable with interactive menu fallback
- `lib/ComputerTools/cli.rb` - Thor CLI with dynamic command registration
- `lib/ComputerTools/commands/base_command.rb` - Abstract base class for all commands
- `lib/ComputerTools/logger.rb` - Singleton logger with custom types and emoji output
- `lib/ComputerTools/configuration.rb` - TTY::Config-based configuration management
- `lib/ComputerTools/config/` - Default configuration files for different components

## Development Workflow

### Command Creation Guidelines
- For every command created, also add it the TUI menu