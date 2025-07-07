# frozen_string_literal: true

require 'tty-which'
require 'fileutils'
require 'open3'

module ComputerTools
  module Wrappers
    module Backup
      class Restic
        attr_reader :config, :mount_point, :repository

        def initialize(config)
          @config = config
          @mount_point = config.fetch('paths', 'restic_mount_point')
          @repository = config.fetch('paths', 'restic_repo')
          @mounted = false
          @mount_pid = nil
          @home_dir = config.fetch('paths', 'home_dir')

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

          FileUtils.mkdir_p(@mount_point) unless File.directory?(@mount_point)

          puts "🔐 Mounting restic repository...".colorize(:blue)
          puts "   Repository: #{@repository}".colorize(:cyan)
          puts "   Mount point: #{@mount_point}".colorize(:cyan)
          puts "   Note: You will be prompted for the repository passphrase".colorize(:yellow)

          terminal_cmd = detect_terminal_emulator
          unless terminal_cmd
            puts "❌ No suitable terminal emulator found.".colorize(:red)
            puts "   Please install: alacritty, kitty, gnome-terminal, konsole, or xterm".colorize(:red)
            return false
          end

          restic_cmd = "restic mount -r '#{@repository}' '#{@mount_point}'"

          # Launch restic mount in a new terminal
          pid = fork do
            exec("#{terminal_cmd} '#{restic_cmd}'")
          end

          if pid
            @mount_pid = pid
            puts "🚀 Launched restic mount in new terminal (PID: #{pid})".colorize(:green)
            puts "⏳ Waiting for mount to be available...".colorize(:blue)

            wait_for_mount
          else
            puts "❌ Failed to launch restic mount process.".colorize(:red)
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

        def wait_for_mount
          mount_timeout = @config.fetch('restic', 'mount_timeout', 60)

          mount_timeout.times do |i|
            sleep 1

            if mounted?
              puts "\n✅ Mount point is ready!".colorize(:green)
              @mounted = true
              return true
            end

            # Show progress every 5 seconds
            puts "   Still waiting... (#{i}/#{mount_timeout}s)".colorize(:cyan) if i % 5 == 0
          end

          puts "\n❌ Timeout waiting for mount point.".colorize(:red)
          puts "   Please ensure the restic repository is mounted successfully.".colorize(:red)
          puts "   Check the terminal window for any error messages.".colorize(:yellow)
          false
        end

        def detect_terminal_emulator
          terminal_preferences = @config.fetch('terminals', 'preferred_order', default_terminals)

          terminal_preferences.each do |terminal|
            return "#{terminal['cmd']} #{terminal['args']}" if TTY::Which.exist?(terminal['cmd'])
          end

          nil
        end

        def default_terminals
          [
            { 'cmd' => 'alacritty', 'args' => '-e' },
            { 'cmd' => 'kitty', 'args' => '-e' },
            { 'cmd' => 'gnome-terminal', 'args' => '--' },
            { 'cmd' => 'konsole', 'args' => '-e' },
            { 'cmd' => 'xterm', 'args' => '-e' }
          ]
        end

        def setup_cleanup_handler
          at_exit { cleanup }
        end
      end
    end
  end
end