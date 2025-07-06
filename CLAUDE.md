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

## Architecture

This is a Ruby CLI application built with the Sublayer framework, following a modular architecture:

### Core Components

**CLI Framework**: Built on Thor for command-line interface management with dynamic command registration from the Commands module.

**Sublayer Integration**: Uses Sublayer framework for AI-powered text generation with configurable AI providers (currently configured for Gemini).

**Modular Structure**:
- `Commands/` - CLI command implementations inheriting from BaseCommand
- `Generators/` - AI-powered content generators using Sublayer
- `Actions/` - Reusable action classes for common operations
- `Agents/` - AI agent implementations for complex workflows
- `Wrappers/` - External tool wrappers (Docling, Trafilatura) with fluent interfaces

### Key Architecture Patterns

**Command Pattern**: Commands are automatically registered via metaprogramming in cli.rb:5-11, scanning all classes in the Commands module.

**Builder Pattern**: Wrapper classes (Docling, Trafilatura) use fluent interfaces for configuring external CLI tools.

**Template Method**: BaseCommand provides common structure while concrete commands implement specific execute methods.

### Configuration

- `config/sublayer.yml` - AI provider configuration (Gemini with gemini-1.5-flash-latest model)
- Logging configured to `log/sublayer.log` with JSON format

### External Dependencies

The application integrates with external Python tools:
- **Docling**: Document processing and conversion (requires `pip install docling`)
- **Trafilatura**: Web content extraction (requires `pip install trafilatura`)

Both tools are wrapped with Ruby DSLs providing fluent interfaces for complex operations.