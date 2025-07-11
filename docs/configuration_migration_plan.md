# Configuration Migration Plan

## Overview

This document outlines the step-by-step migration from the monolithic `ComputerTools::Configuration` class to role-specific configuration classes, ensuring zero downtime and backward compatibility.

## Migration Strategy

### Gradual Migration Approach
- **Phase 1**: Create new configuration classes alongside existing ones
- **Phase 2**: Update container registrations with new configurations
- **Phase 3**: Migrate high-impact components one by one
- **Phase 4**: Deprecate and remove monolithic configuration

### Backward Compatibility Guarantee
- Existing code continues to work throughout migration
- ApplicationConfiguration provides delegation to maintain interface
- Container maintains existing 'configuration' registration

## Phase 1: Foundation (P1-T004)

### Step 1.1: Create Configuration Directory Structure
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

### Step 1.2: Implement Core Configuration Classes

#### LoggingConfiguration
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
        config = new
        return config unless yaml_data&.dig('logger')
        
        logger_data = yaml_data['logger']
        config.config.level = logger_data['level'] if logger_data['level']
        config.config.file_logging = logger_data['file_logging'] if logger_data.key?('file_logging')
        config.config.file_path = logger_data['file_path'] if logger_data['file_path']
        config.config.file_level = logger_data['file_level'] if logger_data['file_level']
        
        config
      end
      
      def configure_tty_logger
        # Implementation for TTY::Logger setup
      end
      
      private
      
      def default_log_path
        state_home = ENV['XDG_STATE_HOME'] || File.expand_path('~/.local/state')
        File.join(state_home, 'computertools', 'app.log')
      end
    end
  end
end
```

#### PathConfiguration
```ruby
module ComputerTools
  module Configuration
    class PathConfiguration
      include Dry::Configurable
      
      setting :home_dir, default: -> { File.expand_path('~') }
      setting :restic_mount_point, default: -> { File.expand_path('~/mnt/restic') }
      setting :restic_repo, default: -> { ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo' }
      
      def self.from_yaml(yaml_data)
        config = new
        return config unless yaml_data&.dig('paths')
        
        paths_data = yaml_data['paths']
        config.config.home_dir = paths_data['home_dir'] if paths_data['home_dir']
        config.config.restic_mount_point = paths_data['restic_mount_point'] if paths_data['restic_mount_point']
        config.config.restic_repo = paths_data['restic_repo'] if paths_data['restic_repo']
        
        config
      end
      
      def validate_paths
        unless Dir.exist?(File.expand_path(config.home_dir))
          raise "Home directory '#{config.home_dir}' does not exist"
        end
      end
    end
  end
end
```

#### TerminalConfiguration
```ruby
module ComputerTools
  module Configuration
    class TerminalConfiguration
      include Dry::Configurable
      
      setting :command, default: 'kitty'
      setting :args, default: '-e'
      
      def self.from_yaml(yaml_data)
        config = new
        return config unless yaml_data&.dig('terminal')
        
        terminal_data = yaml_data['terminal']
        config.config.command = terminal_data['command'] if terminal_data['command']
        config.config.args = terminal_data['args'] if terminal_data['args']
        
        config
      end
      
      def validate_terminal_command
        cmd = Terrapin::CommandLine.new("which", ":command", command: config.command)
        cmd.run
        true
      rescue Terrapin::CommandNotFoundError, Terrapin::ExitStatusError
        false
      end
      
      def build_command_line(command)
        "#{config.command} #{config.args} #{command}"
      end
    end
  end
end
```

#### DisplayConfiguration
```ruby
module ComputerTools
  module Configuration
    class DisplayConfiguration
      include Dry::Configurable
      
      setting :time_format, default: '%Y-%m-%d %H:%M:%S'
      
      def self.from_yaml(yaml_data)
        config = new
        return config unless yaml_data&.dig('display')
        
        display_data = yaml_data['display']
        config.config.time_format = display_data['time_format'] if display_data['time_format']
        
        config
      end
      
      def format_time(time)
        time.strftime(config.time_format)
      end
      
      def validate_time_format
        Time.now.strftime(config.time_format)
      rescue ArgumentError => e
        raise "Invalid time format '#{config.time_format}': #{e.message}"
      end
    end
  end
end
```

#### BackupConfiguration
```ruby
module ComputerTools
  module Configuration
    class BackupConfiguration
      include Dry::Configurable
      
      setting :mount_timeout, default: 60
      
      def self.from_yaml(yaml_data)
        config = new
        return config unless yaml_data&.dig('restic')
        
        restic_data = yaml_data['restic']
        config.config.mount_timeout = restic_data['mount_timeout'] if restic_data['mount_timeout']
        
        config
      end
      
      def validate_timeout
        unless config.mount_timeout.is_a?(Integer) && config.mount_timeout > 0
          raise "Mount timeout must be a positive integer, got '#{config.mount_timeout}'"
        end
      end
    end
  end
end
```

#### ApplicationConfiguration
```ruby
module ComputerTools
  module Configuration
    class ApplicationConfiguration
      def initialize(yaml_file_path = nil)
        @yaml_file_path = yaml_file_path || default_config_file_path
        @yaml_data = load_yaml_data
        
        @logging_config = LoggingConfiguration.from_yaml(@yaml_data)
        @path_config = PathConfiguration.from_yaml(@yaml_data)
        @terminal_config = TerminalConfiguration.from_yaml(@yaml_data)
        @display_config = DisplayConfiguration.from_yaml(@yaml_data)
        @backup_config = BackupConfiguration.from_yaml(@yaml_data)
      end
      
      attr_reader :logging_config, :path_config, :terminal_config, 
                  :display_config, :backup_config
      
      # Backward compatibility method
      def fetch(*keys)
        case keys.first
        when :logger
          delegate_to_logging_config(keys)
        when :paths
          delegate_to_path_config(keys)
        when :terminal
          delegate_to_terminal_config(keys)
        when :display
          delegate_to_display_config(keys)
        when :restic
          delegate_to_backup_config(keys)
        else
          raise "Unknown configuration section: #{keys.first}"
        end
      end
      
      private
      
      def default_config_file_path
        File.expand_path('~/.config/computertools/config.yml')
      end
      
      def load_yaml_data
        return {} unless File.exist?(@yaml_file_path)
        YAML.load_file(@yaml_file_path) || {}
      end
      
      def delegate_to_logging_config(keys)
        case keys[1]
        when :level then @logging_config.config.level
        when :file_logging then @logging_config.config.file_logging
        when :file_path then @logging_config.config.file_path
        when :file_level then @logging_config.config.file_level
        else raise "Unknown logging config key: #{keys[1]}"
        end
      end
      
      def delegate_to_path_config(keys)
        case keys[1]
        when :home_dir then @path_config.config.home_dir
        when :restic_mount_point then @path_config.config.restic_mount_point
        when :restic_repo then @path_config.config.restic_repo
        else raise "Unknown path config key: #{keys[1]}"
        end
      end
      
      def delegate_to_terminal_config(keys)
        case keys[1]
        when :command then @terminal_config.config.command
        when :args then @terminal_config.config.args
        else raise "Unknown terminal config key: #{keys[1]}"
        end
      end
      
      def delegate_to_display_config(keys)
        case keys[1]
        when :time_format then @display_config.config.time_format
        else raise "Unknown display config key: #{keys[1]}"
        end
      end
      
      def delegate_to_backup_config(keys)
        case keys[1]
        when :mount_timeout then @backup_config.config.mount_timeout
        else raise "Unknown backup config key: #{keys[1]}"
        end
      end
    end
  end
end
```

#### ConfigurationFactory
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
      
      def self.create_application_config(yaml_file_path = nil)
        ApplicationConfiguration.new(yaml_file_path)
      end
    end
  end
end
```

### Step 1.3: Create Comprehensive Tests

#### Test Structure
```
spec/configuration/
├── application_configuration_spec.rb
├── logging_configuration_spec.rb
├── path_configuration_spec.rb
├── terminal_configuration_spec.rb
├── display_configuration_spec.rb
├── backup_configuration_spec.rb
└── configuration_factory_spec.rb
```

### Step 1.4: Update Container Registrations

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

## Phase 2: Component Migration (P1-T006)

### Step 2.1: Migrate Logger Module
```ruby
# lib/ComputerTools/logger.rb
module ComputerTools
  module Logger
    def self.instance
      return @@instance if @@instance

      # Use new LoggingConfiguration from container
      logging_config = ComputerTools.container['logging_configuration']
      
      @@instance = TTY::Logger.new do |config|
        handlers = []
        handlers << configure_console_handler(logging_config.config.level)
        handlers << configure_file_handler(logging_config.config.file_path, logging_config.config.file_level) if logging_config.config.file_logging

        config.handlers = handlers
      end
      
      # Add custom log types...
      @@instance
    end
  end
end
```

### Step 2.2: Migrate ResticWrapper
```ruby
# lib/ComputerTools/wrappers/restic_wrapper.rb
module ComputerTools
  module Wrappers
    class ResticWrapper
      def initialize(path_config:, terminal_config:, backup_config:)
        @path_config = path_config
        @terminal_config = terminal_config
        @backup_config = backup_config
        
        @mount_point = @path_config.config.restic_mount_point
        @repository = @path_config.config.restic_repo
        @home_dir = @path_config.config.home_dir
        @mount_timeout = @backup_config.config.mount_timeout
        
        @mounted = false
        @mount_pid = nil
        setup_cleanup_handler
      end
      
      private
      
      def open_terminal_in_mount
        terminal_cmd = @terminal_config.build_command_line("cd #{@mount_point} && $SHELL")
        system(terminal_cmd)
      end
    end
  end
end
```

### Step 2.3: Update Container Registrations
```ruby
# Update ResticWrapper registration
ComputerTools::Container.register('restic_wrapper') do
  ComputerTools::Wrappers::ResticWrapper.new(
    path_config: ComputerTools::Container['path_configuration'],
    terminal_config: ComputerTools::Container['terminal_configuration'],
    backup_config: ComputerTools::Container['backup_configuration']
  )
end
```

## Phase 3: Validation and Testing

### Step 3.1: Run Comprehensive Tests
```bash
# Run all configuration tests
bundle exec rspec spec/configuration/

# Run integration tests
bundle exec rspec spec/container_spec.rb

# Run component tests with new configurations
bundle exec rspec spec/wrappers/restic_wrapper_spec.rb
```

### Step 3.2: Validate Backward Compatibility
```ruby
# Test existing interface still works
config = ComputerTools::Configuration.new
expect(config.fetch(:logger, :level)).to eq('info')
expect(config.fetch(:paths, :home_dir)).to be_present
```

### Step 3.3: Test Application Startup
```bash
# Ensure application still starts correctly
exe/ComputerTools help

# Test container resolution
bundle exec ruby -e "
require 'ComputerTools'
ComputerTools.initialize_container
puts 'New configs available:'
puts ComputerTools.container.registered?('logging_configuration')
puts ComputerTools.container.registered?('path_configuration')
puts 'Backward compatibility:'
puts ComputerTools.container.registered?('configuration')
"
```

## Phase 4: Documentation and Deprecation

### Step 4.1: Update Documentation
- Update CLAUDE.md with new configuration architecture
- Create migration guide for external users
- Update README with new configuration examples

### Step 4.2: Add Deprecation Warnings
```ruby
# In original Configuration class
def initialize
  puts "⚠️  DEPRECATION WARNING: ComputerTools::Configuration is deprecated. Use ComputerTools::Configuration::ApplicationConfiguration instead."
  # ... rest of initialization
end
```

## Rollback Plan

### If Issues Arise
1. **Immediate**: Remove new container registrations
2. **Short-term**: Revert to original Configuration class
3. **Long-term**: Fix issues in role-specific classes

### Rollback Steps
```ruby
# Remove new registrations from container
ComputerTools::Container._container.delete('logging_configuration')
ComputerTools::Container._container.delete('path_configuration')
# ... etc

# Revert component constructor changes
# Restore original ResticWrapper constructor
```

## Success Criteria

### Phase 1 Complete
- [ ] All role-specific configuration classes created
- [ ] All tests passing
- [ ] Container registrations updated
- [ ] No breaking changes to existing functionality

### Phase 2 Complete
- [ ] Logger migrated to LoggingConfiguration
- [ ] ResticWrapper migrated to role-specific configs
- [ ] All integration tests passing
- [ ] Backward compatibility maintained

### Phase 3 Complete
- [ ] All validation tests passing
- [ ] Application starts correctly
- [ ] Container resolution working
- [ ] No performance degradation

### Phase 4 Complete
- [ ] Documentation updated
- [ ] Deprecation warnings added
- [ ] Migration guide created
- [ ] External users informed

## Timeline

- **Phase 1**: 2-3 days (Foundation)
- **Phase 2**: 1-2 days (Migration)
- **Phase 3**: 1 day (Validation)
- **Phase 4**: 1 day (Documentation)

**Total**: 5-7 days for complete migration

This migration plan ensures a smooth transition while maintaining full backward compatibility and providing a clear path forward for the improved configuration architecture.