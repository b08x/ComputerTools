# frozen_string_literal: true

module ComputerTools
  module Commands
    ##
    # OverviewCommand provides a comprehensive summary of ComputerTools features and functionality.
    #
    # This command generates and displays an overview of the ComputerTools system in various formats,
    # making it useful for documentation purposes, quick reference, or system integration.
    #
    # The command supports multiple output formats including console, markdown, and JSON,
    # allowing for flexible integration with different presentation layers or documentation systems.
    #
    # @example Basic usage (console output)
    #   ComputerTools::Commands::OverviewCommand.new({}).execute
    #
    # @example Markdown output
    #   ComputerTools::Commands::OverviewCommand.new({}).execute('markdown')
    #
    # @example JSON output
    #   ComputerTools::Commands::OverviewCommand.new({}).execute('json')
    class OverviewCommand < BaseCommand
      ##
      # Provides a description of the OverviewCommand's purpose.
      #
      # @return [String] A description explaining that this command displays
      #   a comprehensive overview of ComputerTools features and functionality.
      def self.description
        "Display comprehensive overview of ComputerTools features and functionality"
      end

      ##
      # Executes the overview command with the specified output format.
      #
      # This method determines the output format from the provided arguments,
      # generates the overview using OverviewGenerator, and outputs the result.
      #
      # @param [Array<String>] args An array of arguments where the first element
      #   specifies the output format. Supported formats are 'console', 'markdown',
      #   'md' (alias for markdown), and 'json'.
      #
      # @return [void] This method outputs the generated overview directly to stdout
      #   rather than returning a value.
      #
      # @example Console output (default)
      #   execute
      #   # Outputs the overview in console format to stdout
      #
      # @example Markdown output
      #   execute('markdown')
      #   # Outputs the overview in markdown format to stdout
      #
      # @example JSON output
      #   execute('json')
      #   # Outputs the overview in JSON format to stdout
      #
      # @note If no format is specified or if an unsupported format is provided,
      #   the method defaults to console output format.
      #
      # @see ComputerTools::Generators::OverviewGenerator The generator class that
      #   produces the actual overview content.
      def execute(*args)
        format = args.first || 'console'

        output_format = case format.downcase
                        when 'markdown', 'md'
                          'markdown'
                        when 'json'
                          'json'
                        else
                          'console'
                        end

        result = ComputerTools::Generators::OverviewGenerator.new(
          format: output_format
        ).generate

        puts result
      end
    end
  end
end