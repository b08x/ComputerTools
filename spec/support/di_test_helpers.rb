# frozen_string_literal: true

require_relative 'test_container'

# Dependency Injection test helpers for RSpec
#
# Provides utilities for testing components that use dependency injection,
# including container isolation, mock registration, and test patterns.
module DITestHelpers
  # Executes a test block with an isolated test container
  #
  # Creates a new test container, temporarily replaces the main application
  # container, and ensures cleanup after the test completes.
  #
  # @yield [ComputerTools::TestContainer] the isolated test container
  # @return [Object] the result of the block execution
  #
  # @example Using with_test_container
  #   with_test_container do |container|
  #     container.register_mock('git_wrapper', mock_git)
  #     action = MyAction.new(container)
  #     action.execute
  #   end
  def with_test_container(&block)
    original_container = ComputerTools.container
    test_container = ComputerTools::TestContainer.new_instance
    
    # Replace the main container temporarily
    ComputerTools.instance_variable_set(:@container, test_container)
    
    yield(test_container)
  ensure
    # Restore the original container
    ComputerTools.instance_variable_set(:@container, original_container)
    test_container.reset! if test_container.respond_to?(:reset!)
  end

  # Registers a mock dependency in the current container
  #
  # @param name [String, Symbol] the dependency name
  # @param mock_object [Object] the mock object to register
  # @return [Object] the registered mock object
  def mock_dependency(name, mock_object)
    ComputerTools.container.register(name.to_s) { mock_object }
    mock_object
  end

  # Creates and registers a test double with method expectations
  #
  # @param name [String, Symbol] the dependency name
  # @param expectations [Hash] method name to return value mappings
  # @return [Object] the created test double
  #
  # @example
  #   register_test_double('git_wrapper', {
  #     commit: true,
  #     current_branch: 'main',
  #     dirty?: false
  #   })
  def register_test_double(name, expectations = {})
    test_double = double(name.to_s)
    expectations.each do |method, return_value|
      allow(test_double).to receive(method).and_return(return_value)
    end
    mock_dependency(name, test_double)
  end

  # Creates and registers a spy for testing method calls
  #
  # @param name [String, Symbol] the dependency name
  # @param base_methods [Array<Symbol>] methods to stub initially
  # @return [Object] the created spy
  def register_spy(name, base_methods = [])
    test_spy = spy(name.to_s)
    base_methods.each do |method|
      allow(test_spy).to receive(method)
    end
    mock_dependency(name, test_spy)
  end

  # Creates a test configuration object with specified values
  #
  # @param config_class [Class] the configuration class to instantiate
  # @param overrides [Hash] configuration values to override
  # @return [Object] configured test configuration object
  def create_test_config(config_class, overrides = {})
    config = config_class.new
    overrides.each do |key, value|
      config.configure { |c| c.public_send("#{key}=", value) }
    end
    config
  end

  # Sets up a minimal container with essential dependencies
  #
  # Registers basic mocks for common dependencies to enable testing
  # without full application initialization.
  #
  # @param container [Dry::Container::Mixin] the container to setup
  # @return [Hash] hash of registered mock objects
  def setup_minimal_container(container = ComputerTools.container)
    mocks = {}
    
    # Mock logger
    mocks[:logger] = double('logger')
    allow(mocks[:logger]).to receive(:info)
    allow(mocks[:logger]).to receive(:debug)
    allow(mocks[:logger]).to receive(:warn)
    allow(mocks[:logger]).to receive(:error)
    container.register('logger') { mocks[:logger] }

    # Mock configuration
    mocks[:configuration] = double('configuration')
    allow(mocks[:configuration]).to receive(:fetch).and_return(nil)
    container.register('configuration') { mocks[:configuration] }

    mocks
  end

  # Verifies that a dependency injection is working correctly
  #
  # @param object [Object] the object to test
  # @param dependency_name [String, Symbol] the name of the dependency
  # @param expected_class [Class] the expected class of the dependency
  # @return [Boolean] true if verification passes
  def verify_dependency_injection(object, dependency_name, expected_class = nil)
    dependency = object.instance_variable_get("@#{dependency_name}")
    
    return false if dependency.nil?
    return true if expected_class.nil?
    
    dependency.is_a?(expected_class)
  end

  # Creates a factory for test objects with injected dependencies
  #
  # @param klass [Class] the class to instantiate
  # @param dependencies [Hash] dependency name to object mappings
  # @return [Object] instantiated object with injected dependencies
  def create_with_dependencies(klass, dependencies = {})
    # If the class has a constructor that accepts dependencies
    if dependencies.any?
      # Try keyword arguments first
      begin
        klass.new(**dependencies)
      rescue ArgumentError
        # Fall back to positional arguments
        klass.new(*dependencies.values)
      end
    else
      klass.new
    end
  end

  # Asserts that an object implements a specific interface
  #
  # @param object [Object] the object to check
  # @param interface_module [Module] the interface module
  # @return [Boolean] true if object implements the interface
  # @raise [RSpec::Expectations::ExpectationNotMetError] if interface not implemented
  def expect_interface_implementation(object, interface_module)
    expect(object).to be_a(interface_module)
    
    # Verify all interface methods are implemented
    if interface_module.respond_to?(:required_methods)
      interface_module.required_methods.each do |method_name|
        expect(object).to respond_to(method_name)
      end
    end
  end

  # Checks if container can resolve all specified dependencies
  #
  # @param dependency_names [Array<String, Symbol>] list of dependency names
  # @param container [Dry::Container::Mixin] container to check (default: current)
  # @return [Boolean] true if all dependencies can be resolved
  def container_can_resolve_all?(dependency_names, container = ComputerTools.container)
    dependency_names.all? do |name|
      container.registered?(name.to_s) && !container[name.to_s].nil?
    end
  end

  # Generates a report of container registrations for debugging
  #
  # @param container [Dry::Container::Mixin] container to inspect
  # @return [Hash] detailed report of container state
  def container_report(container = ComputerTools.container)
    {
      registered_count: container.keys.length,
      registered_keys: container.keys.sort,
      sample_resolutions: container.keys.first(3).map do |key|
        begin
          { key => container[key].class.name }
        rescue => e
          { key => "Error: #{e.message}" }
        end
      end.reduce({}, :merge)
    }
  end
end