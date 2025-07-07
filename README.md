# ComputerTools

A comprehensive Ruby CLI toolkit built on the Sublayer framework, providing AI-enhanced tools for software development and automation.

## 🚀 Overview

ComputerTools is a modular collection of intelligent CLI utilities that leverage AI capabilities through the Sublayer framework. Each tool is designed to streamline common development workflows with smart automation and semantic understanding.

### 🎯 Interactive Menu System

For easy discovery and usage, ComputerTools provides an interactive menu system:

```bash
# Launch interactive menu
./exe/ComputerTools

# Traditional CLI usage still works
./exe/ComputerTools blueprint submit my_file.rb
```

The interactive menu guides you through all available commands with parameter prompts and format selections. **📖 For complete details, see [Interactive Menu Documentation](docs/interactive-menu.md)**

## 🛠️ Available Tools

### 📋 Blueprint Manager

AI-enhanced code blueprint management with semantic search and automatic metadata generation.

**Quick Start:**

```bash
# Submit a code blueprint
exe/ComputerTools blueprint submit my_script.rb

# Search semantically
exe/ComputerTools blueprint search "authentication helper"

# Interactive browser
exe/ComputerTools blueprint browse

# View with AI analysis
exe/ComputerTools blueprint view 123 --analyze
```

**📖 For complete setup instructions, features, and Rails server integration, see [Blueprint Manager Documentation](docs/blueprint-manager.md)**

### 🎙️ Deepgram Parser

Parse, analyze, and convert Deepgram JSON output with AI-enhanced insights and multiple output formats.

**Quick Start:**

```bash
# Parse Deepgram JSON to markdown
exe/ComputerTools deepgram parse transcript.json

# Convert to SRT subtitles
exe/ComputerTools deepgram convert transcript.json srt --console

# Interactive segment analysis
exe/ComputerTools deepgram analyze segments.json --interactive

# Configuration setup
exe/ComputerTools deepgram config setup
```

**📖 For detailed usage, formats, and AI features, see [Deepgram Parser Documentation](docs/deepgram-parser.md)**

### 📊 Latest Changes Analyzer

Comprehensive file activity tracking across Git, YADM, and Restic with intelligent analysis and beautiful reporting.

**Quick Start:**

```bash
# Analyze recent changes (last 24h)
exe/ComputerTools latestchanges

# Custom time range and format
exe/ComputerTools latestchanges --time-range 7d --format summary

# Interactive file browser
exe/ComputerTools latestchanges --interactive

# Configure tracking preferences
exe/ComputerTools latestchanges config
```

**📖 For complete setup, configuration, and multi-platform tracking, see [Latest Changes Documentation](docs/latest-changes-analyzer.md)**

### 🔧 Additional Tools

*More AI-powered development tools coming soon*

## 📦 Installation

### Prerequisites

- Ruby 3.4+
- PostgreSQL with pgvector extension (for blueprint management)
- Google Gemini API key (for AI features)
- Additional tools for latest changes analysis:
  - `fd` command (file discovery)
  - `git` (repository analysis)
  - `yadm` (optional, for dotfile tracking)
  - `restic` (optional, for backup comparison)

### Setup

```bash
# Install dependencies
bundle install

# Configure the blueprint database (if using blueprint tools)
exe/ComputerTools blueprint config setup

# Configure latest changes analyzer (if using tracking tools)
exe/ComputerTools latestchanges config

# Set required environment variables
export GEMINI_API_KEY="your_gemini_api_key"
export BLUEPRINT_DATABASE_URL="postgresql://user:pass@host:port/database"
```

## 💻 Usage

ComputerTools supports two usage modes:

### Interactive Mode (Recommended for Discovery)

```bash
# Launch the interactive menu
./exe/ComputerTools

# Enable debug mode for troubleshooting
COMPUTERTOOLS_DEBUG=true ./exe/ComputerTools
```

Navigate through menus to discover and execute commands with guided parameter collection.

### Command Line Mode (Ideal for Automation)

```bash
# Direct command execution
./exe/ComputerTools blueprint submit my_script.rb
./exe/ComputerTools deepgram parse transcript.json markdown --console
./exe/ComputerTools latestchanges --time-range 7d --format summary
./exe/ComputerTools help

# Get help for specific commands
./exe/ComputerTools blueprint help
./exe/ComputerTools deepgram help
./exe/ComputerTools latestchanges help
```

## 🏗️ Architecture

```mermaid
graph TB
    CLI[ComputerTools CLI] --> Thor[Thor Framework]
    Thor --> Commands[Command Classes]
    
    Commands --> Actions[Action Classes]
    Actions --> Wrappers[Database/API Wrappers]
    Actions --> Generators[AI Generators]
    
    Generators --> Sublayer[Sublayer Framework]
    Sublayer --> Gemini[Google Gemini API]
    
    Wrappers --> DB[(PostgreSQL + pgvector)]
    Wrappers --> External[External Tools]
    
    subgraph "Blueprint Tool Architecture"
        BCmd[BlueprintCommand] --> BActions[Blueprint Actions]
        BActions --> BDB[BlueprintDatabase]
        BActions --> BGen[Blueprint Generators]
        
        BDB --> Postgres[(PostgreSQL)]
        BGen --> AI[AI Providers]
        
        BGen --> DescGen[Description Generator]
        BGen --> CatGen[Category Generator] 
        BGen --> NameGen[Name Generator]
        BGen --> ImpGen[Improvement Generator]
    end
```

### Core Design Principles

1. **Modular Architecture**: Each tool follows the same pattern with Commands, Actions, Generators, and Wrappers
2. **AI Integration**: Sublayer framework provides consistent AI capabilities across all tools
3. **Database Direct**: Efficient operations through direct database connections
4. **Framework Consistency**: Thor CLI integration with automatic command registration
5. **Configuration Management**: YAML-based configuration with environment variable support

## 🔧 Configuration

### Global Configuration

Configuration is managed through YAML files in `lib/ComputerTools/config/`:

```yaml
# Example: blueprints.yml
database:
  url: "postgresql://localhost/blueprints_development"

ai:
  provider: "gemini"
  model: "text-embedding-004"

features:
  auto_description: true
  auto_categorize: true
  improvement_analysis: true
```

### Environment Variables

```bash
# AI Provider Keys
GEMINI_API_KEY=your_gemini_key
OPENAI_API_KEY=your_openai_key

# Database Connections
BLUEPRINT_DATABASE_URL=postgresql://...

# Editor Preferences  
EDITOR=vim
VISUAL=code
```

## 📚 Usage Examples

### Blueprint Management Workflow

```bash
# 1. Submit a new blueprint with auto-generated metadata
exe/ComputerTools blueprint submit app/models/user.rb

# 2. Search for similar blueprints
exe/ComputerTools blueprint search "user authentication model"

# 3. View with AI improvement suggestions
exe/ComputerTools blueprint view 42 --analyze

# 4. Edit with automatic re-embedding
exe/ComputerTools blueprint edit 42

# 5. Export for sharing
exe/ComputerTools blueprint export 42 user_model.rb
```

### Interactive Mode

```bash
# Launch interactive blueprint browser
exe/ComputerTools blueprint browse

# Interactive configuration setup
exe/ComputerTools blueprint config setup
```

## 🧪 Development

### Testing

```bash
# Run the full test suite
bundle exec rspec

# Run specific tests
bundle exec rspec spec/path/to/specific_spec.rb
```

### Code Quality

```bash
# Lint with RuboCop
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop --autocorrect
```

### Documentation

```bash
# Generate documentation
bundle exec yard doc

# Start documentation server
bundle exec yard server
```

## 🎯 Key Features

### AI-Powered Intelligence

- **Automatic Metadata Generation**: Smart names, descriptions, and categories
- **Semantic Search**: Find code by meaning, not just keywords
- **Improvement Suggestions**: AI analysis for code quality enhancement
- **Language Detection**: Automatic programming language identification

### Developer Experience

- **Interactive CLI**: Rich TTY interface with colors and prompts
- **Multiple Output Formats**: JSON, table, summary views
- **Flexible Configuration**: YAML files + environment variables
- **Comprehensive Help**: Built-in documentation and examples

### Performance & Reliability

- **Direct Database Access**: No HTTP overhead for local operations
- **Vector Embeddings**: Efficient semantic search with pgvector
- **Connection Pooling**: Optimized database connections
- **Error Handling**: Graceful degradation and helpful error messages

## 🚦 Roadmap

### Phase 1: Foundation ✅

- [x] Blueprint management system
- [x] AI-powered metadata generation
- [x] Semantic search with vector embeddings
- [x] Interactive CLI interface

### Phase 2: Expansion ✅

- [x] Latest changes analyzer with multi-platform tracking
- [x] Deepgram audio transcription processing
- [ ] Code analysis and refactoring tools
- [ ] Documentation generation utilities
- [ ] Test automation helpers

### Phase 3: Intelligence 📋

- [ ] Multi-language support
- [ ] Advanced code understanding
- [ ] Automated code review
- [ ] Performance optimization suggestions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-tool`)
3. Follow the established patterns in `/lib/ComputerTools/`
4. Add comprehensive tests
5. Ensure RuboCop compliance (`bundle exec rubocop`)
6. Submit a pull request

### Adding New Tools

Each new tool should follow the modular pattern:

```
lib/ComputerTools/
├── commands/your_tool_command.rb     # CLI interface
├── actions/your_tool_*.rb            # Business logic
├── generators/your_tool_*.rb         # AI integration
├── wrappers/your_tool_*.rb           # External integrations
└── config/your_tool.yml              # Configuration
```

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- **Sublayer Framework**: For providing the AI integration foundation
- **Thor**: For robust CLI framework capabilities  
- **pgvector**: For efficient vector operations in PostgreSQL
- **TTY Toolkit**: For rich terminal user interfaces
- **Google Gemini**: For powerful AI language model capabilities

---

**ComputerTools** - Making development workflows smarter, faster, and more intuitive through AI-powered automation.
