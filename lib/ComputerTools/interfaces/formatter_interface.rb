# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # FormatterInterface defines the contract for data formatting operations.
    #
    # This interface specifies the methods that any formatter implementation
    # must provide for converting data between different output formats.
    #
    # @example Implementing the interface
    #   class MyDataFormatter
    #     include ComputerTools::Interfaces::FormatterInterface
    #     
    #     def format_data(data, format)
    #       # Implementation here
    #     end
    #     
    #     # ... other interface methods
    #   end
    module FormatterInterface
      ##
      # Formats data into the specified output format.
      #
      # @abstract
      # @param data [Hash, Array, Object] The data to format
      # @param format [String, Symbol] The desired output format
      # @return [String] The formatted output
      # @raise [NotImplementedError] if not implemented
      def format_data(data, format)
        raise NotImplementedError, "#{self.class} must implement #format_data"
      end

      ##
      # Converts data to JSON format.
      #
      # @abstract
      # @param data [Hash, Array, Object] The data to convert
      # @return [String] JSON formatted string
      # @raise [NotImplementedError] if not implemented
      def to_json(data = nil)
        raise NotImplementedError, "#{self.class} must implement #to_json"
      end

      ##
      # Converts data to Markdown format.
      #
      # @abstract
      # @param data [Hash, Array, Object] The data to convert
      # @return [String] Markdown formatted string
      # @raise [NotImplementedError] if not implemented
      def to_markdown(data = nil)
        raise NotImplementedError, "#{self.class} must implement #to_markdown"
      end

      ##
      # Returns the list of supported output formats.
      #
      # @abstract
      # @return [Array<String>] Array of supported format names
      # @raise [NotImplementedError] if not implemented
      def supported_formats
        raise NotImplementedError, "#{self.class} must implement #supported_formats"
      end

      ##
      # Checks if the specified format is supported.
      #
      # @abstract
      # @param format [String, Symbol] The format to check
      # @return [Boolean] true if format is supported, false otherwise
      # @raise [NotImplementedError] if not implemented
      def supports_format?(format)
        raise NotImplementedError, "#{self.class} must implement #supports_format?"
      end

      ##
      # Returns the default format for this formatter.
      #
      # @abstract
      # @return [String] The default format name
      # @raise [NotImplementedError] if not implemented
      def default_format
        raise NotImplementedError, "#{self.class} must implement #default_format"
      end
    end
  end
end