# frozen_string_literal: true

module ComputerTools
  class CLI < Thor
    EXCLUDED_COMMANDS = %i[Base Menu]

    # Find all command classes in the nested module structure
    def self.find_command_classes
      commands = []

      # Explicitly require the Commands module to ensure it's loaded
      require_relative 'commands'

      # Let Zeitwerk handle lazy loading - no need for eager loading in CLI discovery

      # Search through all nested modules in Commands
      ComputerTools::Commands.constants.each do |module_name|
        module_obj = ComputerTools::Commands.const_get(module_name)
        next unless module_obj.is_a?(Module)

        module_obj.constants.each do |class_name|
          commands << ComputerTools::Commands.const_get(module_name).const_get(class_name)
        end
      end

      commands.reject { |cmd| EXCLUDED_COMMANDS.include?(cmd.name.split('::').last.to_sym) }
    end

    # Commands will be registered dynamically when needed

    def self.start(given_args=ARGV)
      # Register commands dynamically when starting
      find_command_classes.each do |command_class|
        desc command_class.command_name, command_class.description
        define_method(command_class.command_name) do |*args|
          command_class.new(options).execute(*args)
        end
      end

      # If no arguments provided, launch interactive menu
      if given_args.empty?
        begin
          require 'tty-prompt'
          debug_mode = ENV['COMPUTERTOOLS_DEBUG'] == 'true'
          ComputerTools::Commands::Interface::Menu.new(debug: debug_mode).start
        rescue StandardError => e
          # Handle missing TTY::Prompt gracefully
          puts "#{e.class}: #{e.message}".colorize(:red)
          puts "❌ TTY::Prompt not available. Please run: bundle install".colorize(:red)
          super
        end
      else
        super
      end
    end
  end
end
