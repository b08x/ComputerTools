# frozen_string_literal: true

module ComputerTools
  module Providers
    module RubyLLM
      ##
      # OpenRouter provider for ruby_llm integration.
      #
      # This class provides a ruby_llm-compatible interface for interacting with
      # OpenRouter's API. It handles authentication, request formatting, response
      # processing, and error handling for OpenRouter endpoints.
      #
      # The provider supports the full range of OpenRouter models and features
      # including function calling, streaming, and usage tracking.
      #
      class OpenRouter
        ##
        # Creates a new OpenRouter provider instance.
        #
        # @param api_key [String] The OpenRouter API key (defaults to ENV['OPENROUTER_API_KEY'])
        # @param model [String] The model to use for requests
        # @param timeout [Integer] Request timeout in seconds (default: 30)
        # @param base_url [String] The OpenRouter API base URL
        #
        def initialize(api_key: nil, model:, timeout: 30, base_url: 'https://openrouter.ai/api/v1')
          @api_key = api_key || ENV['OPENROUTER_API_KEY'] || ENV['OPENAI_ACCESS_TOKEN']
          @model = model
          @timeout = timeout
          @base_url = base_url
          
          raise ArgumentError, "OpenRouter API key is required" if @api_key.nil? || @api_key.empty?
        end

        ##
        # Executes a chat completion request to the OpenRouter API.
        #
        # This method sends a structured chat request to OpenRouter and processes
        # the response according to ruby_llm conventions. It supports all OpenRouter
        # features including function calling and streaming.
        #
        # @param messages [Array<Hash>] Array of message objects with role and content
        # @param options [Hash] Additional options for the request
        # @option options [Float] :temperature Sampling temperature (default: 0.3)
        # @option options [Integer] :max_tokens Maximum tokens to generate
        # @option options [Boolean] :stream Whether to stream the response
        # @option options [Array<Hash>] :tools Function definitions for tool calling
        # @option options [Hash] :tool_choice Tool selection strategy
        # @return [Hash] The API response in standardized format
        # @raise [StandardError] When the API request fails or returns an error
        #
        def chat(messages:, **options)
          request_body = build_chat_request(messages, options)
          
          response = make_request('/chat/completions', request_body)
          validate_response(response)
          
          response
        rescue StandardError => e
          handle_api_error(e, request_body)
        end

        ##
        # Executes a completion request with function calling support.
        #
        # This method is designed for structured output generation using
        # OpenRouter's function calling capabilities.
        #
        # @param prompt [String] The user prompt
        # @param functions [Array<Hash>] Function definitions for structured output
        # @param options [Hash] Additional request options
        # @return [Hash] The processed function call response
        #
        def completion_with_functions(prompt:, functions:, **options)
          messages = [{ role: "user", content: prompt }]
          
          tools = functions.map { |func| format_function_for_openrouter(func) }
          
          response = chat(
            messages: messages,
            tools: tools,
            tool_choice: { type: 'function', function: { name: functions.first[:name] } },
            **options
          )
          
          extract_function_result(response, functions.first)
        end

        ##
        # Lists available models from OpenRouter.
        #
        # @return [Array<Hash>] List of available models with their metadata
        #
        def available_models
          response = make_request('/models')
          response['data'] || []
        rescue StandardError => e
          ComputerTools.logger&.error("Failed to fetch OpenRouter models", { error: e.message })
          []
        end

        ##
        # Checks if the provider is available and responding.
        #
        # @return [Boolean] true if the provider is available, false otherwise
        #
        def available?
          test_response = chat(
            messages: [{ role: "user", content: "test" }],
            max_tokens: 1,
            temperature: 0
          )
          
          test_response.is_a?(Hash) && test_response.dig('choices', 0, 'message')
        rescue StandardError
          false
        end

        private

        ##
        # Builds a chat request payload for OpenRouter.
        #
        # @param messages [Array<Hash>] The chat messages
        # @param options [Hash] Request options
        # @return [Hash] The request payload
        #
        def build_chat_request(messages, options)
          {
            model: @model,
            messages: messages,
            temperature: options.fetch(:temperature, 0.3),
            max_tokens: options[:max_tokens],
            stream: options.fetch(:stream, false),
            tools: options[:tools],
            tool_choice: options[:tool_choice]
          }.compact
        end

        ##
        # Formats a function definition for OpenRouter's API format.
        #
        # @param function [Hash] The function definition
        # @return [Hash] The formatted function for OpenRouter
        #
        def format_function_for_openrouter(function)
          {
            type: "function",
            function: {
              name: function[:name] || "response",
              description: function[:description] || "Generate structured response",
              parameters: {
                type: "object",
                properties: function[:properties] || {},
                required: function[:required] || []
              }
            }
          }
        end

        ##
        # Makes an HTTP request to the OpenRouter API.
        #
        # @param endpoint [String] The API endpoint path
        # @param payload [Hash] The request payload (nil for GET requests)
        # @return [Hash] The API response
        # @raise [StandardError] When the request fails
        #
        def make_request(endpoint, payload = nil)
          require 'net/http'
          require 'json'
          require 'uri'

          uri = URI.join(@base_url, endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = @timeout

          request = payload ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{@api_key}"
          request['Content-Type'] = 'application/json' if payload
          request['HTTP-Referer'] = 'https://github.com/your-org/ComputerTools'
          request['X-Title'] = 'ComputerTools'
          
          request.body = payload.to_json if payload

          response = http.request(request)
          
          handle_http_response(response)
        rescue StandardError => e
          raise StandardError, "OpenRouter API request failed: #{e.message}"
        end

        ##
        # Handles HTTP response and error codes.
        #
        # @param response [Net::HTTPResponse] The HTTP response
        # @return [Hash] The parsed JSON response
        # @raise [StandardError] For various error conditions
        #
        def handle_http_response(response)
          case response.code.to_i
          when 200..299
            JSON.parse(response.body)
          when 400
            error_data = JSON.parse(response.body) rescue { 'error' => { 'message' => response.body } }
            raise StandardError, "Bad request: #{error_data.dig('error', 'message')}"
          when 401
            raise StandardError, "Authentication failed: Check your OpenRouter API key"
          when 403
            raise StandardError, "Access forbidden: Insufficient permissions"
          when 429
            raise StandardError, "Rate limit exceeded: Please wait before making more requests"
          when 500..599
            raise StandardError, "OpenRouter server error: #{response.code}"
          else
            raise StandardError, "Unexpected response: #{response.code} - #{response.body}"
          end
        rescue JSON::ParserError => e
          raise StandardError, "Failed to parse OpenRouter response: #{e.message}"
        end

        ##
        # Validates the API response structure.
        #
        # @param response [Hash] The API response
        # @raise [StandardError] If response is invalid
        #
        def validate_response(response)
          unless response.is_a?(Hash) && response['choices'].is_a?(Array)
            raise StandardError, "Invalid OpenRouter response format"
          end

          if response['choices'].empty?
            raise StandardError, "OpenRouter returned empty choices"
          end

          choice = response['choices'][0]
          if choice['finish_reason'] == 'length'
            raise StandardError, "Response truncated due to max tokens limit. Consider increasing max_tokens."
          end
        end

        ##
        # Extracts function call results from the response.
        #
        # @param response [Hash] The API response
        # @param function_def [Hash] The function definition used
        # @return [Object] The extracted function result
        #
        def extract_function_result(response, function_def)
          message = response.dig('choices', 0, 'message')
          tool_calls = message&.dig('tool_calls')
          
          if tool_calls.nil? || tool_calls.empty?
            raise StandardError, "No function called in OpenRouter response"
          end

          function_call = tool_calls.first
          arguments_str = function_call.dig('function', 'arguments')
          
          if arguments_str.nil? || arguments_str.empty? || arguments_str == '{}'
            raise StandardError, "Empty function arguments in OpenRouter response"
          end

          begin
            arguments = JSON.parse(arguments_str)
            # Return the specific field requested or the entire arguments
            function_name = function_def[:name] || 'response'
            arguments[function_name] || arguments
          rescue JSON::ParserError => e
            raise StandardError, "Failed to parse function arguments: #{e.message}"
          end
        end

        ##
        # Handles API errors with appropriate error messages and logging.
        #
        # @param error [StandardError] The original error
        # @param request_data [Hash] The request data for debugging
        # @raise [StandardError] With a more descriptive message
        #
        def handle_api_error(error, request_data = nil)
          # Log the error for debugging
          ComputerTools.logger&.error("OpenRouter API error", {
            error_class: error.class.name,
            error_message: error.message,
            model: @model,
            request_preview: request_data&.slice(:model, :temperature, :max_tokens)
          })

          case error
          when Net::TimeoutError, Timeout::Error
            raise StandardError, "OpenRouter request timed out after #{@timeout} seconds"
          when Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            raise StandardError, "Cannot connect to OpenRouter API"
          when JSON::ParserError
            raise StandardError, "OpenRouter returned invalid JSON response"
          else
            # Re-raise with original message if it's already descriptive
            raise error
          end
        end
      end
    end
  end
end