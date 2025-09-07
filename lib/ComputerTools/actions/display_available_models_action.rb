# frozen_string_literal: true

require 'tty-table'
require 'dotenv/load'
require 'ruby_llm'

module ComputerTools
  module Actions
    class DisplayAvailableModelsAction < ComputerTools::Actions::BaseAction
      def initialize(provider: nil)
        @provider = provider
      end

      def call
        fetch_and_display_models
      end

      private

      def fetch_and_display_models
        puts "Fetching model list from AI providers..."

        # Configure RubyLLM first
        configure_rubyllm

        # Refresh the model registry
        RubyLLM.models.refresh!

        # Get all available models
        all_models = RubyLLM.models.all

        # Filter models based on provider if specified, otherwise show gemini models
        filtered_models = if @provider
                            all_models.select { |m| m.provider.to_s.downcase.include?(@provider.downcase) }
                          else
                            all_models.select { |m| m.provider.to_s.downcase.include?("gemini") }
                          end

        # Transform the model data into a format suitable for the table
        formatted_models = filtered_models.map do |model|
          {
            id: model.id,
            provider: model.provider,
            type: model.type || 'chat',
            name: model.name,
            context_window: model.context_window,
            max_tokens: model.max_tokens,
            supports_vision: model.supports_vision? ? 'Yes' : 'No',
            supports_functions: model.supports_functions? ? 'Yes' : 'No',
            input_price: model.input_price_per_million,
            output_price: model.output_price_per_million,
            family: model.family
          }
        end

        display_table(formatted_models)
      rescue StandardError => e
        puts "An error occurred while fetching the models."
        puts "Please ensure your API keys are set correctly in environment variables."
        puts "Supported keys: GEMINI_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, DEEPSEEK_API_KEY"
        puts "Error details: #{e.message}"
        exit
      end

      def configure_rubyllm
        RubyLLM.configure do |config|
          config.gemini_api_key = ENV['GEMINI_API_KEY'] || ENV.fetch('GOOGLE_API_KEY', nil)
          config.openai_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
          config.openai_api_base = ENV.fetch('OPENROUTER_API_BASE', 'https://openrouter.ai/api/v1')
          # config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
          # config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)

          # Set reasonable defaults
          config.request_timeout = 30
          config.max_retries = 3
          config.retry_interval = 1
          config.log_level = :info
        end
      end

      def display_table(formatted_models)
        provider_name = @provider&.capitalize || 'Gemini'
        puts "\n📋 Available #{provider_name} Models (via ruby_llm)".colorize(:cyan)
        puts "─" * 80

        # Sort models by version (extracted from ID) then by context window
        sorted_models = formatted_models.sort_by do |model|
          version = extract_version(model[:id])
          context_window = model[:context_window] || 0
          [version, context_window]
        end

        # Display simple list with name and ID
        sorted_models.each do |model|
          puts "• #{model[:name]} (#{model[:id]})".colorize(:light_blue)
        end

        puts "\n#{sorted_models.count} models found".colorize(:green)
      end

      private

      def extract_version(model_id)
        # Extract version number from model ID (e.g., "gemini-1.5-pro" -> [1, 5])
        version_match = model_id.match(/(\d+)\.(\d+)/)
        if version_match
          [version_match[1].to_i, version_match[2].to_i]
        else
          # If no version found, put it at the end
          [999, 999]
        end
      end
    end
  end
end