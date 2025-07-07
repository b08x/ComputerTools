# frozen_string_literal: true

require 'colorize'
require_relative 'base_command'

module ComputerTools
  module Commands
    class LatestChangesCommand < BaseCommand
      def self.description
        "Analyze recent file changes across Git, YADM, and Restic tracking methods"
      end

      def initialize(options)
        super
        @directory = options['directory'] || '.'
        @time_range = options['time_range'] || '24h'
        @format = options['format'] || 'table'
        @interactive = options['interactive'] || false
      end

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

      def handle_config
        puts "⚙️  Configuration setup for file analysis...".colorize(:blue)

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