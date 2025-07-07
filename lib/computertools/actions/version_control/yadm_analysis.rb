# frozen_string_literal: true

require 'tty-which'

module ComputerTools
  module Actions
    module VersionControl
      class YadmAnalysis < Sublayer::Actions::Base
      def initialize(files:, config:)
        @files = files
        @config = config
      end

      def call
        return [] if @files.empty?

        unless TTY::Which.exist?('yadm')
          puts "⚠️  Warning: 'yadm' not found. Skipping YADM file processing.".colorize(:yellow)
          return []
        end

        data = []

        @files.each do |file_info|
          file_data = analyze_yadm_file(file_info)
          data << file_data if file_data
        rescue StandardError => e
          puts "⚠️  Warning: Could not analyze YADM file #{file_info[:path]}: #{e.message}".colorize(:yellow)
        end

        data
      rescue StandardError => e
        puts "❌ Error analyzing YADM files: #{e.message}".colorize(:red)
        []
      end

      private

      def analyze_yadm_file(file_info)
        relative_path = file_info[:path]

        # Get diff information
        diff_output = `yadm diff HEAD -- "#{relative_path}" 2>/dev/null`
        diff_info = parse_diff_output(diff_output)

        # Get status information
        status_output = `yadm status --porcelain "#{relative_path}" 2>/dev/null`
        status_info = parse_status_output(status_output)

        create_file_data(file_info, 'YADM', status_info, diff_info)
      end

      def parse_diff_output(diff_output)
        {
          additions: diff_output.scan(/^\+[^+]/).length,
          deletions: diff_output.scan(/^-[^-]/).length,
          chunks: diff_output.scan(/^@@/).length
        }
      end

      def parse_status_output(status_output)
        git_status = status_output.strip.empty? ? '--' : status_output[0..1]

        {
          raw_status: git_status,
          index: git_status[0] ? status_char_to_name(git_status[0]) : 'Clean',
          worktree: git_status[1] ? status_char_to_name(git_status[1]) : 'Clean'
        }
      end

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