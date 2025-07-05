# frozen_string_literal: true

module ComputerTools
  class CLI < Thor
    ComputerTools::Commands.constants.reject{ |command_class| command_class == :BaseCommand }.each do |command_class|
      command = ComputerTools::Commands.const_get(command_class)
      desc command.command_name, command.description
      define_method(command.command_name) do |*args|
        command.new(options).execute(*args)
      end
    end
  end
end
