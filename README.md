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
./exe/ComputerTools deepgram parse transcript.json
```

The interactive menu guides you through all available commands with parameter prompts and format selections. **📖 For complete details, see [Interactive Menu Documentation](docs/interactive-menu.md)**

## 🛠️ Available Tools

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

Comprehensive file activity tracking across Git and YADM with intelligent analysis and beautiful reporting.

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

#### 🤖 AI Model Management
List and manage available AI models across different providers:

```bash
# List all available models
exe/ComputerTools listmodels

# Interactive model browser
exe/ComputerTools listmodels --interactive
```


#### 🎬 Media Processing (FFmpeg Integration)
*FFmpeg wrapper functionality for media processing tasks*

*More AI-powered development tools coming soon*

## 📦 Installation

### Prerequisites

- Ruby 2.6+ (Ruby 3.0+ recommended)
- Google Gemini API key (for AI features)
- Additional tools for enhanced functionality:
  - `fd` command (file discovery for latest changes analysis)
  - `git` (repository analysis)
  - `yadm` (optional, for dotfile tracking)
    - `ffmpeg` (optional, for media processing features)
- PostgreSQL with pgvector extension (optional, for semantic search features)

### Setup

```bash
# Install dependencies
bundle install

# Configure latest changes analyzer (if using tracking tools)
exe/ComputerTools latestchanges config

# Set required environment variables
export GEMINI_API_KEY="your_gemini_api_key"
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
./exe/ComputerTools deepgram parse transcript.json markdown --console
./exe/ComputerTools latestchanges --time-range 7d --format summary
./exe/ComputerTools help

# Get help for specific commands
./exe/ComputerTools deepgram help
./exe/ComputerTools latestchanges help
```

## 🏗️ Architecture

```mermaid
graph TB
    CLI[ComputerTools CLI] --> Thor[Thor Framework]
    Thor --> Commands[Command Classes]
    
    Commands --> Actions[Action Classes]
    Actions --> Wrappers[External Tool Wrappers]
    Actions --> Generators[AI Generators]
    
    Generators --> Sublayer[Sublayer Framework]
    Sublayer --> Gemini[Google Gemini API]
    
    Wrappers --> External[External Tools]
    
    subgraph "Latest Changes Architecture"
        LCCmd[LatestChangesCommand] --> LCActions[File Activity Actions]
        LCActions --> GitWrapper[GitWrapper]
        LCActions --> YadmWrapper[YADM Analysis]
        LCActions --> FileDiscovery[File Discovery]
    end
```

### Core Design Principles

1. **Modular Architecture**: Each tool follows the same pattern with Commands, Actions, Generators, and Wrappers
2. **AI Integration**: Sublayer framework provides consistent AI capabilities across all tools
3. **Process Management**: Open3 for robust external process handling (especially for restic mounting)
4. **Framework Consistency**: Thor CLI integration with automatic command registration
5. **Configuration Management**: YAML-based configuration with environment variable support

## 🔧 Configuration

### Global Configuration

Configuration is managed through YAML files in `lib/ComputerTools/config/`:

```yaml
# Example: deepgram.yml
api:
  key: "your_deepgram_api_key"
  base_url: "https://api.deepgram.com"

output:
  default_format: "markdown"
  console_output: true
  
features:
  auto_analysis: true
  topic_extraction: true
  summary_generation: true
```

### User Configuration

User-specific settings are stored in `~/.config/computertools/config.yml`:

```yaml
# User configuration example
paths:
  home_dir: "/home/user"

display:
  time_format: "%Y-%m-%d %H:%M:%S"

terminal:
  command: "kitty"
  args: "-e"

logger:
  level: "info"           # Console log level: debug, info, warn, error
  file_logging: false     # Enable file logging
  file_path: "~/.local/state/computertools/app.log"
  file_level: "debug"     # File log level (more verbose than console)
```

### Environment Variables

```bash
# AI Provider Keys
GEMINI_API_KEY=your_gemini_key
OPENAI_API_KEY=your_openai_key

# Deepgram API
DEEPGRAM_API_KEY=your_deepgram_key


# Database Configuration (for blueprint/semantic search features)
DATABASE_URL=postgresql://user:pass@localhost/computertools

# Editor Preferences  
EDITOR=vim
VISUAL=code

# Logger Configuration (optional)
COMPUTERTOOLS_LOG_LEVEL=debug
COMPUTERTOOLS_LOG_FILE_ENABLED=true
COMPUTERTOOLS_LOG_FILE_PATH=/path/to/app.log
COMPUTERTOOLS_LOG_FILE_LEVEL=debug
```

## 📝 Logging System

ComputerTools features a unified logging system that preserves the rich emoji-driven UI while providing professional debugging capabilities.

### Quick Setup

```bash
# Configure logging interactively
exe/ComputerTools config setup

# Or configure just logging
exe/ComputerTools config edit
# Select "📝 Logger settings"
```

### Logging Features

- **Rich Console Output**: Emoji-enhanced messages with colors
- **File Logging**: Structured JSON logs for analysis
- **Configurable Levels**: Control verbosity per output destination
- **Structured Data**: Key-value pairs for better debugging
- **Exception Handling**: Clean user messages + detailed debug traces

### Log Types

| Type | Symbol | Usage |
|------|--------|--------|
| `success` | ✅ | Operation completed successfully |
| `failure` | ❌ | Critical errors that halt operations |
| `warning` | ⚠️ | Non-critical issues or warnings |
| `tip` | 💡 | Helpful guidance for users |
| `step` | 🚀 | Major process steps or milestones |
| `info` | ℹ️ | General informational messages |
| `debug` | 🐞 | Verbose diagnostic information |

### Usage Examples

```bash
# View current logging configuration
exe/ComputerTools config show

# Set console logging to debug level
COMPUTERTOOLS_LOG_LEVEL=debug exe/ComputerTools deepgram parse transcript.json

# Enable file logging for troubleshooting
COMPUTERTOOLS_LOG_FILE_ENABLED=true exe/ComputerTools latestchanges --time-range 7d

# Configure persistent logging settings
exe/ComputerTools config edit

# List available AI models with debug logging
COMPUTERTOOLS_LOG_LEVEL=debug exe/ComputerTools listmodels


### Log File Location

By default, log files are written to:
- **Linux/macOS**: `~/.local/state/computertools/app.log`
- **Custom Path**: Configurable via settings or environment variables

### Structured Logging

All log messages support structured data for better analysis:

```ruby
# Example: Internal API calls include context
ComputerTools.logger.success("Transcript processed", file: "audio.json", format: "markdown")
ComputerTools.logger.failure("Restic mount failed", error: "timeout", retry_count: 3)
```

This produces JSON output in log files:
```json
{"level":"info","message":"Transcript processed","file":"audio.json","format":"markdown","timestamp":"2024-01-01T10:30:00Z"}
{"level":"error","message":"Restic mount failed","error":"timeout","retry_count":3,"timestamp":"2024-01-01T10:30:05Z"}
```

## 📚 Usage Examples

### Deepgram Processing Workflow

```bash
# 1. Parse Deepgram JSON output
exe/ComputerTools deepgram parse transcript.json

# 2. Convert to different formats
exe/ComputerTools deepgram convert transcript.json srt --console

# 3. Analyze segments with AI
exe/ComputerTools deepgram analyze segments.json --interactive

# 4. Generate summaries and insights
exe/ComputerTools deepgram parse transcript.json --format summary
```

### Latest Changes Analysis Workflow

```bash
# 1. Analyze recent changes across all sources
exe/ComputerTools latestchanges --time-range 24h

# 2. Focus on specific file types
exe/ComputerTools latestchanges --format summary --interactive


# 5. List available AI models and providers
exe/ComputerTools listmodels --format table
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

- **Transcript Analysis**: Smart parsing of Deepgram JSON output
- **Content Summarization**: AI-generated summaries and insights
- **Topic Extraction**: Automatic identification of key themes
- **Format Conversion**: Multiple output formats (markdown, SRT, plain text)

### Developer Experience

- **Interactive CLI**: Rich TTY interface with colors and prompts
- **Multiple Output Formats**: JSON, table, summary views
- **Flexible Configuration**: YAML files + environment variables
- **Comprehensive Help**: Built-in documentation and examples

### Performance & Reliability

- **Process Management**: Robust Open3-based external process handling
- **Multi-source Analysis**: Efficient tracking across Git and YADM
- **Error Handling**: Graceful degradation and helpful error messages

## 🚦 Roadmap

### Phase 1: Foundation ✅

- [x] Interactive CLI interface with Thor framework
- [x] Modular architecture with Commands, Actions, Generators, and Wrappers
- [x] AI integration through Sublayer framework
- [x] Comprehensive logging system

### Phase 2: Core Tools ✅

- [x] Latest changes analyzer with multi-platform tracking
- [x] Deepgram audio transcription processing
- [x] Configuration management system
- [x] AI model management and listing
- [ ] FFmpeg media processing wrapper (in development)
- [ ] Code analysis and refactoring tools
- [ ] Documentation generation utilities

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
├── config/your_tool.yml              # Configuration
└── container/registrations.rb        # Dependency injection
```

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- **Sublayer Framework**: For providing the AI integration foundation
- **Thor**: For robust CLI framework capabilities  
- **TTY Toolkit**: For rich terminal user interfaces
- **Google Gemini**: For powerful AI language model capabilities
- **Open3**: For reliable external process management

---

**ComputerTools** - Making development workflows smarter, faster, and more intuitive through AI-powered automation.
