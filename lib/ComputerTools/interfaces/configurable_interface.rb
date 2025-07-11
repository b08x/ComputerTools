# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # ConfigurableInterface defines the contract for fluent configuration builders.
    #
    # This interface specifies the methods that any configurable wrapper implementation
    # must provide for fluent configuration and execution patterns, commonly used
    # by CLI tool wrappers that support method chaining.
    #
    # @example Implementing the interface
    #   class MyConfigurableWrapper
    #     include ComputerTools::Interfaces::ConfigurableInterface
    #     
    #     def configure
    #       # Implementation here
    #       self
    #     end
    #     
    #     def run(input)
    #       # Implementation here
    #     end
    #     
    #     # ... other interface methods
    #   end
    module ConfigurableInterface
      ##
      # Configures the wrapper with a block for fluent interface.
      #
      # @abstract
      # @yield [self] Yields self to the block for configuration
      # @return [self] Returns self for method chaining
      # @raise [NotImplementedError] if not implemented
      def configure(&block)
        raise NotImplementedError, "#{self.class} must implement #configure"
      end

      ##
      # Executes the configured operation on the given input.
      #
      # @abstract
      # @param input [String, Hash, Object] The input to process
      # @return [String, Hash, Object] The processed output
      # @raise [NotImplementedError] if not implemented
      def run(input)
        raise NotImplementedError, "#{self.class} must implement #run"
      end

      ##
      # Resets the configuration to default values.
      #
      # @abstract
      # @return [self] Returns self for method chaining
      # @raise [NotImplementedError] if not implemented
      def reset
        raise NotImplementedError, "#{self.class} must implement #reset"
      end

      ##
      # Validates the current configuration.
      #
      # @abstract
      # @return [Boolean] true if configuration is valid, false otherwise
      # @raise [NotImplementedError] if not implemented
      def valid?
        raise NotImplementedError, "#{self.class} must implement #valid?"
      end

      ##
      # Returns the current configuration as a hash.
      #
      # @abstract
      # @return [Hash] The current configuration options
      # @raise [NotImplementedError] if not implemented
      def to_hash
        raise NotImplementedError, "#{self.class} must implement #to_hash"
      end
    end
  end
end