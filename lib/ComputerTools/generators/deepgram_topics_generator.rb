# frozen_string_literal: true

module ComputerTools
  module Generators
    class DeepgramTopicsGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :list_of_strings,
                         name:        "topics",
                         description: "Enhanced topic extraction and categorization"

      def initialize(transcript:, existing_topics: [])
        @transcript = transcript
        @existing_topics = existing_topics
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Analyze this transcript and extract comprehensive topic information.

          Transcript:
          #{@transcript}

          #{existing_topics_section}

          Please identify and categorize topics with the following approach:

          ## Topic Extraction Goals:
          1. **Primary Topics**: Main subjects of discussion
          2. **Subtopics**: Detailed aspects within primary topics
          3. **Technical Topics**: Technical concepts, tools, or processes mentioned
          4. **Business Topics**: Business-related discussions, decisions, strategies
          5. **Contextual Topics**: Environmental or situational topics
          6. **Emerging Topics**: New or unexpected subjects that arise

          ## Topic Categories:
          - Business & Strategy
          - Technical & Engineering
          - Process & Operations
          - Communication & Collaboration
          - Problem Solving & Issues
          - Planning & Decision Making
          - Education & Knowledge Transfer
          - Innovation & Ideas

          ## Instructions:
          - Provide specific, actionable topic names
          - Avoid overly generic terms
          - Include technical terminology where appropriate
          - Consider both explicit and implicit topics
          - Maintain consistent naming conventions
          - Order by relevance and importance

          Return a list of enhanced topics that provide better insight than basic keyword extraction.
          Each topic should be clear, specific, and valuable for categorization and search.
        PROMPT
      end

      private

      def existing_topics_section
        return "" if @existing_topics.empty?

        topics_list = @existing_topics.map { |t| "- #{t[:topic]}" }.join("\n")
        "\nExisting Topics Detected by Deepgram:\n#{topics_list}\n"
      end
    end
  end
end
