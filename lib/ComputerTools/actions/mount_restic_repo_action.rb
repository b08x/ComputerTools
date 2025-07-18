# frozen_string_literal: true

require 'open3'
require 'tty-prompt'
require 'tty-which'

module ComputerTools
  module Actions
    class MountResticRepoAction < Sublayer::Actions::Base
      attr_reader :repository, :mount_point, :mount_process

      def initialize(repository:, mount_point:)
        @repository = repository
        @mount_point = mount_point
        @mount_process = nil
      end

      def call
        mount_repository
      end

      def mounted?
        File.directory?(@mount_point) && !Dir.empty?(@mount_point)
      end

      def unmount
        return unless mounted?

        puts "🔒 Unmounting restic repository...".colorize(:blue)

        if @mount_process
          begin
            Process.kill('TERM', @mount_process.pid)
            Process.wait(@mount_process.pid)
            puts "✅ Restic repository unmounted successfully.".colorize(:green)
          rescue Errno::ESRCH
            puts "✅ Restic process already terminated.".colorize(:green)
          rescue StandardError => e
            puts "⚠️  Warning: Error terminating restic process: #{e.message}".colorize(:yellow)
          end
        end

        # Fallback to system umount if needed
        system("umount '#{@mount_point}' 2>/dev/null") if mounted? && TTY::Which.exist?('umount')

        @mount_process = nil
        ENV.delete("RESTIC_PASSWORD")
      end

      private

      def mount_repository
        unless TTY::Which.exist?('restic')
          puts "❌ 'restic' command not found. Please install restic.".colorize(:red)
          return false
        end

        return true if mounted?

        puts "🔐 Mounting restic repository...".colorize(:blue)
        puts "   Repository: #{@repository}".colorize(:cyan)
        puts "   Mount point: #{@mount_point}".colorize(:cyan)

        setup_password
        create_mount_point
        start_mount_process
      end

      def setup_password
        return if ENV["RESTIC_PASSWORD"]

        prompt = TTY::Prompt.new
        puts "   Note: You will be prompted for the repository passphrase".colorize(:yellow)

        ENV["RESTIC_PASSWORD"] = prompt.mask("Enter the restic repository passphrase:") do |q|
          q.validate(/\S/, "Passphrase cannot be empty")
        end
      end

      def create_mount_point
        FileUtils.mkdir_p(@mount_point)
      end

      def start_mount_process
        stdin, stdout, stderr, wait_thr = Open3.popen3("restic mount -r #{@repository} #{@mount_point}")
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
    end
  end
end