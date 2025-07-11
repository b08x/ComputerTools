# frozen_string_literal: true

module ComputerTools
  module Actions
    class FileDiscoveryAction < Sublayer::Actions::Base
      def initialize(directory:, time_range:, config:)
        @directory = directory
        @time_range = time_range
        @config = config
      end

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

      def yadm_tracked?(file_path)
        return false unless TTY::Which.exist?('yadm')

        cmd = "yadm list -a"
        output = `#{cmd} 2>/dev/null`
        return false unless $?.success?

        tracked_files = output.split("\n")
        relative_path = file_path.gsub("#{home_dir}/", '')
        tracked_files.include?(relative_path)
      end

      def home_dir
        @config.fetch('paths', 'home_dir')
      end
    end
  end
end