# frozen_string_literal: true

require 'colorize'
require_relative 'file_discovery_action'
require_relative 'git_analysis_action'
require_relative 'yadm_analysis_action'
require_relative 'restic_analysis_action'
require_relative '../generators/file_activity_report_generator'
require_relative '../configuration'

module ComputerTools
  module Actions
    class LatestChangesAction < Sublayer::Actions::Base
      def initialize(directory:, time_range: '24h', format: 'table', interactive: false)
        @directory = File.expand_path(directory)
        @time_range = time_range
        @format = format.to_sym
        @interactive = interactive
        @configuration = ComputerTools::Configuration.new
        @config = @configuration
      end

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

      def discover_recent_files
        puts "🔎 Discovering recent files...".colorize(:yellow)

        FileDiscoveryAction.new(
          directory: @directory,
          time_range: @time_range,
          config: @config
        ).call
      end

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
          restic_data = ResticAnalysisAction.new(
            files: untracked_files,
            config: @config
          ).call
          all_data.concat(restic_data) if restic_data
        end

        all_data
      end

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

      def handle_no_files
        puts "ℹ️  No files modified in the last #{@time_range}".colorize(:cyan)
        true
      end

      def handle_no_data
        puts "ℹ️  No analyzable file data found".colorize(:cyan)
        true
      end
    end
  end
end