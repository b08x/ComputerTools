# ACTIONS MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/actions/

## OVERVIEW

Business logic orchestration connecting commands, wrappers, and generators.

## STRUCTURE

```
actions/
├── file_activity/          # File analysis operations (5 files)
│   ├── git_analysis_action.rb         # Git diff analysis
│   ├── restic_analysis_action.rb      # Backup comparison
│   ├── yadm_analysis_action.rb        # Dotfile analysis
│   ├── latest_changes_action.rb       # Recent activity aggregation
│   └── file_discovery_action.rb      # File system scanning
├── base_action.rb        # Base class for all actions
├── shell_command_action.rb # Command execution wrapper
├── display_available_models_action.rb # AI model listing
└── mount_restic_repo_action.rb       # Backup mounting
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Add new action** | New file or `file_activity/` | Extend `BaseAction` |
| **Add file analysis** | `file_activity/` | Domain-specific analysis logic |
| **Orchestrate workflow** | Action classes | Coordinate wrappers + generators |
| **Execute shell commands** | `shell_command_action.rb` | Safe command execution |

## CONVENTIONS

- **Inheritance**: All actions extend `BaseAction`
- **Execute Method**: Main entry point via `execute(params)`
- **Dependency Injection**: Accept wrappers/generators via constructor
- **Error Handling**: Custom action-specific error classes

## ANTI-PATTERNS

- **NEVER** add CLI logic (belongs in commands/)
- **NEVER** implement tool-specific code (belongs in wrappers/)
- **NEVER** skip error handling in execute methods

## UNIQUE STYLES

- **File Activity Separation**: Dedicated subdirectory for file/backup analysis
- **Workflow Orchestration**: Actions coordinate multiple wrappers/generators
- **Base Class Foundation**: Common error handling and logging
