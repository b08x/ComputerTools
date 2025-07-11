# frozen_string_literal: true

require 'colorize'
require 'tty-prompt'
require_relative 'base_command'

module ComputerTools
  module Commands
    class ConfigCommand < BaseCommand
      def self.description
        "Manage ComputerTools configuration settings"
      end

      def initialize(options)
        super
        @prompt = TTY::Prompt.new
      end

      def execute(*args)
        subcommand = args.shift

        case subcommand
        when 'setup', nil
          handle_setup
        when 'show'
          handle_show
        when 'edit'
          handle_edit
        when 'reset'
          handle_reset
        when 'validate'
          handle_validate
        when 'help'
          show_help
        else
          puts "❌ Unknown subcommand: #{subcommand}".colorize(:red)
          show_help
          false
        end
      end

      private

      def handle_setup
        puts "🔧 ComputerTools Configuration Setup".colorize(:blue)
        puts "=" * 40

        begin
          require_relative '../configuration'
          config = ComputerTools::Configuration.new
          success = config.interactive_setup

          if success
            puts "✅ Configuration setup completed successfully!".colorize(:green)
            true
          else
            puts "⚠️  Configuration setup completed with warnings.".colorize(:yellow)
            false
          end
        rescue StandardError => e
          puts "❌ Error during configuration setup: #{e.message}".colorize(:red)
          puts "   File: #{e.backtrace.first}" if ENV['DEBUG']
          false
        end
      end

      def handle_show
        puts "📋 Current Configuration".colorize(:blue)
        puts "=" * 25

        begin
          require_relative '../configuration'
          config = ComputerTools::Configuration.new
          config_hash = config.config.to_hash

          if config_hash.empty?
            puts "⚠️  No configuration found. Run 'config setup' to create one.".colorize(:yellow)
            return false
          end

          display_config_section("Paths", config_hash['paths']) if config_hash['paths']
          display_config_section("Display", config_hash['display']) if config_hash['display']
          display_config_section("Restic", config_hash['restic']) if config_hash['restic']
          display_config_section("Terminal", config_hash['terminal']) if config_hash['terminal']
          display_config_section("Logger", config_hash['logger']) if config_hash['logger']

          true
        rescue StandardError => e
          puts "❌ Error reading configuration: #{e.message}".colorize(:red)
          false
        end
      end

      def handle_edit
        puts "✏️  Interactive Configuration Editor".colorize(:blue)
        puts "=" * 35

        begin
          require_relative '../configuration'
          config = ComputerTools::Configuration.new

          section = @prompt.select("Which section would you like to edit?") do |menu|
            menu.choice "📁 Paths (directories and repositories)", :paths
            menu.choice "🎨 Display settings", :display
            menu.choice "📦 Restic backup settings", :restic
            menu.choice "💻 Terminal settings", :terminal
            menu.choice "📝 Logger settings", :logger
            menu.choice "🔄 Full setup (all sections)", :all
            menu.choice "❌ Cancel", :cancel
          end

          return true if section == :cancel

          case section
          when :paths
            config.send(:configure_paths)
          when :display
            config.send(:configure_display)
          when :restic
            config.send(:configure_restic)
          when :terminal
            config.send(:configure_terminals)
          when :logger
            config.send(:configure_logger)
          when :all
            config.interactive_setup
          end

          config.send(:save_config)
          puts "✅ Configuration updated successfully!".colorize(:green)
          true
        rescue StandardError => e
          puts "❌ Error editing configuration: #{e.message}".colorize(:red)
          false
        end
      end

      def handle_reset
        puts "🔄 Reset Configuration".colorize(:blue)
        puts "=" * 22

        config_file = File.expand_path('~/.config/computertools/config.yml')

        if File.exist?(config_file)
          confirmed = @prompt.yes?("⚠️  This will delete your current configuration. Are you sure?")
          return false unless confirmed

          begin
            File.delete(config_file)
            puts "✅ Configuration file deleted successfully.".colorize(:green)
            puts "💡 Run 'config setup' to create a new configuration.".colorize(:cyan)
            true
          rescue StandardError => e
            puts "❌ Error deleting configuration file: #{e.message}".colorize(:red)
            false
          end
        else
          puts "ℹ️  No configuration file found at #{config_file}".colorize(:blue)
          true
        end
      end

      def handle_validate
        puts "🔍 Validating Configuration".colorize(:blue)
        puts "=" * 26

        begin
          require_relative '../configuration'
          config = ComputerTools::Configuration.new

          # Test terminal command
          puts "📡 Checking terminal availability...".colorize(:cyan)
          terminals_valid = config.send(:validate_terminal_command)

          if terminals_valid
            puts "✅ Configuration validation passed!".colorize(:green)
          else
            puts "⚠️  Configuration validation completed with warnings.".colorize(:yellow)
          end

          true
        rescue TTY::Config::ValidationError => e
          puts "❌ Configuration validation failed: #{e.message}".colorize(:red)
          false
        rescue StandardError => e
          puts "❌ Error during validation: #{e.message}".colorize(:red)
          false
        end
      end

      def display_config_section(title, data)
        puts "\n#{title}:".colorize(:cyan)
        case data
        when Hash
          data.each do |key, value|
            puts "  #{key}: #{format_value(value)}"
          end
        when Array
          data.each_with_index do |item, i|
            puts "  #{i + 1}. #{format_value(item)}"
          end
        else
          puts "  #{format_value(data)}"
        end
      end

      def format_value(value)
        case value
        when Hash
          if value.key?('command') && value.key?('args')
            "#{value['command']} #{value['args']}".colorize(:yellow)
          else
            value.inspect.colorize(:yellow)
          end
        when String
          value.colorize(:yellow)
        else
          value.to_s.colorize(:yellow)
        end
      end

      def show_help
        puts <<~HELP
          Configuration Management Commands:

          🔧 Setup & Management:
            config setup                         Interactive configuration setup (default)
            config show                          Display current configuration
            config edit                          Edit specific configuration sections
            config reset                         Delete configuration file
            config validate                      Validate configuration and check dependencies

          📋 Configuration Sections:
            • Paths: Home directory, restic mount point, repository paths
            • Display: Time format and output preferences#{'  '}
            • Restic: Backup mounting timeout and settings
            • Terminal: Default terminal emulator command and arguments
            • Logger: Log levels, file logging, and output preferences

          💾 Configuration File:
            Location: ~/.config/computertools/config.yml
            Format: YAML with hierarchical sections

          Examples:
            config                               # Run interactive setup
            config show                          # View current settings
            config edit                          # Edit specific sections
            config validate                      # Check configuration validity
            config reset                         # Start fresh

          💡 Tips:
            • Use 'config setup' for first-time configuration
            • Use 'config edit' to modify specific sections only
            • Use 'config validate' to check if external tools are available

        HELP
      end
    end
  end
end