# frozen_string_literal: true

module ComputerTools
  class CLI < Thor
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
