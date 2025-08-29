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

      # Extracts words with their speaker identification information from the Deepgram response.
      #
      # This method processes the transcript data to identify individual words along with
      # their associated speaker information, including confidence scores and precise timing.
      # Only words with both speaker ID and speaker confidence data are included.
      #
      # @return [Array<Hash>] An array of word hashes containing:
      #   - `:word` [String] The spoken word
      #   - `:speaker` [Integer] Speaker identifier (unique integer for each detected speaker)
      #   - `:speaker_confidence` [Float] Confidence score for speaker identification (0.0-1.0)
      #   - `:start` [String] Formatted start timestamp in HH:MM:SS
      #   - `:end` [String] Formatted end timestamp in HH:MM:SS
      #   - `:start_raw` [Float] Raw start time in seconds
      #   - `:end_raw` [Float] Raw end time in seconds
      #
      # @example Getting words with detailed speaker information
      #   parser.words_with_speaker_info.each do |word|
      #     puts "Word: #{word[:word]}"
      #     puts "Speaker: #{word[:speaker]}"
      #     puts "Confidence: #{(word[:speaker_confidence] * 100).round(2)}%"
      #     puts "Start: #{word[:start]}, End: #{word[:end]}"
      #   end
      #
      # @example Filtering words by high speaker confidence
      #   high_confidence_words = parser.words_with_speaker_info.select do |word|
      #     word[:speaker_confidence] > 0.9
      #   end
      #
      # @raise [RuntimeError] If the JSON data is malformed or missing required fields
      # @see #speaker_segments For grouping words into speaker-based segments
      # @see #has_speaker_data? For checking if speaker data is available
      # @since 1.0.0 Speaker diarization feature
      def words_with_speaker_info
        words = @json_data.dig("results", "channels", 0, "alternatives", 0, "words")
        return [] unless words

        words.filter_map do |word|
          next unless word["speaker"] && word["speaker_confidence"]

          {
            word: word["word"],
            speaker: word["speaker"],
            speaker_confidence: word["speaker_confidence"],
            start: format_timestamp(word["start"]),
            end: format_timestamp(word["end"]),
            start_raw: word["start"],
            end_raw: word["end"]
          }
        end
      end

      # Groups consecutive words by speaker to create speaker-based segments
      #
      # @param [Float] min_confidence minimum speaker confidence threshold (0.0-1.0)
      # @return [Array<Hash>] array of speaker segment hashes
      # @example Creating speaker segments
      #   segments = parser.speaker_segments(min_confidence: 0.8)
      #   segments.each do |segment|
      #     puts "Speaker #{segment[:speaker_id]}: #{segment[:text]}"
      #     puts "Time: #{segment[:start]} - #{segment[:end]}"
      #     puts "Confidence: #{segment[:confidence]}"
      #   end
      def speaker_segments(min_confidence: 0.8)
        words = words_with_speaker_info
        return [] if words.empty?

        # Filter words by confidence threshold
        filtered_words = words.select { |word| word[:speaker_confidence] >= min_confidence }
        return [] if filtered_words.empty?

        segments = []
        current_segment = nil

        filtered_words.each do |word|
          if current_segment.nil? || current_segment[:speaker_id] != word[:speaker]
            # Finalize previous segment if it exists
            if current_segment
              finalize_segment(current_segment)
              segments << current_segment
            end

            # Start new segment
            current_segment = {
              speaker_id: word[:speaker],
              words: [word],
              confidences: [word[:speaker_confidence]],
              start_raw: word[:start_raw],
              end_raw: word[:end_raw]
            }
          else
            # Continue current segment
            current_segment[:words] << word
            current_segment[:confidences] << word[:speaker_confidence]
            current_segment[:end_raw] = word[:end_raw]
          end
        end

        # Don't forget the last segment
        if current_segment
          finalize_segment(current_segment)
          segments << current_segment
        end

        segments
      end

      # Checks if the JSON response contains valid speaker diarization data.
      #
      # This method verifies the presence of speaker identification information
      # in the Deepgram transcript by examining the words data. It ensures that
      # at least one word has both a speaker ID and confidence score.
      #
      # @return [Boolean] 
      #   * `true` if speaker data is present and valid
      #   * `false` if no speaker information is detected
      #
      # @example Basic usage for checking speaker data
      #   if parser.has_speaker_data?
      #     puts "Speaker diarization is available"
      #     segments = parser.speaker_segments
      #   else
      #     puts "No speaker information in the transcript"
      #   end
      #
      # @example Complex scenario with conditional processing
      #   parser.has_speaker_data? && parser.speaker_segments(min_confidence: 0.9).each do |segment|
      #     puts "High-confidence speaker segment: #{segment[:text]}"
      #   end
      #
      # @note This method does not validate the quality of speaker data,
      #   only its presence. Use `speaker_statistics` to assess data quality.
      #
      # @see #speaker_segments For retrieving speaker-based text segments
      # @see #speaker_statistics For detailed speaker data analysis
      # @since 1.0.0 Speaker diarization feature
      def has_speaker_data?
        words = @json_data.dig("results", "channels", 0, "alternatives", 0, "words")
        return false unless words&.any?

        words.any? { |word| word["speaker"] && word["speaker_confidence"] }
      end

      # Computes comprehensive statistics about speakers in the transcription.
      #
      # This method provides a detailed analysis of speaker information, including
      # the number of speakers, total words with speaker data, and individual
      # speaker performance metrics. It is useful for understanding the complexity
      # and quality of speaker diarization in the transcript.
      #
      # @return [Hash] A comprehensive hash of speaker statistics containing:
      #   - `:speaker_count` [Integer] Total number of unique speakers detected
      #   - `:total_words_with_speaker_data` [Integer] Number of words successfully identified with a speaker
      #   - `:speakers` [Hash] A hash of individual speaker metrics, keyed by speaker ID
      #     * `:word_count` [Integer] Number of words spoken by the speaker
      #     * `:avg_confidence` [Float] Average speaker identification confidence (0.0-1.0)
      #     * `:min_confidence` [Float] Lowest speaker confidence for the speaker
      #     * `:max_confidence` [Float] Highest speaker confidence for the speaker
      #   - `:overall_avg_confidence` [Float] Average confidence across all speaker identifications
      #
      # @example Comprehensive speaker statistics analysis
      #   stats = parser.speaker_statistics
      #   puts "Speaker Analysis Report"
      #   puts "Total Speakers: #{stats[:speaker_count]}"
      #   puts "Words with Speaker Data: #{stats[:total_words_with_speaker_data]}"
      #   puts "Overall Speaker Confidence: #{(stats[:overall_avg_confidence] * 100).round(2)}%"
      #
      #   stats[:speakers].each do |speaker_id, speaker_stats|
      #     puts "\nSpeaker #{speaker_id} Details:"
      #     puts "  Words Spoken: #{speaker_stats[:word_count]}"
      #     puts "  Avg Confidence: #{(speaker_stats[:avg_confidence] * 100).round(2)}%"
      #     puts "  Min Confidence: #{(speaker_stats[:min_confidence] * 100).round(2)}%"
      #     puts "  Max Confidence: #{(speaker_stats[:max_confidence] * 100).round(2)}%"
      #   end
      #
      # @note If no speaker data is available, returns a hash with zero values
      #
      # @example Handling transcripts without speaker data
      #   stats = parser.speaker_statistics
      #   if stats[:speaker_count] == 0
      #     puts "No speaker information available in the transcript"
      #   end
      #
      # @see #words_with_speaker_info For individual word speaker details
      # @see #has_speaker_data? To check if speaker data exists
      # @since 1.0.0 Speaker diarization feature
      def speaker_statistics
        words_with_speakers = words_with_speaker_info
        
        return {
          speaker_count: 0,
          total_words_with_speaker_data: 0,
          speakers: {},
          overall_avg_confidence: 0.0
        } if words_with_speakers.empty?

        speaker_data = {}
        total_confidence = 0.0

        words_with_speakers.each do |word|
          speaker_id = word[:speaker]
          confidence = word[:speaker_confidence]
          
          speaker_data[speaker_id] ||= { word_count: 0, total_confidence: 0.0, confidences: [] }
          speaker_data[speaker_id][:word_count] += 1
          speaker_data[speaker_id][:total_confidence] += confidence
          speaker_data[speaker_id][:confidences] << confidence
          total_confidence += confidence
        end

        # Calculate averages and additional stats for each speaker
        speakers_stats = speaker_data.transform_values do |data|
          confidences = data[:confidences]
          {
            word_count: data[:word_count],
            avg_confidence: (data[:total_confidence] / data[:word_count]).round(3),
            min_confidence: confidences.min.round(3),
            max_confidence: confidences.max.round(3)
          }
        end

        {
          speaker_count: speaker_data.keys.size,
          total_words_with_speaker_data: words_with_speakers.size,
          speakers: speakers_stats,
          overall_avg_confidence: (total_confidence / words_with_speakers.size).round(3)
        }
      end

      # Provides summary statistics about the parsed transcription
      #
      # @return [Hash] hash containing various counts and metrics about the transcription
      # @example Getting summary statistics
      #   stats = parser.summary_stats
      #   puts "Total words: #{stats[:total_words]}"
      #   puts "Total sentences: #{stats[:total_sentences]}"
      def summary_stats
        base_stats = {
          total_words: words_with_confidence.count,
          total_sentences: segmented_sentences.count,
          total_paragraphs: @paragraphs.count,
          total_topics: @topics.count,
          total_intents: @intents.count,
          transcript_length: @transcript&.length || 0
        }

        # Add speaker statistics if available
        if has_speaker_data?
          speaker_stats = speaker_statistics
          base_stats.merge!(
            speaker_count: speaker_stats[:speaker_count],
            words_with_speaker_data: speaker_stats[:total_words_with_speaker_data]
          )
        end

        base_stats
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

      # Finalizes a speaker segment by calculating derived fields
      #
      # @param [Hash] segment the segment hash to finalize
      # @return [Hash] the finalized segment with text, timestamps, confidence, and word count
      def finalize_segment(segment)
        words_text = segment[:words].map { |word| word[:word] }
        avg_confidence = segment[:confidences].sum / segment[:confidences].size.to_f

        segment.merge!(
          text: words_text.join(" "),
          start: format_timestamp(segment[:start_raw]),
          end: format_timestamp(segment[:end_raw]),
          confidence: avg_confidence.round(3),
          word_count: words_text.size
        )
        
        # Remove temporary arrays to keep the result clean
        segment.delete(:words)
        segment.delete(:confidences)
        segment.delete(:start_raw)
        segment.delete(:end_raw)
        
        segment
      end
    end
  end
end