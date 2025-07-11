# frozen_string_literal: true

require 'tty-which'
require 'fileutils'
require 'open3'

module ComputerTools
  module Wrappers
    class ResticWrapper
      attr_reader :config, :mount_point, :repository

      def initialize(config)
        @config = config
        @mount_point = config.fetch(:paths, :restic_mount_point) || File.expand_path('~/mnt/restic')
        @repository = config.fetch(:paths, :restic_repo) || ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo'
        @mounted = false
        @mount_pid = nil
        @home_dir = config.fetch(:paths, :home_dir) || File.expand_path('~')

        setup_cleanup_handler
      end

      def ensure_mounted
        return true if mounted?

        puts "📦 Restic backup not mounted. Attempting to mount...".colorize(:blue)
        mount_backup
      end

      def mounted?
        File.directory?(@mount_point) && !Dir.empty?(@mount_point)
      end

      def snapshot_path
        File.join(@mount_point, 'snapshots', 'latest', 'home', File.basename(@home_dir))
      end

      def mount_backup
        unless TTY::Which.exist?('restic')
          puts "❌ 'restic' command not found. Please install restic.".colorize(:red)
          return false
        end

        # FileUtils.mkdir_p(@mount_point) unless File.directory?(@mount_point)

        puts "🔐 Mounting restic repository...".colorize(:blue)
        puts "   Repository: #{@repository}".colorize(:cyan)
        puts "   Mount point: #{@mount_point}".colorize(:cyan)
        puts "   Note: You will be prompted for the repository passphrase".colorize(:yellow)

        fork do
          `kitty -e restic mount -r #{@repository} #{@mount_point}`
        end

        sleep 20

        if $?.success?
          puts "✅ Restic repository mounted successfully.".colorize(:green)
          @mounted = true
          @mount_pid = $?.pid
        else
          puts "❌ Failed to mount restic repository: #{result.error}".colorize(:red)
          puts "   Please check the repository path and passphrase.".colorize(:yellow)
          false
        end
      rescue StandardError => e
        puts "❌ Error mounting restic backup: #{e.message}".colorize(:red)
        false
      end

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

      def unmount
        return unless mounted?

        puts "🔒 Unmounting restic repository...".colorize(:blue)

        if TTY::Which.exist?('umount')
          if system("umount '#{@mount_point}' 2>/dev/null")
            puts "✅ Restic repository unmounted successfully.".colorize(:green)
            @mounted = false
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

      def cleanup
        unmount if mounted?
      end

      private

      # def wait_for_mount
      #   mount_timeout = @config.fetch(:restic, :mount_timeout) || 60

      #   mount_timeout.times do |i|
      #     sleep 1

      #     if mounted?
      #       puts "\n✅ Mount point is ready!".colorize(:green)
      #       @mounted = true
      #       return true
      #     end

      #     # Show progress every 5 seconds
      #     puts "   Still waiting... (#{i}/#{mount_timeout}s)".colorize(:cyan) if i % 5 == 0
      #   end

      #   puts "\n❌ Timeout waiting for mount point.".colorize(:red)
      #   puts "   Please ensure the restic repository is mounted successfully.".colorize(:red)
      #   puts "   Check the terminal window for any error messages.".colorize(:yellow)
      #   false
      # end

      def detect_terminal_emulator
        command = @config.fetch(:terminal, :command) || 'kitty'
        args = @config.fetch(:terminal, :args) || '-e'

        return nil unless TTY::Which.exist?(command)

        "#{command} #{args}"
      end

      def setup_cleanup_handler
        at_exit { cleanup }
      end
    end
  end
end