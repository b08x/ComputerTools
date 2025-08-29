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
      # Converts the parsed transcription data into SRT (SubRip) subtitle format.
      #
      # This advanced method generates standard SRT subtitle files with flexible speaker
      # diarization support. It can produce SRT entries in two primary modes:
      # 1. Standard paragraph-based mode
      # 2. Speaker-aware mode with detailed speaker labeling
      #
      # When speaker diarization is enabled and valid speaker data exists, the method
      # creates subtitle entries that distinguish between different speakers, enhancing
      # the readability and comprehension of multi-speaker transcripts.
      #
      # @param speaker_options [Hash, nil] Optional configuration for speaker-aware SRT generation
      # @option speaker_options [Boolean] :enable (false) Flag to enable speaker-aware processing
      # @option speaker_options [Float] :confidence_threshold (0.8) Minimum confidence for speaker identification
      #   * Range: 0.0 to 1.0
      #   * Higher values mean stricter speaker detection
      # @option speaker_options [String] :label_format ("[Speaker %d]: ") Template for generating speaker labels
      #   * Must include a '%d' placeholder
      #   * Examples: "[Speaker %d]: ", "S%d: ", "Person %d: "
      # @option speaker_options [Boolean] :merge_consecutive_segments (true) Combines multiple
      #   consecutive segments from the same speaker into a single subtitle entry
      # @option speaker_options [Float] :min_segment_duration (1.0) Minimum duration (in seconds)
      #   for a segment to be considered a valid subtitle entry
      # @option speaker_options [Integer] :max_speakers (10) Maximum number of unique speakers to label
      #   * Limits processing to prevent overwhelming subtitle displays
      #   * Remaining speakers will be omitted
      #
      # @return [String] Fully formatted SRT subtitle content
      #
      # @example Basic SRT generation
      #   # Generates standard paragraph-based SRT without speaker labels
      #   srt_content = formatter.to_srt
      #   File.write('subtitles.srt', srt_content)
      #
      # @example Advanced speaker-aware SRT generation
      #   # Creates SRT with detailed speaker identification
      #   options = {
      #     enable: true,
      #     confidence_threshold: 0.9,  # Very high confidence
      #     label_format: "[Speaker %d]: ",
      #     merge_consecutive_segments: true,
      #     min_segment_duration: 0.5,  # Allow shorter segments
      #     max_speakers: 5  # Limit to 5 speakers
      #   }
      #   srt_content = formatter.to_srt(speaker_options: options)
      #   File.write('subtitles_with_speakers.srt', srt_content)
      #
      # @note If no valid speaker data is found, falls back to paragraph-based SRT
      #
      # @raise [StandardError] If SRT generation encounters unexpected processing errors
      # @see #build_srt_from_paragraphs Default paragraph-based SRT generation
      # @see #build_srt_with_speakers Speaker-specific SRT generation method
      # @since 1.0.0 Enhanced speaker diarization support
      def to_srt(speaker_options: nil)
        if speaker_enabled?(speaker_options)
          build_srt_with_speakers(speaker_options)
        else
          build_srt_from_paragraphs
        end
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
      # Builds SRT content from paragraph data (original implementation).
      #
      # @return [String] The formatted SRT content without speaker labels
      # @private
      def build_srt_from_paragraphs
        output = []
        @parser.paragraphs.each_with_index do |p, index|
          output << (index + 1).to_s
          output << "#{format_timestamp_for_srt(p[:start])} --> #{format_timestamp_for_srt(p[:end])}"
          output << p[:text]
          output << ""
        end
        output.join("\n").strip
      end

      ##
      # Builds SRT content with speaker labels from speaker segments.
      #
      # @param options [Hash] Speaker configuration options
      # @return [String] The formatted SRT content with speaker labels
      # @private
      def build_srt_with_speakers(options)
        # Get speaker segments with confidence threshold
        confidence_threshold = options.fetch(:confidence_threshold, 0.8)
        segments = @parser.speaker_segments(min_confidence: confidence_threshold)
        
        # If no speaker segments available, fall back to paragraphs
        return build_srt_from_paragraphs if segments.empty?

        # Apply additional filtering and processing
        segments = filter_short_segments(segments, options.fetch(:min_segment_duration, 1.0))
        segments = merge_consecutive_speaker_segments(segments) if options.fetch(:merge_consecutive_segments, true)
        segments = limit_speakers(segments, options.fetch(:max_speakers, 10))
        
        # Build SRT entries
        output = []
        label_format = options.fetch(:label_format, "[Speaker %d]: ")
        
        segments.each_with_index do |segment, index|
          output << (index + 1).to_s
          output << "#{format_timestamp_for_srt_raw(segment[:start_raw])} --> #{format_timestamp_for_srt_raw(segment[:end_raw])}"
          
          speaker_label = format_speaker_label(segment[:speaker_id], label_format)
          output << "#{speaker_label}#{segment[:text]}"
          output << ""
        end
        
        output.join("\n").strip
      rescue StandardError => e
        # If speaker processing fails, gracefully fall back to paragraph-based SRT
        build_srt_from_paragraphs
      end

      ##
      # Checks if speaker diarization should be enabled for SRT generation.
      #
      # @param options [Hash, nil] Speaker configuration options
      # @return [Boolean] true if speaker processing should be used
      # @private
      def speaker_enabled?(options)
        return false unless options.is_a?(Hash)
        return false unless options[:enable]
        return false unless @parser.respond_to?(:has_speaker_data?)
        
        @parser.has_speaker_data?
      end

      ##
      # Formats a speaker label according to the specified format.
      #
      # @param speaker_id [Integer] The speaker identifier
      # @param format_string [String] The format string with %d placeholder
      # @return [String] The formatted speaker label
      # @private
      def format_speaker_label(speaker_id, format_string)
        # Check if the format string contains a valid placeholder
        unless format_string.include?('%d') || format_string.include?('%s')
          return "[Speaker #{speaker_id}]: "
        end
        
        format_string % speaker_id
      rescue ArgumentError
        # If format string is invalid, use a safe default
        "[Speaker #{speaker_id}]: "
      end

      ##
      # Merges consecutive segments from the same speaker into more coherent subtitle entries.
      #
      # This method is designed to reduce fragmentation in speaker-based subtitle generation.
      # It combines multiple short segments from the same speaker into a single, more
      # readable segment, which helps create more natural subtitle presentations.
      #
      # @param segments [Array<Hash>] Input array of speaker segments with individual words
      #   Each segment is expected to have keys like `:speaker_id`, `:words`, `:confidences`
      #
      # @return [Array<Hash>] An array of merged segments with the following transformations:
      #   - Consecutive segments from the same speaker are combined
      #   - Text is merged into a single continuous string
      #   - Start and end times are adjusted to span the entire merged segment
      #   - Confidence scores are recalculated to represent the merged segment
      #
      # @example How merging works
      #   # Input: Two short segments from Speaker 1
      #   # Output: A single, longer segment representing the continuous speech
      #
      # @note This method helps prevent rapid speaker label changes in subtitles
      #   by combining closely related speech segments
      #
      # @see #filter_short_segments For removing very brief segments before merging
      # @since 1.0.0 Speaker segment processing enhancement
      # @private
      def merge_consecutive_speaker_segments(segments)
        return segments if segments.length <= 1
        
        merged = []
        current_segment = segments.first.dup
        
        segments[1..-1].each do |segment|
          if current_segment[:speaker_id] == segment[:speaker_id]
            # Merge with current segment
            current_segment[:words] += segment[:words]
            current_segment[:confidences] += segment[:confidences]
            current_segment[:end_raw] = segment[:end_raw]
            current_segment[:text] = current_segment[:words].map { |w| w[:word] }.join(' ')
            current_segment[:avg_confidence] = current_segment[:confidences].sum / current_segment[:confidences].length.to_f
          else
            # Finalize current segment and start new one
            merged << current_segment
            current_segment = segment.dup
          end
        end
        
        merged << current_segment
        merged
      end

      ##
      # Filters out segments that are shorter than the minimum duration.
      #
      # @param segments [Array<Hash>] Array of speaker segments
      # @param min_duration [Float] Minimum duration in seconds
      # @return [Array<Hash>] Array of filtered segments
      # @private
      def filter_short_segments(segments, min_duration)
        segments.select do |segment|
          duration = segment[:end_raw] - segment[:start_raw]
          duration >= min_duration
        end
      end

      ##
      # Limits the number of different speakers handled.
      #
      # @param segments [Array<Hash>] Array of speaker segments
      # @param max_speakers [Integer] Maximum number of speakers to handle
      # @return [Array<Hash>] Array of segments with limited speakers
      # @private
      def limit_speakers(segments, max_speakers)
        return segments if max_speakers <= 0
        
        # Count occurrences of each speaker
        speaker_counts = segments.each_with_object(Hash.new(0)) do |segment, counts|
          counts[segment[:speaker_id]] += 1
        end
        
        # Get the most frequent speakers
        top_speakers = speaker_counts.sort_by { |_, count| -count }
                                     .first(max_speakers)
                                     .map { |speaker_id, _| speaker_id }
                                     .to_set
        
        # Filter segments to only include top speakers
        segments.select { |segment| top_speakers.include?(segment[:speaker_id]) }
      end

      ##
      # Formats a raw timestamp (in seconds) for SRT format.
      #
      # Converts floating point seconds to HH:MM:SS,mmm format required by SRT files.
      #
      # @param timestamp_seconds [Float] The timestamp in seconds
      # @return [String] The formatted timestamp string in HH:MM:SS,mmm format
      # @private
      def format_timestamp_for_srt_raw(timestamp_seconds)
        return "00:00:00,000" unless timestamp_seconds
        
        total_seconds = timestamp_seconds.to_f
        hours = (total_seconds / 3600).to_i
        minutes = ((total_seconds % 3600) / 60).to_i
        seconds = (total_seconds % 60).to_i
        milliseconds = ((total_seconds % 1) * 1000).to_i
        
        format("%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
      end

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