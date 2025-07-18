# frozen_string_literal: true

require_relative '../actions/mount_restic_repo_action'

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

      # The mount action instance
      # @return [ComputerTools::Actions::MountResticRepoAction] the mount action
      attr_reader :mount_action

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
        @home_dir = config.fetch(:paths, :home_dir) || File.expand_path('~')

        @mount_action = ComputerTools::Actions::MountResticRepoAction.new(
          repository: @repository,
          mount_point: @mount_point
        )

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
        @mount_action.mounted?
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
        @mount_action.call
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
        @mount_action.unmount
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

      # Sets up a cleanup handler to ensure the repository is unmounted when the program exits.
      #
      # @return [void]
      def setup_cleanup_handler
        at_exit { cleanup }
      end
    end
  end
end