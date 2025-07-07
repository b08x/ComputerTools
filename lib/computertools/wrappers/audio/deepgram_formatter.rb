# frozen_string_literal: true

module ComputerTools
  module Wrappers
    module Audio
      class DeepgramFormatter
      def initialize(parser)
        @parser = parser
      end

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

          🏷️  Topics Identified: #{stats[:total_topics]}
          #{@parser.topics.map { |t| "   • #{t[:topic]}" }.join("\n")}

          🎯 Intents Detected: #{stats[:total_intents]}
          #{@parser.intents.map { |i| "   • #{i[:intent]}" }.join("\n")}

          ⏱️  Duration: #{calculate_duration}
        SUMMARY
      end

      private

      def format_timestamp_for_srt(timestamp_str)
        # Convert HH:MM:SS to HH:MM:SS,000 format for SRT
        return "00:00:00,000" unless timestamp_str

        parts = timestamp_str.split(':')
        return "00:00:00,000" unless parts.length == 3

        "#{parts[0]}:#{parts[1]}:#{parts[2]},000"
      end

      def calculate_duration
        return "Unknown" if @parser.paragraphs.empty?

        last_paragraph = @parser.paragraphs.last
        last_paragraph[:end] || "Unknown"
      end
    end
    end
  end
end