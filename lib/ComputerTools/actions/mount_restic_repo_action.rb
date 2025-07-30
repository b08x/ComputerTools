# frozen_string_literal: true

module ComputerTools
  module Actions
    ##
    # MountResticRepoAction handles mounting and unmounting of Restic backup repositories.
    #
    # This class provides a complete solution for managing Restic repository mounts,
    # including password handling, process management, and proper cleanup.
    #
    # Primary use cases:
    # - Mounting encrypted Restic repositories for backup access
    # - Managing the lifecycle of mounted repositories
    # - Handling secure password input for repository access
    #
    # Example usage:
    #   action = MountResticRepoAction.new(
    #     repository: 's3:my-backup-bucket',
    #     mount_point: '/mnt/backups'
    #   )
    #   action.call # Mounts the repository
    #   # ... work with mounted repository ...
    #   action.unmount # When done
    class MountResticRepoAction < Sublayer::Actions::Base
      attr_reader :repository, :mount_point, :mount_process

      ##
      # Initializes a new MountResticRepoAction instance.
      #
      # @param repository [String] the Restic repository to mount (e.g., 's3:my-bucket' or '/path/to/repo')
      # @param mount_point [String] the local filesystem path where the repository should be mounted
      def initialize(repository:, mount_point:)
        @repository = repository
        @mount_point = mount_point
        @mount_process = nil
      end

      ##
      # Main action method that mounts the Restic repository.
      #
      # This is called when the action is invoked and handles the complete mounting process.
      #
      # @return [Boolean] true if the repository was successfully mounted, false otherwise
      def call
        mount_repository
      end

      ##
      # Checks if the repository is currently mounted.
      #
      # Verifies both that the mount point exists and that it's not empty.
      #
      # @return [Boolean] true if the repository is mounted and accessible, false otherwise
      def mounted?
        File.directory?(@mount_point) && !Dir.empty?(@mount_point)
      end

      ##
      # Unmounts the Restic repository and cleans up resources.
      #
      # This method handles both graceful termination of the restic process
      # and fallback to system unmount if needed. It also clears the
      # RESTIC_PASSWORD environment variable for security.
      #
      # @return [void]
      def unmount
        return unless mounted?

        puts "🔒 Unmounting restic repository...".colorize(:blue)

        terminate_restic_process if @mount_process

        # Fallback to system umount if needed
        system("umount '#{@mount_point}' 2>/dev/null") if mounted? && TTY::Which.exist?('umount')

        @mount_process = nil
        ENV.delete("RESTIC_PASSWORD")
      end

      private

      ##
      # Handles the complete repository mounting process.
      #
      # This includes checking for restic availability, verifying if already mounted,
      # setting up the password, creating the mount point, and starting the mount process.
      #
      # @return [Boolean] true if the repository was successfully mounted, false otherwise
      def mount_repository
        unless TTY::Which.exist?('restic')
          puts "❌ 'restic' command not found. Please install restic.".colorize(:red)
          return false
        end

        return true if mounted?

        puts "🔐 Mounting restic repository...".colorize(:blue)
        puts "   Repository: #{@repository}".colorize(:cyan)
        puts "   Mount point: #{@mount_point}".colorize(:cyan)

        # setup_password
        create_mount_point
        start_mount_process
      end

      ##
      # Sets up the repository password if not already set in the environment.
      #
      # Uses TTY::Prompt to securely collect the password from the user with masking.
      # Validates that the password is not empty.
      #
      # @return [void]
      def setup_password
        return if ENV["RESTIC_PASSWORD"]

        prompt = TTY::Prompt.new
        puts "   Note: You will be prompted for the repository passphrase".colorize(:yellow)

        ENV["RESTIC_PASSWORD"] = prompt.mask("Enter the restic repository passphrase:") do |q|
          q.validate(/\S/, "Passphrase cannot be empty")
        end
      end

      ##
      # Creates the mount point directory if it doesn't exist.
      #
      # Uses FileUtils.mkdir_p to create parent directories as needed.
      #
      # @return [void]
      def create_mount_point
        FileUtils.mkdir_p(@mount_point)
      end

      ##
      # Starts the restic mount process and monitors its output.
      #
      # Uses Open3.popen3 to capture stdin, stdout, and stderr of the process.
      # Spawns threads to monitor output and error streams for status updates.
      #
      # @return [Boolean] true if the mount was successful, false otherwise
      def start_mount_process
        stdin, stdout, stderr, wait_thr = Open3.popen3("restic mount -r #{@repository} #{@mount_point} --insecure-no-password")
        @mount_process = wait_thr

        # Monitor stdout for successful mount confirmation
        Thread.new do
          stdout.each_line do |line|
            puts "Restic: #{line.chomp}".colorize(:cyan)

            if line.include?("Now serving") && line.include?(@mount_point)
              puts "✅ Restic repository mounted successfully at #{@mount_point}".colorize(:green)
              break
            end
          end
        end

        # Monitor stderr for errors
        Thread.new do
          stderr.each_line do |line|
            puts "Restic Error: #{line.chomp}".colorize(:red)
          end
        end

        # Give the mount process time to start
        sleep(3)

        # Check if mount was successful
        if mounted?
          puts "✅ Mount verified - repository is accessible".colorize(:green)
          true
        else
          puts "❌ Mount failed or not yet ready".colorize(:red)
          false
        end
      rescue StandardError => e
        puts "❌ Error mounting restic repository: #{e.message}".colorize(:red)
        @mount_process = nil
        false
      ensure
        stdin&.close
      end

      ##
      # Terminates the restic mount process.
      #
      # Attempts graceful termination with TERM signal first, then falls back
      # to KILL if the process doesn't respond. Handles various edge cases
      # including already terminated processes.
      #
      # @return [void]
      def terminate_restic_process
        return unless @mount_process

        pid = @mount_process.pid

        # Check if the process is still running
        unless process_running?(pid)
          puts "✅ Restic process already terminated.".colorize(:green)
          return
        end

        begin
          # Send TERM signal to allow graceful shutdown
          Process.kill('TERM', pid)

          # Wait for the process to terminate with a timeout
          wait_for_process_termination(pid, timeout: 10)

          puts "✅ Restic repository unmounted successfully.".colorize(:green)
        rescue Errno::ESRCH
          # Process no longer exists (already terminated)
          puts "✅ Restic process already terminated.".colorize(:green)
        rescue Errno::ECHILD
          # No child processes - process already cleaned up
          puts "✅ Restic process already cleaned up.".colorize(:green)
        rescue Timeout::Error
          # Process didn't respond to TERM, try KILL
          puts "⚠️  Process not responding to TERM, sending KILL...".colorize(:yellow)
          begin
            Process.kill('KILL', pid)
            Process.wait(pid)
            puts "✅ Restic process forcefully terminated.".colorize(:green)
          rescue Errno::ESRCH, Errno::ECHILD
            puts "✅ Restic process already terminated.".colorize(:green)
          end
        rescue StandardError => e
          puts "⚠️  Warning: Error terminating restic process: #{e.message}".colorize(:yellow)
        end
      end

      ##
      # Checks if a process with the given PID is still running.
      #
      # @param pid [Integer] the process ID to check
      # @return [Boolean] true if the process is running, false otherwise
      def process_running?(pid)
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH
        false
      rescue Errno::EPERM
        # Process exists but we don't have permission to signal it
        # This shouldn't happen with our own child process, but just in case
        true
      end

      ##
      # Waits for a process to terminate with a timeout.
      #
      # @param pid [Integer] the process ID to wait for
      # @param timeout [Integer] maximum time to wait in seconds (default: 10)
      # @return [void]
      def wait_for_process_termination(pid, timeout: 10)
        require 'timeout'

        Timeout.timeout(timeout) do
          Process.wait(pid)
        end
      rescue Errno::ECHILD
        # Child process already cleaned up by the system
        nil
      end
    end
  end
end