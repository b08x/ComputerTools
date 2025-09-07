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
    class DeepgramSummaryGenerator < ComputerTools::Generators::BaseGenerator

      # Initializes a new DeepgramSummaryGenerator instance.
      #
      # @param transcript [String] The full text of the conversation transcript to be summarized.
      # @param topics [Array<Hash>] An optional array of identified topics. Each hash
      #   should have a `:topic` key (e.g., `[{ topic: 'Project Alpha' }]`).
      # @param intents [Array<Hash>] An optional array of detected intents. Each hash
      #   should have `:intent`, `:start`, and `:end` keys (e.g.,
      #   `[{ intent: 'ask_question', start: 10.5, end: 12.3 }]`).
      def initialize(transcript:, topics: [], intents: [])
        super()
        @transcript = transcript
        @topics = topics
        @intents = intents
      end

      # Executes the summary generation process using ruby_llm-schema.
      #
      # This method constructs a detailed prompt and uses schema validation
      # to ensure the response contains a properly formatted summary.
      #
      # @return [String] The generated comprehensive summary of the transcript.
      def call
        with_generation_handling("deepgram summary generation") do
          schema = ComputerTools::Schemas::DeepgramSummaryResponse.new
          schema_json = schema.to_json_schema
          full_prompt = build_structured_prompt(schema_json)
          
          response_content = generate_llm_content(
            full_prompt,
            system_prompt: build_system_prompt(
              task_description: "comprehensive conversation transcript summarization",
              output_format: "structured JSON matching the provided schema",
              additional_instructions: "Create professional summaries suitable for executive briefings and documentation"
            ),
            temperature: 0.3,
            max_tokens: 1500
          )
          
          # Parse and validate the response
          begin
            parsed_response = JSON.parse(response_content)
            parsed_response["summary"] || response_content
          rescue JSON::ParserError => e
            log(:warn, "JSON parsing failed, returning raw content", { error: e.message })
            # Fallback to raw content extraction
            extract_fallback_content(response_content, "summary")
          end
        end
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

      # Builds a structured prompt that includes the schema instructions.
      #
      # @param schema_json [Hash] The JSON schema from ruby_llm-schema
      # @return [String] The complete structured prompt
      def build_structured_prompt(schema_json)
        schema_text = JSON.pretty_generate(schema_json[:schema])
        
        <<~PROMPT
          #{prompt}

          IMPORTANT: Your response must be a valid JSON object that matches this exact schema:

          #{schema_text}

          Respond ONLY with valid JSON. Do not include any explanatory text outside the JSON structure.
        PROMPT
      end

      # Extracts fallback content when schema validation fails.
      #
      # @param content [String] The raw LLM response
      # @param field_name [String] The field name to extract
      # @return [String] The extracted content or the full content
      def extract_fallback_content(content, field_name)
        # Try to extract JSON and get the field
        begin
          parsed = JSON.parse(content)
          return parsed[field_name] if parsed[field_name]
        rescue JSON::ParserError
          # Fall through to return raw content
        end
        
        # Return the content as-is if we can't parse it
        content
      end

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