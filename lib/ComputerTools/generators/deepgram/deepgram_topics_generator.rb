# frozen_string_literal: true

module ComputerTools
  module Generators
    ##
    # Uses a Large Language Model (LLM) to perform enhanced topic extraction from a
    # provided transcript.
    #
    # This generator analyzes a transcript to identify a comprehensive list of topics,
    # including primary subjects, subtopics, and technical or business-related themes.
    # It can also incorporate a list of pre-existing topics to provide more context
    # to the model, improving the quality and relevance of the generated topics.
    #
    # The output is configured to be a simple list of topic strings.
    #
    # @example Generating topics from a transcript
    #   transcript_text = "This meeting covers our Q3 marketing strategy and the new CI/CD pipeline."
    #   generator = ComputerTools::Generators::DeepgramTopicsGenerator.new(transcript: transcript_text)
    #   topics = generator.generate
    #   # => ["Q3 Marketing Strategy", "CI/CD Pipeline Implementation"]
    #
    # @example Providing existing topics for context
    #   transcript_text = "Let's discuss the deployment issues we saw yesterday."
    #   existing = [{ topic: "Software Deployment" }]
    #   generator = ComputerTools::Generators::DeepgramTopicsGenerator.new(
    #     transcript: transcript_text,
    #     existing_topics: existing
    #   )
    #   topics = generator.generate
    #   # => ["Deployment Issue Analysis", "Software Deployment"]
    #
    class DeepgramTopicsGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :list_of_strings,
                         name:        "topics",
                         description: "Enhanced topic extraction and categorization"

      ##
      # Initializes a new DeepgramTopicsGenerator instance.
      #
      # @param transcript [String] The full text transcript to be analyzed for topics.
      # @param existing_topics [Array<Hash>] An optional array of topics that have
      #   already been identified (e.g., by Deepgram's base topic detection). Each hash
      #   is expected to have a `:topic` key. This provides context to the LLM.
      def initialize(transcript:, existing_topics: [])
        @transcript = transcript
        @existing_topics = existing_topics
      end

      ##
      # Executes the topic generation process.
      #
      # This method calls the parent class's `generate` method, which orchestrates
      # the interaction with the LLM using the prompt defined in this class.
      #
      # @return [Array<String>] An array of generated topic strings, based on the
      #   `llm_output_adapter` configuration.
      def generate
        super
      end

      ##
      # @private
      # Constructs the prompt for the LLM to generate topics.
      #
      # The prompt includes the transcript, any existing topics, and detailed
      # instructions on how to identify, categorize, and format the topics.
      #
      # @return [String] The complete prompt string sent to the LLM.
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

      ##
      # @private
      # Formats the list of existing topics into a string for the prompt.
      #
      # If no existing topics are provided, it returns an empty string.
      #
      # @return [String] A formatted string of existing topics or an empty string.
      def existing_topics_section
        return "" if @existing_topics.empty?

        topics_list = @existing_topics.map { |t| "- #{t[:topic]}" }.join("\n")
        "\nExisting Topics Detected by Deepgram:\n#{topics_list}\n"
      end
    end
  end
end