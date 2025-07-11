# frozen_string_literal: true

module ComputerTools
  module Actions
    class DeepgramAnalyzeAction < Sublayer::Actions::Base
      def initialize(json_file:, interactive: false, console_output: false)
        @json_file = json_file
        @interactive = interactive
        @console_output = console_output
        @prompt = TTY::Prompt.new if @interactive
      end

      def call
        puts "🔍 Analyzing Deepgram segments...".colorize(:blue)

        begin
          analyzer = ComputerTools::Wrappers::DeepgramAnalyzer.new(@json_file)

          # Display analysis overview
          display_analysis_overview(analyzer)

          if @interactive
            handle_interactive_analysis(analyzer)
          else
            handle_automatic_analysis(analyzer)
          end

          puts "✅ Analysis completed successfully!".colorize(:green)
          true
        rescue StandardError => e
          puts "❌ Error analyzing segments: #{e.message}".colorize(:red)
          puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
          false
        end
      end

      private

      def display_analysis_overview(analyzer)
        stats = analyzer.summary_stats

        puts "\n📊 Analysis Overview:".colorize(:blue)
        puts "   • Total Segments: #{stats[:total_segments]}"
        puts "   • Available Fields: #{stats[:available_fields]}"
        puts "   • Fields with Data: #{stats[:fields_with_data]}"

        puts "   • AI Analysis Present: #{analyzer.has_ai_analysis? ? '✅' : '❌'}"
        puts "   • Software Detection: #{analyzer.has_software_detection? ? '✅' : '❌'}"

        puts "   • Topics: #{analyzer.get_all_topics.join(', ')}" if analyzer.get_all_topics.any?

        puts "   • Software Detected: #{analyzer.get_all_software.join(', ')}" if analyzer.get_all_software.any?

        puts ""
      end

      def handle_interactive_analysis(analyzer)
        loop do
          choice = @prompt.select(
            "What would you like to do?", {
              "View specific fields" => :view_fields,
              "Filter by topic"      => :filter_topic,
              "Filter by software"   => :filter_software,
              "Export analysis"      => :export,
              "Exit"                 => :exit
            }
          )

          case choice
          when :view_fields
            handle_field_selection(analyzer)
          when :filter_topic
            handle_topic_filter(analyzer)
          when :filter_software
            handle_software_filter(analyzer)
          when :export
            handle_export(analyzer)
          when :exit
            break
          end
        end
      end

      def handle_automatic_analysis(analyzer)
        # Show all available fields automatically
        available_fields = analyzer.get_field_options

        if available_fields.any?
          puts "📋 Displaying all available fields:".colorize(:blue)
          results = analyzer.extract_fields(available_fields)
          display_results(results)
        else
          puts "⚠️  No recognizable fields found in the segments".colorize(:yellow)
        end
      end

      def handle_field_selection(analyzer)
        available_fields = analyzer.get_field_options

        if available_fields.empty?
          puts "❌ No fields with data available".colorize(:red)
          return
        end

        selected_fields = @prompt.multi_select(
          "Select fields to display:",
          available_fields,
          default: available_fields.first(3)
        )

        return unless selected_fields.any?

        results = analyzer.extract_fields(selected_fields)
        display_results(results)
      end

      def handle_topic_filter(analyzer)
        topics = analyzer.get_all_topics

        if topics.empty?
          puts "❌ No topics found in segments".colorize(:red)
          return
        end

        selected_topic = @prompt.select("Select topic to filter by:", topics)
        filtered_segments = analyzer.filter_by_topic(selected_topic)

        puts "📋 Segments for topic '#{selected_topic}':".colorize(:blue)
        display_segments(filtered_segments)
      end

      def handle_software_filter(analyzer)
        software_list = analyzer.get_all_software

        if software_list.empty?
          puts "❌ No software detections found".colorize(:red)
          return
        end

        selected_software = @prompt.select("Select software to filter by:", software_list)
        filtered_segments = analyzer.filter_by_software(selected_software)

        puts "📋 Segments with '#{selected_software}':".colorize(:blue)
        display_segments(filtered_segments)
      end

      def handle_export(analyzer)
        format = @prompt.select(
          "Export format:", {
            "JSON" => :json,
            "Markdown" => :markdown,
            "CSV"      => :csv
          }
        )

        output_file = generate_export_filename(format)
        export_analysis(analyzer, format, output_file)
        puts "📄 Analysis exported to: #{output_file}".colorize(:cyan)
      end

      def display_results(results)
        return if results.empty?

        results.each_with_index do |segment_data, index|
          puts "\n=== Segment #{index + 1} ===".colorize(:cyan)
          segment_data.each do |field_name, value|
            puts "#{field_name}: #{value}"
          end
        end
        puts ""
      end

      def display_segments(segments)
        segments.each_with_index do |segment, index|
          puts "\n--- Segment #{index + 1} ---"
          puts "Transcript: #{segment['transcript']}" if segment['transcript']
          puts "Topic: #{segment['topic']}" if segment['topic']
          puts "Analysis: #{segment['gemini_analysis']}" if segment['gemini_analysis']
          puts "Software: #{segment['software_detected']}" if segment['software_detected']
        end
        puts ""
      end

      def generate_export_filename(format)
        base_name = File.basename(@json_file, ".*")
        extension = case format
                    when :json
                      '_analysis.json'
                    when :markdown
                      '_analysis.md'
                    when :csv
                      '_analysis.csv'
                    end

        File.join(File.dirname(@json_file), "#{base_name}#{extension}")
      end

      def export_analysis(analyzer, format, output_file)
        case format
        when :json
          content = {
            summary: analyzer.summary_stats,
            segments: analyzer.segments,
            topics: analyzer.get_all_topics,
            software: analyzer.get_all_software
          }.to_json
        when :markdown
          content = generate_markdown_export(analyzer)
        when :csv
          content = generate_csv_export(analyzer)
        end

        File.write(output_file, content)
      end

      def generate_markdown_export(analyzer)
        content = ["# Deepgram Segment Analysis\n"]

        content << "## Summary\n"
        stats = analyzer.summary_stats
        content << "- Total Segments: #{stats[:total_segments]}\n"
        content << "- Available Fields: #{stats[:available_fields]}\n"
        content << "- AI Analysis: #{analyzer.has_ai_analysis? ? 'Yes' : 'No'}\n"
        content << "- Software Detection: #{analyzer.has_software_detection? ? 'Yes' : 'No'}\n\n"

        content << "## Segments\n"
        analyzer.segments.each_with_index do |segment, index|
          content << "### Segment #{index + 1}\n"
          segment.each do |key, value|
            next if value.nil? || value.to_s.strip.empty?

            content << "- **#{key.tr('_', ' ').split.map(&:capitalize).join(' ')}**: #{value}\n"
          end
          content << "\n"
        end

        content.join
      end

      def generate_csv_export(analyzer)
        require 'csv'

        CSV.generate do |csv|
          # Header row
          headers = analyzer.segments.first&.keys || []
          csv << headers

          # Data rows
          analyzer.segments.each do |segment|
            row = headers.map { |header| segment[header] }
            csv << row
          end
        end
      end
    end
  end
end
