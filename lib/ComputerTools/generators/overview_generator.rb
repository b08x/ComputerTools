# frozen_string_literal: true

# ruby_llm configuration handled by ComputerTools::Config

module ComputerTools
  module Generators
    # Generates a comprehensive overview of the ComputerTools toolkit in various formats.
    #
    # This generator leverages a Large Language Model (LLM) by providing it with a
    # detailed prompt containing extensive context about the ComputerTools features,
    # architecture, and available tools. It is responsible for creating engaging
    # and informative summaries suitable for different display environments like
    # the console, markdown files, or structured JSON.
    class OverviewGenerator < ComputerTools::Generators::BaseGenerator

      # Initializes a new instance of the OverviewGenerator.
      #
      # @param format [String] The desired output format for the overview.
      #   Acceptable values include 'console', 'markdown', and 'json'.
      #
      # @example Create a generator for markdown output
      #   generator = ComputerTools::Generators::OverviewGenerator.new(format: 'markdown')
      def initialize(format: 'console')
        super()
        @format = format
      end

      # Generates the overview using ruby_llm.
      #
      # @return [String, nil] The generated overview or nil on error
      def call
        with_generation_handling("overview generation") do
          system_prompt = build_system_prompt(
            task_description: "comprehensive tool documentation and overview generation",
            output_format: @format,
            additional_instructions: "Focus on practical benefits and clear examples"
          )
          
          content = generate_llm_content(prompt, system_prompt: system_prompt)
          format_output(content, @format.to_sym)
        end
      end

      # Constructs the detailed prompt sent to the LLM for generating the overview.
      #
      # This method builds a multi-line string that serves as the master prompt.
      # It includes all the necessary context about the ComputerTools toolkit and
      # instructs the LLM to tailor the final output based on the format
      # specified during initialization.
      #
      # @return [String] The complete prompt text to be processed by the LLM.
      def prompt
        [
          prompt_header,
          context_information,
          available_tools_section,
          key_features_section,
          architecture_section,
          usage_modes_section,
          format_instructions
        ].join("\n\n")
      end

      private

      def prompt_header
        "Generate a comprehensive overview of ComputerTools based on the following documentation.\n" \
        "Format the output as #{@format} format."
      end

      def context_information
        "CONTEXT INFORMATION:\n" \
        "ComputerTools is a comprehensive Ruby CLI toolkit built with ruby_llm integration, " \
        "providing AI-enhanced tools for software development and automation. It's a modular " \
        "collection of intelligent CLI utilities that leverage AI capabilities through ruby_llm."
      end

      def available_tools_section
        <<~TOOLS
          AVAILABLE TOOLS:

          1. DEEPGRAM PARSER:
          - Parse, analyze, and convert Deepgram JSON output with AI-enhanced insights
          - Features: Multi-format output (markdown, SRT, JSON, summary), interactive analysis, AI integration, statistics & metrics
          - Commands: parse, convert, analyze, config
          - Output formats: markdown (rich analysis), SRT (subtitles), JSON (structured data), summary (concise overview)

          2. LATEST CHANGES ANALYZER:
          - Comprehensive file activity tracking across Git, YADM, and untracked files with intelligent analysis
          - Features: Multi-platform file tracking, intelligent analysis, multiple output formats, advanced configuration
          - Tracks: Git repositories, YADM dotfiles, untracked files
          - Commands: analyze, config
          - Output formats: table view, summary view, JSON export, interactive mode

          3. INTERACTIVE MENU SYSTEM:
          - User-friendly interactive menu system for command discovery and execution
          - Features: guided parameter collection, seamless navigation, error handling, debug mode
          - Provides alternative to traditional CLI usage
        TOOLS
      end

      def key_features_section
        <<~FEATURES
          KEY FEATURES:
          - AI-Powered Intelligence: Automatic metadata generation, semantic search, improvement suggestions
          - Developer Experience: Interactive CLI, multiple output formats, flexible configuration
          - Performance & Reliability: Direct database access, vector embeddings, connection pooling
          - Modular Architecture: Commands, Actions, Generators, Wrappers pattern
          - Framework Integration: Built on Thor CLI framework with ruby_llm AI integration
        FEATURES
      end

      def architecture_section
        <<~ARCHITECTURE
          ARCHITECTURE:
          - Command Pattern: CLI commands with clear interfaces
          - Action Pattern: Encapsulated business logic
          - Generator Pattern: AI-powered content generation
          - Wrapper Pattern: External tool integration
          - Configuration: YAML-based with environment variables
        ARCHITECTURE
      end

      def usage_modes_section
        <<~USAGE
          USAGE MODES:
          - Interactive Mode: ./exe/ComputerTools (launches menu)
          - Command Line Mode: ./exe/ComputerTools <command> <subcommand> [options]
        USAGE
      end

      def format_instructions
        <<~INSTRUCTIONS
          Generate an engaging overview that highlights the comprehensive nature of ComputerTools, 
          its AI-powered capabilities, and practical applications for developers. Include key benefits, 
          primary tools, and usage examples.

          For console format: Use colorized output with emojis and clear sections
          For markdown format: Use proper markdown structure with headers, lists, and code blocks
          For JSON format: Provide structured data with nested objects for each tool
        INSTRUCTIONS
      end
    end
  end
end