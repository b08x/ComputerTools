# frozen_string_literal: true

module ComputerTools
  module Wrappers
    ##
    # DeepgramFormatter converts Deepgram API responses into various output formats.
    #
    # This class takes parsed Deepgram data and formats it into SRT (SubRip), Markdown,
    # JSON, or summary formats for different use cases like subtitles, documentation,
    # or data processing.
    #
    # @example Creating a formatter instance
    #   parser = ComputerTools::Wrappers::DeepgramParser.new('response.json')
    #   formatter = ComputerTools::Wrappers::DeepgramFormatter.new(parser)
    class DeepgramFormatter
      ##
      # Initializes a new DeepgramFormatter instance.
      #
      # @param parser [DeepgramParser] An instance of DeepgramParser containing the parsed data
      # @return [DeepgramFormatter] A new instance of DeepgramFormatter
      def initialize(parser)
        @parser = parser
      end

      ##
      # Converts the parsed data into SRT (SubRip) subtitle format.
      #
      # This method transforms the paragraph data into a standard SRT format with
      # sequential numbering, timestamp ranges, and text content.
      #
      # @return [String] The formatted SRT content
      # @example Converting to SRT format
      #   srt_content = formatter.to_srt
      #   File.write('subtitles.srt', srt_content)
      def to_srt
        output = []
        @parser.paragraphs.each_with_index do |p, index|
          output << (index + 1).to_s
          output << "#{format_timestamp_for_srt(p[:start])} --> #{format_timestamp_for_srt(p[:end])}"
          output << p[:text]
          output << ""
        end
        output.join("\n")
      end

      ##
      # Converts the parsed data into Markdown format.
      #
      # This method creates a comprehensive Markdown document with sections for:
      # - Full transcript
      # - Paragraphs with timestamps
      # - Intents with time ranges
      # - Topics identified
      # - Words with confidence scores
      # - Segmented sentences
      #
      # @return [String] The formatted Markdown content
      # @example Converting to Markdown format
      #   markdown_content = formatter.to_markdown
      #   File.write('analysis.md', markdown_content)
      def to_markdown
        output = ["# Deepgram Analysis Results\n"]

        output << "## Full Transcript\n\n#{@parser.transcript}\n" if @parser.transcript

        unless @parser.paragraphs.empty?
          output << "## Paragraphs\n"
          @parser.paragraphs.each do |p|
            output << "### #{p[:start]} -> #{p[:end]}\n"
            output << "#{p[:text]}\n\n"
          end
        end

        unless @parser.intents.empty?
          output << "## Intents\n"
          @parser.intents.each do |i|
            output << "- #{i[:start]} -> #{i[:end]}: #{i[:intent]}\n"
          end
          output << "\n"
        end

        unless @parser.topics.empty?
          output << "## Topics\n"
          @parser.topics.each do |t|
            output << "- #{t[:topic]}\n"
          end
          output << "\n"
        end

        words = @parser.words_with_confidence
        unless words.empty?
          output << "## Words with Confidence\n"
          words.each do |w|
            output << "- #{w[:word]}: #{w[:confidence]}\n"
          end
          output << "\n"
        end

        sentences = @parser.segmented_sentences
        unless sentences.empty?
          output << "## Segmented Sentences\n"
          sentences.each do |s|
            output << "- #{s[:text]}\n"
          end
        end

        output.join("\n")
      end

      ##
      # Converts the parsed data into JSON format.
      #
      # This method returns a JSON string containing all the parsed data in a structured format,
      # including transcripts, paragraphs, intents, topics, and various analysis results.
      #
      # @return [String] The formatted JSON content
      # @example Converting to JSON format
      #   json_content = formatter.to_json
      #   File.write('analysis.json', json_content)
      def to_json(*_args)
        {
          transcript: @parser.transcript,
          paragraphs: @parser.paragraphs,
          intents: @parser.intents,
          topics: @parser.topics,
          words_with_confidence: @parser.words_with_confidence,
          segmented_sentences: @parser.segmented_sentences,
          segments_with_topics: @parser.segments_with_topics,
          segments_with_intents: @parser.segments_with_intents,
          summary_stats: @parser.summary_stats
        }.to_json
      end

      ##
      # Generates a summary of the Deepgram analysis.
      #
      # This method creates a human-readable summary with key statistics about the content,
      # including word counts, sentence counts, topics identified, intents detected, and duration.
      #
      # @return [String] The formatted summary content
      # @example Generating a summary
      #   summary = formatter.to_summary
      #   puts summary
      def to_summary
        stats = @parser.summary_stats

        <<~SUMMARY
          📊 Deepgram Analysis Summary
          ============================

          📝 Content Overview:
          • Total Words: #{stats[:total_words]}
          • Total Sentences: #{stats[:total_sentences]}
          • Total Paragraphs: #{stats[:total_paragraphs]}
          • Transcript Length: #{stats[:transcript_length]} characters

          🏷️ Topics Identified: #{stats[:total_topics]}
          #{@parser.topics.map { |t| "   • #{t[:topic]}" }.join("\n")}

          🎯 Intents Detected: #{stats[:total_intents]}
          #{@parser.intents.map { |i| "   • #{i[:intent]}" }.join("\n")}

          ⏱️ Duration: #{calculate_duration}
        SUMMARY
      end

      private

      ##
      # Formats a timestamp string for SRT format.
      #
      # Converts HH:MM:SS timestamps to HH:MM:SS,000 format required by SRT files.
      #
      # @param timestamp_str [String] The timestamp string in HH:MM:SS format
      # @return [String] The formatted timestamp string in HH:MM:SS,000 format
      # @private
      def format_timestamp_for_srt(timestamp_str)
        # Convert HH:MM:SS to HH:MM:SS,000 format for SRT
        return "00:00:00,000" unless timestamp_str

        parts = timestamp_str.split(':')
        return "00:00:00,000" unless parts.length == 3

        "#{parts[0]}:#{parts[1]}:#{parts[2]},000"
      end

      ##
      # Calculates the duration of the content based on paragraph timestamps.
      #
      # Determines the duration by finding the end time of the last paragraph.
      #
      # @return [String] The duration as a timestamp string or "Unknown" if not available
      # @private
      def calculate_duration
        return "Unknown" if @parser.paragraphs.empty?

        last_paragraph = @parser.paragraphs.last
        last_paragraph[:end] || "Unknown"
      end
    end
  end
end