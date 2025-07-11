# frozen_string_literal: true

module ComputerTools
  module Actions
    # Analyzes a list of files to determine their status within a `yadm`
    # (Yet Another Dotfiles Manager) repository. This action shells out to the
    # `yadm` command-line tool to get diff and status information for each file.
    #
    # It requires the `yadm` executable to be present in the system's PATH.
    # If `yadm` is not found, the action will issue a warning and return an
    # empty result.
    class YadmAnalysisAction < Sublayer::Actions::Base
      # Initializes the YadmAnalysisAction.
      #
      # @param files [Array<Hash>] An array of file information hashes. Each hash
      #   is expected to have at least a `:path` key with a string value.
      # @param config [Hash] A configuration hash, which should contain
      #   display settings like `time_format`.
      def initialize(files:, config:)
        @files = files
        @config = config
      end

      # Executes the yadm analysis for the provided files.
      #
      # It iterates through each file, gathering its status and diff information
      # from the yadm repository. The method handles errors gracefully, skipping
      # individual files that cause issues and returning an empty array if a
      # critical error occurs or if `yadm` is not installed.
      #
      # @return [Array<Hash>] An array of hashes, where each hash contains
      #   detailed analysis for a file. Returns an empty array if no files are
      #   provided or if `yadm` is not found. The hash structure for each file is:
      #   - `:file` [String] The file path.
      #   - `:modified` [String] The formatted modification time.
      #   - `:modified_time` [Time] The modification time object.
      #   - `:size` [String] The human-readable file size.
      #   - `:tracking` [String] The tracking system name ('YADM').
      #   - `:git_status` [String] The two-character raw git status (e.g., ' M').
      #   - `:index` [String] The human-readable index status (e.g., 'Modified').
      #   - `:worktree` [String] The human-readable work-tree status.
      #   - `:additions` [Integer] The number of added lines.
      #   - `:deletions` [Integer] The number of deleted lines.
      #   - `:chunks` [Integer] The number of diff chunks.
      def call
        return [] if @files.empty?

        unless TTY::Which.exist?('yadm')
          puts "⚠️  Warning: 'yadm' not found. Skipping YADM file processing.".colorize(:yellow)
          return []
        end

        data = []

        @files.each do |file_info|
          file_data = analyze_yadm_file(file_info)
          data << file_data if file_data
        rescue StandardError => e
          puts "⚠️  Warning: Could not analyze YADM file #{file_info[:path]}: #{e.message}".colorize(:yellow)
        end

        data
      rescue StandardError => e
        puts "❌ Error analyzing YADM files: #{e.message}".colorize(:red)
        []
      end

      private

      # Analyzes a single file using `yadm` commands.
      #
      # @param file_info [Hash] A hash containing the file's path.
      # @return [Hash, nil] A hash with analysis data, or nil on failure.
      # @private
      def analyze_yadm_file(file_info)
        relative_path = file_info[:path]

        # Get diff information
        diff_output = `yadm diff HEAD -- "#{relative_path}" 2>/dev/null`
        diff_info = parse_diff_output(diff_output)

        # Get status information
        status_output = `yadm status --porcelain "#{relative_path}" 2>/dev/null`
        status_info = parse_status_output(status_output)

        create_file_data(file_info, 'YADM', status_info, diff_info)
      end

      # Parses the output of `yadm diff` to count changes.
      #
      # @param diff_output [String] The raw string output from the diff command.
      # @return [Hash{Symbol => Integer}] A hash with counts for additions,
      #   deletions, and chunks.
      # @private
      def parse_diff_output(diff_output)
        {
          additions: diff_output.scan(/^\+[^+]/).length,
          deletions: diff_output.scan(/^-[^-]/).length,
          chunks: diff_output.scan(/^@@/).length
        }
      end

      # Parses the porcelain output of `yadm status`.
      #
      # @param status_output [String] The raw string from `yadm status --porcelain`.
      # @return [Hash{Symbol => String}] A hash with raw, index, and worktree status.
      # @private
      def parse_status_output(status_output)
        git_status = status_output.strip.empty? ? '--' : status_output[0..1]

        {
          raw_status: git_status,
          index: git_status[0] ? status_char_to_name(git_status[0]) : 'Clean',
          worktree: git_status[1] ? status_char_to_name(git_status[1]) : 'Clean'
        }
      end

      # Converts a git status character to a human-readable name.
      #
      # @param char [String] A single character representing a git status.
      # @return [String] The full name of the status (e.g., 'Modified').
      # @private
      def status_char_to_name(char)
        case char
        when 'M' then 'Modified'
        when 'A' then 'Added'
        when 'D' then 'Deleted'
        when 'R' then 'Renamed'
        when 'C' then 'Copied'
        when 'U' then 'Unmerged'
        when '?' then 'Untracked'
        when ' ' then 'Unchanged'
        else 'Unknown'
        end
      end

      # Creates the final data hash for a file.
      #
      # @param file_info [Hash] The original file information.
      # @param tracking [String] The name of the tracking system ('YADM').
      # @param status_info [Hash] The parsed status information.
      # @param diff_info [Hash] The parsed diff information.
      # @return [Hash] The consolidated file data hash.
      # @private
      def create_file_data(file_info, tracking, status_info, diff_info)
        {
          file: file_info[:path],
          modified: file_info[:modified_time].strftime(time_format),
          modified_time: file_info[:modified_time],
          size: format_size(file_info[:size]),
          tracking: tracking,
          git_status: status_info[:raw_status] || '--',
          index: status_info[:index] || 'Clean',
          worktree: status_info[:worktree] || 'Clean',
          additions: diff_info[:additions] || 0,
          deletions: diff_info[:deletions] || 0,
          chunks: diff_info[:chunks] || 0
        }
      end

      # Retrieves the time format string from the configuration.
      #
      # @return [String] The time format string.
      # @private
      def time_format
        @config.fetch('display', 'time_format')
      end

      # Formats a file size in bytes into a human-readable string.
      #
      # @param bytes [Numeric, nil] The file size in bytes.
      # @return [String] A formatted string (e.g., "1.2KB") or "N/A".
      # @private
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