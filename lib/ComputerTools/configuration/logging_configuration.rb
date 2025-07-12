# frozen_string_literal: true

require 'dry-configurable'

module ComputerTools
  module Configurations
    class LoggingConfiguration
      include Dry::Configurable

      setting :level, default: 'info'
      setting :file_logging, default: false
      setting :file_path, default: nil
      setting :file_level, default: 'debug'

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('logger')

        logger_config = yaml_data['logger']
        
        instance.configure do |config|
          config.level = logger_config['level'] if logger_config.key?('level')
          config.file_logging = logger_config['file_logging'] if logger_config.key?('file_logging')
          config.file_path = logger_config['file_path'] if logger_config.key?('file_path')
          config.file_level = logger_config['file_level'] if logger_config.key?('file_level')
        end

        instance
      end

      def configure_tty_logger
        # Configure TTY::Logger with these settings
        logger_config = {
          level: config.level.to_sym,
          output: []
        }

        # Add console output
        logger_config[:output] << $stdout

        # Add file output if enabled
        if config.file_logging
          file_path = config.file_path || default_log_path
          logger_config[:output] << file_path
        end

        logger_config
      end

      def validate_level
        valid_levels = %w[debug info warn error fatal]
        unless valid_levels.include?(config.level.to_s.downcase)
          raise ArgumentError, "Invalid log level: #{config.level}. Must be one of #{valid_levels.join(', ')}"
        end
      end

      def validate_file_level
        valid_levels = %w[debug info warn error fatal]
        unless valid_levels.include?(config.file_level.to_s.downcase)
          raise ArgumentError, "Invalid file log level: #{config.file_level}. Must be one of #{valid_levels.join(', ')}"
        end
      end

      def validate_file_path
        if config.file_logging
          file_path = config.file_path || default_log_path
          if file_path.nil? || file_path.empty?
            raise ArgumentError, "File logging enabled but no file path specified"
          end
        end
      end

      def validate!
        validate_level
        validate_file_level
        validate_file_path
      end

      private

      def default_log_path
        File.join(ComputerTools.root, 'log', 'computer_tools.log')
      end
    end
  end
end