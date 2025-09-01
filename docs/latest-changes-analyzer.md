# Latest Changes Analyzer

The Latest Changes Analyzer is a comprehensive file activity tracking system that monitors and analyzes recent modifications across version control and file systems. It provides detailed insights into your development workflow by tracking changes in Git repositories and YADM dotfiles.

## Overview

The analyzer follows a modular Sublayer architecture with dedicated components for file discovery, analysis, and reporting. It generates beautiful, color-coded reports showing file activity grouped by time periods with detailed statistics.

## Features

### Multi-Platform File Tracking
- **Git Repositories**: Analyzes committed and staged changes with diff statistics
- **YADM Dotfiles**: Tracks configuration file modifications in your home directory
- **Untracked Files**: Identifies new files not under version control

### Intelligent Analysis
- **Diff Statistics**: Lines added, removed, and number of chunks modified
- **File Status**: Index and worktree status for version-controlled files
- **Time-based Grouping**: Activity organized by hour for easy timeline analysis
- **Smart Categorization**: Automatic classification by tracking method

### Multiple Output Formats
- **Table View**: Beautiful ASCII tables with color-coded diff statistics
- **Summary View**: High-level overview with key metrics and top active files
- **JSON Export**: Machine-readable format for integration with other tools
- **Interactive Mode**: Browse files with detailed analysis and filtering options

### Advanced Configuration
- **Flexible Time Ranges**: 1h, 6h, 24h, 2d, 7d, or custom periods
- **Configurable Paths**: Customize home directory and repositories
- **Display Customization**: Configurable time formats and output preferences

## Architecture

The Latest Changes Analyzer is built using the Sublayer framework with a clean, modular architecture:

### Command Layer
- **`LatestChangesCommand`**: CLI interface and argument parsing
- Inherits from `BaseCommand` for consistent CLI behavior
- Supports both direct command usage and interactive menu integration

### Action Layer
- **`LatestChangesAction`**: Main orchestration and workflow coordination
- **`FileDiscoveryAction`**: File finding and categorization using `fd` command
- **`GitAnalysisAction`**: Git repository analysis and diff calculation
- **`YadmAnalysisAction`**: YADM dotfile tracking and status analysis

### Wrapper Layer
- **`GitWrapper`**: Git operations abstraction with error handling

### Generator Layer
- **`FileActivityReportGenerator`**: Multi-format report generation with interactive features

### Configuration
- **`Configuration`**: Centralized configuration management with interactive setup
- Stores settings in `~/.config/computertools/config.yml`

## Usage

### Command Line Interface

#### Basic Analysis
```bash
# Analyze current directory for last 24 hours
./exe/ComputerTools latestchanges

# Analyze specific directory
./exe/ComputerTools latestchanges --directory ~/projects

# Custom time range
./exe/ComputerTools latestchanges --time-range 7d

# Different output format
./exe/ComputerTools latestchanges --format summary
```

#### Advanced Options
```bash
# Interactive mode with file browsing
./exe/ComputerTools latestchanges --interactive

# JSON output for scripting
./exe/ComputerTools latestchanges --format json

# Specific time range and directory
./exe/ComputerTools latestchanges --directory ~/code --time-range 2d --format table
```

#### Configuration
```bash
# Interactive configuration setup
./exe/ComputerTools latestchanges config

# View help
./exe/ComputerTools latestchanges help
```

### Interactive Menu

Access through the main ComputerTools menu:
1. Run `./exe/ComputerTools` without arguments
2. Select "Latestchanges - Analyze recent file changes..."
3. Choose from analysis options with guided prompts

### Direct Command Usage

```bash
# All these commands work identically
./exe/ComputerTools latestchanges analyze
./exe/ComputerTools latestchanges  # analyze is default
```

## Configuration

### Initial Setup

Run the configuration setup to customize paths and preferences:

```bash
./exe/ComputerTools latestchanges config
```

This will prompt you to configure:

#### Paths
- **Home Directory**: Base directory for analysis (default: `~`)

#### Display Settings
- **Time Format**: How timestamps are displayed (default: `%Y-%m-%d %H:%M:%S`)



### Configuration File

Settings are stored in `~/.config/computertools/config.yml`:

```yaml
paths:
  home_dir: "/home/username"
display:
  time_format: "%Y-%m-%d %H:%M:%S"
```

## Output Examples

### Table Format
```
================================================================================
📊 OVERALL SUMMARY - File Activity Analysis (24h)
================================================================================
📁 Total files: 42
⏰ Hours with activity: 5
🔄 Modified files: 12
📊 Git tracked: 38
📊 YADM tracked: 3
📈 Total additions: 156
📉 Total deletions: 23

================================================================================
📅 Files Modified During: Monday, July 07, 2025 at 02:00 PM - 02:59 PM
================================================================================
╭─────────────────────────────────────────┬──────────────────┬───────┬──────────┬────────┬───────┬──────────┬────────┬────────┬────────╮
│ File Path                               │ Modified         │ Size  │ Tracking │ Status │ Index │ Worktree │ +Lines │ -Lines │ Chunks │
├─────────────────────────────────────────┼──────────────────┼───────┼──────────┼────────┼───────┼──────────┼────────┼────────┼────────┤
│ lib/ComputerTools/actions/example.rb    │ 2025-07-07 14:23 │ 2.3KB │ Git      │ M      │ Clean │ Modified │     45 │      8 │      3 │
│ docs/latest-changes-analyzer.md         │ 2025-07-07 14:45 │ 8.1KB │ Git      │ A      │ Added │ Clean    │    234 │      0 │      1 │
╰─────────────────────────────────────────┴──────────────────┴───────┴──────────┴────────┴───────┴──────────┴────────┴────────┴────────╯
```

### Summary Format
```
📊 FILE ACTIVITY SUMMARY (24h)
================================================================================
📁 Total files analyzed: 42
⏰ Active time periods: 5
🔄 Modified files: 12

📈 By tracking method:
  Git: 38
  YADM: 3
  Restic: 1

📝 Change statistics:
  + Lines added: 156
  - Lines removed: 23
  📦 Total chunks: 15

🔥 Most active files:
  1. src/main.rs (67 changes)
  2. docs/api.md (34 changes)
  3. config/settings.yml (18 changes)
```

### JSON Format
```json
{
  "metadata": {
    "generated_at": "2025-07-07T14:30:00Z",
    "time_range": "24h",
    "total_files": 42
  },
  "summary": {
    "total_files": 42,
    "hours_with_activity": 5,
    "modified_files": 12,
    "by_tracking": {
      "Git": 38,
      "YADM": 3
    },
    "total_additions": 156,
    "total_deletions": 23
  },
  "files": [
    {
      "file": "lib/example.rb",
      "modified": "2025-07-07 14:23:15",
      "size": "2.3KB",
      "tracking": "Git",
      "git_status": "M ",
      "additions": 45,
      "deletions": 8,
      "chunks": 3
    }
  ]
}
```

## Interactive Features

### File Browser
When using `--interactive` mode:
- View detailed file analysis
- Export filtered data to JSON
- Filter by tracking method
- Navigate through time periods

### Real-time Feedback
- Progress indicators during analysis
- Color-coded status messages
- Detailed error reporting with file locations
- Graceful degradation when tools are unavailable

## Dependencies

### Required Tools
- **`fd`**: Fast file discovery (install: `sudo pacman -S fd`)
- **`git`**: Git repository analysis
- **Ruby gems**: Managed through Bundler

### Optional Tools
- **`yadm`**: For dotfile tracking (install: `sudo pacman -S yadm`)

### System Requirements
- Ruby 3.0+
- Linux/Unix environment
- Terminal with color support

## Troubleshooting

### Common Issues

#### "fd command not found"
Install the `fd` package:
```bash
sudo pacman -S fd        # Arch Linux
sudo apt install fd-find # Ubuntu/Debian
brew install fd          # macOS
```

#### "No files modified"
- Check your time range with a longer period: `--time-range 7d`
- Verify the directory has recent activity
- Ensure file timestamps are recent


#### Git diff errors
- Ensure you're in a Git repository or specify a Git-tracked directory
- Check that HEAD exists (repository has commits)
- Verify file permissions for Git operations

### Debug Mode

Enable detailed error reporting:
```bash
COMPUTERTOOLS_DEBUG=true ./exe/ComputerTools latestchanges analyze
```

This provides:
- Full error backtraces
- File locations for all errors
- Detailed processing information
- Git operation details

### Error Reporting

All errors include:
- Clear error message
- File name and line number
- Suggested solutions
- Graceful fallback when possible

Example error output:
```
❌ Error analyzing Git files: undefined method 'empty?' for Git::Diff
   File: /path/to/git_wrapper.rb:45:in 'get_file_diff'
   Full backtrace:
     /path/to/git_wrapper.rb:45:in 'get_file_diff'
     /path/to/git_analysis_action.rb:23:in 'analyze_git_file'
```

## Integration

### Scripting
Use JSON format for integration with other tools:
```bash
./exe/ComputerTools latestchanges --format json > activity.json
```

### CI/CD Pipelines
Monitor development activity:
```bash
# Check for recent changes
if ./exe/ComputerTools latestchanges --time-range 1h --format json | jq -r '.summary.total_files' -gt 0; then
  echo "Recent development activity detected"
fi
```

### Development Workflow
- **Daily standups**: `latestchanges --time-range 24h --format summary`
- **Sprint reviews**: `latestchanges --time-range 7d --interactive`
- **Code archaeology**: `latestchanges --directory old_project --time-range 30d`

## Performance

### Optimization Tips
- Use shorter time ranges for faster analysis
- Exclude large directories with many files
- Use summary format for quick overviews

### Scalability
- Handles repositories with thousands of files
- Efficient file discovery using `fd`
- Lazy-loaded Git operations
- Configurable timeouts prevent hanging

## Security Considerations

- Configuration file stores paths, not credentials
- Restic passphrase handled by external terminal
- No network operations performed
- Read-only analysis of local files
- Safe handling of file paths with special characters

## Future Enhancements

Planned features for future releases:
- Integration with additional VCS systems (SVN, Mercurial)
- Web-based dashboard for team activity
- Notification system for significant changes
- Integration with project management tools
- Performance metrics and benchmarking
- Customizable report templates