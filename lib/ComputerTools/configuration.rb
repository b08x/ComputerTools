# frozen_string_literal: true

module ComputerTools
  # Main configuration manager for ComputerTools application.
  #
  # Handles loading, saving, and interactive setup of application configuration
  # using TTY::Config. Manages paths, display settings, restic configuration,
  # terminal preferences, and logging setup.
  #
  # @example Basic usage:
  #   config = ComputerTools::Configuration.new
  #   config.interactive_setup
  class Configuration
    # Initializes a new Configuration instance.
    #
    # Sets up the configuration file path, initializes TTY::Config,
    # and loads existing configuration or sets up defaults.
    #
    # @return [ComputerTools::Configuration] a new instance of Configuration
    def initialize
      @config_file = File.expand_path('~/.config/computertools/config.yml')
      @config = TTY::Config.new
      @config.filename = 'config'
      @config.extname = '.yml'
      @config.append_path(File.dirname(@config_file))
      @config.env_prefix = 'COMPUTERTOOLS'
      @prompt = TTY::Prompt.new
      load_config
    end

    # Provides read access to the configuration object.
    #
    # @return [TTY::Config] the configuration object
    attr_reader :config

    # Runs interactive configuration setup process.
    #
    # Guides user through configuration of paths, display settings,
    # restic parameters, terminal preferences, and logging options.
    # Handles errors and validation issues during the process.
    #
    # @return [Boolean] true if configuration was successful, false otherwise
    #
    # @example Running interactive setup:
    #   config = ComputerTools::Configuration.new
    #   config.interactive_setup
    def interactive_setup
      puts "🔧 ComputerTools Configuration Setup".colorize(:blue)
      puts "=" * 40

      # Set up defaults if config is empty
      setup_defaults unless @config.exist?

      # Configure paths
      configure_paths
      configure_display
      configure_restic
      configure_terminals
      configure_logger

      save_config
      puts "\n✅ Configuration saved to #{@config_file}".colorize(:green)
    rescue TTY::Config::ValidationError => e
      puts "\n❌ Configuration validation failed: #{e.message}".colorize(:red)
      puts "🔄 Please check your input and try again.".colorize(:yellow)
      false
    rescue StandardError => e
      puts "\n❌ Setup failed: #{e.message}".colorize(:red)
      puts "🔄 Using default configuration.".colorize(:yellow)
      setup_defaults
      false
    end

    # Compatibility method for fetching configuration values.
    #
    # Provides a safe way to fetch configuration values with error handling.
    # Logs warnings when debug mode is enabled.
    #
    # @param keys [Array<String, Symbol>] the configuration keys to fetch
    # @return [Object, nil] the fetched configuration value or nil if an error occurs
    #
    # @example Fetching a configuration value:
    #   timeout = config.fetch(:restic, :mount_timeout)
    def fetch(*keys)
      @config.fetch(*keys)
    rescue StandardError => e
      puts "⚠️  Warning: Failed to fetch config key #{keys.join('.')}: #{e.message}".colorize(:yellow) if ENV['DEBUG']
      nil
    end

    private

    # Loads configuration from file or sets up defaults.
    #
    # Attempts to read existing configuration file, handles various error cases,
    # and falls back to default configuration when needed.
    #
    # @return [void]
    def load_config
      if @config.exist?
        begin
          @config.read
          puts "📁 Loaded configuration from #{@config_file}".colorize(:green) if ENV['DEBUG']
        rescue TTY::Config::ReadError => e
          puts "❌ Failed to read configuration file: #{e.message}".colorize(:red)
          puts "🔄 Using default configuration instead.".colorize(:yellow)
          setup_defaults
        rescue TTY::Config::ValidationError => e
          puts "❌ Configuration validation failed: #{e.message}".colorize(:red)
          puts "🔄 Using default configuration instead.".colorize(:yellow)
          setup_defaults
        end
      else
        setup_defaults
        puts "⚠️  Using default configuration. Run 'latest-changes config' to customize.".colorize(:yellow)
      end
    rescue StandardError => e
      puts "❌ Unexpected error loading configuration: #{e.message}".colorize(:red)
      puts "🔄 Using default configuration.".colorize(:yellow)
      setup_defaults
    end

    # Saves the current configuration to file.
    #
    # Creates backup of existing configuration if it exists,
    # ensures directory structure exists, and writes the configuration.
    #
    # @return [void]
    #
    # @raise [TTY::Config::WriteError] if configuration cannot be saved
    def save_config
      TTY::File.create_directory(File.dirname(@config_file), verbose: false)

      # Use TTY::File for collision detection and user interaction
      if File.exist?(@config_file)
        # Create a backup before overwriting
        backup_file = "#{@config_file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        TTY::File.copy_file(@config_file, backup_file, verbose: false)
        puts "📋 Created backup at #{backup_file}".colorize(:blue) if ENV['DEBUG']
      end

      @config.write(create: true, force: true)
    rescue TTY::Config::WriteError => e
      puts "❌ Failed to save configuration: #{e.message}".colorize(:red)
      raise
    end

    # Creates configuration file interactively with user confirmation.
    #
    # Uses TTY::File to handle file creation with collision detection
    # and user interaction for existing files.
    #
    # @return [Boolean] true if file was created successfully, false otherwise
    def create_config_file_interactive
      content = @config.marshal(@config.to_hash)

      TTY::File.create_file(
        @config_file, content,
        verbose: true,
        color: :green,
        force: false, # Don't force overwrite - let user decide
        skip: false
      ) # Don't skip - show collision options
    rescue TTY::File::InvalidPathError => e
      puts "❌ Invalid path: #{e.message}".colorize(:red)
      false
    end

    # Checks if an external command is available on the system.
    #
    # Uses Terrapin to check command availability with proper error handling.
    #
    # @param command [String] the command to check
    # @return [Boolean] true if command is available, false otherwise
    def command_available?(command)
      cmd = Terrapin::CommandLine.new("which", ":command", command: command)
      cmd.run
      true
    rescue Terrapin::CommandNotFoundError, Terrapin::ExitStatusError
      false
    rescue StandardError => e
      puts "⚠️  Warning: Could not check for command '#{command}': #{e.message}".colorize(:yellow) if ENV['DEBUG']
      false
    end

    # Validates that the configured terminal command is available.
    #
    # Checks if the terminal command specified in configuration is available
    # on the system, with appropriate logging.
    #
    # @return [Boolean] true if terminal is available, false otherwise
    def validate_terminal_command
      command = @config.fetch(:terminal, 'kitty')

      if command_available?(command)
        puts "✅ Terminal '#{command}' is available".colorize(:green) if ENV['DEBUG']
        true
      else
        puts "⚠️  Terminal '#{command}' is not available on this system".colorize(:yellow)
        false
      end
    rescue StandardError => e
      puts "❌ Failed to validate terminal command: #{e.message}".colorize(:red)
      false
    end

    # Sets up default configuration values.
    #
    # Configures default values for paths, display settings, restic parameters,
    # terminal preferences, and logging options. Also sets up environment
    # variable mappings and validators.
    #
    # @return [void]
    #
    # @raise [StandardError] if default configuration cannot be set up
    def setup_defaults
      @config.set(:paths, :home_dir, value: File.expand_path('~'))
      @config.set(:paths, :restic_mount_point, value: File.expand_path('/mnt/snapshots'))
      @config.set(:paths, :restic_repo, value: ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo')

      @config.set(:display, :time_format, value: '%Y-%m-%d %H:%M:%S')

      @config.set(:restic, :mount_timeout, value: 60)

      @config.set(:terminal, :command, value: 'kitty')
      @config.set(:terminal, :args, value: '-e')

      # Logger defaults
      @config.set(:logger, :level, value: 'info')
      @config.set(:logger, :file_logging, value: false)
      @config.set(:logger, :file_path, value: default_log_path_for_config)
      @config.set(:logger, :file_level, value: 'debug')

      setup_environment_variables
      setup_validators

      puts "✅ Default configuration loaded successfully".colorize(:green) if ENV['DEBUG']
    rescue StandardError => e
      puts "❌ Failed to set up default configuration: #{e.message}".colorize(:red)
      raise
    end

    # Sets up environment variable mappings for configuration.
    #
    # Maps configuration keys to corresponding environment variables
    # that can override the configuration values.
    #
    # @return [void]
    def setup_environment_variables
      # Map configuration keys to environment variables
      @config.set_from_env(:paths, :home_dir) { 'COMPUTERTOOLS_HOME_DIR' }
      @config.set_from_env(:paths, :restic_mount_point) { 'COMPUTERTOOLS_RESTIC_MOUNT_POINT' }
      @config.set_from_env(:paths, :restic_repo) { 'RESTIC_REPOSITORY' }
      @config.set_from_env(:display, :time_format) { 'COMPUTERTOOLS_TIME_FORMAT' }
      @config.set_from_env(:restic, :mount_timeout) { 'COMPUTERTOOLS_RESTIC_TIMEOUT' }
      @config.set_from_env(:terminal, :command) { 'COMPUTERTOOLS_TERMINAL_COMMAND' }
      @config.set_from_env(:terminal, :args) { 'COMPUTERTOOLS_TERMINAL_ARGS' }
      @config.set_from_env(:logger, :level) { 'COMPUTERTOOLS_LOG_LEVEL' }
      @config.set_from_env(:logger, :file_logging) { 'COMPUTERTOOLS_LOG_FILE_ENABLED' }
      @config.set_from_env(:logger, :file_path) { 'COMPUTERTOOLS_LOG_FILE_PATH' }
      @config.set_from_env(:logger, :file_level) { 'COMPUTERTOOLS_LOG_FILE_LEVEL' }
    end

    # Sets up validators for configuration values.
    #
    # Adds validation rules for various configuration parameters
    # to ensure they meet required criteria.
    #
    # @return [void]
    def setup_validators
      # Validate that home directory exists
      @config.validate(:paths, :home_dir) do |_key, value|
        unless Dir.exist?(File.expand_path(value))
          raise TTY::Config::ValidationError, "Home directory '#{value}' does not exist"
        end
      end

      # Validate mount timeout is a positive integer
      @config.validate(:restic, :mount_timeout) do |_key, value|
        unless value.is_a?(Integer) && value > 0
          raise TTY::Config::ValidationError, "Mount timeout must be a positive integer, got '#{value}'"
        end
      end

      # Validate time format string
      @config.validate(:display, :time_format) do |_key, value|
        Time.now.strftime(value)
      rescue ArgumentError => e
        raise TTY::Config::ValidationError, "Invalid time format '#{value}': #{e.message}"
      end

      # Validate terminal command
      @config.validate(:terminal, :command) do |_key, value|
        unless value.is_a?(String) && !value.empty?
          raise TTY::Config::ValidationError, "Terminal command must be a non-empty string"
        end
      end

      # Validate terminal args
      @config.validate(:terminal, :args) do |_key, value|
        raise TTY::Config::ValidationError, "Terminal args must be a string" unless value.is_a?(String)
      end
    end

    # Interactively configures path settings.
    #
    # Prompts user for home directory, restic mount point,
    # and restic repository paths.
    #
    # @return [void]
    def configure_paths
      puts "\n📁 Path Configuration".colorize(:blue)

      current_home = @config.fetch(:paths) { File.expand_path('~') }
      home_dir = @prompt.ask("Home directory:", default: current_home)
      @config.set(:paths, :home_dir, value: home_dir)

      current_mount = @config.fetch(:paths) { File.expand_path('/mnt/snapshots') }
      mount_point = @prompt.ask("Restic mount point:", default: current_mount)
      @config.set(:paths, :restic_mount_point, value: mount_point)

      current_repo = @config.fetch(:paths) { ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo' }
      repo = @prompt.ask("Restic repository:", default: current_repo)
      @config.set(:paths, :restic_repo, value: repo)
    end

    # Interactively configures display settings.
    #
    # Prompts user for time format preference.
    #
    # @return [void]
    def configure_display
      puts "\n🎨 Display Configuration".colorize(:blue)

      current_format = @config.fetch(:display, '%Y-%m-%d %H:%M:%S')
      time_format = @prompt.ask("Time format:", default: current_format)
      @config.set(:display, :time_format, value: time_format)
    end

    # Interactively configures restic settings.
    #
    # Prompts user for mount timeout value with validation.
    #
    # @return [void]
    def configure_restic
      puts "\n📦 Restic Configuration".colorize(:blue)

      current_timeout = @config.fetch(:restic, 60)
      timeout = @prompt.ask("Mount timeout in seconds:", default: current_timeout, convert: :int) do |q|
        q.validate(/^\d+$/, "Please enter a positive integer")
        q.modify :strip
      end
      @config.set(:restic, :mount_timeout, value: timeout)
    end

    # Interactively configures terminal settings.
    #
    # Prompts user for terminal command and arguments.
    #
    # @return [void]
    def configure_terminals
      puts "\n💻 Terminal Configuration".colorize(:blue)

      current_command = @config.fetch(:terminal, 'kitty')
      current_args = @config.fetch(:terminal, '-e')

      puts "Current terminal: #{current_command} #{current_args}".colorize(:cyan)

      command = @prompt.ask("Terminal command:", default: current_command)
      @config.set(:terminal, :command, value: command)

      args = @prompt.ask("Terminal arguments:", default: current_args)
      @config.set(:terminal, :args, value: args)
    end

    # Interactively configures logging settings.
    #
    # Prompts user for log level, file logging preferences,
    # log file path, and file log level.
    #
    # @return [void]
    def configure_logger
      puts "\n📝 Logger Configuration".colorize(:blue)

      current_level = @config.fetch(:logger, :level) { 'info' }
      level = @prompt.select("Console log level:", %w[debug info warn error], default: current_level)
      @config.set(:logger, :level, value: level)

      enable_file_logging = @prompt.yes?("Enable logging to a file?", default: @config.fetch(:logger, :file_logging))
      @config.set(:logger, :file_logging, value: enable_file_logging)

      return unless enable_file_logging

      current_path = @config.fetch(:logger, :file_path) { default_log_path_for_config }
      path = @prompt.ask("Log file path:", default: current_path)
      @config.set(:logger, :file_path, value: path)

      current_file_level = @config.fetch(:logger, :file_level) { 'debug' }
      file_level = @prompt.select("File log level:", %w[debug info warn error], default: current_file_level)
      @config.set(:logger, :file_level, value: file_level)
    end

    # Determines the default log file path based on system configuration.
    #
    # Uses XDG_STATE_HOME environment variable if available, otherwise
    # falls back to standard ~/.local/state path.
    #
    # @return [String] the default log file path
    def default_log_path_for_config
      state_home = ENV['XDG_STATE_HOME'] || File.expand_path('~/.local/state')
      File.join(state_home, 'computertools', 'app.log')
    end
  end
end
