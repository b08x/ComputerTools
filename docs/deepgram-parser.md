# Deepgram Parser

Parse, analyze, and convert Deepgram JSON output with AI-enhanced insights and multiple output formats.

## Overview

The Deepgram Parser is a comprehensive tool for processing Deepgram speech-to-text JSON output. It provides parsing, analysis, and conversion capabilities with AI-powered enhancements through the Sublayer framework.

## Features

- 🎙️ **Multi-Format Output**: Parse to markdown, SRT, JSON, and summary formats
- 🔍 **Interactive Analysis**: TTY-powered interface for analyzing segments
- 🤖 **AI Integration**: Generate summaries, insights, and enhanced topic detection
- 📊 **Statistics & Metrics**: Detailed content analysis and confidence scoring
- ⚙️ **Configurable**: YAML-based configuration with multiple output options
- 🎯 **Segment Analysis**: Handle analyzed segments with field selection and filtering

## Quick Start

### Basic Usage

```bash
# Parse a Deepgram JSON file to markdown
exe/ComputerTools deepgram parse transcript.json

# Parse with specific format and console output
exe/ComputerTools deepgram parse transcript.json summary --console

# Convert to SRT subtitles
exe/ComputerTools deepgram convert transcript.json srt

# Interactive analysis of segments
exe/ComputerTools deepgram analyze segments.json --interactive
```

### Configuration Setup

```bash
# Create default configuration
exe/ComputerTools deepgram config setup

# View current configuration
exe/ComputerTools deepgram config show

# Edit configuration
exe/ComputerTools deepgram config edit
```

## Commands

### Parse Command

Parse Deepgram JSON output into various formats.

```bash
exe/ComputerTools deepgram parse <json_file> [format] [--console]
```

**Arguments:**

- `json_file`: Path to Deepgram JSON output file
- `format`: Output format (markdown, srt, json, summary) - defaults to markdown
- `--console`: Display output in console instead of saving to file

**Examples:**

```bash
# Basic parsing to markdown
exe/ComputerTools deepgram parse interview.json

# Parse to summary format with console output
exe/ComputerTools deepgram parse interview.json summary --console

# Parse to SRT format
exe/ComputerTools deepgram parse interview.json srt
```

### Convert Command

Convert Deepgram JSON to specific formats.

```bash
exe/ComputerTools deepgram convert <json_file> [format] [--console]
```

**Arguments:**

- `json_file`: Path to Deepgram JSON output file
- `format`: Target format (markdown, srt, json, summary) - defaults to srt
- `--console`: Display output in console instead of saving to file

**Examples:**

```bash
# Convert to SRT subtitles
exe/ComputerTools deepgram convert meeting.json srt

# Convert to summary with console output
exe/ComputerTools deepgram convert meeting.json summary --console
```

### Analyze Command

Analyze Deepgram segments with interactive field selection and filtering.

```bash
exe/ComputerTools deepgram analyze <json_file> [--interactive]
```

**Arguments:**

- `json_file`: Path to analyzed segments JSON file
- `--interactive`: Enable interactive mode with prompts and selections

**Examples:**

```bash
# Automatic analysis showing all fields
exe/ComputerTools deepgram analyze analyzed_segments.json

# Interactive analysis with field selection
exe/ComputerTools deepgram analyze analyzed_segments.json --interactive
```

### Config Command

Manage Deepgram Parser configuration.

```bash
exe/ComputerTools deepgram config [show|setup|edit|reset]
```

**Subcommands:**

- `show`: Display current configuration (default)
- `setup`: Create default configuration file
- `edit`: Open configuration in editor
- `reset`: Reset configuration to defaults

## Output Formats

### Markdown Format

Rich analysis with organized sections including:

- Full transcript
- Timestamped paragraphs
- Detected intents with time ranges
- Identified topics
- Word confidence scores
- Segmented sentences

**Example Output:**

```markdown
# Deepgram Analysis Results

## Full Transcript
This is the complete transcript of the audio...

## Paragraphs
### 00:01:23 -> 00:01:45
First paragraph with timestamps...

## Intents
- 00:01:23 -> 00:01:30: question
- 00:02:15 -> 00:02:20: request

## Topics
- software development
- project management
```

### SRT Format

Standard subtitle format compatible with video players:

```srt
1
00:00:00,000 --> 00:00:05,000
First subtitle line here.

2
00:00:05,000 --> 00:00:10,000
Second subtitle line here.
```

### JSON Format

Structured data output including all parsed information:

```json
{
  "transcript": "Full transcript text...",
  "paragraphs": [...],
  "intents": [...],
  "topics": [...],
  "words_with_confidence": [...],
  "summary_stats": {...}
}
```

### Summary Format

Concise overview with key statistics:

```
📊 Deepgram Analysis Summary
============================

📝 Content Overview:
• Total Words: 1,234
• Total Sentences: 67
• Total Paragraphs: 12
• Transcript Length: 5,678 characters

🏷️  Topics Identified: 5
   • software development
   • team collaboration
   • project planning

🎯 Intents Detected: 8
   • question
   • request
   • confirmation

⏱️  Duration: 00:05:23
```

## Interactive Analysis

The analyze command provides an interactive interface for exploring analyzed segments:

### Field Selection

Choose which fields to display from analyzed segments:

- Segment Identifier
- Start/End Time of Segment
- Segment Transcript
- Segment Topic
- Relevant Keywords
- AI Analysis of Segment
- Software Detected in Segment
- List of Software Detections

### Filtering Options

Filter segments by:

- **Topic**: Show segments related to specific topics
- **Software**: Filter by detected software/tools
- **Custom Fields**: Display selected field combinations

### Export Capabilities

Export analysis results in multiple formats:

- **JSON**: Structured data for further processing
- **Markdown**: Human-readable documentation
- **CSV**: Tabular data for spreadsheet analysis

## Configuration

The Deepgram Parser uses YAML configuration located at `lib/ComputerTools/config/deepgram.yml`.

### Configuration Structure

```yaml
# Output format preferences
output:
  default_format: "markdown"     # Default: markdown, srt, json, summary
  auto_timestamp: true           # Include timestamps in output
  include_confidence: true       # Include confidence scores

# AI integration settings
ai:
  provider: "gemini"            # AI provider: gemini, openai
  model: "gemini-1.5-flash-latest"
  enable_insights: true         # Generate AI insights
  enable_summaries: true        # Generate AI summaries
  enable_enhanced_topics: true  # Enhanced topic detection

# Format-specific settings
formats:
  srt:
    include_milliseconds: true  # Include milliseconds in timestamps
    line_length: 42            # Maximum characters per line
    
  markdown:
    include_stats: true        # Include summary statistics
    include_metadata: true     # Include file metadata
```

### Configuration Management

```bash
# Create default configuration
exe/ComputerTools deepgram config setup

# View current settings
exe/ComputerTools deepgram config show

# Edit configuration file
exe/ComputerTools deepgram config edit

# Reset to defaults
exe/ComputerTools deepgram config reset
```

## AI-Powered Features

### Summary Generation

Generate comprehensive summaries using AI:

```ruby
# Available through Sublayer integration
ComputerTools::Generators::DeepgramSummaryGenerator.new(
  transcript: transcript_text,
  topics: detected_topics,
  intents: detected_intents
).generate
```

### Insights Analysis

Extract strategic insights and patterns:

```ruby
# Strategic analysis capabilities
ComputerTools::Generators::DeepgramInsightsGenerator.new(
  transcript: transcript_text,
  topics: detected_topics,
  intents: detected_intents,
  context: additional_context
).generate
```

### Enhanced Topic Detection

Improve topic identification beyond basic keywords:

```ruby
# Enhanced topic extraction
ComputerTools::Generators::DeepgramTopicsGenerator.new(
  transcript: transcript_text,
  existing_topics: deepgram_topics
).generate
```

## Architecture

The Deepgram Parser follows the modular ComputerTools architecture:

```
lib/ComputerTools/
├── commands/
│   └── deepgram_command.rb          # CLI interface
├── actions/
│   ├── deepgram_parse_action.rb     # Core parsing logic
│   ├── deepgram_analyze_action.rb   # Segment analysis
│   ├── deepgram_convert_action.rb   # Format conversion
│   └── deepgram_config_action.rb    # Configuration management
├── wrappers/
│   ├── deepgram_parser.rb           # JSON parsing wrapper
│   ├── deepgram_formatter.rb        # Output formatting
│   └── deepgram_analyzer.rb         # Segment analysis wrapper
├── generators/
│   ├── deepgram_summary_generator.rb    # AI summaries
│   ├── deepgram_insights_generator.rb   # Strategic insights
│   └── deepgram_topics_generator.rb     # Enhanced topics
└── config/
    └── deepgram.yml                 # Configuration file
```

### Design Patterns

- **Command Pattern**: CLI commands with clear interfaces
- **Wrapper Pattern**: External JSON processing with fluent interfaces
- **Generator Pattern**: AI-powered content generation
- **Action Pattern**: Encapsulated business logic

## Input Formats

### Standard Deepgram JSON

Regular Deepgram speech-to-text output:

```json
{
  "results": {
    "channels": [
      {
        "alternatives": [
          {
            "transcript": "Complete transcript...",
            "words": [...],
            "paragraphs": {
              "paragraphs": [...]
            }
          }
        ]
      }
    ],
    "topics": {
      "segments": [...]
    },
    "intents": {
      "segments": [...]
    }
  }
}
```

### Analyzed Segments JSON

Enhanced segments with additional analysis:

```json
[
  {
    "segment_id": "1",
    "start_time": "00:01:23",
    "end_time": "00:01:45",
    "transcript": "Segment transcript...",
    "topic": "software development",
    "keywords": ["code", "development", "testing"],
    "gemini_analysis": "AI analysis of this segment...",
    "software_detected": "Python",
    "software_detections": ["Python", "Git", "Docker"]
  }
]
```

## Error Handling

The parser includes comprehensive error handling:

- **File Validation**: Checks for file existence and accessibility
- **JSON Validation**: Validates JSON structure and content
- **Format Validation**: Ensures supported output formats
- **Graceful Degradation**: Continues processing when optional data is missing
- **Detailed Error Messages**: Clear feedback for troubleshooting

## Performance Considerations

- **Streaming Support**: Handles large transcript files efficiently
- **Memory Management**: Optimized for processing large JSON files
- **Caching**: Optional caching for AI responses
- **Batch Processing**: Support for multiple file processing

## Troubleshooting

### Common Issues

1. **Invalid JSON Format**
   - Ensure the file contains valid Deepgram JSON output
   - Check for truncated or corrupted files

2. **Missing Required Fields**
   - Some features require specific Deepgram API features to be enabled
   - Check that your Deepgram configuration includes topics and intents

3. **AI Generation Errors**
   - Ensure GEMINI_API_KEY environment variable is set
   - Check internet connectivity for AI provider access

4. **Permission Errors**
   - Verify read permissions on input files
   - Ensure write permissions for output directory

### Debug Mode

Enable debug output for troubleshooting:

```bash
DEBUG=1 exe/ComputerTools deepgram parse transcript.json
```

## Integration Examples

### With Video Processing

```bash
# Convert Deepgram output to SRT for video subtitles
exe/ComputerTools deepgram convert meeting_transcript.json srt
# Output: meeting_transcript.srt ready for video players
```

### With Documentation Workflow

```bash
# Generate markdown documentation from meeting transcript
exe/ComputerTools deepgram parse meeting_transcript.json markdown
# Output: meeting_transcript_analysis.md with full analysis
```

### With Data Analysis

```bash
# Export structured data for further analysis
exe/ComputerTools deepgram analyze segments.json --interactive
# Choose CSV export for spreadsheet analysis
```

## Migration from Standalone Script

If migrating from the previous standalone `deepgram_parser.rb` script:

### Command Equivalents

**Old Script:**

```bash
ruby deepgram_parser.rb transcript.json --srt --console
```

**New CLI:**

```bash
exe/ComputerTools deepgram convert transcript.json srt --console
```

### Feature Mapping

| Old Script Feature | New CLI Command |
|-------------------|----------------|
| Basic parsing | `deepgram parse` |
| SRT output | `deepgram convert file.json srt` |
| Console output | `--console` flag |
| Analyzed segments | `deepgram analyze` |
| GUI file selection | Interactive mode with `--interactive` |

### Enhanced Features

The new CLI provides additional capabilities not available in the standalone script:

- AI-powered summaries and insights
- Enhanced topic detection
- Configuration management
- Multiple export formats
- Interactive analysis interface
- Integration with ComputerTools ecosystem

## Getting Help

```bash
# General help
exe/ComputerTools deepgram help

# Command-specific help
exe/ComputerTools help deepgram

# Show available formats and options
exe/ComputerTools deepgram convert
```

For additional support and examples, refer to the main ComputerTools documentation.
