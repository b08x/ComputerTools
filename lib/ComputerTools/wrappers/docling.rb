# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # A Terrapin-based DSL wrapper for the docling CLI tool that provides a fluent interface
    # for converting documents between formats and processing them with various options.
    #
    # This class abstracts the docling command-line interface into a Ruby-friendly builder pattern,
    # allowing for method chaining to configure document processing options.
    #
    # @example Basic usage converting a PDF to Markdown
    #   runner = Docling.new
    #     .from_format('pdf')
    #     .to_markdown
    #     .run('document.pdf')
    #
    # @example Advanced usage with multiple options
    #   runner = Docling.new
    #     .from_format('docx')
    #     .to_html
    #     .image_embedded
    #     .ocr(true)
    #     .verbose(2)
    #     .run('document.docx')
    class Docling
      # Initializes a new Docling instance and validates that the docling CLI is available.
      #
      # @raise [StandardError] if docling CLI is not found in the system path
      def initialize
        @line = Terrapin::CommandLine.new('docling', ':options :source')
        @options = {}
        validate_docling_available
      end

      # Specifies the input document format.
      #
      # @param [String] format The input format (e.g., 'pdf', 'docx')
      # @return [Docling] self for method chaining
      def from_format(format)
        @options[:from] = format
        self
      end

      # Specifies the output document format.
      #
      # @param [String] format The output format (e.g., 'md', 'html')
      # @return [Docling] self for method chaining
      def to_format(format)
        @options[:to] = format
        self
      end

      # Sets the output format to Markdown.
      #
      # @return [Docling] self for method chaining
      def to_markdown
        @options[:to] = 'md'
        self
      end

      # Sets the output format to JSON.
      #
      # @return [Docling] self for method chaining
      def to_json(*_args)
        @options[:to] = 'json'
        self
      end

      # Sets the output format to HTML.
      #
      # @return [Docling] self for method chaining
      def to_html
        @options[:to] = 'html'
        self
      end

      # Sets the output format to plain text.
      #
      # @return [Docling] self for method chaining
      def to_text
        @options[:to] = 'text'
        self
      end

      # Enables or disables layout visualization in the output.
      #
      # @param [Boolean] enabled Whether to show layout (default: true)
      # @return [Docling] self for method chaining
      def show_layout(enabled=true)
        @options[:'show-layout'] = enabled
        self
      end

      # Sets HTTP headers for URL sources.
      #
      # @param [String] headers_json JSON string containing HTTP headers
      # @return [Docling] self for method chaining
      def headers(headers_json)
        @options[:headers] = headers_json
        self
      end

      # Sets the image export mode with a specific value.
      #
      # @param [String] mode The export mode ('placeholder', 'embedded', or 'referenced')
      # @return [Docling] self for method chaining
      def image_export_mode(mode)
        @options[:'image-export-mode'] = mode
        self
      end

      # Sets image export mode to use placeholders.
      #
      # @return [Docling] self for method chaining
      def image_placeholder
        @options[:'image-export-mode'] = 'placeholder'
        self
      end

      # Sets image export mode to embed images directly.
      #
      # @return [Docling] self for method chaining
      def image_embedded
        @options[:'image-export-mode'] = 'embedded'
        self
      end

      # Sets image export mode to reference external image files.
      #
      # @return [Docling] self for method chaining
      def image_referenced
        @options[:'image-export-mode'] = 'referenced'
        self
      end

      # Sets the processing pipeline type.
      #
      # @param [String] type The pipeline type ('standard', 'vlm', or 'asr')
      # @return [Docling] self for method chaining
      def pipeline(type)
        @options[:pipeline] = type
        self
      end

      # Sets the pipeline to use the standard processing pipeline.
      #
      # @return [Docling] self for method chaining
      def standard_pipeline
        @options[:pipeline] = 'standard'
        self
      end

      # Sets the pipeline to use the VLM (Vision-Language Model) pipeline.
      #
      # @return [Docling] self for method chaining
      def vlm_pipeline
        @options[:pipeline] = 'vlm'
        self
      end

      # Sets the pipeline to use the ASR (Automatic Speech Recognition) pipeline.
      #
      # @return [Docling] self for method chaining
      def asr_pipeline
        @options[:pipeline] = 'asr'
        self
      end

      # Sets the VLM model to use for processing.
      #
      # @param [String] model The VLM model identifier
      # @return [Docling] self for method chaining
      def vlm_model(model)
        @options[:'vlm-model'] = model
        self
      end

      # Sets the ASR model to use for processing.
      #
      # @param [String] model The ASR model identifier
      # @return [Docling] self for method chaining
      def asr_model(model)
        @options[:'asr-model'] = model
        self
      end

      # Enables or disables OCR (Optical Character Recognition).
      #
      # @param [Boolean] enabled Whether to enable OCR (default: true)
      # @return [Docling] self for method chaining
      def ocr(enabled=true)
        @options[:ocr] = enabled
        self
      end

      # Enables or disables forced OCR processing.
      #
      # @param [Boolean] enabled Whether to force OCR (default: true)
      # @return [Docling] self for method chaining
      def force_ocr(enabled=true)
        @options[:'force-ocr'] = enabled
        self
      end

      # Sets the OCR engine to use.
      #
      # @param [String] engine The OCR engine identifier
      # @return [Docling] self for method chaining
      def ocr_engine(engine)
        @options[:'ocr-engine'] = engine
        self
      end

      # Sets the languages for OCR processing.
      #
      # @param [String, Array<String>] languages Language codes for OCR
      # @return [Docling] self for method chaining
      def ocr_lang(languages)
        @options[:'ocr-lang'] = languages
        self
      end

      # Sets the PDF backend to use for processing.
      #
      # @param [String] backend The PDF backend identifier
      # @return [Docling] self for method chaining
      def pdf_backend(backend)
        @options[:'pdf-backend'] = backend
        self
      end

      # Sets the table processing mode.
      #
      # @param [String] mode The table processing mode ('fast' or 'accurate')
      # @return [Docling] self for method chaining
      def table_mode(mode)
        @options[:'table-mode'] = mode
        self
      end

      # Sets table processing to fast mode.
      #
      # @return [Docling] self for method chaining
      def table_fast
        @options[:'table-mode'] = 'fast'
        self
      end

      # Sets table processing to accurate mode.
      #
      # @return [Docling] self for method chaining
      def table_accurate
        @options[:'table-mode'] = 'accurate'
        self
      end

      # Enables or disables code enrichment in the output.
      #
      # @param [Boolean] enabled Whether to enrich code (default: true)
      # @return [Docling] self for method chaining
      def enrich_code(enabled=true)
        @options[:'enrich-code'] = enabled
        self
      end

      # Enables or disables formula enrichment in the output.
      #
      # @param [Boolean] enabled Whether to enrich formulas (default: true)
      # @return [Docling] self for method chaining
      def enrich_formula(enabled=true)
        @options[:'enrich-formula'] = enabled
        self
      end

      # Enables or disables picture class enrichment in the output.
      #
      # @param [Boolean] enabled Whether to enrich picture classes (default: true)
      # @return [Docling] self for method chaining
      def enrich_picture_classes(enabled=true)
        @options[:'enrich-picture-classes'] = enabled
        self
      end

      # Enables or disables picture description enrichment in the output.
      #
      # @param [Boolean] enabled Whether to enrich picture descriptions (default: true)
      # @return [Docling] self for method chaining
      def enrich_picture_description(enabled=true)
        @options[:'enrich-picture-description'] = enabled
        self
      end

      # Sets the path for storing processing artifacts.
      #
      # @param [String] path The directory path for artifacts
      # @return [Docling] self for method chaining
      def artifacts_path(path)
        @options[:'artifacts-path'] = path
        self
      end

      # Enables or disables remote services.
      #
      # @param [Boolean] enabled Whether to enable remote services (default: true)
      # @return [Docling] self for method chaining
      def enable_remote_services(enabled=true)
        @options[:'enable-remote-services'] = enabled
        self
      end

      # Enables or disables external plugins.
      #
      # @param [Boolean] enabled Whether to allow external plugins (default: true)
      # @return [Docling] self for method chaining
      def allow_external_plugins(enabled=true)
        @options[:'allow-external-plugins'] = enabled
        self
      end

      # Enables or disables showing external plugins.
      #
      # @param [Boolean] enabled Whether to show external plugins (default: true)
      # @return [Docling] self for method chaining
      def show_external_plugins(enabled=true)
        @options[:'show-external-plugins'] = enabled
        self
      end

      # Enables or disables aborting on errors.
      #
      # @param [Boolean] enabled Whether to abort on errors (default: true)
      # @return [Docling] self for method chaining
      def abort_on_error(enabled=true)
        @options[:'abort-on-error'] = enabled
        self
      end

      # Sets the output directory for processed files.
      #
      # @param [String] path The output directory path
      # @return [Docling] self for method chaining
      def output_dir(path)
        @options[:output] = path
        self
      end

      # Sets the verbosity level for processing.
      #
      # @param [Integer] level The verbosity level (default: 1)
      # @return [Docling] self for method chaining
      def verbose(level=1)
        @options[:verbose] = level
        self
      end

      # Enables or disables cell visualization debugging.
      #
      # @param [Boolean] enabled Whether to visualize cells (default: true)
      # @return [Docling] self for method chaining
      def debug_visualize_cells(enabled=true)
        @options[:'debug-visualize-cells'] = enabled
        self
      end

      # Enables or disables OCR visualization debugging.
      #
      # @param [Boolean] enabled Whether to visualize OCR (default: true)
      # @return [Docling] self for method chaining
      def debug_visualize_ocr(enabled=true)
        @options[:'debug-visualize-ocr'] = enabled
        self
      end

      # Enables or disables layout visualization debugging.
      #
      # @param [Boolean] enabled Whether to visualize layout (default: true)
      # @return [Docling] self for method chaining
      def debug_visualize_layout(enabled=true)
        @options[:'debug-visualize-layout'] = enabled
        self
      end

      # Enables or disables table visualization debugging.
      #
      # @param [Boolean] enabled Whether to visualize tables (default: true)
      # @return [Docling] self for method chaining
      def debug_visualize_tables(enabled=true)
        @options[:'debug-visualize-tables'] = enabled
        self
      end

      # Sets the document processing timeout in seconds.
      #
      # @param [Integer] seconds The timeout duration in seconds
      # @return [Docling] self for method chaining
      def document_timeout(seconds)
        @options[:'document-timeout'] = seconds
        self
      end

      # Sets the number of threads to use for processing.
      #
      # @param [Integer] count The number of threads
      # @return [Docling] self for method chaining
      def num_threads(count)
        @options[:'num-threads'] = count
        self
      end

      # Sets the processing device to use.
      #
      # @param [String] device_type The device type ('cpu', 'cuda', or 'auto')
      # @return [Docling] self for method chaining
      def device(device_type)
        @options[:device] = device_type
        self
      end

      # Sets the processing device to use CPU.
      #
      # @return [Docling] self for method chaining
      def use_cpu
        @options[:device] = 'cpu'
        self
      end

      # Sets the processing device to use CUDA.
      #
      # @return [Docling] self for method chaining
      def use_cuda
        @options[:device] = 'cuda'
        self
      end

      # Sets the processing device to auto-detect.
      #
      # @return [Docling] self for method chaining
      def use_auto
        @options[:device] = 'auto'
        self
      end

      # Executes the configured docling command on the specified source file.
      #
      # @param [String] source_path The path to the source document to process
      # @return [String] The processed output from docling
      # @raise [StandardError] If the docling command fails to execute
      # @example Processing a PDF document
      #   runner = Docling.new.to_markdown
      #   result = runner.run('document.pdf')
      def run(source_path)
        options_string = build_options_string
        @line.run(options: options_string, source: source_path)
      rescue Terrapin::ExitStatusError => e
        raise StandardError, "Docling failed: #{e.message}"
      end

      private

      # Validates that the docling CLI is available in the system path.
      #
      # @raise [StandardError] if docling is not found
      def validate_docling_available
        return if system('which docling > /dev/null 2>&1')

        raise StandardError, 'docling CLI not found. Install with: pip install docling'
      end

      # Builds the options string for the docling command from the configured options.
      #
      # @return [String] The formatted options string
      def build_options_string
        options_parts = []
        @options.each do |key, value|
          flag = "--#{key.to_s.tr('_', '-')}"
          if value.is_a?(TrueClass)
            options_parts << flag
          elsif value.is_a?(FalseClass)
            options_parts << "--no-#{key.to_s.tr('_', '-')}"
          elsif value
            options_parts << "#{flag} #{value}"
          end
        end
        options_parts.join(' ')
      end
    end

    # Processes various document formats into standardized outputs.
    #
    # This class handles the conversion of supported document formats (PDF, DOCX, etc.)
    # into processed outputs using the Docling.
    #
    # @example Processing a document file
    #   processor = FilesDB::Processors::Document.new
    #   result = processor.process('document.pdf')
    class Document
      # Processes a document file based on its extension.
      #
      # @param [String] file_path The path to the document file to process
      # @return [String] The processed document content, or empty string on failure
      # @example Processing a PDF file
      #   processor = FilesDB::Processors::Document.new
      #   markdown = processor.process('report.pdf')
      def process(file_path)
        unless File.exist?(file_path)
          log_error("File not found: #{file_path}")
          return ''
        end

        case File.extname(file_path).downcase
        when '.pdf', '.docx', '.doc', '.odt'
          process_with_docling(file_path)
        else
          log_error("Unsupported document format: #{file_path}")
          ''
        end
      end

      private

      # Processes a document file using the Docling with default settings.
      #
      # @param [String] file_path The path to the document file to process
      # @return [String] The processed document content
      def process_with_docling(file_path)
        runner = Docling.new
          .to_markdown
          .image_referenced
          .table_accurate
          .ocr(true)

        runner.run(file_path)
      rescue StandardError => e
        log_error("Failed to process document #{file_path}: #{e.message}")
        ''
      end

      # Simple logging method
      def log_error(message)
        puts "❌ #{message}".colorize(:red)
      end
    end
  end
end
