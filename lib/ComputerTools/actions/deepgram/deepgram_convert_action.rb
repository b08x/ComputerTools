# frozen_string_literal: true

require 'set'
require 'yaml'

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

          # Store parser for use in display methods
          @parser = parser

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
          speaker_config = load_speaker_configuration
          formatter.to_srt(speaker_options: speaker_config)
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
      # Loads speaker diarization configuration from the deepgram.yml file.
      #
      # This method reads the speaker_diarization section from the configuration
      # file and validates the settings. Returns nil if speaker diarization is
      # disabled or if configuration loading fails.
      #
      # @return [Hash, nil] The speaker configuration hash or nil if disabled/invalid
      #
      # @example Valid configuration structure
      #   {
      #     enable: true,
      #     confidence_threshold: 0.8,
      #     label_format: "[Speaker %d]: ",
      #     merge_consecutive_segments: true,
      #     min_segment_duration: 1.0,
      #     max_speakers: 10
      #   }
      def load_speaker_configuration
        config_file = File.join(__dir__, '..', '..', 'config', 'deepgram.yml')
        
        unless File.exist?(config_file)
          puts "⚠️  Deepgram configuration file not found. Using default SRT generation.".colorize(:yellow) if ENV['DEBUG']
          return nil
        end

        begin
          config = YAML.load_file(config_file)
          speaker_config = config['speaker_diarization']
          
          # Return nil if speaker diarization is not configured or disabled
          return nil unless speaker_config&.dig('enable')
          
          # Validate and return the configuration
          validated_config = validate_speaker_configuration(speaker_config)
          
          if ENV['DEBUG']
            puts "🎤 Speaker diarization enabled with confidence threshold: #{validated_config[:confidence_threshold]}".colorize(:blue)
          end
          
          validated_config
        rescue Psych::SyntaxError => e
          puts "❌ Invalid YAML syntax in deepgram.yml: #{e.message}".colorize(:red)
          puts "🔄 Using default SRT generation without speaker labels.".colorize(:yellow)
          nil
        rescue StandardError => e
          puts "⚠️  Failed to load speaker configuration: #{e.message}".colorize(:yellow) if ENV['DEBUG']
          puts "🔄 Using default SRT generation without speaker labels.".colorize(:yellow)
          nil
        end
      end

      # @!visibility private
      # Validates speaker diarization configuration options.
      #
      # Ensures all configuration values are within acceptable ranges and
      # have valid formats. Provides defaults for missing values.
      #
      # @param config [Hash] The raw configuration from YAML
      # @return [Hash] The validated configuration with symbolized keys
      # @raise [ArgumentError] if configuration values are invalid
      def validate_speaker_configuration(config)
        validated = {}
        
        # Enable flag (already checked in load_speaker_configuration)
        validated[:enable] = true
        
        # Validate confidence threshold (0.0-1.0)
        threshold = config['confidence_threshold'] || 0.8
        unless threshold.is_a?(Numeric) && threshold >= 0.0 && threshold <= 1.0
          raise ArgumentError, "confidence_threshold must be a number between 0.0 and 1.0, got: #{threshold}"
        end
        validated[:confidence_threshold] = threshold.to_f
        
        # Validate label format (must contain %d placeholder)
        label_format = config['label_format'] || "[Speaker %d]: "
        unless label_format.is_a?(String) && label_format.include?('%d')
          raise ArgumentError, "label_format must be a string containing '%d' placeholder, got: #{label_format}"
        end
        validated[:label_format] = label_format
        
        # Validate merge consecutive segments flag
        merge_segments = config['merge_consecutive_segments']
        merge_segments = true if merge_segments.nil?
        validated[:merge_consecutive_segments] = !!merge_segments
        
        # Validate minimum segment duration
        min_duration = config['min_segment_duration'] || 1.0
        unless min_duration.is_a?(Numeric) && min_duration >= 0.0
          raise ArgumentError, "min_segment_duration must be a non-negative number, got: #{min_duration}"
        end
        validated[:min_segment_duration] = min_duration.to_f
        
        # Validate maximum speakers
        max_speakers = config['max_speakers'] || 10
        unless max_speakers.is_a?(Integer) && max_speakers > 0 && max_speakers <= 50
          raise ArgumentError, "max_speakers must be an integer between 1 and 50, got: #{max_speakers}"
        end
        validated[:max_speakers] = max_speakers
        
        validated
      rescue ArgumentError => e
        puts "❌ Invalid speaker configuration: #{e.message}".colorize(:red)
        puts "🔄 Using default SRT generation without speaker labels.".colorize(:yellow)
        nil
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
      #
      # For SRT format, shows additional information about speaker diarization
      # if it was enabled and speaker data was available.
      #
      # @param _output_file [String] The path of the generated file (currently unused).
      def display_format_specific_message(_output_file)
        case @format
        when 'srt'
          puts "🎬 SRT subtitle file ready for video players".colorize(:green)
          display_speaker_info if @parser
        when 'markdown', 'md'
          puts "📝 Markdown file ready for documentation".colorize(:green)
        when 'json'
          puts "📊 JSON file ready for further processing".colorize(:green)
        when 'summary'
          puts "📋 Summary file ready for quick review".colorize(:green)
        end
      end

      # @!visibility private
      # Displays speaker diarization information for SRT format.
      #
      # Shows whether speaker diarization was used and provides statistics
      # about the detected speakers if available.
      #
      # @return [void]
      def display_speaker_info
        return unless @parser.respond_to?(:has_speaker_data?)
        
        speaker_config = load_speaker_configuration
        
        if speaker_config&.dig(:enable)
          if @parser.has_speaker_data?
            speaker_count = count_unique_speakers
            confidence = speaker_config[:confidence_threshold]
            
            puts "🎤 Speaker diarization applied (#{speaker_count} speakers detected, #{(confidence * 100).to_i}% confidence threshold)".colorize(:blue)
            puts "📋 Speaker labels format: #{speaker_config[:label_format].gsub('%d', 'N')}".colorize(:cyan)
          else
            puts "⚠️  No speaker data found in transcript - using paragraph-based SRT".colorize(:yellow)
          end
        end
      end

      # @!visibility private
      # Counts the number of unique speakers in the transcript.
      #
      # @return [Integer] The number of unique speakers detected
      def count_unique_speakers
        return 0 unless @parser.respond_to?(:speaker_segments)
        
        # Get the current speaker configuration to use the same confidence threshold
        speaker_config = load_speaker_configuration
        confidence_threshold = speaker_config&.dig(:confidence_threshold) || 0.8
        
        speakers = Set.new
        @parser.speaker_segments(min_confidence: confidence_threshold).each do |segment|
          speakers.add(segment[:speaker_id]) if segment[:speaker_id]
        end
        speakers.size
      rescue StandardError
        0
      end
    end
  end
end