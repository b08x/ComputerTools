# Proposed Configuration Structure

## Overview

This document outlines the proposed role-specific configuration classes that will replace the monolithic `ComputerTools::Configuration` class, following the Interface Segregation Principle and Single Responsibility Principle.

## New Configuration Architecture

### Class Hierarchy

```
ComputerTools::Configuration (Legacy - Deprecated)
├── ComputerTools::Configuration::ApplicationConfiguration (Coordinator)
│   ├── ComputerTools::Configuration::LoggingConfiguration
│   ├── ComputerTools::Configuration::PathConfiguration
│   ├── ComputerTools::Configuration::TerminalConfiguration
│   ├── ComputerTools::Configuration::DisplayConfiguration
│   └── ComputerTools::Configuration::BackupConfiguration
```

## Role-Specific Configuration Classes

### 1. LoggingConfiguration

**Purpose**: Centralized logging configuration management
**Namespace**: `ComputerTools::Configuration::LoggingConfiguration`

```ruby
module ComputerTools
  module Configuration
    class LoggingConfiguration
      include Dry::Configurable
      
      setting :level, default: 'info'
      setting :file_logging, default: false
      setting :file_path, default: -> { default_log_path }
      setting :file_level, default: 'debug'
      
      def self.from_yaml(yaml_data)
        # Load from YAML logger section
      end
      
      def configure_tty_logger
        # Configure TTY::Logger with these settings
      end
    end
  end
end
```

**YAML Section**: `:logger`
**Responsibilities**:
- Console log level management
- File logging configuration
- Log file path management
- TTY::Logger integration
- Environment variable mapping for logging

**Used By**: Logger module, BaseCommand logging methods

### 2. PathConfiguration

**Purpose**: File system path management and validation
**Namespace**: `ComputerTools::Configuration::PathConfiguration`

```ruby
module ComputerTools
  module Configuration
    class PathConfiguration
      include Dry::Configurable
      
      setting :home_dir, default: -> { File.expand_path('~') }
      setting :restic_mount_point, default: -> { File.expand_path('~/mnt/restic') }
      setting :restic_repo, default: -> { ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo' }
      
      def self.from_yaml(yaml_data)
        # Load from YAML paths section
      end
      
      def validate_paths
        # Validate path existence and permissions
      end
    end
  end
end
```

**YAML Section**: `:paths`
**Responsibilities**:
- Home directory resolution
- Restic mount point configuration
- Repository path management
- Path validation and existence checking
- Environment variable mapping for paths

**Used By**: ResticWrapper, FileDiscoveryAction, file operations

### 3. TerminalConfiguration

**Purpose**: Terminal emulator configuration and validation
**Namespace**: `ComputerTools::Configuration::TerminalConfiguration`

```ruby
module ComputerTools
  module Configuration
    class TerminalConfiguration
      include Dry::Configurable
      
      setting :command, default: 'kitty'
      setting :args, default: '-e'
      
      def self.from_yaml(yaml_data)
        # Load from YAML terminal section
      end
      
      def validate_terminal_command
        # Check if terminal command is available
      end
      
      def build_command_line(command)
        # Build full command line for terminal execution
      end
    end
  end
end
```

**YAML Section**: `:terminal`
**Responsibilities**:
- Terminal command configuration
- Terminal argument management
- Terminal availability validation
- Command line building for terminal execution

**Used By**: ResticWrapper, components launching terminal sessions

### 4. DisplayConfiguration

**Purpose**: Display formatting preferences and localization
**Namespace**: `ComputerTools::Configuration::DisplayConfiguration`

```ruby
module ComputerTools
  module Configuration
    class DisplayConfiguration
      include Dry::Configurable
      
      setting :time_format, default: '%Y-%m-%d %H:%M:%S'
      
      def self.from_yaml(yaml_data)
        # Load from YAML display section
      end
      
      def format_time(time)
        # Format time according to configured format
      end
      
      def validate_time_format
        # Validate time format string
      end
    end
  end
end
```

**YAML Section**: `:display`
**Responsibilities**:
- Time format configuration
- Output formatting preferences
- Locale-specific formatting
- Format validation

**Used By**: Generators, Actions that format output

### 5. BackupConfiguration

**Purpose**: Backup tool configuration (Restic-specific)
**Namespace**: `ComputerTools::Configuration::BackupConfiguration`

```ruby
module ComputerTools
  module Configuration
    class BackupConfiguration
      include Dry::Configurable
      
      setting :mount_timeout, default: 60
      
      def self.from_yaml(yaml_data)
        # Load from YAML restic section
      end
      
      def validate_timeout
        # Validate timeout is positive integer
      end
    end
  end
end
```

**YAML Section**: `:restic`
**Responsibilities**:
- Mount timeout configuration
- Backup-specific settings
- Tool-specific parameters
- Timeout validation

**Used By**: ResticWrapper, backup-related actions

### 6. ApplicationConfiguration

**Purpose**: Application-wide configuration coordination
**Namespace**: `ComputerTools::Configuration::ApplicationConfiguration`

```ruby
module ComputerTools
  module Configuration
    class ApplicationConfiguration
      def initialize
        @logging_config = LoggingConfiguration.new
        @path_config = PathConfiguration.new
        @terminal_config = TerminalConfiguration.new
        @display_config = DisplayConfiguration.new
        @backup_config = BackupConfiguration.new
      end
      
      attr_reader :logging_config, :path_config, :terminal_config, 
                  :display_config, :backup_config
      
      def self.from_yaml_files(file_paths)
        # Load from multiple YAML files
      end
      
      def interactive_setup
        # Coordinate interactive setup across all configs
      end
      
      # Backward compatibility methods
      def fetch(*keys)
        # Delegate to appropriate configuration based on keys
      end
    end
  end
end
```

**YAML Section**: All sections (coordinator)
**Responsibilities**:
- Coordinates other configurations
- Manages configuration file I/O
- Provides backward compatibility
- Handles environment variable integration
- Interactive setup coordination

**Used By**: Commands, setup operations, container registrations

## Configuration Factory Pattern

### ConfigurationFactory

```ruby
module ComputerTools
  module Configuration
    class ConfigurationFactory
      def self.create_logging_config(yaml_data = nil)
        yaml_data ? LoggingConfiguration.from_yaml(yaml_data) : LoggingConfiguration.new
      end
      
      def self.create_path_config(yaml_data = nil)
        yaml_data ? PathConfiguration.from_yaml(yaml_data) : PathConfiguration.new
      end
      
      def self.create_terminal_config(yaml_data = nil)
        yaml_data ? TerminalConfiguration.from_yaml(yaml_data) : TerminalConfiguration.new
      end
      
      def self.create_display_config(yaml_data = nil)
        yaml_data ? DisplayConfiguration.from_yaml(yaml_data) : DisplayConfiguration.new
      end
      
      def self.create_backup_config(yaml_data = nil)
        yaml_data ? BackupConfiguration.from_yaml(yaml_data) : BackupConfiguration.new
      end
      
      def self.create_application_config(yaml_file_paths = nil)
        ApplicationConfiguration.from_yaml_files(yaml_file_paths)
      end
    end
  end
end
```

## Container Registrations

### Updated Container Registrations

```ruby
# In lib/ComputerTools/container/registrations.rb

def self.register_configurations
  # Register individual configuration objects
  ComputerTools::Container.register('logging_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_logging_config
  end
  
  ComputerTools::Container.register('path_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_path_config
  end
  
  ComputerTools::Container.register('terminal_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_terminal_config
  end
  
  ComputerTools::Container.register('display_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_display_config
  end
  
  ComputerTools::Container.register('backup_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_backup_config
  end
  
  ComputerTools::Container.register('application_configuration') do
    ComputerTools::Configuration::ConfigurationFactory.create_application_config
  end
  
  # Backward compatibility - maintain existing registration
  ComputerTools::Container.register('configuration') do
    ComputerTools::Container['application_configuration']
  end
end
```

### Component Registration Updates

```ruby
# ResticWrapper now receives specific configurations
ComputerTools::Container.register('restic_wrapper') do
  ComputerTools::Wrappers::ResticWrapper.new(
    path_config: ComputerTools::Container['path_configuration'],
    terminal_config: ComputerTools::Container['terminal_configuration'],
    backup_config: ComputerTools::Container['backup_configuration']
  )
end

# Logger uses specific configuration
ComputerTools::Container.register('logger') do
  logging_config = ComputerTools::Container['logging_configuration']
  ComputerTools::Logger.new(logging_config)
end
```

## Migration Path

### Phase 1: Create Role-Specific Classes
1. Implement each configuration class with dry-configurable
2. Add YAML loading methods
3. Add validation methods
4. Create comprehensive tests

### Phase 2: Update Container Registrations
1. Register role-specific configurations
2. Update component registrations to use specific configs
3. Maintain backward compatibility registrations

### Phase 3: Refactor Components
1. Update ResticWrapper constructor to accept specific configs
2. Update Logger to use LoggingConfiguration
3. Update other components gradually

### Phase 4: Deprecate Monolithic Configuration
1. Add deprecation warnings
2. Update documentation
3. Provide migration guides

## Benefits

### Interface Segregation
- Components only depend on configuration they use
- Clearer interfaces and responsibilities
- Easier to test with focused mock objects

### Single Responsibility
- Each configuration class has a single purpose
- Validation logic is focused and relevant
- Easier to understand and maintain

### Dependency Injection Ready
- Better integration with DI container
- Cleaner constructor signatures
- Easier to test and mock

### Backward Compatibility
- ApplicationConfiguration maintains existing interface
- Migration can be gradual
- Existing code continues to work

## File Structure

```
lib/ComputerTools/configuration/
├── application_configuration.rb
├── logging_configuration.rb
├── path_configuration.rb
├── terminal_configuration.rb
├── display_configuration.rb
├── backup_configuration.rb
└── configuration_factory.rb
```

## Testing Strategy

### Unit Tests
- Test each configuration class independently
- Test YAML loading and validation
- Test default values and environment variable integration

### Integration Tests
- Test ApplicationConfiguration coordination
- Test container registrations
- Test component integration with new configs

### Migration Tests
- Test backward compatibility
- Test that existing code continues to work
- Test configuration file loading