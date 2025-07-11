# frozen_string_literal: true

module ComputerTools
  module Generators
    #
    # Generates strategic insights and actionable intelligence from a conversation transcript.
    #
    # This generator analyzes a transcript, along with optional topics, intents, and
    # contextual information, to produce a detailed report. The report covers
    # strategic analysis, behavioral insights, actionable recommendations, and
    # content intelligence, making it useful for business reviews, team performance
    # analysis, and decision-making processes.
    #
    # @example Generating insights from a transcript
    #   transcript_text = "Alice: Let's discuss the Q3 project plan. Bob: I think we should prioritize the new feature."
    #   topics = [{ topic: "Project Planning" }, { topic: "Feature Prioritization" }]
    #   context = "This is a weekly sync meeting for the engineering team."
    #
    #   generator = ComputerTools::Generators::DeepgramInsightsGenerator.new(
    #     transcript: transcript_text,
    #     topics: topics,
    #     context: context
    #   )
    #
    #   insights = generator.generate
    #   # insights will be a string containing a detailed analysis report.
    #   puts insights
    #
    class DeepgramInsightsGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
                         name:        "insights",
                         description: "Strategic insights and analysis derived from the transcript"

      #
      # Initializes a new DeepgramInsightsGenerator instance.
      #
      # @param transcript [String] The conversation transcript to be analyzed.
      # @param topics [Array<Hash>] An optional array of identified topics to include in the analysis prompt.
      #   Each hash should have a `:topic` key (e.g., `[{ topic: "Project Planning" }]`).
      # @param intents [Array<Hash>] An optional array of detected intents to include in the prompt.
      #   Each hash should have `:intent`, `:start`, and `:end` keys
      #   (e.g., `[{ intent: "question", start: 10.5, end: 12.0 }]`).
      # @param context [String, nil] Optional additional context as a string to guide the analysis more accurately.
      #
      def initialize(transcript:, topics: [], intents: [], context: nil)
        @transcript = transcript
        @topics = topics
        @intents = intents
        @context = context
      end

      #
      # Executes the insight generation process.
      #
      # This method constructs a detailed prompt using the provided transcript and
      # metadata, then calls the underlying LLM to generate the insights.
      # The output is a single string formatted as a structured report, as defined
      # by the `llm_output_adapter`.
      #
      # @return [String] A string containing the generated strategic insights and analysis.
      #
      def generate
        super
      end

      #
      # Constructs the prompt for the Large Language Model.
      #
      # This method assembles the transcript, identified topics, detected intents,
      # and any additional context into a single, structured prompt. The prompt
      # guides the LLM to perform a multi-faceted analysis covering strategic,
      # behavioral, and content-related aspects of the conversation.
      #
      # @private
      # @return [String] The complete prompt string sent to the LLM.
      #
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

      # @private
      def topics_section
        return "" if @topics.empty?

        topics_list = @topics.map { |t| "- #{t[:topic]}" }.join("\n")
        "\nIdentified Topics:\n#{topics_list}\n"
      end

      # @private
      def intents_section
        return "" if @intents.empty?

        intents_list = @intents.map { |i| "- #{i[:intent]} (#{i[:start]} - #{i[:end]})" }.join("\n")
        "\nDetected Intents:\n#{intents_list}\n"
      end

      # @private
      def context_section
        return "" unless @context

        "\nAdditional Context:\n#{@context}\n"
      end
    end
  end
end