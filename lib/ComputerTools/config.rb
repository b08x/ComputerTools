# frozen_string_literal: true

module ComputerTools
  # Provides a mechanism for loading configuration settings.
  module Config
    ##
    # Loads and applies configuration for the Sublayer gem from a YAML file.
    #
    # This method searches for a `sublayer.yml` file within a `config` directory
    # located relative to this source file (`lib/ComputerTools/config/sublayer.yml`).
    # If the file exists, it uses the settings to configure the `Sublayer` gem,
    # setting the AI provider, model, and a default JSON logger.
    #
    # The logger is configured to write to `log/sublayer.log` in the current
    # working directory from which the script is executed.
    #
    # If the configuration file is not found, a warning is printed to STDOUT,
    # and no configuration is performed.
    #
    # @return [Sublayer::Logging::JsonLogger, nil] The configured logger instance on
    #   successful configuration, or `nil` if the configuration file is not found.
    # @raise [NameError] If the `ai_provider` specified in the YAML file does not
    #   correspond to a valid `Sublayer::Providers` constant.
    # @raise [Psych::SyntaxError] If the `sublayer.yml` file contains invalid YAML.
    #
    # @example Basic Usage (when config file exists)
    #   # Given a file at /path/to/gem/lib/ComputerTools/config/sublayer.yml with:
    #   # ---
    #   # ai_provider: "OpenAI"
    #   # ai_model: "gpt-4-turbo"
    #
    #   # This will configure the Sublayer gem accordingly.
    #   ComputerTools::Config.load
    #
    # @example File Not Found
    #   # When config/sublayer.yml does not exist.
    #   ComputerTools::Config.load
    #   # => Prints "Warning: config/sublayer.yml not found. Using default configuration."
    #   # => Returns nil
    #
    def self.load
      config_path = File.join(File.dirname(__FILE__), "config", "sublayer.yml")

      if File.exist?(config_path)
        config = YAML.load_file(config_path)

        Sublayer.configure do |c|
          c.ai_provider = Object.const_get("Sublayer::Providers::#{config[:ai_provider]}")
          c.ai_model = config[:ai_model]
          c.logger = Sublayer::Logging::JsonLogger.new(File.join(Dir.pwd, 'log', 'sublayer.log'))
        end
      else
        puts "Warning: config/sublayer.yml not found. Using default configuration."
      end
    end
  end
end