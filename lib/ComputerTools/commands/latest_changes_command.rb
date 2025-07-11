# frozen_string_literal: true

module ComputerTools
  module Commands
    ##
    # LatestChangesCommand provides functionality to analyze recent file changes across
    # multiple tracking systems including Git, YADM, and Restic. This command helps
    # developers track modifications in their projects and dotfiles over specified time periods.
    #
    # The command supports multiple output formats and can operate in interactive mode
    # for better user experience. It serves as a comprehensive tool for monitoring file
    # activity across different version control and backup systems.
    #
    # == Usage Examples
    #
    #   # Basic usage - analyze current directory for last 24 hours
    #   LatestChangesCommand.new({}).execute
    #
    #   # Analyze specific directory with custom time range
    #   LatestChangesCommand.new({'directory' => '~/projects', 'time_range' => '7d'}).execute
    #
    #   # Get output in JSON format
    #   LatestChangesCommand.new({'format' => 'json'}).execute
    #
    #   # Run in interactive mode
    #   LatestChangesCommand.new({'interactive' => true}).execute
    #
    #   # Access configuration options
    #   LatestChangesCommand.new({}).execute('config')
    class LatestChangesCommand < BaseCommand
      ##
      # Provides a description of what this command does.
      #
      # @return [String] A description of the command's purpose
      def self.description
        "Analyze recent file changes across Git, YADM, and Restic tracking methods"
      end

      ##
      # Initializes a new LatestChangesCommand with the provided options.
      #
      # @param [Hash] options The options to configure the command
      # @option options [String] :directory The directory to analyze (defaults to current directory)
      # @option options [String] :time_range The time range for analysis (defaults to '24h')
      # @option options [String] :format The output format (defaults to 'table')
      # @option options [Boolean] :interactive Whether to run in interactive mode (defaults to false)
      def initialize(options)
        super
        @directory = options['directory'] || '.'
        @time_range = options['time_range'] || '24h'
        @format = options['format'] || 'table'
        @interactive = options['interactive'] || false
      end

      ##
      # Executes the command based on the provided arguments.
      #
      # This method routes to different handlers based on the subcommand provided.
      # Supported subcommands are 'analyze', 'config', and 'help'.
      #
      # @param [Array<String>] args The arguments to process
      # @return [Boolean, nil] Returns false when an unknown subcommand is provided, otherwise depends on the handler
      #
      # @example Execute with default analyze subcommand
      #   command = LatestChangesCommand.new({})
      #   command.execute
      #
      # @example Execute with config subcommand
      #   command = LatestChangesCommand.new({})
      #   command.execute('config')
      def execute(*args)
        subcommand = args.shift

        case subcommand
        when 'analyze', nil
          handle_analyze
        when 'config'
          handle_config
        when 'help'
          show_help
        else
          puts "❌ Unknown subcommand: #{subcommand}".colorize(:red)
          show_help
          false
        end
      end

      private

      ##
      # Handles the analyze subcommand to track recent file changes.
      #
      # This method initiates the analysis process, displaying status messages
      # and delegating the actual analysis to LatestChangesAction.
      #
      # @return [void]
      #
      # @see ComputerTools::Actions::LatestChangesAction
      def handle_analyze
        puts "🔍 Analyzing recent changes in #{@directory}...".colorize(:blue)
        puts "⏰ Time range: #{@time_range}".colorize(:cyan)

        ComputerTools::Actions::LatestChangesAction.new(
          directory: @directory,
          time_range: @time_range,
          format: @format,
          interactive: @interactive
        ).call
      end

      ##
      # Handles the configuration setup for file analysis.
      #
      # This method guides the user through an interactive configuration process
      # and handles any errors that might occur during the setup.
      #
      # @return [Boolean] true if configuration was successful, false otherwise
      #
      # @example Successful configuration
      #   command = LatestChangesCommand.new({})
      #   command.send(:handle_config) # returns true
      def handle_config
        puts "⚙️ Configuration setup for file analysis...".colorize(:blue)

        begin
          require_relative '../configuration'
          config = ComputerTools::Configuration.new
          config.interactive_setup
          puts "✅ Configuration updated successfully!".colorize(:green)
          true
        rescue StandardError => e
          puts "❌ Error in configuration setup: #{e.message}".colorize(:red)
          puts "   File: #{e.backtrace.first}" if ENV['DEBUG']
          false
        end
      end

      ##
      # Displays help information for the latest-changes command.
      #
      # This method outputs a comprehensive help message that explains
      # the available subcommands, options, and examples of usage.
      #
      # @return [void]
      #
      # @example Display help information
      #   command = LatestChangesCommand.new({})
      #   command.send(:show_help)
      def show_help
        puts <<~HELP
          File Activity Analysis Commands:

          📊 Analysis:
            latest-changes analyze              Analyze recent file changes (default)
            latest-changes config               Configure analysis settings

          Options:
            --directory PATH                    Directory to analyze (default: current)
            --time-range RANGE                  Time range for analysis (default: 24h)
                                               Examples: 1h, 6h, 24h, 2d, 1w
            --format FORMAT                     Output format (table, json, summary)
            --interactive                       Interactive mode with browsing

          Examples:
            latest-changes                      # Analyze current directory for last 24h
            latest-changes --directory ~/code   # Analyze specific directory
            latest-changes --time-range 7d      # Analyze last week
            latest-changes --format json        # Output as JSON
            latest-changes --interactive        # Interactive browsing mode
            latest-changes config               # Configure settings

          The analyzer tracks files across:
          • Git repositories (with diff analysis)
          • YADM dotfile management
          • Restic backup comparisons
          • Untracked files

        HELP
      end
    end
  end
end