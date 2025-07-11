# frozen_string_literal: true

module ComputerTools
  module Actions
    # Analyzes a JSON output file from Deepgram, providing tools to interactively
    # or automatically explore, filter, and export transcript segments and their
    # associated metadata, such as AI-generated topics or detected software.
    #
    # This action can run in two modes:
    # - **Interactive (`interactive: true`):** Presents a command-line menu
    #   to view specific data fields, filter segments by topic or software,
    #   and export the results to various formats (JSON, Markdown, CSV).
    # - **Automatic (`interactive: false`):** Automatically extracts and displays
    #   all available data fields found within the transcript segments.
    #
    # @example Run an interactive analysis session
    #   action = ComputerTools::Actions::DeepgramAnalyzeAction.new(
    #     json_file: 'path/to/transcript.json',
    #     interactive: true
    #   )
    #   action.call
    #
    # @example Run an automatic analysis and print all fields
    #   action = ComputerTools::Actions::DeepgramAnalyzeAction.new(
    #     json_file: 'path/to/enriched_transcript.json'
    #   )
    #   action.call
    class DeepgramAnalyzeAction < Sublayer::Actions::Base
      # Initializes the DeepgramAnalyzeAction.
      #
      # @param json_file [String] The path to the input Deepgram JSON file.
      # @param interactive [Boolean] If true, runs an interactive session using
      #   TTY::Prompt. Defaults to false, running in automatic mode.
      # @param console_output [Boolean] A flag to control console output.
      #   In this action, output is primarily directed to the console.
      def initialize(json_file:, interactive: false, console_output: false)
        @json_file = json_file
        @interactive = interactive
        @console_output = console_output
        @prompt = TTY::Prompt.new if @interactive
      end

      # Executes the analysis process.
      #
      # It initializes an analyzer for the specified JSON file, displays a summary
      # overview, and then proceeds with either an interactive menu-driven session
      # or an automatic data dump to the console, based on the `interactive` flag.
      #
      # @return [Boolean] Returns `true` if the analysis completes successfully,
      #   `false` if an error occurs.
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

      # @private
      # Displays a high-level summary of the analysis data to the console.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Starts the interactive command-line menu loop for user-driven analysis.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Runs the non-interactive analysis, displaying all available fields.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Handles the interactive logic for selecting and displaying specific data fields.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Handles the interactive logic for filtering segments by a selected topic.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Handles the interactive logic for filtering segments by detected software.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Manages the interactive process of exporting the analysis to a file.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
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

      # @private
      # Helper method to format and print extracted field data to the console.
      # @param results [Array<Hash>] An array of hashes, where each hash represents a segment.
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

      # @private
      # Helper method to format and print filtered segments to the console.
      # @param segments [Array<Hash>] An array of segment hashes.
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

      # @private
      # Creates a filename for the export based on the original filename and chosen format.
      # @param format [Symbol] The export format (:json, :markdown, :csv).
      # @return [String] The generated output file path.
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

      # @private
      # Writes the analysis content to a file in the specified format.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
      # @param format [Symbol] The export format (:json, :markdown, :csv).
      # @param output_file [String] The path to the output file.
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

      # @private
      # Builds the Markdown content for an export.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
      # @return [String] The generated Markdown content.
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

      # @private
      # Builds the CSV content for an export.
      # @param analyzer [ComputerTools::Wrappers::DeepgramAnalyzer] The analyzer instance.
      # @return [String] The generated CSV content.
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