# frozen_string_literal: true

require_relative 'base_command'

module ComputerTools
  module Commands
    class ListModelsCommand < BaseCommand
      def self.description
        "Display available AI models and their properties"
      end

      def execute(*args)
        provider = args.first

        log_step "Displaying available models..."

        begin
          ComputerTools::Actions::DisplayAvailableModelsAction.new(
            provider: provider
          ).call

          log_success "Models displayed successfully"
        rescue StandardError => e
          log_error "Failed to display models: #{e.message}"
          exit 1
        end
      end
    end
  end
end