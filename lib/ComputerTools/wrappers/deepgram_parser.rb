# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # DeepgramParser processes JSON output from Deepgram's speech-to-text API,
    # extracting structured information including transcripts, paragraphs, topics,
    # intents, and confidence scores for individual words.
    #
    # This parser is designed to work with Deepgram's response format and provides
    # convenient methods to access different aspects of the transcription data.
    #
    # @example Basic usage
    #   parser = DeepgramParser.new('path/to/deepgram_response.json')
    #   puts parser.transcript
    #   puts parser.paragraphs
    #
    # @see https://developers.deepgram.com/ Deepgram API Documentation
    class DeepgramParser
      # The raw JSON data loaded from the file
      # @return [Hash] the parsed JSON data structure
      attr_reader :json_data

      # Array of paragraph hashes containing text and timing information
      # @return [Array<Hash>] array of paragraph hashes with :text, :start, and :end keys
      attr_reader :paragraphs

      # Array of intent hashes with timing information
      # @return [Array<Hash>] array of intent hashes with :intent, :start, and :end keys
      attr_reader :intents

      # Array of unique topics found in the transcription
      # @return [Array<Hash>] array of topic hashes with :topic keys
      attr_reader :topics

      # The full transcript text
      # @return [String, nil] the complete transcript or nil if not available
      attr_reader :transcript

      # Initializes a new DeepgramParser with data from a JSON file
      #
      # @param [String] json_file_path path to the Deepgram JSON response file
      # @raise [ArgumentError] if the file doesn't exist
      # @raise [RuntimeError] if the file contains invalid JSON
      #
      # @example Creating a new parser instance
      #   parser = DeepgramParser.new('response.json')
      def initialize(json_file_path)
        raise ArgumentError, "File not found: #{json_file_path}" unless File.exist?(json_file_path)

        @json_file_path = json_file_path
        @json_data = load_json_data(json_file_path)
        @paragraphs = []
        @intents = []
        @topics = []
        @transcript = nil

        parse_data
      rescue JSON::ParserError => e
        raise "Invalid JSON file: #{e.message}"
      end

      # Extracts words with their confidence scores from the transcription
      #
      # @return [Array<Hash>] array of hashes with :word and :confidence keys
      # @example Getting words with confidence scores
      #   parser.words_with_confidence.each do |word|
      #     puts "#{word[:word]}: #{word[:confidence]}"
      #   end
      def words_with_confidence
        words = @json_data.dig("results", "channels", 0, "alternatives", 0, "words")
        return [] unless words

        words.map do |word|
          { word: word["word"], confidence: word["confidence"] }
        end
      end

      # Returns all sentences from the transcription as individual elements
      #
      # @return [Array<Hash>] array of hashes with :text keys containing sentence text
      # @example Iterating through sentences
      #   parser.segmented_sentences.each do |sentence|
      #     puts sentence[:text]
      #   end
      def segmented_sentences
        paragraphs = @json_data.dig("results", "channels", 0, "alternatives", 0, "paragraphs", "paragraphs")
        return [] unless paragraphs

        paragraphs
          .flat_map { |p| p["sentences"] || [] }
          .map { |sentence| { text: sentence["text"] } }
      end

      # Returns paragraphs as arrays of sentences
      #
      # @return [Array<Hash>] array of hashes with :paragraph keys containing arrays of sentence strings
      # @example Working with paragraphs
      #   parser.paragraphs_as_sentences.each do |paragraph|
      #     paragraph[:paragraph].each do |sentence|
      #       puts sentence
      #     end
      #   end
      def paragraphs_as_sentences
        paragraphs = @json_data.dig("results", "channels", 0, "alternatives", 0, "paragraphs", "paragraphs")
        return [] unless paragraphs

        paragraphs.map do |p|
          sentences = p["sentences"] || []
          { paragraph: sentences.map { |s| s["text"] } }
        end
      end

      # Returns text segments with their associated topics
      #
      # @return [Array<Hash>] array of hashes with :text and :topics keys
      # @example Extracting topics
      #   parser.segments_with_topics.each do |segment|
      #     puts "Segment: #{segment[:text]}"
      #     segment[:topics].each do |topic|
      #       puts "Topic: #{topic[:topic]}"
      #     end
      #   end
      def segments_with_topics
        segments = @json_data.dig("results", "topics", "segments")
        return [] unless segments

        segments.map do |seg|
          topics = seg["topics"] || []
          {
            text: seg["text"],
            topics: topics.map { |t| { topic: t["topic"] } }
          }
        end
      end

      # Returns text segments with their associated intents
      #
      # @return [Array<Hash>] array of hashes with :text and :intents keys
      # @example Extracting intents
      #   parser.segments_with_intents.each do |segment|
      #     puts "Segment: #{segment[:text]}"
      #     segment[:intents].each do |intent|
      #       puts "Intent: #{intent[:intent]}"
      #     end
      #   end
      def segments_with_intents
        segments = @json_data.dig("results", "intents", "segments")
        return [] unless segments

        segments.map do |seg|
          intents = seg["intents"] || []
          {
            text: seg["text"],
            intents: intents.map { |i| { intent: i["intent"] } }
          }
        end
      end

      # Provides summary statistics about the parsed transcription
      #
      # @return [Hash] hash containing various counts and metrics about the transcription
      # @example Getting summary statistics
      #   stats = parser.summary_stats
      #   puts "Total words: #{stats[:total_words]}"
      #   puts "Total sentences: #{stats[:total_sentences]}"
      def summary_stats
        {
          total_words: words_with_confidence.count,
          total_sentences: segmented_sentences.count,
          total_paragraphs: @paragraphs.count,
          total_topics: @topics.count,
          total_intents: @intents.count,
          transcript_length: @transcript&.length || 0
        }
      end

      private

      # Loads and parses JSON data from a file
      #
      # @param [String] file_path path to the JSON file
      # @return [Hash] parsed JSON data
      # @raise [JSON::ParserError] if the file contains invalid JSON
      def load_json_data(file_path)
        JSON.parse(File.read(file_path))
      end

      # Main parsing method that coordinates extraction of all data components
      def parse_data
        extract_transcript
        extract_paragraphs
        extract_topics
        extract_intents
      end

      # Extracts the full transcript text from the JSON data
      def extract_transcript
        @transcript = @json_data.dig("results", "channels", 0, "alternatives", 0, "transcript")
      end

      # Extracts paragraphs with their timing information
      def extract_paragraphs
        paragraphs = @json_data.dig("results", "channels", 0, "alternatives", 0, "paragraphs", "paragraphs")
        return unless paragraphs

        paragraphs.each do |paragraph|
          sentences = paragraph["sentences"] || []
          next if sentences.empty?

          sentence_texts = sentences.map { |sentence| sentence["text"] }
          start_time = format_timestamp(sentences.first["start"])
          end_time = format_timestamp(sentences.last["end"])
          @paragraphs << { text: sentence_texts.join(" "), start: start_time, end: end_time }
        end
      end

      # Extracts unique topics from the transcription data
      def extract_topics
        segments = @json_data.dig("results", "topics", "segments")
        return unless segments

        segments.each do |seg|
          topics = seg["topics"]
          next unless topics&.any?

          @topics << { topic: topics[0]["topic"] }
        end
        @topics.uniq!
      end

      # Extracts intents with their timing information
      def extract_intents
        segments = @json_data.dig("results", "intents", "segments")
        return unless segments

        segments.each do |seg|
          intents = seg["intents"]
          next unless intents&.any?

          start_time = format_timestamp(seg["start"])
          end_time = format_timestamp(seg["end"])
          @intents << { intent: intents[0]["intent"], start: start_time, end: end_time }
        end
        @intents.uniq!
      end

      # Formats timestamp in seconds to HH:MM:SS format
      #
      # @param [Numeric] seconds timestamp in seconds
      # @param [Boolean] include_ms whether to include milliseconds in the output
      # @return [String, nil] formatted timestamp or nil if input is nil
      # @example Formatting a timestamp
      #   format_timestamp(125.345) # => "00:02:05"
      #   format_timestamp(125.345, include_ms: true) # => "00:02:05,345"
      def format_timestamp(seconds, include_ms: false)
        return nil if seconds.nil?

        hours = (seconds / 3600).to_i
        minutes = ((seconds % 3600) / 60).to_i
        secs = (seconds % 60).to_i
        ms = ((seconds % 1) * 1000).to_i

        if include_ms
          format("%02d:%02d:%02d,%03d", hours, minutes, secs, ms)
        else
          format("%02d:%02d:%02d", hours, minutes, secs)
        end
      rescue StandardError => e
        puts "Error formatting timestamp: #{e.message}"
        nil
      end
    end
  end
end