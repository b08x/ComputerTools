# frozen_string_literal: true

module ComputerTools
  module Actions
    # Discovers, analyzes, and reports on recently modified files within a specified
    # directory. This action serves as a high-level orchestrator that:
    # 1. Finds files changed within a given time frame using `FileDiscoveryAction`.
    # 2. Categorizes files by their tracking method (:git, :yadm, or :none).
    # 3. Delegates the analysis of each category to specialized actions.
    # 4. Generates a consolidated report of all changes.
    #
    # This is useful for getting a quick overview of recent work, preparing for
    # commits, or ensuring that important changes are properly tracked.
    class LatestChangesAction < Sublayer::Actions::Base
      # Initializes the action with configuration for the file analysis.
      #
      # @param directory [String] The path to the directory to analyze.
      # @param time_range [String] The lookback period for file changes (e.g., '24h', '7d').
      #   This string is passed directly to the `fd` command.
      # @param format [String] The desired output format for the report ('table', 'json', etc.).
      # @param interactive [Boolean] If true, the report may include interactive elements.
      def initialize(directory:, time_range: '24h', format: 'table', interactive: false)
        @directory = File.expand_path(directory)
        @time_range = time_range
        @format = format.to_sym
        @interactive = interactive
        @configuration = ComputerTools::Configuration.new
        @config = @configuration
      end

      # Executes the file discovery, analysis, and reporting workflow.
      #
      # The method handles the entire process, from finding files to displaying the
      # final report. It gracefully handles cases where no files are found or no
      # analyzable data is produced. Errors during the process are caught and
      # logged to the console.
      #
      # @example Run an analysis on the current directory for the last 24 hours
      #   ComputerTools::Actions::LatestChangesAction.new(directory: '.').call
      #
      # @return [Boolean] Returns `true` if the analysis completes successfully
      #   (even if no files are found), and `false` if an error occurs.
      def call
        puts "🔍 Starting file analysis...".colorize(:blue)
        puts "📁 Directory: #{@directory == File.expand_path('.') ? '.' : @directory}".colorize(:cyan)
        puts "⏰ Time range: #{@time_range}".colorize(:cyan)

        # Step 1: Discover recent files
        recent_files = discover_recent_files
        return handle_no_files if recent_files.empty?

        # Step 2: Analyze files by tracking method
        all_data = analyze_files_by_tracking_method(recent_files)
        return handle_no_data if all_data.empty?

        # Step 3: Generate and display report
        generate_report(all_data)

        puts "✅ Analysis completed successfully!".colorize(:green)
        true
      rescue StandardError => e
        puts "❌ Error during analysis: #{e.message}".colorize(:red)
        puts "   File: #{e.backtrace.first}" if e.backtrace&.first
        puts "   Full backtrace:" if ENV['DEBUG']
        puts e.backtrace.first(5).join("\n   ") if ENV['DEBUG'] && e.backtrace
        false
      end

      private

      # @private
      # Discovers recently modified files using FileDiscoveryAction.
      # @return [Array<Hash>] A list of file hashes, or an empty array if none are found.
      def discover_recent_files
        puts "🔎 Discovering recent files...".colorize(:yellow)

        FileDiscoveryAction.new(
          directory: @directory,
          time_range: @time_range,
          config: @config
        ).call
      end

      # @private
      # Analyzes a list of files by grouping them by their tracking method
      # and delegating to the appropriate analysis action.
      # @param recent_files [Array<Hash>] The list of files to analyze.
      # @return [Array<Hash>] A consolidated list of analysis data from all sources.
      def analyze_files_by_tracking_method(recent_files)
        puts "📊 Analyzing files by tracking method...".colorize(:yellow)

        # Group files by tracking method
        git_files = recent_files.select { |f| f[:tracking_method] == :git }
        yadm_files = recent_files.select { |f| f[:tracking_method] == :yadm }
        untracked_files = recent_files.select { |f| f[:tracking_method] == :none }

        all_data = []

        # Process Git files
        unless git_files.empty?
          puts "  📝 Processing #{git_files.length} Git-tracked files...".colorize(:blue)
          git_data = GitAnalysisAction.new(
            files: git_files,
            config: @config
          ).call
          all_data.concat(git_data) if git_data
        end

        # Process YADM files
        unless yadm_files.empty?
          puts "  🏠 Processing #{yadm_files.length} YADM-tracked files...".colorize(:blue)
          yadm_data = YadmAnalysisAction.new(
            files: yadm_files,
            config: @config
          ).call
          all_data.concat(yadm_data) if yadm_data
        end

        # Process untracked files
        unless untracked_files.empty?
          puts "  📦 Processing #{untracked_files.length} untracked files...".colorize(:blue)
          untracked_data = UntrackedAnalysisAction.new(
            files: untracked_files,
            config: @config
          ).call
          all_data.concat(untracked_data) if untracked_data
        end

        all_data
      end

      # @private
      # Generates and displays the final report.
      # @param data [Array<Hash>] The consolidated analysis data.
      # @return [void]
      def generate_report(data)
        puts "📋 Generating activity report...".colorize(:yellow)

        ComputerTools::Generators::FileActivityReportGenerator.new(
          data: data,
          format: @format,
          interactive: @interactive,
          time_range: @time_range,
          config: @config
        ).call
      end

      # @private
      # Handles the case where no recently modified files are found.
      # @return [true]
      def handle_no_files
        puts "ℹ️  No files modified in the last #{@time_range}".colorize(:cyan)
        true
      end

      # @private
      # Handles the case where analysis yields no data.
      # @return [true]
      def handle_no_data
        puts "ℹ️  No analyzable file data found".colorize(:cyan)
        true
      end
    end
  end
end