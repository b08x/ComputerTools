# frozen_string_literal: true

module ComputerTools
  module Generators
    # Generates a comprehensive, professional summary from a conversation transcript.
    #
    # This generator is designed to take a raw transcript, along with optional
    # structured data like identified topics and intents (e.g., from Deepgram's
    # analysis features), and produce a well-structured summary. The summary
    # covers main themes, key points, action items, and the overall tone of the
    # conversation.
    #
    # @example Generating a basic summary
    #   transcript_text = "Alice: Let's discuss the Q3 budget. Bob: I've prepared the initial draft."
    #   generator = ComputerTools::Generators::DeepgramSummaryGenerator.new(transcript: transcript_text)
    #   summary = generator.generate
    #   # => "The conversation is about the Q3 budget. Bob has prepared a draft..."
    #
    # @example Generating a summary with topics and intents
    #   transcript_text = "..."
    #   topics = [{ topic: "Budget Planning" }, { topic: "Q3 Goals" }]
    #   intents = [{ intent: "propose_idea", start: 5.2, end: 8.1 }]
    #   generator = ComputerTools::Generators::DeepgramSummaryGenerator.new(
    #     transcript: transcript_text,
    #     topics: topics,
    #     intents: intents
    #   )
    #   summary = generator.generate
    #   # => "The conversation covers Budget Planning and Q3 Goals..."
    class DeepgramSummaryGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
                         name:        "summary",
                         description: "A comprehensive summary of the transcript content"

      # Initializes a new DeepgramSummaryGenerator instance.
      #
      # @param transcript [String] The full text of the conversation transcript to be summarized.
      # @param topics [Array<Hash>] An optional array of identified topics. Each hash
      #   should have a `:topic` key (e.g., `[{ topic: 'Project Alpha' }]`).
      # @param intents [Array<Hash>] An optional array of detected intents. Each hash
      #   should have `:intent`, `:start`, and `:end` keys (e.g.,
      #   `[{ intent: 'ask_question', start: 10.5, end: 12.3 }]`).
      def initialize(transcript:, topics: [], intents: [])
        @transcript = transcript
        @topics = topics
        @intents = intents
      end

      # Executes the summary generation process.
      #
      # This method constructs a prompt using the provided transcript, topics, and
      # intents, then sends it to the configured LLM. It returns the resulting
      # summary as a single string.
      #
      # @return [String] The generated comprehensive summary of the transcript.
      def generate
        super
      end

      # @!method prompt
      #   Constructs the prompt sent to the LLM for generating the summary.
      #   @private
      #   @return [String] The formatted prompt including the transcript, topics, and intents.
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

      # @!method topics_section
      #   Formats the list of identified topics for inclusion in the prompt.
      #   @private
      #   @return [String] A formatted string of topics or an empty string if none are provided.
      def topics_section
        return "" if @topics.empty?

        topics_list = @topics.map { |t| "- #{t[:topic]}" }.join("\n")
        "\nIdentified Topics:\n#{topics_list}\n"
      end

      # @!method intents_section
      #   Formats the list of detected intents for inclusion in the prompt.
      #   @private
      #   @return [String] A formatted string of intents or an empty string if none are provided.
      def intents_section
        return "" if @intents.empty?

        intents_list = @intents.map { |i| "- #{i[:intent]} (#{i[:start]} - #{i[:end]})" }.join("\n")
        "\nDetected Intents:\n#{intents_list}\n"
      end
    end
  end
end