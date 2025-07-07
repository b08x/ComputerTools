# frozen_string_literal: true

module ComputerTools
  module Actions
    module Deepgram
      class DeepgramParse < Sublayer::Actions::Base
      def initialize(json_file:, output_format: 'markdown', output_file: nil, console_output: false)
        @json_file = json_file
        @output_format = output_format.downcase
        @output_file = output_file
        @console_output = console_output
      end

      def call
        puts "🎙️  Parsing Deepgram output...".colorize(:blue)

        begin
          parser = ComputerTools::Wrappers::DeepgramParser.new(@json_file)
          formatter = ComputerTools::Wrappers::DeepgramFormatter.new(parser)

          # Display summary statistics
          display_summary(parser.summary_stats)

          # Generate output content
          content = generate_content(formatter)

          # Output the content
          handle_output(content)

          puts "✅ Parsing completed successfully!".colorize(:green)
          true
        rescue StandardError => e
          puts "❌ Error parsing Deepgram file: #{e.message}".colorize(:red)
          puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
          false
        end
      end

      private

      def generate_content(formatter)
        case @output_format
        when 'markdown', 'md'
          formatter.to_markdown
        when 'srt'
          formatter.to_srt
        when 'json'
          formatter.to_json
        when 'summary'
          formatter.to_summary
        else
          puts "⚠️  Unknown format '#{@output_format}', defaulting to markdown".colorize(:yellow)
          formatter.to_markdown
        end
      end

      def handle_output(content)
        if @console_output
          puts "\n" + ("=" * 60)
          puts content
        else
          output_file = determine_output_file
          File.write(output_file, content)
          puts "📄 Output written to: #{output_file}".colorize(:cyan)
        end
      end

      def determine_output_file
        return @output_file if @output_file

        base_name = File.basename(@json_file, ".*")
        extension = case @output_format
                    when 'srt'
                      '.srt'
                    when 'json'
                      '_parsed.json'
                    when 'summary'
                      '_summary.txt'
                    else
                      '_analysis.md'
                    end

        File.join(File.dirname(@json_file), "#{base_name}#{extension}")
      end

      def display_summary(stats)
        puts "\n📊 Content Overview:".colorize(:blue)
        puts "   • Total Words: #{stats[:total_words]}"
        puts "   • Total Sentences: #{stats[:total_sentences]}"
        puts "   • Total Paragraphs: #{stats[:total_paragraphs]}"
        puts "   • Topics Identified: #{stats[:total_topics]}"
        puts "   • Intents Detected: #{stats[:total_intents]}"
        puts "   • Transcript Length: #{stats[:transcript_length]} characters"
        puts ""
      end
    end
  end
end
end