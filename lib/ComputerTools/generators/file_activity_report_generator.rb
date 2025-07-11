# frozen_string_literal: true

require 'tty-table'
require 'json'

module ComputerTools
  module Generators
    class FileActivityReportGenerator < Sublayer::Generators::Base
      def initialize(data:, config:, format: :table, interactive: false, time_range: '24h')
        @data = data
        @format = format
        @interactive = interactive
        @time_range = time_range
        @config = config
      end

      def call
        case @format
        when :json
          generate_json_report
        when :summary
          generate_summary_report
        when :table
          generate_table_report
        else
          generate_table_report
        end

        handle_interactive_mode if @interactive
        true
      rescue StandardError => e
        puts "❌ Error generating report: #{e.message}".colorize(:red)
        false
      end

      private

      def generate_json_report
        report_data = {
          metadata: {
            generated_at: Time.now.iso8601,
            time_range: @time_range,
            total_files: @data.length
          },
          summary: generate_summary_stats,
          files: @data
        }

        puts JSON.pretty_generate(report_data)
      end

      def generate_summary_report
        stats = generate_summary_stats

        puts "\n#{'=' * 60}"
        puts "📊 FILE ACTIVITY SUMMARY (#{@time_range})".colorize(:blue)
        puts "=" * 60

        puts "📁 Total files analyzed: #{stats[:total_files]}".colorize(:green)
        puts "⏰ Active time periods: #{stats[:hours_with_activity]}".colorize(:cyan)
        puts "🔄 Modified files: #{stats[:modified_files]}".colorize(:yellow)

        puts "\n📈 By tracking method:".colorize(:blue)
        stats[:by_tracking].each do |method, count|
          puts "  #{method}: #{count}".colorize(:cyan)
        end

        puts "\n📝 Change statistics:".colorize(:blue)
        puts "  + Lines added: #{stats[:total_additions]}".colorize(:green)
        puts "  - Lines removed: #{stats[:total_deletions]}".colorize(:red)
        puts "  📦 Total chunks: #{stats[:total_chunks]}".colorize(:cyan)

        return unless stats[:top_files].any?

        puts "\n🔥 Most active files:".colorize(:blue)
        stats[:top_files].first(5).each_with_index do |file_data, i|
          changes = file_data[:additions] + file_data[:deletions]
          puts "  #{i + 1}. #{file_data[:file]} (#{changes} changes)".colorize(:cyan)
        end
      end

      def generate_table_report
        return puts "📭 No files to display.".colorize(:cyan) if @data.empty?

        grouped_data = group_files_by_hour(@data)

        display_overall_summary

        grouped_data.keys.sort.each do |hour_key|
          hour_data = grouped_data[hour_key]
          display_hourly_table(hour_key, hour_data)
        end
      end

      def display_overall_summary
        stats = generate_summary_stats

        puts "\n#{'=' * 80}"
        puts "📊 OVERALL SUMMARY - File Activity Analysis (#{@time_range})".colorize(:blue)
        puts "=" * 80

        puts "📁 Total files: #{stats[:total_files]}".colorize(:green)
        puts "⏰ Hours with activity: #{stats[:hours_with_activity]}".colorize(:cyan)
        puts "🔄 Modified files: #{stats[:modified_files]}".colorize(:yellow)

        stats[:by_tracking].each do |method, count|
          puts "📊 #{method} tracked: #{count}".colorize(:cyan)
        end

        puts "📈 Total additions: #{stats[:total_additions]}".colorize(:green)
        puts "📉 Total deletions: #{stats[:total_deletions]}".colorize(:red)
      end

      def display_hourly_table(hour_key, hour_data)
        hour_label = format_hour_label(hour_key)

        puts "\n#{'=' * 80}"
        puts "📅 Files Modified During: #{hour_label}".colorize(:blue)
        puts "=" * 80

        display_data_table(hour_data, hour_label)
      end

      def display_data_table(data, _title)
        return puts "📭 No files found.".colorize(:cyan) if data.empty?

        # Define headers and columns
        columns = %i[file modified size tracking git_status index worktree additions deletions chunks]
        headers = [
          "File Path",
          "Modified",
          "Size",
          "Tracking",
          "Status",
          "Index",
          "Worktree",
          "+Lines",
          "-Lines",
          "Chunks"
        ]

        # Convert hash data to row arrays with row numbers
        rows = data.map.with_index(1) do |row_data, index|
          row_values = columns.map { |col| format_cell_value(row_data[col], col) }
          [index] + row_values # Add row number as first column
        end

        # Create table with row numbers header
        table_headers = ["#"] + headers
        table = TTY::Table.new(header: table_headers, rows: rows)

        # Render table with styling
        puts table.render(:ascii) do |renderer|
          renderer.border.separator = :each_row
          renderer.padding = [0, 1, 0, 1]
          renderer.alignments = [:right] + ([:left] * headers.length)
        end

        display_hour_summary(data)
      end

      def format_cell_value(value, column)
        case column
        when :additions
          value.to_s.colorize(:green)
        when :deletions
          value.to_s.colorize(:red)
        when :git_status
          value == '--' ? value : value.colorize(:yellow)
        when :tracking
          case value
          when 'Git'
            value.colorize(:blue)
          when 'YADM'
            value.colorize(:magenta)
          when 'Restic'
            value.colorize(:cyan)
          else
            value.to_s
          end
        else
          value.to_s
        end
      end

      def display_hour_summary(data)
        tracking_counts = data.group_by { |row| row[:tracking] }.transform_values(&:count)
        modified_files = data.count { |row| row[:git_status] != '--' }
        total_additions = data.sum { |row| row[:additions] }
        total_deletions = data.sum { |row| row[:deletions] }

        puts "\n📊 Hour Summary:".colorize(:blue)
        puts "  📁 Files: #{data.length}".colorize(:cyan)
        puts "  🔄 Modified: #{modified_files}".colorize(:yellow)

        tracking_counts.each do |method, count|
          puts "  📊 #{method}: #{count}".colorize(:cyan)
        end

        puts "  📈 Additions: #{total_additions}, 📉 Deletions: #{total_deletions}".colorize(:green)
      end

      def handle_interactive_mode
        return unless @interactive

        puts "\n🎯 Interactive Mode - Choose an action:".colorize(:blue)
        puts "  1. View detailed file analysis".colorize(:cyan)
        puts "  2. Export data to JSON".colorize(:cyan)
        puts "  3. Filter by tracking method".colorize(:cyan)
        puts "  4. Exit".colorize(:cyan)

        print "\nEnter your choice (1-4): ".colorize(:yellow)
        choice = gets.chomp.to_i

        case choice
        when 1
          interactive_file_details
        when 2
          interactive_export_json
        when 3
          interactive_filter_tracking
        when 4
          puts "👋 Goodbye!".colorize(:green)
        else
          puts "❌ Invalid choice. Exiting.".colorize(:red)
        end
      end

      def interactive_file_details
        puts "\n📋 Select a file for detailed analysis:".colorize(:blue)

        @data.each_with_index do |file_data, index|
          status_indicator = file_data[:git_status] == '--' ? '📄' : '🔄'
          puts "  #{index + 1}. #{status_indicator} #{file_data[:file]}".colorize(:cyan)
        end

        print "\nEnter file number: ".colorize(:yellow)
        file_index = gets.chomp.to_i - 1

        if file_index >= 0 && file_index < @data.length
          display_file_details(@data[file_index])
        else
          puts "❌ Invalid file number.".colorize(:red)
        end
      end

      def display_file_details(file_data)
        puts "\n#{'=' * 60}"
        puts "📄 FILE DETAILS".colorize(:blue)
        puts "=" * 60

        file_data.each do |key, value|
          formatted_key = key.to_s.capitalize.tr('_', ' ')
          puts "#{formatted_key}: #{value}".colorize(:cyan)
        end
      end

      def interactive_export_json
        puts "\n💾 Exporting data to JSON format...".colorize(:blue)
        generate_json_report
        puts "\n✅ JSON export completed.".colorize(:green)
      end

      def interactive_filter_tracking
        tracking_methods = @data.map { |d| d[:tracking] }.uniq.sort

        puts "\n📊 Filter by tracking method:".colorize(:blue)
        tracking_methods.each_with_index do |method, index|
          count = @data.count { |d| d[:tracking] == method }
          puts "  #{index + 1}. #{method} (#{count} files)".colorize(:cyan)
        end

        print "\nEnter tracking method number: ".colorize(:yellow)
        method_index = gets.chomp.to_i - 1

        if method_index >= 0 && method_index < tracking_methods.length
          method = tracking_methods[method_index]
          filtered_data = @data.select { |d| d[:tracking] == method }
          puts "\n📋 Files tracked by #{method}:".colorize(:blue)
          display_data_table(filtered_data, "#{method} Files")
        else
          puts "❌ Invalid tracking method number.".colorize(:red)
        end
      end

      def generate_summary_stats
        tracking_counts = @data.group_by { |row| row[:tracking] }.transform_values(&:count)
        modified_files = @data.count { |row| row[:git_status] != '--' }
        total_additions = @data.sum { |row| row[:additions] }
        total_deletions = @data.sum { |row| row[:deletions] }
        total_chunks = @data.sum { |row| row[:chunks] }
        hours_with_activity = group_files_by_hour(@data).keys.count

        # Top files by activity
        top_files = @data.sort_by { |d| -(d[:additions] + d[:deletions]) }

        {
          total_files: @data.length,
          hours_with_activity: hours_with_activity,
          modified_files: modified_files,
          by_tracking: tracking_counts,
          total_additions: total_additions,
          total_deletions: total_deletions,
          total_chunks: total_chunks,
          top_files: top_files
        }
      end

      def group_files_by_hour(data)
        data.group_by do |row|
          row[:modified_time].strftime('%Y-%m-%d %H')
        end
      end

      def format_hour_label(hour_key)
        date_time = Time.strptime(hour_key, '%Y-%m-%d %H')
        date_time.strftime('%A, %B %d, %Y at %I:%M %p - %I:59 %p')
      rescue ArgumentError
        hour_key
      end
    end
  end
end