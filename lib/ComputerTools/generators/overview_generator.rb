# frozen_string_literal: true

module ComputerTools
  module Generators
    class OverviewGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :single_string,
                         name: "generated_text",
                         description: "A comprehensive overview of ComputerTools features and functionality"

      def initialize(format: 'console')
        @format = format
      end

      def prompt
        <<-PROMPT
          Generate a comprehensive overview of ComputerTools based on the following documentation.
          Format the output as #{@format} format.

          CONTEXT INFORMATION:
          ComputerTools is a comprehensive Ruby CLI toolkit built on the Sublayer framework, providing AI-enhanced tools for software development and automation. It's a modular collection of intelligent CLI utilities that leverage AI capabilities through the Sublayer framework.

          AVAILABLE TOOLS:

          1. BLUEPRINT MANAGER:
          - AI-enhanced code blueprint management with semantic search and automatic metadata generation
          - Features: AI-generated metadata, semantic search, direct database access, smart editing, export/import, safe deletion, interactive UI
          - Uses PostgreSQL with pgvector extension for vector embeddings
          - Integrates with Rails server for web interface
          - Commands: submit, list, browse, view, edit, search, export, delete, config

          2. DEEPGRAM PARSER:
          - Parse, analyze, and convert Deepgram JSON output with AI-enhanced insights
          - Features: Multi-format output (markdown, SRT, JSON, summary), interactive analysis, AI integration, statistics & metrics
          - Commands: parse, convert, analyze, config
          - Output formats: markdown (rich analysis), SRT (subtitles), JSON (structured data), summary (concise overview)

          3. LATEST CHANGES ANALYZER:
          - Comprehensive file activity tracking across Git, YADM, and Restic with intelligent analysis
          - Features: Multi-platform file tracking, intelligent analysis, multiple output formats, advanced configuration
          - Tracks: Git repositories, YADM dotfiles, Restic backups, untracked files
          - Commands: analyze, config
          - Output formats: table view, summary view, JSON export, interactive mode

          4. INTERACTIVE MENU SYSTEM:
          - User-friendly interactive menu system for command discovery and execution
          - Features: guided parameter collection, seamless navigation, error handling, debug mode
          - Provides alternative to traditional CLI usage

          KEY FEATURES:
          - AI-Powered Intelligence: Automatic metadata generation, semantic search, improvement suggestions
          - Developer Experience: Interactive CLI, multiple output formats, flexible configuration
          - Performance & Reliability: Direct database access, vector embeddings, connection pooling
          - Modular Architecture: Commands, Actions, Generators, Wrappers pattern
          - Framework Integration: Built on Thor CLI framework with Sublayer AI integration

          ARCHITECTURE:
          - Command Pattern: CLI commands with clear interfaces
          - Action Pattern: Encapsulated business logic
          - Generator Pattern: AI-powered content generation
          - Wrapper Pattern: External tool integration
          - Configuration: YAML-based with environment variables

          USAGE MODES:
          - Interactive Mode: ./exe/ComputerTools (launches menu)
          - Command Line Mode: ./exe/ComputerTools <command> <subcommand> [options]

          Generate an engaging overview that highlights the comprehensive nature of ComputerTools, its AI-powered capabilities, and practical applications for developers. Include key benefits, primary tools, and usage examples.

          For console format: Use colorized output with emojis and clear sections
          For markdown format: Use proper markdown structure with headers, lists, and code blocks
          For JSON format: Provide structured data with nested objects for each tool
        PROMPT
      end
    end
  end
end
