# frozen_string_literal: true

require 'git'
# GitWrapper will be autoloaded by Zeitwerk

module ComputerTools
  module Actions
    module VersionControl
      class GitAnalysis < Sublayer::Actions::Base
        def initialize(files:, config:)
          @files = files
          @config = config
        end

        def call
          return [] if @files.empty?

          data = []
          @git_wrapper = ComputerTools::Wrappers::VersionControl::GitWrapper.new

          @files.each do |file_info|
            file_data = analyze_git_file(file_info)
            data << file_data if file_data
          rescue StandardError => e
            puts "⚠️  Warning: Could not analyze Git file #{file_info[:path]}: #{e.message}".colorize(:yellow)
          end

          data
        rescue StandardError => e
          puts "❌ Error analyzing Git files: #{e.message}".colorize(:red)
          puts "   File: #{e.backtrace.first}" if e.backtrace&.first
          puts "   Full backtrace:" if ENV['DEBUG']
          puts e.backtrace.first(3).join("\n   ") if ENV['DEBUG'] && e.backtrace
          []
        end

        private

        def analyze_git_file(file_info)
          repo_path = find_git_repo(file_info[:full_path])
          return nil unless repo_path

          git = @git_wrapper.open_repository(repo_path)
          return nil unless git

          relative_to_repo = file_info[:full_path].gsub("#{repo_path}/", '')

          status_info = @git_wrapper.get_file_status(git, relative_to_repo)
          diff_info = @git_wrapper.get_file_diff(git, relative_to_repo)

          create_file_data(file_info, 'Git', status_info, diff_info)
        end

        def find_git_repo(file_path)
          dir = File.dirname(file_path)
          while dir != '/'
            return dir if File.directory?(File.join(dir, '.git'))

            dir = File.dirname(dir)
          end
          nil
        end

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

        def time_format
          @config.fetch('display', 'time_format')
        end

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
end