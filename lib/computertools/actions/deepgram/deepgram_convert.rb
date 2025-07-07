# frozen_string_literal: true

module ComputerTools
  module Actions
    module Deepgram
      class DeepgramConvert < Sublayer::Actions::Base
      SUPPORTED_FORMATS = %w[srt markdown md json summary].freeze

      def initialize(json_file:, format:, output_file: nil, console_output: false)
        @json_file = json_file
        @format = format.downcase
        @output_file = output_file
        @console_output = console_output
      end

      def call
        puts "🔄 Converting Deepgram output to #{@format.upcase}...".colorize(:blue)

        unless SUPPORTED_FORMATS.include?(@format)
          puts "❌ Unsupported format: #{@format}".colorize(:red)
          puts "Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
          return false
        end

        begin
          parser = ComputerTools::Wrappers::DeepgramParser.new(@json_file)
          formatter = ComputerTools::Wrappers::DeepgramFormatter.new(parser)

          # Generate content in requested format
          content = generate_content(formatter)

          # Handle output
          handle_output(content)

          puts "✅ Conversion completed successfully!".colorize(:green)
          true
        rescue StandardError => e
          puts "❌ Error converting file: #{e.message}".colorize(:red)
          puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
          false
        end
      end

      private

      def generate_content(formatter)
        case @format
        when 'srt'
          formatter.to_srt
        when 'markdown', 'md'
          formatter.to_markdown
        when 'json'
          formatter.to_json
        when 'summary'
          formatter.to_summary
        else
          raise "Unsupported format: #{@format}"
        end
      end

      def handle_output(content)
        if @console_output
          puts "\n" + ("=" * 60)
          puts content
        else
          output_file = determine_output_file
          File.write(output_file, content)
          puts "📄 Converted file saved to: #{output_file}".colorize(:cyan)

          # Show format-specific success message
          display_format_specific_message(output_file)
        end
      end

      def determine_output_file
        return @output_file if @output_file

        base_name = File.basename(@json_file, ".*")
        extension = case @format
                    when 'srt'
                      '.srt'
                    when 'markdown', 'md'
                      '.md'
                    when 'json'
                      '_converted.json'
                    when 'summary'
                      '_summary.txt'
                    end

        File.join(File.dirname(@json_file), "#{base_name}#{extension}")
      end

      def display_format_specific_message(_output_file)
        case @format
        when 'srt'
          puts "🎬 SRT subtitle file ready for video players".colorize(:green)
        when 'markdown', 'md'
          puts "📝 Markdown file ready for documentation".colorize(:green)
        when 'json'
          puts "📊 JSON file ready for further processing".colorize(:green)
        when 'summary'
          puts "📋 Summary file ready for quick review".colorize(:green)
        end
      end
    end
  end
end
end