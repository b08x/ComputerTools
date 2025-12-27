# frozen_string_literal: true

module ComputerTools
  module Actions
    # Analyzes a list of files by comparing them against the latest snapshot in a
    # Restic backup repository. This action determines if files are new, modified,
    # or unchanged relative to their backed-up versions.
    #
    # It requires the `restic` command-line tool to be installed and accessible in the
    # system's PATH. The action will attempt to mount the Restic repository if it's
    # not already mounted.
    #
    # If `restic` is unavailable or the repository cannot be mounted, it gracefully
    # falls back to providing basic file information without comparison data.
    class ResticAnalysisAction < Sublayer::Actions::Base
      # Initializes the ResticAnalysisAction.
      #
      # @param files [Array<Hash>] An array of file information hashes. Each hash
      #   is expected to contain keys like `:path`, `:full_path`, `:modified_time`,
      #   and `:size`.
      # @param config [Hash] A configuration hash containing settings for Restic,
      #   such as repository path, mount point, and display formats.
      def initialize(files:, config:)
        @files = files
        @config = config
        @restic_wrapper = ComputerTools::Wrappers::ResticWrapper.new(config)
      end

      # Executes the file analysis against the Restic backup.
      #
      # The method performs the following steps:
      # 1. Checks for the `restic` executable.
      # 2. Ensures the Restic repository is mounted, attempting to mount it if necessary.
      # 3. Locates the path to the latest snapshot.
      # 4. Iterates through each file, comparing it with the version in the snapshot.
      #
      # If any of the initial checks fail (e.g., `restic` not found, mount fails),
      # the method returns a list of files with basic information and no comparison data.
      #
      # @return [Array<Hash>] An array of hashes, where each hash represents a
      #   file and contains detailed analysis data, including modification status,
      #   size, tracking source ('Restic', 'New', or 'None'), and diff statistics
      #   (additions, deletions). Returns an empty array if the initial file list is empty.
      def call
        return [] if @files.empty?

        unless TTY::Which.exist?('restic')
          puts "⚠️  Warning: 'restic' not found. Skipping backup comparison.".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        data = []

        # Check if restic is already mounted or attempt to mount
        unless @restic_wrapper.ensure_mounted
          puts "⚠️  Warning: Could not mount Restic backup. Analyzing files without comparison.".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        snapshot_path = @restic_wrapper.snapshot_path
        unless File.directory?(snapshot_path)
          puts "⚠️  Warning: Latest snapshot not found at #{snapshot_path}".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        @files.each do |file_info|
          file_data = analyze_untracked_file(file_info, snapshot_path)
          data << file_data if file_data
        rescue StandardError => e
          puts "⚠️  Warning: Could not analyze file #{file_info[:path]}: #{e.message}".colorize(:yellow)
        end

        data
      rescue StandardError => e
        puts "❌ Error analyzing untracked files: #{e.message}".colorize(:red)
        add_untracked_files_without_diff
      end

      private

      # @private
      # Analyzes a single file against its corresponding version in the snapshot.
      #
      # If the file exists in the snapshot, it's compared for changes. If not,
      # it's marked as a new file.
      #
      # @param file_info [Hash] The information hash for the local file.
      # @param snapshot_path [String] The path to the mounted Restic snapshot directory.
      # @return [Hash] A hash containing the formatted analysis data for the file.
      def analyze_untracked_file(file_info, snapshot_path)
        snapshot_file = File.join(snapshot_path, file_info[:path])

        if File.exist?(snapshot_file)
          # Compare with snapshot
          diff_result = @restic_wrapper.compare_with_snapshot(file_info[:full_path], snapshot_file)

          status_info = {
            raw_status: diff_result[:changed] ? 'M ' : '--',
            index: 'N/A',
            worktree: diff_result[:changed] ? 'Modified' : 'Unchanged'
          }

          create_file_data(file_info, 'Restic', status_info, diff_result)
        else
          # New file not in snapshot
          status_info = { raw_status: 'A ', index: 'N/A', worktree: 'Added' }
          diff_info = {
            additions: count_lines(file_info[:full_path]),
            deletions: 0,
            chunks: 1
          }

          create_file_data(file_info, 'New', status_info, diff_info)
        end
      end

      # @private
      # Generates a basic list of file data when Restic comparison is not possible.
      #
      # This serves as a fallback, populating file data with 'N/A' for tracking
      # and diff-related fields.
      #
      # @return [Array<Hash>] An array of hashes with basic file information.
      def add_untracked_files_without_diff
        @files.map do |file_info|
          {
            file: file_info[:path],
            modified: file_info[:modified_time].strftime(time_format),
            modified_time: file_info[:modified_time],
            size: format_size(file_info[:size]),
            tracking: 'None',
            git_status: '--',
            index: 'N/A',
            worktree: 'N/A',
            additions: 0,
            deletions: 0,
            chunks: 0
          }
        end
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
      # @param tracking [String] The source of the tracking information (e.g., 'Restic', 'New').
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
          index: status_info[:index] || 'Clean',
          worktree: status_info[:worktree] || 'Clean',
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