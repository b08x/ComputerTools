# Component-to-Configuration Mapping

## Overview

This document provides a detailed mapping of which components use which configuration sections, enabling informed decisions about configuration refactoring.

## Configuration Usage by Component

### Infrastructure Components

| Component | File | Config Sections | Keys Used | Usage Pattern |
|-----------|------|-----------------|-----------|---------------|
| **Logger** | `lib/ComputerTools/logger.rb` | `:logger` | `:level`, `:file_logging`, `:file_path`, `:file_level` | Direct instantiation, singleton |
| **Container** | `lib/ComputerTools/container.rb` | None | N/A | Registers Configuration as dependency |
| **Main Module** | `lib/ComputerTools.rb` | None | N/A | Provides access to container |

### Wrapper Components

| Component | File | Config Sections | Keys Used | Usage Pattern |
|-----------|------|-----------------|-----------|---------------|
| **ResticWrapper** | `lib/ComputerTools/wrappers/restic_wrapper.rb` | `:paths`, `:restic`, `:terminal` | `:restic_mount_point`, `:restic_repo`, `:home_dir`, `:mount_timeout`, `:command`, `:args` | Constructor injection from container |
| **GitWrapper** | `lib/ComputerTools/wrappers/git_wrapper.rb` | None | None | No configuration usage |
| **BlueprintDatabase** | `lib/ComputerTools/wrappers/blueprint_database.rb` | None | None | No configuration usage |
| **Docling** | `lib/ComputerTools/wrappers/docling.rb` | None | None | No configuration usage |
| **Trafilatura** | `lib/ComputerTools/wrappers/trafilatura.rb` | None | None | No configuration usage |
| **DeepgramParser** | `lib/ComputerTools/wrappers/deepgram_parser.rb` | None | None | No configuration usage |
| **DeepgramAnalyzer** | `lib/ComputerTools/wrappers/deepgram_analyzer.rb` | None | None | No configuration usage |
| **DeepgramFormatter** | `lib/ComputerTools/wrappers/deepgram_formatter.rb` | None | None | No configuration usage |

### Action Components

| Component | File | Config Sections | Keys Used | Usage Pattern |
|-----------|------|-----------------|-----------|---------------|
| **LatestChangesAction** | `lib/ComputerTools/actions/file_activity/latest_changes_action.rb` | All sections | All keys | Direct instantiation |
| **FileDiscoveryAction** | `lib/ComputerTools/actions/file_activity/file_discovery_action.rb` | `:paths` | `:home_dir` | Direct instantiation |
| **GitAnalysisAction** | `lib/ComputerTools/actions/file_activity/git_analysis_action.rb` | None | None | No configuration usage |
| **ResticAnalysisAction** | `lib/ComputerTools/actions/file_activity/restic_analysis_action.rb` | None | None | No configuration usage |
| **YadmAnalysisAction** | `lib/ComputerTools/actions/file_activity/yadm_analysis_action.rb` | None | None | No configuration usage |
| **Blueprint Actions** | `lib/ComputerTools/actions/blueprint/*.rb` | None | None | No configuration usage |
| **Deepgram Actions** | `lib/ComputerTools/actions/deepgram/*.rb` | None | None | No configuration usage |

### Command Components

| Component | File | Config Sections | Keys Used | Usage Pattern |
|-----------|------|-----------------|-----------|---------------|
| **ConfigCommand** | `lib/ComputerTools/commands/config_command.rb` | All sections | All keys | Direct instantiation for setup |
| **LatestChangesCommand** | `lib/ComputerTools/commands/latest_changes_command.rb` | All sections | All keys | Direct instantiation for setup |
| **DeepgramCommand** | `lib/ComputerTools/commands/deepgram_command.rb` | All sections | All keys | Direct instantiation for setup |
| **BlueprintCommand** | `lib/ComputerTools/commands/blueprint_command.rb` | None | None | No configuration usage |
| **OverviewCommand** | `lib/ComputerTools/commands/overview_command.rb` | None | None | No configuration usage |
| **MenuCommand** | `lib/ComputerTools/commands/menu_command.rb` | None | None | No configuration usage |
| **BaseCommand** | `lib/ComputerTools/commands/base_command.rb` | None | None | No configuration usage |

### Generator Components

| Component | File | Config Sections | Keys Used | Usage Pattern |
|-----------|------|-----------------|-----------|---------------|
| **FileActivityReportGenerator** | `lib/ComputerTools/generators/file_activity/*.rb` | `:display` | `:time_format` | Constructor injection |
| **Blueprint Generators** | `lib/ComputerTools/generators/blueprint/*.rb` | None | None | No configuration usage |
| **Deepgram Generators** | `lib/ComputerTools/generators/deepgram/*.rb` | None | None | No configuration usage |
| **OverviewGenerator** | `lib/ComputerTools/generators/overview_generator.rb` | None | None | No configuration usage |

## Configuration Section Usage Summary

### `:logger` Section
**Used By**: Logger module (1 component)
**Keys**: `:level`, `:file_logging`, `:file_path`, `:file_level`
**Usage**: Singleton logger configuration

### `:paths` Section
**Used By**: ResticWrapper, FileDiscoveryAction, LatestChangesAction (3 components)
**Keys**: `:home_dir`, `:restic_mount_point`, `:restic_repo`
**Usage**: File system operations and path resolution

### `:terminal` Section
**Used By**: ResticWrapper, LatestChangesAction (2 components)
**Keys**: `:command`, `:args`
**Usage**: Terminal emulator operations

### `:display` Section
**Used By**: FileActivityReportGenerator, LatestChangesAction (2 components)
**Keys**: `:time_format`
**Usage**: Output formatting

### `:restic` Section
**Used By**: ResticWrapper, LatestChangesAction (2 components)
**Keys**: `:mount_timeout`
**Usage**: Restic backup tool configuration

## Configuration Coupling Analysis

### High Coupling (3+ sections)
- **ResticWrapper**: Uses `:paths`, `:restic`, `:terminal`
- **LatestChangesAction**: Uses all sections (setup operations)

### Medium Coupling (2 sections)
- **FileActivityReportGenerator**: Uses `:display`
- **FileDiscoveryAction**: Uses `:paths`

### Low Coupling (1 section)
- **Logger**: Uses `:logger`

### No Coupling (0 sections)
- **Most components**: 23 components use no configuration

## Refactoring Priorities

### Priority 1: High-Impact, Low-Risk
- **Logger**: Single section usage, clear boundaries
- **FileDiscoveryAction**: Single section usage, simple interface

### Priority 2: Medium-Impact, Medium-Risk
- **ResticWrapper**: Multiple sections, but well-defined interface
- **FileActivityReportGenerator**: Simple usage, clear boundaries

### Priority 3: Low-Impact, High-Risk
- **LatestChangesAction**: Uses all sections, complex setup operations
- **Command classes**: Interactive setup, complex validation

## Migration Strategy by Component

### Phase 1: Single-Section Components
1. Logger → LoggingConfiguration
2. FileDiscoveryAction → PathConfiguration
3. FileActivityReportGenerator → DisplayConfiguration

### Phase 2: Multi-Section Components
1. ResticWrapper → PathConfiguration + TerminalConfiguration + BackupConfiguration
2. Update container registrations for multi-section components

### Phase 3: Complex Components
1. LatestChangesAction → ApplicationConfiguration (coordinator)
2. Command classes → ApplicationConfiguration (setup operations)

### Phase 4: Container Integration
1. Update all container registrations
2. Provide backward compatibility shims
3. Add deprecation warnings

## Testing Strategy

### Unit Tests
- Test each configuration class independently
- Mock configuration objects for component tests
- Validate configuration loading and validation

### Integration Tests
- Test component integration with new configuration classes
- Verify container registrations work correctly
- Test backward compatibility

### Migration Tests
- Test that existing code continues to work
- Verify no regressions in functionality
- Test configuration file loading

## Validation Checklist

- [ ] All configuration sections are accounted for
- [ ] All components' configuration usage is mapped
- [ ] Migration path is defined for each component
- [ ] No configuration usage is overlooked
- [ ] Backward compatibility is maintained
- [ ] Container registrations are updated
- [ ] Tests cover all migration scenarios