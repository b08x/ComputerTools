# frozen_string_literal: true

module ComputerTools
  module Generators
    class BlueprintImprovementGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :list_of_strings,
        name: "improvements",
        description: "Suggested improvements and best practices for this code blueprint"

      def initialize(code:, description: nil)
        @code = code
        @description = description
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Analyze this code blueprint and suggest specific, actionable improvements.

          #{@description ? "Description: #{@description}" : ""}

          Code:
          ```
          #{@code}
          ```

          Please provide 3-6 specific improvement suggestions focusing on:

          **Code Quality:**
          - Readability and clarity improvements
          - Better variable/method naming
          - Code organization and structure
          - DRY principle violations

          **Performance:**
          - Algorithm efficiency improvements
          - Memory usage optimizations
          - Database query optimizations (if applicable)
          - Caching opportunities

          **Security:**
          - Input validation and sanitization
          - Authentication and authorization concerns
          - Data exposure risks
          - Secure coding practices

          **Best Practices:**
          - Framework-specific conventions
          - Error handling improvements
          - Logging and debugging enhancements
          - Testing considerations

          **Maintainability:**
          - Documentation needs
          - Configuration externalization
          - Dependency management
          - Code modularity

          Format each suggestion as a single, actionable sentence that clearly explains:
          1. WHAT to improve
          2. WHY it's important
          3. HOW to implement it (briefly)

          Focus on the most impactful improvements first. Avoid generic advice.
        PROMPT
      end
    end
  end
end