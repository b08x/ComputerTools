# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # ResticWrapper provides an interface to interact with Restic backup repositories.
    # It handles mounting, unmounting, and comparing files with snapshots in a Restic repository.
    #
    # This wrapper is particularly useful for backup analysis and file comparison tasks,
    # allowing developers to integrate Restic backup functionality into their applications.
    class ResticWrapper
      include ComputerTools::Interfaces::BackupInterface
      # The configuration hash used to initialize the wrapper
      # @return [Hash] the configuration hash
      attr_reader :config

      # The mount point where the Restic repository will be mounted
      # @return [String] the mount point path
      attr_reader :mount_point

      # The Restic repository path
      # @return [String] the repository path
      attr_reader :repository

      # Initializes a new ResticWrapper instance.
      #
      # @param config [Hash] Configuration hash containing paths and settings
      # @option config [String] :paths Configuration for various paths including restic_mount_point, restic_repo, and home_dir
      # @example Initializing with a configuration hash
      #   config = {
      #     paths: {
      #       restic_mount_point: '/mnt/restic',
      #       restic_repo: '/path/to/repo',
      #       home_dir: '/home/user'
      #     }
      #   }
      #   wrapper = ComputerTools::Wrappers::ResticWrapper.new(config)
      def initialize(config)
        @config = config
        @mount_point = config.fetch(:paths, :restic_mount_point) || File.expand_path('~/mnt/restic')
        @repository = config.fetch(:paths, :restic_repo) || ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo'
        @mounted = false
        @mount_pid = nil
        @home_dir = config.fetch(:paths, :home_dir) || File.expand_path('~')

        setup_cleanup_handler
      end

      # Ensures the Restic backup is mounted.
      #
      # @return [Boolean] true if the backup is already mounted or was successfully mounted, false otherwise
      # @example Ensuring the backup is mounted
      #   wrapper.ensure_mounted
      def ensure_mounted
        return true if mounted?

        puts "📦 Restic backup not mounted. Attempting to mount...".colorize(:blue)
        mount_backup
      end

      # Checks if the Restic backup is mounted.
      #
      # @return [Boolean] true if the backup is mounted and the mount point is not empty, false otherwise
      # @example Checking if the backup is mounted
      #   if wrapper.mounted?
      #     puts "Backup is mounted."
      #   else
      #     puts "Backup is not mounted."
      #   end
      def mounted?
        File.directory?(@mount_point) && !Dir.empty?(@mount_point)
      end

      # Returns the path to the latest snapshot.
      #
      # @return [String] the path to the latest snapshot
      # @example Getting the snapshot path
      #   snapshot_path = wrapper.snapshot_path
      def snapshot_path
        File.join(@mount_point, 'snapshots', 'latest', 'home', File.basename(@home_dir))
      end

      # Mounts the Restic backup repository.
      #
      # @return [Boolean] true if the repository was successfully mounted, false otherwise
      # @example Mounting the backup repository
      #   success = wrapper.mount_backup
      #   if success
      #     puts "Repository mounted successfully."
      #   else
      #     puts "Failed to mount repository."
      #   end
      def mount_backup
        unless TTY::Which.exist?('restic')
          puts "❌ 'restic' command not found. Please install restic.".colorize(:red)
          return false
        end

        puts "🔐 Mounting restic repository...".colorize(:blue)
        puts "   Repository: #{@repository}".colorize(:cyan)
        puts "   Mount point: #{@mount_point}".colorize(:cyan)
        puts "   Note: You will be prompted for the repository passphrase".colorize(:yellow)

        prompt = TTY::Prompt.new

        ENV["RESTIC_PASSWORD"] = prompt.mask("enter the restic repository passphrase:") do |q|
          q.validate(/\S/, "Passphrase cannot be empty")
        end

        Open3.popen3("restic mount -r #{@repository} #{@mount_point}") do |stdin, stdout, stderr, wait_thr|
          stdout_thread = Thread.new do
            stdout.each_line do |line|
              puts "Restic Output: #{line.chomp}"

              if line.include?("Now serving") && line.include?(@mount_point)
                puts "Restic mount successful! Proceeding..."
                break
              end
            end
          end

          stdout_thread.join

          puts "You can now browse your restic repository at #{@mount_point}"

          # When you're ready to unmount:
          # Process.kill("TERM", wait_thr.pid)
          # Process.wait(wait_thr.pid)

          puts "Parent process continuing after restic mount."
        end

        # fork do
        #   `kitty -e restic mount -r #{@repository} #{@mount_point}`
        # end

        # sleep 20

        # if $?.success?
        #   puts "✅ Restic repository mounted successfully.".colorize(:green)
        #   @mounted = true
        #   @mount_pid = $?.pid
        # else
        #   puts "❌ Failed to mount restic repository: #{result.error}".colorize(:red)
        #   puts "   Please check the repository path and passphrase.".colorize(:yellow)
        #   false
        # end
      rescue StandardError => e
        puts "❌ Error mounting restic backup: #{e.message}".colorize(:red)
        # false
        exit! 1
      end

      # Compares a current file with its snapshot version.
      #
      # @param current_file [String] the path to the current file
      # @param snapshot_file [String] the path to the snapshot file
      # @return [Hash] a hash containing comparison results with keys :changed, :additions, :deletions, and :chunks
      # @example Comparing a file with its snapshot
      #   comparison = wrapper.compare_with_snapshot('/path/to/current/file', '/path/to/snapshot/file')
      #   if comparison[:changed]
      #     puts "File has been modified with #{comparison[:additions]} additions and #{comparison[:deletions]} deletions."
      #   else
      #     puts "File has not been modified."
      #   end
      def compare_with_snapshot(current_file, snapshot_file)
        unless TTY::Which.exist?('diff')
          puts "⚠️  Warning: 'diff' command not found. Cannot compare files.".colorize(:yellow)
          return { changed: false, additions: 0, deletions: 0, chunks: 0 }
        end

        stdout, _, status = Open3.capture3("diff -u \"#{snapshot_file}\" \"#{current_file}\"")

        if status.exitstatus == 0
          { changed: false, additions: 0, deletions: 0, chunks: 0 }
        else
          {
            changed: true,
            additions: stdout.scan(/^\+[^+]/).length,
            deletions: stdout.scan(/^-[^-]/).length,
            chunks: stdout.scan(/^@@/).length
          }
        end
      rescue StandardError => e
        puts "⚠️  Warning: Could not compare files: #{e.message}".colorize(:yellow)
        { changed: false, additions: 0, deletions: 0, chunks: 0 }
      end

      # Unmounts the Restic repository.
      #
      # @return [void]
      # @example Unmounting the repository
      #   wrapper.unmount
      def unmount
        return unless mounted?

        puts "🔒 Unmounting restic repository...".colorize(:blue)

        if TTY::Which.exist?('umount')
          if system("umount '#{@mount_point}' 2>/dev/null")
            puts "✅ Restic repository unmounted successfully.".colorize(:green)
            @mounted = false
            ENV.delete("RESTIC_PASSWORD")
          else
            puts "⚠️  Warning: Could not unmount #{@mount_point}".colorize(:yellow)
            puts "   Please manually unmount or terminate the restic process with Ctrl+C".colorize(:yellow)
          end
        else
          puts "⚠️  Warning: 'umount' command not available.".colorize(:yellow)
          puts "   Please manually unmount #{@mount_point}".colorize(:yellow)
          puts "   Or terminate the restic process in the terminal with Ctrl+C".colorize(:yellow)
        end
      end

      # Cleans up by unmounting the repository if it is mounted.
      #
      # @return [void]
      # @example Cleaning up
      #   wrapper.cleanup
      def cleanup
        unmount if mounted?
      end

      private

      # Detects the terminal emulator to use.
      #
      # @return [String, nil] the terminal command with arguments or nil if the command does not exist
      def detect_terminal_emulator
        command = @config.fetch(:terminal, :command) || 'kitty'
        args = @config.fetch(:terminal, :args) || '-e'

        return nil unless TTY::Which.exist?(command)

        "#{command} #{args}"
      end

      # Sets up a cleanup handler to ensure the repository is unmounted when the program exits.
      #
      # @return [void]
      def setup_cleanup_handler
        at_exit { cleanup }
      end
    end
  end
end