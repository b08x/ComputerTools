# frozen_string_literal: true

module ComputerTools
  # ComputerTools::CLI is the main command line interface for ComputerTools.
  # It extends Thor to provide a command-line interface with various computer-related utilities.
  # When no arguments are provided, it launches an interactive menu system.
  #
  # @example Basic usage with arguments
  #   ComputerTools::CLI.start(['command_name', 'arg1', 'arg2'])
  # @example Interactive menu mode (no arguments)
  #   ComputerTools::CLI.start
  class CLI < Thor
    # Dynamically registers all available commands from ComputerTools::Commands
    # as Thor commands, excluding the base and menu commands.
    #
    # This is automatically executed when the class is loaded and sets up
    # the command descriptions and method definitions for each available command.
    excluded_commands = %i[BaseCommand MenuCommand]
    valid_commands = ComputerTools::Commands.constants.reject do |command_class|
      excluded_commands.include?(command_class)
    end

    valid_commands.each do |command_class|
      command = ComputerTools::Commands.const_get(command_class)
      desc command.command_name, command.description
      define_method(command.command_name) do |*args|
        command.new(options).execute(*args)
      end
    end

    # Starts the CLI application with the given arguments.
    #
    # When no arguments are provided, launches an interactive menu system.
    # Otherwise, processes the provided command line arguments.
    #
    # @param given_args [Array<String>] the command line arguments to process
    # @return [void]
    #
    # @example Starting with arguments
    #   ComputerTools::CLI.start(['disk_usage', '/path/to/check'])
    #
    # @example Starting interactive menu
    #   ComputerTools::CLI.start
    #
    # @note Requires 'tty-prompt' gem for interactive menu functionality
    # @note Set COMPUTERTOOLS_DEBUG=true environment variable for debug output
    def self.start(given_args=ARGV)
      # If no arguments provided, launch interactive menu
      if given_args.empty?
        begin
          require 'tty-prompt'
          debug_mode = ENV['COMPUTERTOOLS_DEBUG'] == 'true'
          ComputerTools::Commands::MenuCommand.new(debug: debug_mode).start
        rescue LoadError
          puts "❌ TTY::Prompt not available. Please run: bundle install".colorize(:red)
          super
        end
      else
        super
      end
    end
  end
end