# WRAPPERS MODULE

**Generated:** 2026-01-15
**Location:** lib/ComputerTools/wrappers/

## OVERVIEW

External tool adapters providing unified Ruby interfaces to system utilities.

## STRUCTURE

```
wrappers/
├── git_wrapper.rb        # Git operations wrapper
├── restic_wrapper.rb     # Backup tool wrapper
├── shell_command_wrapper.rb  # Safe shell execution
├── trafilatura.rb        # Web content extraction
└── docling.rb            # Document parsing (PDF/DOCX)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Add new wrapper** | New file | Implement relevant interface |
| **Git operations** | `git_wrapper.rb` | Version control commands |
| **Backup operations** | `restic_wrapper.rb` | Mount/compare snapshots |
| **Shell execution** | `shell_command_wrapper.rb` | Safe command runner |
| **Content parsing** | `trafilatura.rb`, `docling.rb` | Web/docs extraction |

## CONVENTIONS

- **Interface Compliance**: Implement relevant interfaces from `Interfaces::`
- **Error Handling**: Wrap tool-specific errors in standard exceptions
- **Output Normalization**: Return consistent Ruby objects (not raw strings)
- **Constructor Injection**: Accept config/dependencies via constructor

## ANTI-PATTERNS

- **NEVER** execute shell commands unsafely (use `shell_command_wrapper.rb`)
- **NEVER** return raw tool output (normalize to Ruby objects)
- **NEVER** skip interface implementation

## UNIQUE STYLES

- **Interface-Based**: All wrappers implement defined contracts
- **Safe Execution**: Centralized shell command handling
- **Tool Abstraction**: Hide tool-specific quirks behind clean Ruby API
