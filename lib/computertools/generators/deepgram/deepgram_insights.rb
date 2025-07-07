# frozen_string_literal: true

module ComputerTools
  module Generators
    module Deepgram
      class DeepgramInsights < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
                         name:        "insights",
                         description: "Strategic insights and analysis derived from the transcript"

      def initialize(transcript:, topics: [], intents: [], context: nil)
        @transcript = transcript
        @topics = topics
        @intents = intents
        @context = context
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Analyze this transcript to extract strategic insights and actionable intelligence.

          Transcript:
          #{@transcript}

          #{topics_section}
          #{intents_section}
          #{context_section}

          Please provide insights that include:

          ## Strategic Analysis
          - Key business or technical patterns
          - Decision-making processes observed
          - Communication effectiveness
          - Knowledge gaps or opportunities

          ## Behavioral Insights
          - Speaking patterns and engagement levels
          - Collaboration dynamics
          - Problem-solving approaches
          - Emotional undertones

          ## Actionable Recommendations
          - Immediate action items
          - Process improvements
          - Follow-up suggestions
          - Risk mitigation strategies

          ## Content Intelligence
          - Information hierarchy and importance
          - Missing information or perspectives
          - Technical vs. non-technical content balance
          - Audience appropriateness

          Focus on providing valuable insights that go beyond surface-level content analysis.
          Consider both explicit information and implicit patterns in the conversation.
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

      def context_section
        return "" unless @context

        "\nAdditional Context:\n#{@context}\n"
      end
    end
    end
  end
end