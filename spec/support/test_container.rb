# frozen_string_literal: true

require 'dry-container'

module ComputerTools
  # Test container for isolated dependency injection testing
  #
  # Provides a separate container instance for testing that doesn't interfere
  # with the main application container. Supports easy registration of test
  # doubles and automatic cleanup between tests.
  class TestContainer
    # Add helper methods via module extension
    module HelperMethods
      def registered?(key)
        key?(key.to_s)
      end
      
      def register_mock(name, mock_object)
        register(name.to_s) { mock_object }
      end

      def register_double(name, expectations = {})
        double_object = RSpec::Mocks::Double.new(name.to_s)
        expectations.each do |method, return_value|
          double_object.as_null_object
          allow(double_object).to receive(method).and_return(return_value)
        end
        register(name.to_s) { double_object }
        double_object
      end

      def register_spy(name, base_methods = [])
        spy_object = RSpec::Mocks::Double.new(name.to_s)
        spy_object.as_null_object
        base_methods.each do |method|
          allow(spy_object).to receive(method)
        end
        register(name.to_s) { spy_object }
        spy_object
      end
      
      def verify_registrations(required_keys)
        missing_keys = required_keys.reject { |key| registered?(key) }
        
        if missing_keys.any?
          raise StandardError, "Missing required dependencies: #{missing_keys.join(', ')}"
        end
        
        true
      end

      def stats
        {
          registered_count: keys.length,
          keys: keys.sort
        }
      end
      
      def copy_registrations_from(source_container, keys_param = nil)
        keys_to_copy = keys_param || source_container.keys
        keys_to_copy.each do |key|
          next unless source_container.respond_to?(:registered?) ? source_container.registered?(key) : source_container.key?(key)
          
          register(key) { source_container[key] }
        end
      end
      
      def empty?
        keys.empty?
      end
      
      def reset!
        # Since Dry::Container doesn't have a delete method,
        # we'll create a new container and replace the internal storage
        initialize
      end
    end

    # Enhanced new_instance that includes helper methods
    def self.new_instance
      container = Dry::Container.new
      container.extend(HelperMethods)
      container
    end
  end
end