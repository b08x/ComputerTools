# frozen_string_literal: true

module ComputerTools
  module Generators
    module Blueprints
      class BlueprintName < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
        name: "name",
        description: "A descriptive name for this code blueprint"

      def initialize(code:, description: nil)
        @code = code
        @description = description
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
          Generate a clear, descriptive name for this code blueprint.

          #{@description ? "Description: #{@description}" : ""}

          Code:
          ```
          #{@code}
          ```

          The name should:
          - Be 3-6 words long
          - Clearly indicate what the code does
          - Use title case (e.g., "User Authentication Helper", "CSV Data Processor")
          - Be specific enough to distinguish it from similar code
          - Avoid generic terms like "Script" or "Code" unless necessary

          Examples of good names:
          - "REST API Response Formatter"
          - "Database Migration Helper"
          - "Email Template Generator"
          - "JWT Token Validator"
          - "File Upload Handler"

          Return only the name, no additional text or explanation.
        PROMPT
      end
    end
    end
  end
end
