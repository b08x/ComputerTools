# frozen_string_literal: true

require 'dry-configurable'
require 'tty-which'

module ComputerTools
  module Configurations
    class TerminalConfiguration
      include Dry::Configurable

      setting :command, default: 'kitty'
      setting :args, default: '-e'

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('terminal')

        terminal_config = yaml_data['terminal']

        instance.configure do |config|
          config.command = terminal_config['command'] if terminal_config.key?('command')
          config.args = terminal_config['args'] if terminal_config.key?('args')
        end

        instance
      end

      def validate_terminal_command
        return if TTY::Which.which(config.command)

        raise ArgumentError, "Terminal command '#{config.command}' not found in PATH"
      end

      def validate!
        validate_terminal_command
      end

      def build_command_line(command)
        [config.command, config.args, command].flatten.compact
      end

      def terminal_available?
        TTY::Which.which(config.command) ? true : false
      end

      def execute_in_terminal(command)
        full_command = build_command_line(command)
        system(*full_command)
      end
    end
  end
end