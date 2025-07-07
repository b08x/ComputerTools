# frozen_string_literal: true

module ComputerTools
  module Commands
    # Manages command-line operations related to Deepgram output, including parsing,
    # analysis, format conversion, and configuration management.
    #
    # This class acts as a dispatcher for various Deepgram-specific subcommands,
    # allowing users to interact with Deepgram JSON data through a unified interface.
    # It delegates specific operations to dedicated action classes (e.g., for parsing,
    # analysis, conversion, and configuration).
    #
    # @see ComputerTools::Actions::DeepgramParseAction
    # @see ComputerTools::Actions::DeepgramAnalyzeAction
    # @see ComputerTools::Actions::DeepgramConvertAction
    # @see ComputerTools::Actions::DeepgramConfigAction
    class DeepgramCommand < BaseCommand
      # Returns a brief description of the command's purpose.
      #
      # This description is typically used in help menus or command listings to
      # provide a quick overview of what the `deepgram` command does.
      #
      # @return [String] A descriptive string explaining the command's functionality.
      # @example
      #   DeepgramCommand.description #=> "Parse and analyze Deepgram JSON output with AI-enhanced insights"

      def self.description
        "Parse and analyze Deepgram JSON output with AI-enhanced insights"
      end

      # Initializes a new DeepgramCommand instance.
      #
      # Sets up the command with an initial set of options inherited from `BaseCommand`.
      # Internal instance variables `@subcommand` and `@args` are initialized to `nil` and
      # an empty array, respectively, to be populated later by the {#execute} method.
      #
      # @param [Hash] options A hash of options, typically parsed from command-line arguments.
      #   These options are passed to the superclass initializer and can influence
      #   behavior in subsequent actions (e.g., `output` file path or `interactive` mode).

      def initialize(options)
        super
        @subcommand = nil
        @args = []
      end

      # Executes the specified Deepgram subcommand based on the provided arguments.
      #
      # This method parses the first argument as a subcommand and dispatches
      # to the appropriate private handler method (e.g., {#handle_parse},
      # {#handle_analyze}, {#handle_convert}, {#handle_config}).
      # If no subcommand or 'help' is provided, it displays the help message.
      # If an unknown subcommand is given, it logs an error and shows help.
      #
      # @param [Array<String>] args A variable number of strings representing
      #   command-line arguments. The first element is expected to be the subcommand
      #   (e.g., 'parse', 'analyze'), and subsequent elements are arguments for that subcommand.
      # @return [Boolean] `true` if a known subcommand was successfully executed or help was shown,
      #   `false` if an unknown subcommand was provided, or if a subcommand handler
      #   returned `false` due to missing/invalid input (e.g., file not found).
      # @example Parse a Deepgram JSON file to markdown and display in console
      #   command = DeepgramCommand.new({'output' => 'parsed.md'})
      #   command.execute('parse', 'transcript.json', 'markdown', '--console')
      # @example Analyze a Deepgram JSON file interactively
      #   command = DeepgramCommand.new({'interactive' => true})
      #   command.execute('analyze', 'segments.json')
      # @example Convert a Deepgram JSON file to SRT format
      #   command = DeepgramCommand.new({})
      #   command.execute('convert', 'transcript.json', 'srt')
      # @example Show the general help message for the Deepgram command
      #   command = DeepgramCommand.new({})
      #   command.execute('help')
      # @example Handle an unknown subcommand gracefully
      #   command = DeepgramCommand.new({})
      #   command.execute('unknown_command') # Logs an error and shows help, returns `false`

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

      # Handles the 'parse' subcommand, processing Deepgram JSON output.
      #
      # This method expects a JSON file path as the first element in `@args`
      # and an optional output format (defaults to 'markdown') as the second.
      # It validates the presence and existence of the JSON file, printing an
      # error message and usage instructions if validation fails.
      # Upon successful validation, it delegates the parsing operation to
      # {ComputerTools::Actions::DeepgramParseAction}.
      #
      # @return [Object, Boolean] The result of the `DeepgramParseAction.call` method
      #   if parsing proceeds, or `false` if a JSON file path is missing or the file
      #   does not exist.
      # @see ComputerTools::Actions::DeepgramParseAction

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

      # Handles the 'analyze' subcommand, applying AI-enhanced insights to Deepgram JSON.
      #
      # This method expects a JSON file path as the first element in `@args`.
      # It validates the presence and existence of the JSON file, printing an
      # error message and usage instructions if validation fails.
      # Upon successful validation, it delegates the analysis operation to
      # {ComputerTools::Actions::DeepgramAnalyzeAction}.
      #
      # @return [Object, Boolean] The result of the `DeepgramAnalyzeAction.call` method
      #   if analysis proceeds, or `false` if a JSON file path is missing or the file
      #   does not exist.
      # @see ComputerTools::Actions::DeepgramAnalyzeAction
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

      # Handles the 'convert' subcommand, transforming Deepgram JSON into various formats.
      #
      # This method expects a JSON file path as the first element in `@args`
      # and an optional target format (defaults to 'srt', can also be from `@options['format']`)
      # as the second. It validates the presence and existence of the JSON file,
      # printing an error message and usage instructions if validation fails.
      # Upon successful validation, it delegates the conversion operation to
      # {ComputerTools::Actions::DeepgramConvertAction}.
      #
      # @return [Object, Boolean] The result of the `DeepgramConvertAction.call` method
      #   if conversion proceeds, or `false` if a JSON file path is missing or the file
      #   does not exist.
      # @see ComputerTools::Actions::DeepgramConvertAction
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

      # Handles the 'config' subcommand, managing Deepgram API configuration.
      #
      # This method takes an optional subcommand (e.g., 'show' or 'setup')
      # as the first element in `@args`, defaulting to 'show' if not provided.
      # It delegates the configuration management to
      # {ComputerTools::Actions::DeepgramConfigAction}.
      #
      # @return [Object] The result of the `DeepgramConfigAction.call` method,
      #   which typically indicates the success or outcome of the configuration operation.
      # @see ComputerTools::Actions::DeepgramConfigAction
      def handle_config
        subcommand = @args.first || 'show'

        ComputerTools::Actions::DeepgramConfigAction.new(
          subcommand: subcommand
        ).call
      end

      # Displays the help message for the Deepgram command.
      #
      # This method prints a detailed usage guide to the console, including
      # available subcommands, arguments, examples, and supported output formats.
      # It is typically called when the `deepgram` command is executed with
      # 'help' or no arguments, or with an unknown subcommand.
      #
      # @return [nil] This method prints directly to stdout and does not return a meaningful value.
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
