# frozen_string_literal: true

module ComputerTools
  module Commands
    class DeepgramCommand < BaseCommand
      def self.description
        "Parse and analyze Deepgram JSON output with AI-enhanced insights"
      end

      def initialize(options)
        super
        @subcommand = nil
        @args = []
      end

      def execute(*args)
        @subcommand = args.shift
        @args = args

        case @subcommand
        when 'parse'
          handle_parse
        when 'analyze'
          handle_analyze
        when 'convert'
          handle_convert
        when 'config'
          handle_config
        when 'help', nil
          show_help
        else
          puts "❌ Unknown subcommand: #{@subcommand}".colorize(:red)
          show_help
          false
        end
      end

      private

      def handle_parse
        json_file = @args.first
        output_format = @args[1] || 'markdown'

        unless json_file
          puts "❌ Please provide a JSON file path".colorize(:red)
          puts "Usage: deepgram parse <json_file> [format]"
          puts "Available formats: markdown, srt, json, summary"
          return false
        end

        unless File.exist?(json_file)
          puts "❌ File not found: #{json_file}".colorize(:red)
          return false
        end

        ComputerTools::Actions::DeepgramParseAction.new(
          json_file: json_file,
          output_format: output_format,
          output_file: @options['output'],
          console_output: @args.include?('--console')
        ).call
      end

      def handle_analyze
        json_file = @args.first

        unless json_file
          puts "❌ Please provide a JSON file path".colorize(:red)
          puts "Usage: deepgram analyze <json_file>"
          return false
        end

        unless File.exist?(json_file)
          puts "❌ File not found: #{json_file}".colorize(:red)
          return false
        end

        ComputerTools::Actions::DeepgramAnalyzeAction.new(
          json_file: json_file,
          interactive: @options['interactive'] || false,
          console_output: @options['console'] || false
        ).call
      end

      def handle_convert
        json_file = @args.first
        target_format = @args[1] || @options['format'] || 'srt'

        unless json_file
          puts "❌ Please provide a JSON file path".colorize(:red)
          puts "Usage: deepgram convert <json_file> [format]"
          puts "Available formats: markdown, srt, json, summary"
          return false
        end

        unless File.exist?(json_file)
          puts "❌ File not found: #{json_file}".colorize(:red)
          return false
        end

        ComputerTools::Actions::DeepgramConvertAction.new(
          json_file: json_file,
          format: target_format,
          output_file: @options['output'],
          console_output: @args.include?('--console')
        ).call
      end

      def handle_config
        subcommand = @args.first || 'show'

        ComputerTools::Actions::DeepgramConfigAction.new(
          subcommand: subcommand
        ).call
      end

      def show_help
        puts <<~HELP
          Deepgram Analysis Commands:

          📄 Core Operations:
            deepgram parse <json_file> [format]     Parse Deepgram JSON output
            deepgram analyze <json_file>            Analyze segments with AI insights
            deepgram convert <json_file> [format]   Convert to different formats

          🔧 Configuration:
            deepgram config [show|setup]           Manage configuration

          Arguments:
            format                             Output format (markdown, srt, json, summary)
            --console                          Display output in console
            --interactive                      Interactive mode for selections

          Examples:
            deepgram parse transcript.json
            deepgram parse transcript.json markdown --console
            deepgram analyze segments.json --interactive
            deepgram convert transcript.json srt
            deepgram convert transcript.json summary --console
            deepgram config setup

          Supported Formats:
            - markdown: Rich analysis with sections
            - srt: Standard subtitle format
            - json: Structured data output

        HELP
      end
    end
  end
end
