# frozen_string_literal: true

require_relative 'logging_configuration'
require_relative 'path_configuration'
require_relative 'terminal_configuration'
require_relative 'display_configuration'

module ComputerTools
  module Configurations
    class ConfigurationFactory
      def self.create_logging_config(yaml_data=nil)
        yaml_data ? LoggingConfiguration.from_yaml(yaml_data) : LoggingConfiguration.new
      end

      def self.create_path_config(yaml_data=nil)
        yaml_data ? PathConfiguration.from_yaml(yaml_data) : PathConfiguration.new
      end

      def self.create_terminal_config(yaml_data=nil)
        yaml_data ? TerminalConfiguration.from_yaml(yaml_data) : TerminalConfiguration.new
      end

      def self.create_display_config(yaml_data=nil)
        yaml_data ? DisplayConfiguration.from_yaml(yaml_data) : DisplayConfiguration.new
      end

def self.create_application_config(yaml_file_paths=nil)
        ApplicationConfiguration.from_yaml_files(yaml_file_paths)
      end

      def self.load_yaml_data(file_paths=nil)
        yaml_data = {}

        if file_paths
          file_paths.each do |file_path|
            if File.exist?(file_path)
              file_data = YAML.load_file(file_path)
              yaml_data.merge!(file_data) if file_data.is_a?(Hash)
            end
          end
        end

        yaml_data
      end
    end
  end
end