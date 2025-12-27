# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # ProcessorInterface defines the contract for data processing operations.
    #
    # This interface specifies the methods that any data processor implementation
    # must provide for processing input data and generating various output formats.
    #
    # @example Implementing the interface
    #   class MyDataProcessor
    #     include ComputerTools::Interfaces::ProcessorInterface
    #
    #     def process(input)
    #       # Implementation here
    #     end
    #
    #     # ... other interface methods
    #   end
    module ProcessorInterface
      ##
      # Processes input data and returns the processed result.
      #
      # @abstract
      # @param input [String, Hash, Object] The input data to process
      # @return [String, Hash, Object] The processed output
      # @raise [NotImplementedError] if not implemented
      def process(input)
        raise NotImplementedError, "#{self.class} must implement #process"
      end

      ##
      # Checks if the processor can handle the given input type.
      #
      # @abstract
      # @param input [String, Hash, Object] The input to check
      # @return [Boolean] true if the input can be processed, false otherwise
      # @raise [NotImplementedError] if not implemented
      def can_process?(input)
        raise NotImplementedError, "#{self.class} must implement #can_process?"
      end

      ##
      # Returns the supported input formats.
      #
      # @abstract
      # @return [Array<String>] Array of supported input format names
      # @raise [NotImplementedError] if not implemented
      def supported_input_formats
        raise NotImplementedError, "#{self.class} must implement #supported_input_formats"
      end

      ##
      # Returns the supported output formats.
      #
      # @abstract
      # @return [Array<String>] Array of supported output format names
      # @raise [NotImplementedError] if not implemented
      def supported_output_formats
        raise NotImplementedError, "#{self.class} must implement #supported_output_formats"
      end
    end
  end
end