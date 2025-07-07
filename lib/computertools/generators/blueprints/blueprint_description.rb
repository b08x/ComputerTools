# frozen_string_literal: true

module ComputerTools
  module Generators
    module Blueprints
      class BlueprintDescription < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
        name: "description",
        description: "A clear, concise description of what this code blueprint accomplishes"

      def initialize(code:, language: nil)
        @code = code
        @language = language || detect_language(code)
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Analyze this #{@language} code and generate a clear, concise description of what it does.

          Code:
          ```#{@language}
          #{@code}
          ```

          Please provide a description that:
          - Explains the primary functionality in 1-2 sentences
          - Mentions key design patterns or techniques used
          - Indicates the intended use case or context
          - Is written for developers who might want to reuse this code

          Focus on WHAT the code does and WHY someone would use it, not HOW it works in detail.
        PROMPT
      end

      private

      def detect_language(code)
        case code
        when /class\s+\w+.*<.*ApplicationRecord/m, /def\s+\w+.*end/m, /require ['"].*['"]/m
          'ruby'
        when /function\s+\w+\s*\(/m, /const\s+\w+\s*=/m, /import\s+.*from/m
          'javascript'
        when /def\s+\w+\s*\(/m, /import\s+\w+/m, /from\s+\w+\s+import/m
          'python'
        when /#include\s*<.*>/m, /int\s+main\s*\(/m
          'c'
        when /public\s+class\s+\w+/m, /import\s+java\./m
          'java'
        when /fn\s+\w+\s*\(/m, /use\s+std::/m
          'rust'
        when /func\s+\w+\s*\(/m, /package\s+main/m
          'go'
        else
          'code'
        end
      end
    end
    end
  end
end
