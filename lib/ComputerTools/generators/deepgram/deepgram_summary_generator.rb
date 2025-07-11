# frozen_string_literal: true

module ComputerTools
  module Generators
    class DeepgramSummaryGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
                         name:        "summary",
                         description: "A comprehensive summary of the transcript content"

      def initialize(transcript:, topics: [], intents: [])
        @transcript = transcript
        @topics = topics
        @intents = intents
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Analyze this transcript and generate a comprehensive summary.

          Transcript:
          #{@transcript}

          #{topics_section}
          #{intents_section}

          Please provide a summary that includes:
          1. Main topics and themes discussed
          2. Key points and takeaways
          3. Important decisions or action items mentioned
          4. Overall tone and context of the conversation
          5. Any notable patterns or insights

          The summary should be well-structured and professional, suitable for:
          - Executive briefings
          - Meeting minutes
          - Content analysis reports
          - Documentation purposes

          Focus on extracting the most valuable and actionable information from the transcript.
        PROMPT
      end

      private

      def topics_section
        return "" if @topics.empty?

        topics_list = @topics.map { |t| "- #{t[:topic]}" }.join("\n")
        "\nIdentified Topics:\n#{topics_list}\n"
      end

      def intents_section
        return "" if @intents.empty?

        intents_list = @intents.map { |i| "- #{i[:intent]} (#{i[:start]} - #{i[:end]})" }.join("\n")
        "\nDetected Intents:\n#{intents_list}\n"
      end
    end
  end
end
