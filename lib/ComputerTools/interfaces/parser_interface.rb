# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # ParserInterface defines the contract for data parsing operations.
    #
    # This interface specifies the methods that any parser implementation
    # must provide for parsing structured data and extracting specific information.
    #
    # @example Implementing the interface
    #   class MyDataParser
    #     include ComputerTools::Interfaces::ParserInterface
    #     
    #     def parse_data(input)
    #       # Implementation here
    #     end
    #     
    #     # ... other interface methods
    #   end
    module ParserInterface
      ##
      # Parses the input data and extracts structured information.
      #
      # @abstract
      # @param input [String, Hash, Object] The input data to parse
      # @return [Hash, Array, Object] The parsed and structured data
      # @raise [NotImplementedError] if not implemented
      def parse_data(input)
        raise NotImplementedError, "#{self.class} must implement #parse_data"
      end

      ##
      # Extracts specific fields from the parsed data.
      #
      # @abstract
      # @param fields [Array<String, Symbol>] The fields to extract
      # @return [Array<Hash>] Array of hashes containing the extracted fields
      # @raise [NotImplementedError] if not implemented
      def extract_fields(fields)
        raise NotImplementedError, "#{self.class} must implement #extract_fields"
      end

      ##
      # Returns available field names that can be extracted.
      #
      # @abstract
      # @return [Array<String>] Array of available field names
      # @raise [NotImplementedError] if not implemented
      def available_fields
        raise NotImplementedError, "#{self.class} must implement #available_fields"
      end

      ##
      # Validates that the input data has the expected format.
      #
      # @abstract
      # @param input [String, Hash, Object] The input data to validate
      # @return [Boolean] true if data format is valid, false otherwise
      # @raise [NotImplementedError] if not implemented
      def valid_format?(input)
        raise NotImplementedError, "#{self.class} must implement #valid_format?"
      end

      ##
      # Returns summary statistics about the parsed data.
      #
      # @abstract
      # @return [Hash] A hash containing statistics about the parsed data
      # @raise [NotImplementedError] if not implemented
      def summary_stats
        raise NotImplementedError, "#{self.class} must implement #summary_stats"
      end

      ##
      # Returns the raw, unparsed data.
      #
      # @abstract
      # @return [Object] The original raw data
      # @raise [NotImplementedError] if not implemented
      def raw_data
        raise NotImplementedError, "#{self.class} must implement #raw_data"
      end
    end
  end
end