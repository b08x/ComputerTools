# frozen_string_literal: true

module ComputerTools
  module Providers
    module RubyLLM
      ##
      # Ollama provider for ruby_llm integration.
      #
      # This class provides a ruby_llm-compatible interface for interacting with
      # Ollama-hosted language models. It handles API requests, response processing,
      # and error handling for Ollama endpoints.
      #
      # The provider supports function calling and structured output through
      # ruby_llm's standardized interface, making it compatible with the rest
      # of the ComputerTools ecosystem.
      #
      class Ollama
        ##
        # Creates a new Ollama provider instance.
        #
        # @param host [String] The base URL of the Ollama API endpoint
        # @param model [String] The model identifier to use for requests
        # @param timeout [Integer] Request timeout in seconds (default: 30)
        #
        def initialize(host:, model:, timeout: 30)
          @host = host
          @model = model
          @timeout = timeout
        end

        ##
        # Executes a chat completion request to the Ollama API.
        #
        # This method sends a structured chat request to the Ollama endpoint
        # and processes the response according to ruby_llm conventions.
        #
        # @param messages [Array<Hash>] Array of message objects with role and content
        # @param options [Hash] Additional options for the request
        # @option options [Float] :temperature Sampling temperature (default: 0.3)
        # @option options [Integer] :max_tokens Maximum tokens to generate
        # @option options [Boolean] :stream Whether to stream the response
        # @return [Hash] The API response in standardized format
        # @raise [StandardError] When the API request fails or returns an error
        #
        def chat(messages:, **options)
          request_body = build_chat_request(messages, options)
          
          response = make_request(request_body)
          process_chat_response(response)
        rescue StandardError => e
          handle_api_error(e)
        end

        ##
        # Executes a completion request with function calling support.
        #
        # This method is designed for structured output generation using
        # function calling capabilities of compatible Ollama models.
        #
        # @param prompt [String] The user prompt
        # @param functions [Array<Hash>] Function definitions for structured output
        # @param options [Hash] Additional request options
        # @return [Hash] The processed function call response
        #
        def completion_with_functions(prompt:, functions:, **options)
          messages = [{ role: "user", content: prompt }]
          
          request_body = build_function_request(messages, functions, options)
          response = make_request(request_body)
          
          process_function_response(response, functions.first)
        end

        ##
        # Checks if the provider is available and responding.
        #
        # @return [Boolean] true if the provider is available, false otherwise
        #
        def available?
          test_response = make_request({
            model: @model,
            messages: [{ role: "user", content: "test" }],
            stream: false,
            max_tokens: 1
          })
          
          test_response.is_a?(Hash) && test_response.key?('message')
        rescue StandardError
          false
        end

        private

        ##
        # Builds a chat request payload.
        #
        # @param messages [Array<Hash>] The chat messages
        # @param options [Hash] Request options
        # @return [Hash] The request payload
        #
        def build_chat_request(messages, options)
          {
            model: @model,
            messages: messages,
            stream: options.fetch(:stream, false),
            temperature: options.fetch(:temperature, 0.3),
            max_tokens: options[:max_tokens]
          }.compact
        end

        ##
        # Builds a function calling request payload.
        #
        # @param messages [Array<Hash>] The chat messages
        # @param functions [Array<Hash>] Function definitions
        # @param options [Hash] Request options
        # @return [Hash] The request payload
        #
        def build_function_request(messages, functions, options)
          {
            model: @model,
            messages: messages,
            stream: false,
            temperature: options.fetch(:temperature, 0.3),
            tools: functions.map { |func| format_function_for_ollama(func) }
          }
        end

        ##
        # Formats a function definition for Ollama's API format.
        #
        # @param function [Hash] The function definition
        # @return [Hash] The formatted function for Ollama
        #
        def format_function_for_ollama(function)
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
        # Makes an HTTP request to the Ollama API.
        #
        # @param payload [Hash] The request payload
        # @return [Hash] The API response
        # @raise [StandardError] When the request fails
        #
        def make_request(payload)
          require 'net/http'
          require 'json'
          require 'uri'

          uri = URI.parse(@host)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = @timeout

          request = Net::HTTP::Post.new(uri.path.empty? ? '/api/chat' : uri.path)
          request['Content-Type'] = 'application/json'
          request.body = payload.to_json

          response = http.request(request)
          
          unless response.code.start_with?('2')
            raise StandardError, "Ollama API error: #{response.code} - #{response.body}"
          end

          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise StandardError, "Failed to parse Ollama response: #{e.message}"
        end

        ##
        # Processes a standard chat response.
        #
        # @param response [Hash] The raw API response
        # @return [Hash] The processed response
        #
        def process_chat_response(response)
          message = response['message']
          
          {
            'choices' => [{
              'message' => {
                'role' => message['role'] || 'assistant',
                'content' => message['content']
              }
            }],
            'usage' => extract_usage_info(response)
          }
        end

        ##
        # Processes a function calling response.
        #
        # @param response [Hash] The raw API response
        # @param function_def [Hash] The function definition used
        # @return [Hash] The processed function response
        #
        def process_function_response(response, function_def)
          message = response['message']
          tool_calls = message['tool_calls']
          
          if tool_calls.nil? || tool_calls.empty?
            raise StandardError, "No function called in Ollama response"
          end

          function_call = tool_calls.first
          function_args = function_call.dig('function', 'arguments')
          
          if function_args.is_a?(String)
            function_args = JSON.parse(function_args)
          end

          {
            'choices' => [{
              'message' => {
                'role' => 'assistant',
                'content' => nil,
                'tool_calls' => [{
                  'function' => {
                    'name' => function_call.dig('function', 'name'),
                    'arguments' => function_args
                  }
                }]
              }
            }],
            'usage' => extract_usage_info(response)
          }
        rescue JSON::ParserError => e
          raise StandardError, "Failed to parse function arguments: #{e.message}"
        end

        ##
        # Extracts usage information from the response.
        #
        # @param response [Hash] The API response
        # @return [Hash] Usage information
        #
        def extract_usage_info(response)
          # Ollama may not always provide usage info
          {
            'prompt_tokens' => 0,
            'completion_tokens' => 0,
            'total_tokens' => 0
          }
        end

        ##
        # Handles API errors with appropriate error messages.
        #
        # @param error [StandardError] The original error
        # @raise [StandardError] With a more descriptive message
        #
        def handle_api_error(error)
          case error
          when Net::TimeoutError, Timeout::Error
            raise StandardError, "Ollama request timed out after #{@timeout} seconds"
          when Errno::ECONNREFUSED
            raise StandardError, "Cannot connect to Ollama server at #{@host}"
          when JSON::ParserError
            raise StandardError, "Ollama returned invalid JSON response"
          else
            raise StandardError, "Ollama API error: #{error.message}"
          end
        end
      end
    end
  end
end