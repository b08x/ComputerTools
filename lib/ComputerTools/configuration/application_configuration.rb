# frozen_string_literal: true

require 'yaml'
require_relative 'configuration_factory'
require_relative 'logging_configuration'
require_relative 'path_configuration'
require_relative 'terminal_configuration'
require_relative 'display_configuration'
require_relative 'backup_configuration'

module ComputerTools
  module Configurations
    class ApplicationConfiguration
      attr_reader :logging_config, :path_config, :terminal_config,
                  :display_config, :backup_config

      def initialize(yaml_data=nil)
        @logging_config = ConfigurationFactory.create_logging_config(yaml_data)
        @path_config = ConfigurationFactory.create_path_config(yaml_data)
        @terminal_config = ConfigurationFactory.create_terminal_config(yaml_data)
        @display_config = ConfigurationFactory.create_display_config(yaml_data)
        @backup_config = ConfigurationFactory.create_backup_config(yaml_data)
      end

      def self.from_yaml_files(file_paths=nil)
        yaml_data = ConfigurationFactory.load_yaml_data(file_paths)
        new(yaml_data)
      end

      def interactive_setup
        # Coordinate interactive setup across all configs
        puts "Setting up ComputerTools configuration..."

        # Could coordinate setup across all config objects
        # For now, just validate all configurations
        validate_all!

        puts "Configuration setup completed successfully!"
      end

      def validate_all!
        @logging_config.validate!
        @path_config.validate!
        @terminal_config.validate!
        @display_config.validate!
        @backup_config.validate!
      end

      # Backward compatibility methods
      def fetch(*keys)
        case keys.first
        when :logger
          delegate_to_logging_config(keys[1..-1])
        when :paths
          delegate_to_path_config(keys[1..-1])
        when :terminal
          delegate_to_terminal_config(keys[1..-1])
        when :display
          delegate_to_display_config(keys[1..-1])
        when :restic
          delegate_to_backup_config(keys[1..-1])
        else
          raise ArgumentError, "Unknown configuration section: #{keys.first}"
        end
      end

      private

      def delegate_to_logging_config(keys)
        case keys.first
        when :level
          @logging_config.config.level
        when :file_logging
          @logging_config.config.file_logging
        when :file_path
          @logging_config.config.file_path
        when :file_level
          @logging_config.config.file_level
        else
          raise ArgumentError, "Unknown logging configuration key: #{keys.first}"
        end
      end

      def delegate_to_path_config(keys)
        case keys.first
        when :home_dir
          @path_config.config.home_dir
        when :restic_mount_point
          @path_config.config.restic_mount_point
        when :restic_repo
          @path_config.config.restic_repo
        else
          raise ArgumentError, "Unknown path configuration key: #{keys.first}"
        end
      end

      def delegate_to_terminal_config(keys)
        case keys.first
        when :command
          @terminal_config.config.command
        when :args
          @terminal_config.config.args
        else
          raise ArgumentError, "Unknown terminal configuration key: #{keys.first}"
        end
      end

      def delegate_to_display_config(keys)
        case keys.first
        when :time_format
          @display_config.config.time_format
        else
          raise ArgumentError, "Unknown display configuration key: #{keys.first}"
        end
      end

      def delegate_to_backup_config(keys)
        case keys.first
        when :mount_timeout
          @backup_config.config.mount_timeout
        else
          raise ArgumentError, "Unknown backup configuration key: #{keys.first}"
        end
      end
    end
  end
end