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
    class DeepgramTopicsGenerator < ComputerTools::Generators::BaseGenerator

      ##
      # Initializes a new DeepgramTopicsGenerator instance.
      #
      # @param transcript [String] The full text transcript to be analyzed for topics.
      # @param existing_topics [Array<Hash>] An optional array of topics that have
      #   already been identified (e.g., by Deepgram's base topic detection). Each hash
      #   is expected to have a `:topic` key. This provides context to the LLM.
      def initialize(transcript:, existing_topics: [])
        super()
        @transcript = transcript
        @existing_topics = existing_topics
      end

      ##
      # Executes the topic generation process using ruby_llm-schema.
      #
      # This method constructs a detailed prompt and uses schema validation
      # to ensure the response contains a proper array of topic strings.
      #
      # @return [Array<String>] An array of generated topic strings.
      def call
        with_generation_handling("deepgram topic extraction") do
          schema = ComputerTools::Schemas::DeepgramTopicsResponse.new
          schema_json = schema.to_json_schema
          full_prompt = build_structured_prompt(schema_json)
          
          response_content = generate_llm_content(
            full_prompt,
            system_prompt: build_system_prompt(
              task_description: "comprehensive topic extraction and categorization from conversation transcripts",
              output_format: "structured JSON array matching the provided schema",
              additional_instructions: "Focus on specific, actionable topics that provide insight beyond basic keyword extraction"
            ),
            temperature: 0.2,  # Lower temperature for more consistent topic extraction
            max_tokens: 1000
          )
          
          # Parse and validate the response
          begin
            parsed_response = JSON.parse(response_content)
            parsed_response["topics"] || []
          rescue JSON::ParserError => e
            log(:warn, "JSON parsing failed, returning fallback topics", { error: e.message })
            # Fallback to raw content extraction
            extract_fallback_topics(response_content)
          end
        end
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

      # Extracts fallback topics when schema validation fails.
      #
      # @param content [String] The raw LLM response
      # @return [Array<String>] The extracted topics or empty array
      def extract_fallback_topics(content)
        # Try to extract JSON and get the topics array
        begin
          parsed = JSON.parse(content)
          return parsed["topics"] if parsed["topics"].is_a?(Array)
        rescue JSON::ParserError
          # Fall through to text parsing
        end
        
        # Try to extract topics from text using patterns
        topics = []
        content.scan(/^[-*]\s*(.+)$/m) do |match|
          topic = match[0].strip
          topics << topic unless topic.empty?
        end
        
        # If no patterns found, try line-by-line extraction
        if topics.empty?
          content.split("\n").each do |line|
            cleaned = line.strip.gsub(/^[-*•]\s*/, "")
            topics << cleaned unless cleaned.empty? || cleaned.length < 3
          end
        end
        
        topics.uniq.first(20) # Limit to 20 topics max
      end

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