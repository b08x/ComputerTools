# frozen_string_literal: true

module ComputerTools
  module Actions
    ##
    # Base class for all ComputerTools actions using ruby_llm.
    #
    # This class provides a foundation for creating actions that interact with
    # language models through ruby_llm. It offers common functionality such as
    # configuration management, logging, error handling, and standardized
    # method signatures for action execution.
    #
    # Actions inheriting from this class should implement the `call` method
    # to define their specific behavior.
    #
    # @example Creating a custom action
    #   class MyCustomAction < ComputerTools::Actions::BaseAction
    #     def initialize(data:, config:)
    #       super()
    #       @data = data
    #       @config = config
    #     end
    #
    #     def call
    #       # Implementation logic here
    #       process_data(@data)
    #     end
    #
    #     private
    #
    #     def process_data(data)
    #       # Action-specific processing
    #     end
    #   end
    #
    class BaseAction
      ##
      # Initializes a new BaseAction instance.
      #
      # Sets up basic configuration and logging for the action.
      # Subclasses should call super() and then initialize their own
      # instance variables as needed.
      #
      def initialize
        @logger = ComputerTools.logger
        @llm_client = initialize_llm_client
      end

      ##
      # Main execution method for the action.
      #
      # This method should be overridden by subclasses to implement
      # the specific logic for the action. The base implementation
      # raises a NotImplementedError.
      #
      # @return [Object] The result of the action execution
      # @raise [NotImplementedError] When not implemented by subclass
      #
      def call
        raise NotImplementedError, "#{self.class} must implement the `call` method"
      end

      protected

      ##
      # Initializes the ruby_llm client with default configuration.
      #
      # This method sets up a basic ruby_llm client that can be used
      # by actions that need to interact with language models.
      #
      # @return [RubyLLM] Configured LLM client
      #
      def initialize_llm_client
        RubyLLM.configure do |config|
          config.provider = :openrouter
          config.chat_model = "anthropic/claude-3.5-sonnet"
          config.log_level = :info
          config.timeout = 30
        end

        RubyLLM
      end

      ##
      # Logs a message with the specified level.
      #
      # Provides a convenient interface for logging within actions.
      #
      # @param level [Symbol] The log level (:debug, :info, :warn, :error)
      # @param message [String] The message to log
      # @param data [Hash] Optional additional data to include in the log
      #
      def log(level, message, data = {})
        @logger&.send(level, message, data)
      end

      ##
      # Executes a block with error handling and logging.
      #
      # This method provides standardized error handling for action operations,
      # including logging of errors and optional recovery behavior.
      #
      # @param operation [String] Description of the operation being performed
      # @param fallback_result [Object] Value to return if the operation fails
      # @yield The block to execute with error handling
      # @return [Object] The result of the block or fallback_result on error
      #
      def with_error_handling(operation, fallback_result = nil)
        log(:info, "Starting #{operation}")
        
        result = yield
        
        log(:info, "Completed #{operation}")
        result
      rescue StandardError => e
        log(:error, "Error during #{operation}: #{e.message}", {
          error_class: e.class.name,
          backtrace: e.backtrace&.first(5)
        })
        
        fallback_result
      end

      ##
      # Validates required parameters for the action.
      #
      # This method checks that all required parameters are present
      # and raises an ArgumentError if any are missing.
      #
      # @param params [Hash] The parameters to validate
      # @param required_keys [Array<Symbol>] List of required parameter keys
      # @raise [ArgumentError] When required parameters are missing
      #
      def validate_required_params(params, required_keys)
        missing_keys = required_keys - params.keys
        
        unless missing_keys.empty?
          raise ArgumentError, "Missing required parameters: #{missing_keys.join(', ')}"
        end
      end

      ##
      # Executes a ruby_llm chat request with error handling.
      #
      # This method provides a standardized interface for making LLM requests
      # within actions, including proper error handling and logging.
      #
      # @param messages [Array<Hash>] The messages for the chat request
      # @param options [Hash] Additional options for the request
      # @return [Hash, nil] The LLM response or nil on error
      #
      def llm_chat(messages, options = {})
        default_options = {
          temperature: 0.3,
          max_tokens: 1000
        }
        
        request_options = default_options.merge(options)
        
        with_error_handling("LLM chat request") do
          @llm_client.chat(
            messages: messages,
            **request_options
          )
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
        return nil unless response.is_a?(Hash)
        
        response.dig("choices", 0, "message", "content") ||
        response.dig("message", "content") ||
        response["content"]
      end
    end
  end
end