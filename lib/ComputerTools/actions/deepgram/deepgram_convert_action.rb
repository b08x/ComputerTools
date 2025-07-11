# frozen_string_literal: true

module ComputerTools
  module Actions
    # Converts a Deepgram JSON transcript file into various other formats.
    #
    # This action is used to take the raw JSON output from the Deepgram API
    # and transform it into more usable formats like SRT for subtitles,
    # Markdown for documentation, or a simple summary. It provides options
    # for file-based output or printing directly to the console.
    #
    # @example Convert a JSON file to an SRT subtitle file
    #   action = ComputerTools::Actions::DeepgramConvertAction.new(
    #     json_file: 'path/to/transcript.json',
    #     format: 'srt'
    #   )
    #   action.call # => true, and writes 'path/to/transcript.srt'
    #
    # @example Get a summary printed to the console
    #   action = ComputerTools::Actions::DeepgramConvertAction.new(
    #     json_file: 'path/to/transcript.json',
    #     format: 'summary',
    #     console_output: true
    #   )
    #   action.call # => true, and prints summary to STDOUT
    class DeepgramConvertAction < Sublayer::Actions::Base
      # A list of the output formats supported by the conversion action.
      SUPPORTED_FORMATS = %w[srt markdown md json summary].freeze

      # Initializes a new DeepgramConvertAction.
      #
      # @param json_file [String] The path to the input Deepgram JSON file.
      # @param format [String] The desired output format. Supported formats are:
      #   'srt', 'markdown', 'md', 'json', and 'summary'.
      # @param output_file [String, nil] The optional path for the output file.
      #   If nil, a path is automatically generated based on the input file name
      #   and target format.
      # @param console_output [Boolean] If true, the result is printed to the
      #   console instead of being saved to a file. Defaults to false.
      def initialize(json_file:, format:, output_file: nil, console_output: false)
        @json_file = json_file
        @format = format.downcase
        @output_file = output_file
        @console_output = console_output
      end

      # Executes the conversion process.
      #
      # This method reads the source JSON file, validates the requested format,
      # converts the content, and then either writes it to an output file or
      # prints it to the console. It handles file I/O and error reporting.
      #
      # @return [Boolean] Returns `true` if the conversion is successful,
      #   otherwise returns `false` (e.g., for an unsupported format or file error).
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

      # @!visibility private
      # Generates the output content string based on the requested format.
      # @param formatter [ComputerTools::Wrappers::DeepgramFormatter] The formatter instance.
      # @return [String] The formatted content.
      # @raise [RuntimeError] if the format is not supported.
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

      # @!visibility private
      # Handles the output of the converted content.
      # @param content [String] The content to output.
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

      # @!visibility private
      # Determines the appropriate output file path.
      # @return [String] The path for the output file.
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

      # @!visibility private
      # Displays a helpful message specific to the output format.
      # @param _output_file [String] The path of the generated file (currently unused).
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