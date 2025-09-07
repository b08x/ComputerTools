# frozen_string_literal: true

module ComputerTools
  module Generators
    ##
    # Base class for all ComputerTools generators using ruby_llm.
    #
    # This class provides a foundation for creating generators that use
    # language models to produce structured output. It offers common
    # functionality such as configuration management, schema validation
    # using ruby_llm-schema, error handling, and standardized interfaces
    # for content generation.
    #
    # Generators inheriting from this class should implement the `call` method
    # to define their specific generation logic.
    #
    # @example Creating a custom generator
    #   class MyCustomGenerator < ComputerTools::Generators::BaseGenerator
    #     def initialize(data:, config:, format: :text)
    #       super()
    #       @data = data
    #       @config = config
    #       @format = format
    #     end
    #
    #     def call
    #       with_generation_handling("custom content generation") do
    #         generate_custom_content
    #       end
    #     end
    #
    #     private
    #
    #     def generate_custom_content
    #       # Implementation logic here
    #       prompt = build_prompt(@data)
    #       response = generate_llm_content(prompt)
    #       format_output(response)
    #     end
    #   end
    #
    class BaseGenerator
      ##
      # Initializes a new BaseGenerator instance.
      #
      # Sets up basic configuration, logging, and LLM client for the generator.
      # Subclasses should call super() and then initialize their own
      # instance variables as needed.
      #
      def initialize
        @logger = ComputerTools.logger
        @llm_client = initialize_llm_client
      end

      ##
      # Main execution method for the generator.
      #
      # This method should be overridden by subclasses to implement
      # the specific logic for content generation. The base implementation
      # raises a NotImplementedError.
      #
      # @return [Object] The result of the generation process
      # @raise [NotImplementedError] When not implemented by subclass
      #
      def call
        raise NotImplementedError, "#{self.class} must implement the `call` method"
      end

      protected

      ##
      # Initializes the ruby_llm client with default configuration.
      #
      # This method sets up a basic ruby_llm client optimized for
      # content generation tasks.
      #
      # @return [RubyLLM] Configured LLM client
      #
      def initialize_llm_client
        # Configuration is already loaded by ComputerTools::Config.load
        # Create a RubyLLM::Chat instance 
        model = ENV['RUBY_LLM_MODEL'] || "anthropic/claude-3.5-sonnet"
        RubyLLM.chat(model: model)
      end

      ##
      # Logs a message with the specified level.
      #
      # Provides a convenient interface for logging within generators.
      #
      # @param level [Symbol] The log level (:debug, :info, :warn, :error)
      # @param message [String] The message to log
      # @param data [Hash] Optional additional data to include in the log
      #
      def log(level, message, data = {})
        @logger&.send(level, message, data)
      end

      ##
      # Executes a block with error handling specific to generation operations.
      #
      # This method provides standardized error handling for generator operations,
      # including logging of errors and fallback behavior for generation failures.
      #
      # @param operation [String] Description of the generation operation
      # @param fallback_result [Object] Value to return if generation fails
      # @yield The block to execute with error handling
      # @return [Object] The result of the block or fallback_result on error
      #
      def with_generation_handling(operation, fallback_result = nil)
        log(:info, "Starting #{operation}")
        
        result = yield
        
        log(:info, "Completed #{operation}")
        result
      rescue StandardError => e
        log(:error, "Error during #{operation}: #{e.message}", {
          error_class: e.class.name,
          backtrace: e.backtrace&.first(5)
        })
        
        handle_generation_error(e, operation, fallback_result)
      end

      ##
      # Handles errors that occur during generation.
      #
      # This method can be overridden by subclasses to provide specific
      # error handling behavior for their generation processes.
      #
      # @param error [StandardError] The error that occurred
      # @param operation [String] Description of the failed operation
      # @param fallback_result [Object] Default fallback result
      # @return [Object] The fallback result or alternative handling
      #
      def handle_generation_error(error, operation, fallback_result)
        puts "❌ Error during #{operation}: #{error.message}".colorize(:red)
        
        case error
        when Timeout::Error
          puts "   Generation timed out. Try reducing the complexity or breaking into smaller parts.".colorize(:yellow)
        when JSON::ParserError
          puts "   Invalid response format. Retrying with simpler structure may help.".colorize(:yellow)
        when StandardError
          puts "   Unexpected error occurred. Check your configuration and try again.".colorize(:yellow)
        end
        
        fallback_result
      end

      ##
      # Generates content using the LLM client.
      #
      # This method provides a standardized interface for content generation
      # with proper error handling and response processing.
      #
      # @param prompt [String] The prompt for content generation
      # @param system_prompt [String] Optional system prompt
      # @param options [Hash] Additional options for the LLM request
      # @return [String, nil] The generated content or nil on error
      #
      def generate_llm_content(prompt, system_prompt: nil, **options)        
        with_generation_handling("LLM content generation") do
          # Create a fresh chat instance for each generation
          model = ENV['RUBY_LLM_MODEL'] || "anthropic/claude-3.5-sonnet"
          chat = RubyLLM.chat(model: model)
          
          # Apply temperature if specified
          temperature = options[:temperature] || 0.3
          chat = chat.with_temperature(temperature)
          
          # Add system instructions if provided
          if system_prompt
            chat = chat.with_instructions(system_prompt)
          end
          
          # Make the request and get response
          response = chat.ask(prompt)
          extract_llm_content(response)
        end
      end

      ##
      # Extracts content from an LLM response.
      #
      # This method provides a safe way to extract the main content
      # from an LLM response, handling various response formats.
      #
      # @param response [Hash] The LLM response
      # @return [String, nil] The extracted content or nil if not found
      #
      def extract_llm_content(response)
        # ruby_llm chat.ask returns a RubyLLM::Message object with a content method
        if response.respond_to?(:content)
          response.content
        elsif response.is_a?(Hash)
          # Fallback for other response formats
          response.dig("choices", 0, "message", "content") ||
          response.dig("message", "content") ||
          response["content"]
        else
          response.to_s if response
        end
      end

      ##
      # Validates and processes structured output using ruby_llm-schema.
      #
      # This method provides schema validation for generated content,
      # ensuring that the output conforms to expected structures.
      #
      # @param content [String] The content to validate
      # @param schema [Hash] The schema to validate against
      # @return [Hash, nil] The validated structure or nil if invalid
      #
      def validate_structured_output(content, schema)
        return nil if content.nil? || content.empty?
        
        begin
          parsed_content = JSON.parse(content)
          
          # Basic schema validation (can be enhanced with ruby_llm-schema)
          if schema && !validate_against_schema(parsed_content, schema)
            log(:warn, "Generated content does not match expected schema")
            return nil
          end
          
          parsed_content
        rescue JSON::ParserError => e
          log(:error, "Failed to parse generated JSON content", { error: e.message })
          nil
        end
      end

      ##
      # Builds a system prompt with standard instructions.
      #
      # This method creates a standardized system prompt that can be
      # customized by subclasses for their specific generation needs.
      #
      # @param task_description [String] Description of the generation task
      # @param output_format [String] Description of the expected output format
      # @param additional_instructions [String] Additional task-specific instructions
      # @return [String] The complete system prompt
      #
      def build_system_prompt(task_description:, output_format: nil, additional_instructions: nil)
        prompt_parts = []
        
        prompt_parts << "You are an expert assistant specializing in #{task_description}."
        prompt_parts << "Focus on providing accurate, relevant, and actionable information."
        
        if output_format
          prompt_parts << "Please format your response as #{output_format}."
        end
        
        if additional_instructions
          prompt_parts << additional_instructions
        end
        
        prompt_parts << "Use clear, professional language and ensure your response is well-structured."
        
        prompt_parts.join("\n\n")
      end

      ##
      # Formats output based on the specified format.
      #
      # This method provides a standardized way to format generated content
      # for different output types (JSON, text, structured, etc.).
      #
      # @param content [String] The content to format
      # @param format [Symbol] The desired output format
      # @return [Object] The formatted content
      #
      def format_output(content, format = :text)
        return content if content.nil?
        
        case format
        when :json
          validate_structured_output(content, nil) || content
        when :text
          content.to_s
        when :structured
          parse_structured_content(content)
        else
          content
        end
      end

      private

      ##
      # Performs basic schema validation.
      #
      # This is a simple validation implementation that can be enhanced
      # with more sophisticated schema validation libraries.
      #
      # @param data [Hash] The data to validate
      # @param schema [Hash] The schema to validate against
      # @return [Boolean] Whether the data matches the schema
      #
      def validate_against_schema(data, schema)
        return true unless schema.is_a?(Hash)
        return false unless data.is_a?(Hash)
        
        # Simple validation - check required keys exist
        required_keys = schema[:required] || []
        required_keys.all? { |key| data.key?(key.to_s) || data.key?(key.to_sym) }
      end

      ##
      # Parses structured content from text.
      #
      # This method attempts to extract structured data from generated text,
      # looking for JSON blocks, YAML, or other structured formats.
      #
      # @param content [String] The content to parse
      # @return [Hash, String] The parsed structure or original content
      #
      def parse_structured_content(content)
        # Try to extract JSON blocks from the content
        json_match = content.match(/```(?:json)?\s*(\{.*?\})\s*```/m)
        if json_match
          begin
            return JSON.parse(json_match[1])
          rescue JSON::ParserError
            # Fall through to return original content
          end
        end
        
        # Try to parse the entire content as JSON
        begin
          JSON.parse(content)
        rescue JSON::ParserError
          content
        end
      end
    end
  end
end