# frozen_string_literal: true

module ComputerTools
  module Actions
    # Analyzes a list of untracked files by providing basic file information
    # without backup comparison complexity. This action generates simple file
    # metadata suitable for daily reports including file path, size, modification
    # time, and other basic properties.
    #
    # This is a lightweight replacement for backup comparison functionality,
    # focusing on providing consistent data structure for reporting while
    # maintaining compatibility with the existing report generation system.
    class UntrackedAnalysisAction < Sublayer::Actions::Base
      # Initializes the UntrackedAnalysisAction.
      #
      # @param files [Array<Hash>] An array of file information hashes. Each hash
      #   is expected to contain keys like `:path`, `:full_path`, `:modified_time`,
      #   and `:size`.
      # @param config [Hash] A configuration hash containing display settings
      #   such as time format and other display preferences.
      def initialize(files:, config:)
        @files = files
        @config = config
      end

      # Executes the file analysis for untracked files.
      #
      # The method processes each file to generate basic metadata including:
      # - File path and modification time
      # - File size in human-readable format
      # - Basic tracking information (marked as 'Untracked')
      # - Line count for text files
      #
      # @return [Array<Hash>] An array of hashes, where each hash represents a
      #   file and contains basic analysis data including modification time,
      #   size, and tracking information. Returns an empty array if the initial
      #   file list is empty.
      def call
        return [] if @files.empty?

        data = []

        @files.each do |file_info|
          file_data = analyze_untracked_file(file_info)
          data << file_data if file_data
        rescue StandardError => e
          puts "⚠️  Warning: Could not analyze file #{file_info[:path]}: #{e.message}".colorize(:yellow)
        end

        data
      rescue StandardError => e
        puts "❌ Error analyzing untracked files: #{e.message}".colorize(:red)
        puts "   File: #{e.backtrace.first}" if e.backtrace&.first
        puts "   Full backtrace:" if ENV['DEBUG']
        puts e.backtrace.first(3).join("\n   ") if ENV['DEBUG'] && e.backtrace
        []
      end

      private

      # @private
      # Analyzes a single untracked file to generate basic metadata.
      #
      # @param file_info [Hash] The information hash for the local file.
      # @return [Hash] A hash containing the formatted analysis data for the file.
      def analyze_untracked_file(file_info)
        # Get line count for text files
        line_count = count_lines(file_info[:full_path])
        
        status_info = { 
          raw_status: 'U ', 
          index: 'N/A', 
          worktree: 'Untracked' 
        }
        
        diff_info = {
          additions: line_count,
          deletions: 0,
          chunks: line_count > 0 ? 1 : 0
        }

        create_file_data(file_info, 'Untracked', status_info, diff_info)
      end

      # @private
      # Counts the number of lines in a given file.
      #
      # @param file_path [String] The path to the file.
      # @return [Integer] The number of lines in the file, or 0 if an error occurs.
      def count_lines(file_path)
        File.readlines(file_path).length
      rescue StandardError
        0
      end

      # @private
      # Creates the final formatted hash for a file's analysis data.
      #
      # @param file_info [Hash] The original file information hash.
      # @param tracking [String] The source of the tracking information ('Untracked').
      # @param status_info [Hash] A hash with status details like `:raw_status` and `:worktree`.
      # @param diff_info [Hash] A hash with diff details like `:additions` and `:deletions`.
      # @return [Hash] The fully-formed hash for display or further processing.
      def create_file_data(file_info, tracking, status_info, diff_info)
        {
          file: file_info[:path],
          modified: file_info[:modified_time].strftime(time_format),
          modified_time: file_info[:modified_time],
          size: format_size(file_info[:size]),
          tracking: tracking,
          git_status: status_info[:raw_status] || '--',
          index: status_info[:index] || 'N/A',
          worktree: status_info[:worktree] || 'N/A',
          additions: diff_info[:additions] || 0,
          deletions: diff_info[:deletions] || 0,
          chunks: diff_info[:chunks] || 0
        }
      end

      # @private
      # Retrieves the time format string from the configuration.
      #
      # @return [String] The time format string (e.g., '%Y-%m-%d %H:%M').
      def time_format
        @config.fetch('display', 'time_format')
      end

      # @private
      # Formats a file size in bytes into a human-readable string.
      #
      # @param bytes [Numeric, nil] The file size in bytes.
      # @return [String] A human-readable string (e.g., "1.2MB", "512B") or 'N/A' if input is not numeric.
      def format_size(bytes)
        return 'N/A' unless bytes.is_a?(Numeric)

        units = ['B', 'KB', 'MB', 'GB']
        size = bytes.to_f
        unit_index = 0

        while size >= 1024 && unit_index < units.length - 1
          size /= 1024.0
          unit_index += 1
        end

        if unit_index == 0
          "#{size.to_i}#{units[unit_index]}"
        else
          "#{size.round(1)}#{units[unit_index]}"
        end
      end
    end
  end
end