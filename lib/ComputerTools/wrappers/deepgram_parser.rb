# frozen_string_literal: true

module ComputerTools
  module Wrappers
    class DeepgramParser
      attr_reader :json_data, :paragraphs, :intents, :topics, :transcript

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

      def words_with_confidence
        words = @json_data.dig("results", "channels", 0, "alternatives", 0, "words")
        return [] unless words

        words.map do |word|
          { word: word["word"], confidence: word["confidence"] }
        end
      end

      def segmented_sentences
        paragraphs = @json_data.dig("results", "channels", 0, "alternatives", 0, "paragraphs", "paragraphs")
        return [] unless paragraphs

        paragraphs
          .flat_map { |p| p["sentences"] || [] }
          .map { |sentence| { text: sentence["text"] } }
      end

      def paragraphs_as_sentences
        paragraphs = @json_data.dig("results", "channels", 0, "alternatives", 0, "paragraphs", "paragraphs")
        return [] unless paragraphs

        paragraphs.map do |p|
          sentences = p["sentences"] || []
          { paragraph: sentences.map { |s| s["text"] } }
        end
      end

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

      def load_json_data(file_path)
        JSON.parse(File.read(file_path))
      end

      def parse_data
        extract_transcript
        extract_paragraphs
        extract_topics
        extract_intents
      end

      def extract_transcript
        @transcript = @json_data.dig("results", "channels", 0, "alternatives", 0, "transcript")
      end

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
