# frozen_string_literal: true

require 'tty-which'
require 'open3'
require_relative '../wrappers/restic_wrapper'

module ComputerTools
  module Actions
    class ResticAnalysisAction < Sublayer::Actions::Base
      def initialize(files:, config:)
        @files = files
        @config = config
        @restic_wrapper = ComputerTools::Wrappers::ResticWrapper.new(config)
      end

      def call
        return [] if @files.empty?

        unless TTY::Which.exist?('restic')
          puts "⚠️  Warning: 'restic' not found. Skipping backup comparison.".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        data = []

        # Check if restic is already mounted or attempt to mount
        unless @restic_wrapper.ensure_mounted
          puts "⚠️  Warning: Could not mount Restic backup. Analyzing files without comparison.".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        snapshot_path = @restic_wrapper.snapshot_path
        unless File.directory?(snapshot_path)
          puts "⚠️  Warning: Latest snapshot not found at #{snapshot_path}".colorize(:yellow)
          return add_untracked_files_without_diff
        end

        @files.each do |file_info|
          file_data = analyze_untracked_file(file_info, snapshot_path)
          data << file_data if file_data
        rescue StandardError => e
          puts "⚠️  Warning: Could not analyze file #{file_info[:path]}: #{e.message}".colorize(:yellow)
        end

        data
      rescue StandardError => e
        puts "❌ Error analyzing untracked files: #{e.message}".colorize(:red)
        add_untracked_files_without_diff
      end

      private

      def analyze_untracked_file(file_info, snapshot_path)
        snapshot_file = File.join(snapshot_path, file_info[:path])

        if File.exist?(snapshot_file)
          # Compare with snapshot
          diff_result = @restic_wrapper.compare_with_snapshot(file_info[:full_path], snapshot_file)

          status_info = {
            raw_status: diff_result[:changed] ? 'M ' : '--',
            index: 'N/A',
            worktree: diff_result[:changed] ? 'Modified' : 'Unchanged'
          }

          create_file_data(file_info, 'Restic', status_info, diff_result)
        else
          # New file not in snapshot
          status_info = { raw_status: 'A ', index: 'N/A', worktree: 'Added' }
          diff_info = {
            additions: count_lines(file_info[:full_path]),
            deletions: 0,
            chunks: 1
          }

          create_file_data(file_info, 'New', status_info, diff_info)
        end
      end

      def add_untracked_files_without_diff
        @files.map do |file_info|
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

      def count_lines(file_path)
        File.readlines(file_path).length
      rescue StandardError
        0
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