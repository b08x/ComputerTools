# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # A Terrapin-based DSL wrapper for the trafilatura CLI tool that provides a fluent interface
    # for HTML/XML content extraction and processing. This class enables Ruby developers to
    # programmatically interact with trafilatura's powerful web scraping and content extraction
    # capabilities through a clean, chainable API.
    #
    # The class handles command construction, option validation, and execution of the trafilatura
    # command-line tool, abstracting away the complexity of direct CLI interaction while providing
    # full access to all trafilatura features.
    #
    # @example Basic usage for extracting content from a URL
    #   Trafilatura.new
    #     .url('https://example.com')
    #     .formatting
    #     .run
    #
    # @example Processing multiple files with output formatting
    #   Trafilatura.new
    #     .input_dir('path/to/files')
    #     .output_dir('path/to/output')
    #     .markdown
    #     .run
    #
    # @note Requires trafilatura to be installed and available in the system PATH
    # @see https://trafilatura.readthedocs.io/en/latest/ Trafilatura documentation
    class Trafilatura
      # Initializes a new Trafilatura instance and validates that trafilatura is available
      # in the system.
      #
      # @raise [StandardError] if trafilatura is not found in the system PATH
      def initialize
        @line = Terrapin::CommandLine.new('trafilatura', ':options :source')
        @options = {}
        validate_trafilatura_available
      end

      # Specifies an input file to process
      #
      # @param [String] file_path Path to the input file
      # @return [Trafilatura] self for method chaining
      def input_file(file_path)
        @options[:'input-file'] = file_path
        self
      end

      # Specifies an input directory to process
      #
      # @param [String] dir_path Path to the input directory
      # @return [Trafilatura] self for method chaining
      def input_dir(dir_path)
        @options[:'input-dir'] = dir_path
        self
      end

      # Specifies a URL to process
      #
      # @param [String] url The URL to fetch and process
      # @return [Trafilatura] self for method chaining
      def url(url)
        @options[:URL] = url
        self
      end

      # Enables parallel processing with the specified number of workers
      #
      # @param [Integer] count Number of parallel workers to use
      # @return [Trafilatura] self for method chaining
      def parallel(count)
        @options[:parallel] = count
        self
      end

      # Specifies a blacklist file containing URLs or patterns to exclude
      #
      # @param [String] file_path Path to the blacklist file
      # @return [Trafilatura] self for method chaining
      def blacklist(file_path)
        @options[:blacklist] = file_path
        self
      end

      # Lists files without processing them
      #
      # @return [Trafilatura] self for method chaining
      def list_only
        @options[:list] = true
        self
      end

      # Specifies an output directory for processed files
      #
      # @param [String] dir_path Path to the output directory
      # @return [Trafilatura] self for method chaining
      def output_dir(dir_path)
        @options[:'output-dir'] = dir_path
        self
      end

      # Specifies a backup directory for original files
      #
      # @param [String] dir_path Path to the backup directory
      # @return [Trafilatura] self for method chaining
      def backup_dir(dir_path)
        @options[:'backup-dir'] = dir_path
        self
      end

      # Preserves directory structure in output
      #
      # @return [Trafilatura] self for method chaining
      def keep_dirs
        @options[:'keep-dirs'] = true
        self
      end

      # Processes content from a feed (RSS/Atom)
      #
      # @param [String, nil] url Optional URL of the feed to process
      # @return [Trafilatura] self for method chaining
      def feed(url=nil)
        @options[:feed] = url || true
        self
      end

      # Processes content from a sitemap
      #
      # @param [String, nil] url Optional URL of the sitemap to process
      # @return [Trafilatura] self for method chaining
      def sitemap(url=nil)
        @options[:sitemap] = url || true
        self
      end

      # Enables crawling mode with optional depth limit
      #
      # @param [Integer, nil] count Optional maximum number of pages to crawl
      # @return [Trafilatura] self for method chaining
      def crawl(count=nil)
        @options[:crawl] = count || true
        self
      end

      # Explores links found in the processed content
      #
      # @param [String, nil] url Optional base URL for exploration
      # @return [Trafilatura] self for method chaining
      def explore(url=nil)
        @options[:explore] = url || true
        self
      end

      # Probes URLs to check their availability and content type
      #
      # @param [String, nil] url Optional URL to probe
      # @return [Trafilatura] self for method chaining
      def probe(url=nil)
        @options[:probe] = url || true
        self
      end

      # Processes archived web pages
      #
      # @return [Trafilatura] self for method chaining
      def archived
        @options[:archived] = true
        self
      end

      # Filters URLs based on the provided patterns
      #
      # @param [Array<String>] patterns URL patterns to filter by
      # @return [Trafilatura] self for method chaining
      def url_filter(*patterns)
        @options[:'url-filter'] = patterns.join(' ')
        self
      end

      # Enables fast processing mode (less accurate but faster)
      #
      # @return [Trafilatura] self for method chaining
      def fast
        @options[:fast] = true
        self
      end

      # Preserves formatting in the output
      #
      # @return [Trafilatura] self for method chaining
      def formatting
        @options[:formatting] = true
        self
      end

      # Includes links in the output
      #
      # @return [Trafilatura] self for method chaining
      def links
        @options[:links] = true
        self
      end

      # Includes images in the output
      #
      # @return [Trafilatura] self for method chaining
      def images
        @options[:images] = true
        self
      end

      # Excludes comments from the output
      #
      # @return [Trafilatura] self for method chaining
      def no_comments
        @options[:'no-comments'] = true
        self
      end

      # Excludes tables from the output
      #
      # @return [Trafilatura] self for method chaining
      def no_tables
        @options[:'no-tables'] = true
        self
      end

      # Processes only documents with metadata
      #
      # @return [Trafilatura] self for method chaining
      def only_with_metadata
        @options[:'only-with-metadata'] = true
        self
      end

      # Includes metadata in the output
      #
      # @return [Trafilatura] self for method chaining
      def with_metadata
        @options[:'with-metadata'] = true
        self
      end

      # Sets the target language for content extraction
      #
      # @param [String] lang_code ISO language code (e.g., 'en', 'fr')
      # @return [Trafilatura] self for method chaining
      def target_language(lang_code)
        @options[:'target-language'] = lang_code
        self
      end

      # Enables deduplication of content
      #
      # @return [Trafilatura] self for method chaining
      def deduplicate
        @options[:deduplicate] = true
        self
      end

      # Specifies a configuration file to use
      #
      # @param [String] file_path Path to the configuration file
      # @return [Trafilatura] self for method chaining
      def config_file(file_path)
        @options[:'config-file'] = file_path
        self
      end

      # Optimizes for precision (may be slower)
      #
      # @return [Trafilatura] self for method chaining
      def precision
        @options[:precision] = true
        self
      end

      # Optimizes for recall (may be less precise)
      #
      # @return [Trafilatura] self for method chaining
      def recall
        @options[:recall] = true
        self
      end

      # Sets the output format for the processed content
      #
      # @param [String] format Output format (e.g., 'txt', 'html', 'json')
      # @return [Trafilatura] self for method chaining
      def output_format(format)
        @options[:'output-format'] = format
        self
      end

      # Sets output format to CSV
      #
      # @return [Trafilatura] self for method chaining
      def csv
        @options[:csv] = true
        self
      end

      # Sets output format to HTML
      #
      # @return [Trafilatura] self for method chaining
      def html
        @options[:html] = true
        self
      end

      # Sets output format to JSON
      #
      # @return [Trafilatura] self for method chaining
      def json
        @options[:json] = true
        self
      end

      # Sets output format to Markdown
      #
      # @return [Trafilatura] self for method chaining
      def markdown
        @options[:markdown] = true
        self
      end

      # Sets output format to XML
      #
      # @return [Trafilatura] self for method chaining
      def xml
        @options[:xml] = true
        self
      end

      # Sets output format to XML-TEI
      #
      # @return [Trafilatura] self for method chaining
      def xmltei
        @options[:xmltei] = true
        self
      end

      # Validates TEI output
      #
      # @return [Trafilatura] self for method chaining
      def validate_tei
        @options[:'validate-tei'] = true
        self
      end

      # Sets the verbosity level for output
      #
      # @param [Integer] level Verbosity level (default: 1)
      # @return [Trafilatura] self for method chaining
      def verbose(level=1)
        @options[:verbose] = level
        self
      end

      # Executes the trafilatura command with the configured options
      #
      # @param [String, nil] source_input Optional direct input string to process
      # @return [String] The output from the trafilatura command
      # @raise [StandardError] If the trafilatura command fails
      # @example Processing a URL
      #   Trafilatura.new.url('https://example.com').run
      # @example Processing a file
      #   Trafilatura.new.input_file('document.html').run
      # @example Processing direct input
      #   html_content = '<html>...</html>'
      #   Trafilatura.new.run(html_content)
      def run(source_input=nil)
        options_string = build_options_string
        if source_input
          result = @line.run(options: options_string, source: source_input)
        else
          # For cases where input is specified via options (like --input-file)
          command = Terrapin::CommandLine.new('trafilatura', ':options')
          result = command.run(options: options_string)
        end
        result
      rescue Terrapin::ExitStatusError => e
        raise StandardError, "Trafilatura failed: #{e.message}"
      end

      private

      # Validates that trafilatura is available in the system PATH
      #
      # @raise [StandardError] if trafilatura is not found
      def validate_trafilatura_available
        return if system('which trafilatura > /dev/null 2>&1')

        raise StandardError, 'trafilatura CLI not found. Install with: pip install trafilatura'
      end

      # Builds the options string for the trafilatura command
      #
      # @return [String] The constructed options string
      def build_options_string
        options_parts = []
        @options.each do |key, value|
          flag = "--#{key.to_s.tr('_', '-')}"

          if value.is_a?(TrueClass)
            options_parts << flag
          elsif value.is_a?(FalseClass)
            # Skip false values
            next
          elsif value && value != true
            options_parts << "#{flag} #{value}"
          end
        end
        options_parts.join(' ')
      end
    end
  end
end
