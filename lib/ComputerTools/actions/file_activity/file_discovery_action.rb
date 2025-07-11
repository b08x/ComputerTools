# frozen_string_literal: true

module ComputerTools
  module Actions
    # Discovers recently modified files within a specified directory using the `fd` command.
    #
    # This action is a core component for finding file activity. It scans a directory
    # for files changed within a given time frame, gathers metadata for each file,
    # and determines how the file is tracked (e.g., by Git or yadm).
    #
    # @note This class requires the `fd` command-line tool to be installed and
    #   available in the system's PATH. If `fd` is not found, the action will
    #   print an error and return an empty array.
    #
    # @see ComputerTools::Actions::LatestChangesAction which uses this action to find files.
    class FileDiscoveryAction < Sublayer::Actions::Base
      # Initializes a new FileDiscoveryAction.
      #
      # @param directory [String] The path to the directory to search. Can be '.' for the current directory.
      # @param time_range [String] A time string compatible with `fd`'s `--changed-within` flag (e.g., '24h', '2d', '1w').
      # @param config [ComputerTools::Configuration] The application configuration object, used to resolve paths like the home directory.
      def initialize(directory:, time_range:, config:)
        @directory = directory
        @time_range = time_range
        @config = config
      end

      # Executes the file discovery process.
      #
      # It constructs and runs an `fd` command to find files modified within the
      # specified time range. Each found file is then processed to gather metadata.
      #
      # @return [Array<Hash>] An array of hashes, where each hash represents a
      #   found file and contains the following keys:
      #   - `:path` (String) The relative path of the file.
      #   - `:full_path` (String) The absolute path of the file.
      #   - `:modified_time` (Time) The last modification time.
      #   - `:size` (Integer) The size of the file in bytes.
      #   - `:tracking_method` (Symbol) The version control method (`:git`, `:yadm`, or `:none`).
      # @return [Array] An empty array if the `fd` command is not found or if an error occurs during execution.
      def call
        unless TTY::Which.exist?('fd')
          puts "❌ 'fd' command not found. Please install fd for file search functionality.".colorize(:red)
          return []
        end

        search_dir = @directory == '.' ? home_dir : @directory

        cmd = "fd --type f --changed-within #{@time_range} . \"#{search_dir}\""
        files_output = `#{cmd}`

        files = files_output.split("\n").filter_map do |file|
          next if file.strip.empty?

          begin
            process_file(file, search_dir)
          rescue StandardError => e
            puts "⚠️  Warning: Could not process file #{file}: #{e.message}".colorize(:yellow)
            next
          end
        end

        puts "📁 Found #{files.length} recently modified files".colorize(:green)
        files
      rescue StandardError => e
        puts "❌ Error discovering files: #{e.message}".colorize(:red)
        puts "   File: #{e.backtrace.first}" if e.backtrace&.first
        puts "   Full backtrace:" if ENV['DEBUG']
        puts e.backtrace.first(3).join("\n   ") if ENV['DEBUG'] && e.backtrace
        []
      end

      private

      # @!method process_file(file, search_dir)
      # @!visibility private
      # Gathers metadata for a single file.
      # @param file [String] The full path to the file.
      # @param search_dir [String] The base directory of the search.
      # @return [Hash] A hash containing file metadata.
      def process_file(file, search_dir)
        stat = File.stat(file)
        relative_path = file.gsub("#{search_dir}/", '')

        {
          path: relative_path,
          full_path: file,
          modified_time: stat.mtime,
          size: stat.size,
          tracking_method: determine_tracking_method(file)
        }
      end

      # @!method determine_tracking_method(file_path)
      # @!visibility private
      # Determines the version control tracking method for a file.
      # It checks for a `.git` directory in parent folders or if the file is tracked by `yadm`.
      # @param file_path [String] The full path to the file.
      # @return [Symbol] `:git`, `:yadm`, or `:none`.
      def determine_tracking_method(file_path)
        # Check if file is in a git repository
        dir = File.dirname(file_path)
        while dir != '/' && dir != home_dir
          return :git if File.directory?(File.join(dir, '.git'))

          dir = File.dirname(dir)
        end

        # Check if file is tracked by yadm
        return :yadm if yadm_tracked?(file_path)

        :none
      end

      # @!method yadm_tracked?(file_path)
      # @!visibility private
      # Checks if a file is tracked by yadm.
      # Requires the `yadm` command-line tool.
      # @param file_path [String] The full path to the file.
      # @return [Boolean] True if the file is tracked by yadm, false otherwise.
      def yadm_tracked?(file_path)
        return false unless TTY::Which.exist?('yadm')

        cmd = "yadm list -a"
        output = `#{cmd} 2>/dev/null`
        return false unless $?.success?

        tracked_files = output.split("\n")
        relative_path = file_path.gsub("#{home_dir}/", '')
        tracked_files.include?(relative_path)
      end

      # @!method home_dir
      # @!visibility private
      # Retrieves the user's home directory path from the configuration.
      # @return [String] The path to the home directory.
      def home_dir
        @config.fetch('paths', 'home_dir')
      end
    end
  end
end