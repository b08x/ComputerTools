# frozen_string_literal: true

module ComputerTools
  # Provides a mechanism for loading configuration settings.
  module Config
    ##
    # Loads and applies configuration for ruby_llm from a YAML file.
    #
    # This method searches for a `ruby_llm.yml` file within a `config` directory
    # located relative to this source file (`lib/ComputerTools/config/ruby_llm.yml`).
    # If the file exists, it uses the settings to configure ruby_llm,
    # setting the provider, model, API keys, and logging configuration.
    #
    # The configuration supports multiple providers including OpenRouter, Ollama,
    # OpenAI, Anthropic, and others supported by ruby_llm.
    #
    # If the configuration file is not found, default ruby_llm configuration
    # is used based on environment variables.
    #
    # @return [Boolean] true if configuration was loaded successfully, false otherwise
    # @raise [Psych::SyntaxError] If the `ruby_llm.yml` file contains invalid YAML.
    #
    # @example Basic Usage (when config file exists)
    #   # Given a file at /path/to/gem/lib/ComputerTools/config/ruby_llm.yml with:
    #   # ---
    #   # provider: "openrouter"
    #   # chat_model: "anthropic/claude-3.5-sonnet"
    #   # api_key: "your-api-key"
    #   # timeout: 30
    #   # log_level: "info"
    #
    #   # This will configure ruby_llm accordingly.
    #   ComputerTools::Config.load
    #
    # @example Environment Variable Fallback
    #   # When config/ruby_llm.yml does not exist, uses ENV vars:
    #   # RUBY_LLM_PROVIDER, RUBY_LLM_MODEL, OPENROUTER_API_KEY, etc.
    #   ComputerTools::Config.load
    #
    def self.load
      config_path = File.join(File.dirname(__FILE__), "config", "ruby_llm.yml")

      if File.exist?(config_path)
        load_from_file(config_path)
      else
        load_from_environment
      end
    end

    ##
    # Loads configuration from a YAML file.
    #
    # @param config_path [String] Path to the configuration file
    # @return [Boolean] true if successful
    #
    def self.load_from_file(config_path)
      config = YAML.load_file(config_path)
      
      # Configure ruby_llm directly
      RubyLLM.configure do |c|
        # Set API keys for different providers
        c.openrouter_api_key = config['openrouter_api_key'] || config[:openrouter_api_key] || ENV['OPENROUTER_API_KEY']
        c.openai_api_key = config['openai_api_key'] || config[:openai_api_key] || ENV['OPENAI_API_KEY']
        c.anthropic_api_key = config['anthropic_api_key'] || config[:anthropic_api_key] || ENV['ANTHROPIC_API_KEY']
      end
      
      # Also set environment variables for backward compatibility
      ENV['RUBY_LLM_PROVIDER'] = (config['provider'] || config[:provider] || 'openrouter').to_s
      ENV['RUBY_LLM_MODEL'] = config['chat_model'] || config[:chat_model] || "anthropic/claude-3.5-sonnet"

      puts "Ruby_llm configured from file: #{config_path}" if ENV['DEBUG']
      true
    rescue Psych::SyntaxError => e
      puts "Error: Invalid YAML in configuration file: #{config_path} - #{e.message}" if ENV['DEBUG']
      false
    rescue StandardError => e
      puts "Error: Failed to load configuration: #{config_path} - #{e.message}" if ENV['DEBUG']
      false
    end

    ##
    # Loads configuration from environment variables.
    #
    # @return [Boolean] true if successful
    #
    def self.load_from_environment
      RubyLLM.configure do |c|
        # Set API keys for different providers
        c.openrouter_api_key = ENV['OPENROUTER_API_KEY']
        c.openai_api_key = ENV['OPENAI_API_KEY'] 
        c.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      end

      puts "Ruby_llm configured from environment variables" if ENV['DEBUG']
      true
    rescue StandardError => e
      puts "Error: Failed to load environment configuration - #{e.message}" if ENV['DEBUG']
      false
    end


    ##
    # Configures logging for ruby_llm.
    #
    # @param config_obj [RubyLLM::Configuration] The configuration object
    # @param config [Hash] The configuration hash
    #
    def self.configure_logging(config_obj, config)
      log_file = config['log_file'] || config[:log_file]
      
      if log_file
        # Create log directory if it doesn't exist
        log_dir = File.dirname(log_file)
        FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
        
        # Set up file logging (this will depend on ruby_llm's logging interface)
        ComputerTools.logger&.info("Ruby_llm logging configured", { log_file: log_file })
      end
    end

    ##
    # Returns the current ruby_llm configuration status.
    #
    # @return [Hash] Configuration status information
    #
    def self.status
      {
        configured: true,
        provider: ENV['RUBY_LLM_PROVIDER'] || 'openrouter',
        model: ENV['RUBY_LLM_MODEL'] || "anthropic/claude-3.5-sonnet",
        has_openrouter_key: !ENV['OPENROUTER_API_KEY'].nil?,
        has_openai_key: !ENV['OPENAI_API_KEY'].nil?,
        has_anthropic_key: !ENV['ANTHROPIC_API_KEY'].nil?
      }
    rescue StandardError => e
      {
        configured: false,
        error: e.message
      }
    end
  end
end