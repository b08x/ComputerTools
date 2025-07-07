# frozen_string_literal: true

require 'table_tennis'
require 'git'
require 'time'
require 'fileutils'
require 'open3'
require 'tty-which'
require_relative '../logging'

module Tools
  ##
  # Analyzes files in a directory to determine their modification status,
  # tracking method (Git, yadm, Restic), and generates a report of recent changes.
  #
  # This class uses `fd` to find recently modified files, then categorizes them.
  # For version-controlled files (Git, yadm), it calculates diffs. For untracked
  # files, it attempts to compare them against a Restic backup snapshot.
  # The final output is a series of tables, grouped by hour, summarizing the activity.
  class GitFileAnalyzer
    include Logging

    ##
    # @!attribute [r] directory
    #   @return [String] The absolute path to the directory being analyzed.
    # @!attribute [r] time_range
    #   @return [String] The time range for finding recent files (e.g., '24h', '7d').
    # @!attribute [r] config
    #   @return [Hash] The application's configuration settings.
    attr_reader :directory, :time_range, :config

    ##
    # Initializes the analyzer.
    #
    # Sets up the directory, time range, and configuration. It also checks for
    # system dependencies, initializes a Git object if in a repository, and
    # sets up a cleanup handler for Restic mounts.
    #
    # @param [String] directory The directory to analyze. Defaults to the current directory.
    # @param [String] time_range A string representing the time range to search for
    #   modified files (e.g., '24h', '2d', '1w'). Passed to the `fd` command.
    def initialize(directory = '.', time_range = '24h')
      @directory = File.expand_path(directory)
      @time_range = time_range
      @configuration = Configuration.new
      @config = @configuration.config
      @restic_mounted = false
      @restic_pid = nil

      SystemDependencies.check!
      initialize_git_repository
      setup_cleanup_handler
    end

    ##
    # Runs an interactive setup process to configure the tool.
    #
    # This method delegates to the `Configuration` object to prompt the user
    # for necessary settings, such as paths and preferences.
    #
    # @return [void]
    def configure_interactively
      @configuration.interactive_setup
    end

    ##
    # The main entry point for running the file analysis.
    #
    # It performs the following steps:
    # 1. Finds all files modified within the specified `time_range`.
    # 2. Groups files by their tracking method (:git, :yadm, :none).
    # 3. Processes each group to gather status and diff information.
    # 4. Displays the aggregated data in hourly tables.
    #
    # @return [void]
    def analyze
      logger.info "Starting analysis of #{@directory == '.' ? home_dir : @directory}"
      logger.info "Time range: #{@time_range}"

      recent_files = get_recent_files

      if recent_files.empty?
        logger.info "No files modified in the last #{@time_range}"
        return
      end

      # Group files by tracking method
      git_files = recent_files.select { |f| f[:tracking_method] == :git }
      yadm_files = recent_files.select { |f| f[:tracking_method] == :yadm }
      untracked_files = recent_files.select { |f| f[:tracking_method] == :none }

      # Process each group
      all_data = []
      all_data.concat(process_git_files(git_files)) unless git_files.empty?
      all_data.concat(process_yadm_files(yadm_files)) unless yadm_files.empty?
      all_data.concat(process_untracked_files(untracked_files)) unless untracked_files.empty?

      # Display results grouped by hour
      display_hourly_tables(all_data)
    end

    private

    ##
    # Initializes a `Git::Base` object if the analysis directory is a Git repository.
    #
    # @return [void]
    def initialize_git_repository
      @git = nil
      return unless File.directory?(File.join(@directory, '.git'))

      begin
        @git = Git.open(@directory)
      rescue Git::Error
        logger.debug "Not a git repository or git error"
      end
    end

    ##
    # Registers an `at_exit` handler to ensure the Restic mount is cleaned up.
    #
    # @return [void]
    def setup_cleanup_handler
      at_exit { cleanup_restic_mount }
    end

    ##
    # Retrieves the user's home directory from the configuration.
    #
    # @return [String] The path to the home directory.
    def home_dir
      @config.fetch('paths', 'home_dir')
    end

    ##
    # Retrieves the Restic mount point from the configuration.
    #
    # @return [String] The path where the Restic backup should be mounted.
    def restic_mount_point
      @config.fetch('paths', 'restic_mount_point')
    end

    ##
    # Retrieves the Restic repository location from the configuration.
    #
    # @return [String] The identifier for the Restic repository.
    def restic_repo
      @config.fetch('paths', 'restic_repo')
    end

    ##
    # Retrieves the time format string from the configuration.
    #
    # @return [String] A `strftime`-compatible format string.
    def time_format
      @config.fetch('display', 'time_format')
    end

    ##
    # Retrieves the Restic mount timeout from the configuration.
    #
    # @return [Integer] The number of seconds to wait for the mount to become available.
    def mount_timeout
      @config.fetch('restic', 'mount_timeout')
    end

    ##
    # Retrieves the preferred terminal emulators from the configuration.
    #
    # @return [Array<Hash>] A list of terminal configurations, ordered by preference.
    def terminal_preferences
      @config.fetch('terminals', 'preferred_order')
    end

    ##
    # Finds recently modified files using the `fd` command.
    #
    # It constructs and executes an `fd` command to search for files changed
    # within the configured `time_range`.
    #
    # @return [Array<Hash>] An array of hashes, each representing a file with its
    #   path, modification time, size, and tracking method. Returns an empty
    #   array if `fd` is not installed.
    def get_recent_files
      search_dir = @directory == '.' ? home_dir : @directory

      unless TTY::Which.exist?('fd')
        logger.error "'fd' command not found. Please install fd for file search functionality."
        return []
      end

      cmd = "fd --type f --changed-within #{@time_range} . \"#{search_dir}\""
      files_output = `#{cmd}`

      files_output.split("\n").map do |file|
        next if file.strip.empty?

        stat = File.stat(file)
        relative_path = file.gsub("#{search_dir}/", '')

        {
          path: relative_path,
          full_path: file,
          modified_time: stat.mtime,
          size: stat.size,
          tracking_method: determine_tracking_method(file)
        }
      end.compact
    end

    ##
    # Determines how a file is tracked (Git, yadm, or none).
    #
    # It checks for a `.git` directory in parent paths and then checks if the
    # file is tracked by `yadm`.
    #
    # @param [String] file_path The absolute path to the file.
    # @return [Symbol] The tracking method (`:git`, `:yadm`, or `:none`).
    def determine_tracking_method(file_path)
      # Check if file is in a git repository
      dir = File.dirname(file_path)
      while dir != '/' && dir != home_dir
        if File.directory?(File.join(dir, '.git'))
          return :git
        end
        dir = File.dirname(dir)
      end

      # Check if file is tracked by yadm
      if yadm_tracked?(file_path)
        return :yadm
      end

      :none
    end

    ##
    # Checks if a file is tracked by yadm.
    #
    # @param [String] file_path The absolute path to the file.
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

    ##
    # Processes files that are tracked by a standard Git repository.
    #
    # For each file, it opens the corresponding repository, gets the file's
    # status and diff information, and formats it for display.
    #
    # @param [Array<Hash>] git_files An array of file info hashes for Git-tracked files.
    # @return [Array<Hash>] An array of data hashes ready for the report table.
    def process_git_files(git_files)
      logger.info "Processing #{git_files.length} git-tracked files"
      data = []

      git_files.each do |file_info|
        repo_path = find_git_repo(file_info[:full_path])
        next unless repo_path

        begin
          git = Git.open(repo_path)
          relative_to_repo = file_info[:full_path].gsub("#{repo_path}/", '')

          status_info = get_file_git_status(git, relative_to_repo)
          diff_info = get_file_git_diff(git, relative_to_repo)

          data << create_file_data(file_info, 'Git', status_info, diff_info)
        rescue Git::Error => e
          logger.warn "Could not process git file #{file_info[:path]}: #{e.message}"
        end
      end

      data
    end

    ##
    # Processes files that are tracked by yadm.
    #
    # For each file, it uses `yadm` commands to get status and diff information.
    #
    # @param [Array<Hash>] yadm_files An array of file info hashes for yadm-tracked files.
    # @return [Array<Hash>] An array of data hashes ready for the report table.
    def process_yadm_files(yadm_files)
      unless TTY::Which.exist?('yadm')
        logger.warn "'yadm' not found. Skipping YADM file processing."
        return []
      end

      logger.info "Processing #{yadm_files.length} yadm-tracked files"
      data = []

      yadm_files.each do |file_info|
        relative_path = file_info[:path]

        diff_output = `yadm diff HEAD -- "#{relative_path}" 2>/dev/null`
        additions = diff_output.scan(/^\+[^+]/).length
        deletions = diff_output.scan(/^-[^-]/).length
        chunks = diff_output.scan(/^@@/).length

        status_output = `yadm status --porcelain "#{relative_path}" 2>/dev/null`
        git_status = status_output.strip.empty? ? '--' : status_output[0..1]

        status_info = {
          raw_status: git_status,
          index: git_status[0] ? status_char_to_name(git_status[0]) : 'Clean',
          worktree: git_status[1] ? status_char_to_name(git_status[1]) : 'Clean'
        }

        diff_info = { additions: additions, deletions: deletions, chunks: chunks }

        data << create_file_data(file_info, 'YADM', status_info, diff_info)
      end

      data
    end

    ##
    # Processes files that are not tracked by Git or yadm.
    #
    # It attempts to mount a Restic backup and compare the untracked files
    # against their versions in the latest snapshot.
    #
    # @param [Array<Hash>] untracked_files An array of file info hashes.
    # @return [Array<Hash>] An array of data hashes ready for the report table.
    def process_untracked_files(untracked_files)
      logger.info "Processing #{untracked_files.length} untracked files"

      unless File.directory?(restic_mount_point) && !Dir.empty?(restic_mount_point)
        logger.info "Restic backup not mounted. Attempting to mount..."
        unless mount_restic_backup
          logger.warn "Failed to mount restic backup. Skipping untracked file comparison."
          return add_untracked_files_without_diff(untracked_files)
        end
      else
        logger.info "Restic backup already mounted at #{restic_mount_point}"
        @restic_mounted = true
      end

      snapshot_path = File.join(restic_mount_point, 'snapshots', 'latest', 'home', 'b08x')

      unless File.directory?(snapshot_path)
        logger.warn "Latest snapshot not found at #{snapshot_path}"
        return add_untracked_files_without_diff(untracked_files)
      end

      process_files_with_snapshots(untracked_files, snapshot_path)
    end

    ##
    # Creates a standardized hash of file data for the report.
    #
    # @param [Hash] file_info Basic information about the file (path, mtime, size).
    # @param [String] tracking The tracking method ('Git', 'YADM', 'Restic', 'New').
    # @param [Hash] status_info Git status information.
    # @param [Hash] diff_info Diff statistics (additions, deletions, chunks).
    # @return [Hash] A hash containing all data formatted for the table.
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

    ##
    # Compares untracked files against their counterparts in a Restic snapshot.
    #
    # @param [Array<Hash>] untracked_files An array of file info hashes.
    # @param [String] snapshot_path The path to the directory of the latest snapshot.
    # @return [Array<Hash>] An array of data hashes ready for the report table.
    def process_files_with_snapshots(untracked_files, snapshot_path)
      data = []

      untracked_files.each do |file_info|
        snapshot_file = File.join(snapshot_path, file_info[:path])

        if File.exist?(snapshot_file)
          diff_result = compare_with_snapshot(file_info[:full_path], snapshot_file)

          status_info = {
            raw_status: diff_result[:changed] ? 'M ' : '--',
            index: 'N/A',
            worktree: diff_result[:changed] ? 'Modified' : 'Unchanged'
          }

          data << create_file_data(file_info, 'Restic', status_info, diff_result)
        else
          # New file not in snapshot
          status_info = { raw_status: 'A ', index: 'N/A', worktree: 'Added' }
          diff_info = {
            additions: count_lines(file_info[:full_path]),
            deletions: 0,
            chunks: 1
          }

          data << create_file_data(file_info, 'New', status_info, diff_info)
        end
      end

      data
    end

    ##
    # Displays the final report, with data grouped into hourly tables.
    #
    # @param [Array<Hash>] data The complete set of analyzed file data.
    # @return [void]
    def display_hourly_tables(data)
      return logger.info "No files found." if data.empty?

      grouped_data = group_files_by_hour(data)
      sorted_hours = grouped_data.keys.sort

      display_overall_summary(data)

      sorted_hours.each do |hour_key|
        hour_data = grouped_data[hour_key]
        hour_label = format_hour_label(hour_key)

        puts "\n" + "="*80
        puts "Files Modified During: #{hour_label}"
        puts "="*80

        display_single_table(hour_data, hour_label)
      end
    end

    ##
    # Groups file data by the hour of modification.
    #
    # @param [Array<Hash>] data The file data to group.
    # @return [Hash{String => Array<Hash>}] A hash where keys are hour strings
    #   (e.g., '2023-01-01 14') and values are arrays of file data.
    def group_files_by_hour(data)
      data.group_by do |row|
        row[:modified_time].strftime('%Y-%m-%d %H')
      end
    end

    ##
    # Formats an hour key string into a human-readable label.
    #
    # @param [String] hour_key The hour key (e.g., '2023-01-01 14').
    # @return [String] A formatted string like 'Sunday, January 01, 2023 at 02:00 PM - 02:59 PM'.
    def format_hour_label(hour_key)
      date_time = Time.strptime(hour_key, '%Y-%m-%d %H')
      date_time.strftime('%A, %B %d, %Y at %I:%M %p - %I:59 %p')
    rescue ArgumentError
      hour_key
    end

    ##
    # Displays a high-level summary of all file activity.
    #
    # @param [Array<Hash>] data The complete set of analyzed file data.
    # @return [void]
    def display_overall_summary(data)
      tracking_counts = data.group_by { |row| row[:tracking] }.transform_values(&:count)
      modified_files = data.count { |row| row[:git_status] != '--' }
      total_additions = data.sum { |row| row[:additions] }
      total_deletions = data.sum { |row| row[:deletions] }
      hours_with_activity = group_files_by_hour(data).keys.count

      puts "\n" + "="*80
      puts "OVERALL SUMMARY - Daily Activity Analysis (Last #{@time_range})"
      puts "="*80
      puts "  Total files: #{data.length}"
      puts "  Hours with activity: #{hours_with_activity}"
      puts "  Modified files: #{modified_files}"
      tracking_counts.each { |method, count| puts "  #{method} tracked: #{count}" }
      puts "  Total additions: #{total_additions}"
      puts "  Total deletions: #{total_deletions}"
    end

    ##
    # Displays a single table of file data for a specific hour using TableTennis.
    #
    # @param [Array<Hash>] data The file data for a single hour.
    # @param [String] hour_label The label for the hour being displayed.
    # @return [void]
    def display_single_table(data, hour_label)
      return puts "No files found." if data.empty?

      options = {
        title: "#{data.length} files modified",
        zebra: true,
        row_numbers: true,
        color_scales: { additions: :g, deletions: :r },
        mark: ->(row) { row[:git_status] != '--' },
        columns: %i[file modified size tracking git_status index worktree additions deletions chunks],
        headers: {
          file: "File Path",
          modified: "Last Modified",
          size: "Size",
          tracking: "Tracking",
          git_status: "Status",
          index: "Index",
          worktree: "Worktree",
          additions: "+Lines",
          deletions: "-Lines",
          chunks: "Chunks"
        },
        theme: :ansi,
        layout: false
      }

      puts TableTennis.new(data, options)

      # Hour-specific summary
      tracking_counts = data.group_by { |row| row[:tracking] }.transform_values(&:count)
      modified_files = data.count { |row| row[:git_status] != '--' }
      total_additions = data.sum { |row| row[:additions] }
      total_deletions = data.sum { |row| row[:deletions] }

      puts "\nHour Summary:"
      puts "  Files: #{data.length}"
      puts "  Modified: #{modified_files}"
      tracking_counts.each { |method, count| puts "  #{method}: #{count}" }
      puts "  Additions: #{total_additions}, Deletions: #{total_deletions}"
    end

    ##
    # Finds the root directory of the Git repository containing a given file.
    #
    # @param [String] file_path The path to the file.
    # @return [String, nil] The path to the Git repository root, or nil if not found.
    def find_git_repo(file_path)
      dir = File.dirname(file_path)
      while dir != '/'
        if File.directory?(File.join(dir, '.git'))
          return dir
        end
        dir = File.dirname(dir)
      end
      nil
    end

    ##
    # Mounts the Restic backup repository in a new terminal window.
    #
    # It detects a preferred terminal emulator, forks a process to run the
    # `restic mount` command, and waits for the mount point to become available.
    #
    # @return [Boolean] True on successful mount, false otherwise.
    def mount_restic_backup
      unless TTY::Which.exist?('restic')
        logger.error "'restic' not found. Please install restic for backup functionality."
        return false
      end

      FileUtils.mkdir_p(restic_mount_point) unless File.directory?(restic_mount_point)

      logger.info "Mounting restic repository in new terminal..."
      logger.info "Repository: #{restic_repo}"
      logger.info "Mount point: #{restic_mount_point}"

      terminal_cmd = detect_terminal_emulator

      unless terminal_cmd
        logger.error "No suitable terminal emulator found."
        logger.error "Please install one of: alacritty, kitty, gnome-terminal, konsole, xterm"
        return false
      end

      restic_cmd = "restic mount -r '#{restic_repo}' '#{restic_mount_point}'"

      pid = fork do
        exec("#{terminal_cmd} #{restic_cmd}")
      end

      if pid
        @restic_pid = pid
        logger.info "Launched restic mount in new terminal (PID: #{pid})"
        logger.info "Waiting for mount to be available..."

        mount_timeout.times do
          sleep 1
          if File.directory?(restic_mount_point) && !Dir.empty?(restic_mount_point)
            logger.info "Mount point is ready!"
            @restic_mounted = true
            return true
          end
          print "."
        end

        logger.error "Timeout waiting for mount point. Please ensure restic mounted successfully."
        return false
      else
        logger.error "Failed to fork restic mount process."
        return false
      end
    end

    ##
    # Detects an available terminal emulator based on user preferences.
    #
    # @return [String, nil] The command to run the terminal, or nil if none are found.
    def detect_terminal_emulator
      terminal_preferences.each do |terminal|
        if TTY::Which.exist?(terminal['cmd'])
          return "#{terminal['cmd']} #{terminal['args']}"
        end
      end

      nil
    end

    ##
    # Unmounts the Restic repository.
    #
    # This is typically called by the `at_exit` handler.
    #
    # @return [void]
    def cleanup_restic_mount
      return unless @restic_mounted

      logger.info "Cleaning up restic mount..."

      if TTY::Which.exist?('umount')
        if system("umount #{restic_mount_point} 2>/dev/null")
          logger.info "Restic mount unmounted successfully."
        else
          logger.warn "Note: You may need to manually unmount #{restic_mount_point}"
          logger.warn "Or terminate the restic process in the other terminal with Ctrl+C"
        end
      else
        logger.warn "Note: 'umount' not available. Please manually unmount #{restic_mount_point}"
        logger.warn "Or terminate the restic process in the other terminal with Ctrl+C"
      end

      @restic_mounted = false
    end

    ##
    # Compares a file with its version in the Restic snapshot using `diff`.
    #
    # @param [String] current_file The path to the local file.
    # @param [String] snapshot_file The path to the file in the mounted snapshot.
    # @return [Hash] A hash with diff statistics: `{ changed:, additions:, deletions:, chunks: }`.
    def compare_with_snapshot(current_file, snapshot_file)
      unless TTY::Which.exist?('diff')
        logger.warn "'diff' not found. Cannot compare files with snapshots."
        return { changed: false, additions: 0, deletions: 0, chunks: 0 }
      end

      stdout, stderr, status = Open3.capture3("diff -u \"#{snapshot_file}\" \"#{current_file}\"")

      if status.exitstatus == 0
        { changed: false, additions: 0, deletions: 0, chunks: 0 }
      else
        additions = stdout.scan(/^\+[^+]/).length
        deletions = stdout.scan(/^-[^-]/).length
        chunks = stdout.scan(/^@@/).length

        { changed: true, additions: additions, deletions: deletions, chunks: chunks }
      end
    end

    ##
    # Creates data for untracked files when a diff is not possible.
    #
    # @param [Array<Hash>] untracked_files An array of file info hashes.
    # @return [Array<Hash>] An array of data hashes with 'N/A' for status.
    def add_untracked_files_without_diff(untracked_files)
      untracked_files.map do |file_info|
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

    ##
    # Counts the number of lines in a file.
    #
    # @param [String] file_path The path to the file.
    # @return [Integer] The number of lines, or 0 on error.
    def count_lines(file_path)
      File.readlines(file_path).length
    rescue
      0
    end

    ##
    # Gets the Git status of a single file.
    #
    # @param [Git::Base] git The Git object for the repository.
    # @param [String] file_path The path of the file relative to the repo root.
    # @return [Hash] A hash with status info: `{ raw_status:, index:, worktree: }`.
    def get_file_git_status(git, file_path)
      git_status = git.status

      if git_status.added.include?(file_path)
        { raw_status: 'A ', index: 'Added', worktree: 'Unchanged' }
      elsif git_status.changed.include?(file_path)
        { raw_status: ' M', index: 'Unchanged', worktree: 'Modified' }
      elsif git_status.deleted.include?(file_path)
        { raw_status: ' D', index: 'Unchanged', worktree: 'Deleted' }
      elsif git_status.untracked.include?(file_path)
        { raw_status: '??', index: 'Unchanged', worktree: 'Untracked' }
      else
        { raw_status: '--', index: 'Clean', worktree: 'Clean' }
      end
    end

    ##
    # Gets the diff statistics for a single file against HEAD.
    #
    # @param [Git::Base] git The Git object for the repository.
    # @param [String] file_path The path of the file relative to the repo root.
    # @return [Hash] A hash with diff stats: `{ additions:, deletions:, chunks: }`.
    def get_file_git_diff(git, file_path)
      begin
        diff = git.diff('HEAD', file_path)
        if diff.size > 0
          file_diff = diff.first
          {
            additions: file_diff.patch ? file_diff.patch.scan(/^\+[^+]/).length : 0,
            deletions: file_diff.patch ? file_diff.patch.scan(/^-[^-]/).length : 0,
            chunks: file_diff.patch ? file_diff.patch.scan(/^@@/).length : 0
          }
        else
          { additions: 0, deletions: 0, chunks: 0 }
        end
      rescue Git::Error
        { additions: 0, deletions: 0, chunks: 0 }
      end
    end

    ##
    # Converts a Git status character to a human-readable name.
    #
    # @param [String] char The single character from Git status output.
    # @return [String] The full status name (e.g., 'Modified').
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

    ##
    # Formats a file size in bytes into a human-readable string (KB, MB, etc.).
    #
    # @param [Integer, nil] bytes The size of the file in bytes.
    # @return [String] The formatted size string (e.g., "1.2KB").
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
