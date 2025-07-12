# frozen_string_literal: true

# Custom RSpec matchers for dependency injection testing
#
# These matchers provide convenient assertions for testing DI-related functionality

# Matcher to test if an object can be resolved from the container
#
# @example
#   expect('git_wrapper').to be_resolvable_from_container
#   expect('git_wrapper').to be_resolvable_from_container(test_container)
RSpec::Matchers.define :be_resolvable_from_container do |container = nil|
  match do |dependency_key|
    test_container = container || ComputerTools.container
    test_container.registered?(dependency_key.to_s) && !test_container[dependency_key.to_s].nil?
  rescue => e
    @error = e
    false
  end

  failure_message do |dependency_key|
    container_name = container ? 'provided container' : 'ComputerTools.container'
    if @error
      "expected '#{dependency_key}' to be resolvable from #{container_name}, but got error: #{@error.message}"
    else
      "expected '#{dependency_key}' to be resolvable from #{container_name}, but it was not registered or returned nil"
    end
  end

  failure_message_when_negated do |dependency_key|
    container_name = container ? 'provided container' : 'ComputerTools.container'
    "expected '#{dependency_key}' not to be resolvable from #{container_name}, but it was"
  end

  description do
    container_name = container ? 'provided container' : 'ComputerTools.container'
    "be resolvable from #{container_name}"
  end
end

# Matcher to test if an object implements a specific interface
#
# @example
#   expect(git_wrapper).to implement_interface(ComputerTools::Interfaces::GitInterface)
RSpec::Matchers.define :implement_interface do |interface_module|
  match do |object|
    return false unless object.is_a?(interface_module)
    
    # Check if interface validation exists and use it
    if defined?(ComputerTools::Interfaces::Validation)
      interface_name = interface_module.name.split('::').last.downcase.gsub('interface', '')
      validation_method = "implements_#{interface_name}_interface?"
      
      if ComputerTools::Interfaces::Validation.respond_to?(validation_method)
        return ComputerTools::Interfaces::Validation.public_send(validation_method, object)
      end
    end
    
    true
  end

  failure_message do |object|
    "expected #{object.class} to implement #{interface_module}, but it does not"
  end

  failure_message_when_negated do |object|
    "expected #{object.class} not to implement #{interface_module}, but it does"
  end

  description do
    "implement #{interface_module}"
  end
end

# Matcher to test if an object has proper dependency injection setup
#
# @example
#   expect(action_instance).to have_dependency_injection_for(:git_wrapper)
#   expect(action_instance).to have_dependency_injection_for('logger', String)
RSpec::Matchers.define :have_dependency_injection_for do |dependency_name, expected_type = nil|
  match do |object|
    # Check for instance variable
    ivar_name = "@#{dependency_name}"
    dependency = object.instance_variable_get(ivar_name)
    
    return false if dependency.nil?
    return true if expected_type.nil?
    
    dependency.is_a?(expected_type)
  end

  failure_message do |object|
    ivar_name = "@#{dependency_name}"
    dependency = object.instance_variable_get(ivar_name)
    
    if dependency.nil?
      "expected #{object.class} to have dependency injection for #{dependency_name}, but #{ivar_name} was nil"
    elsif expected_type && !dependency.is_a?(expected_type)
      "expected #{object.class} to have #{dependency_name} of type #{expected_type}, but got #{dependency.class}"
    else
      "expected #{object.class} to have dependency injection for #{dependency_name}"
    end
  end

  failure_message_when_negated do |object|
    "expected #{object.class} not to have dependency injection for #{dependency_name}, but it does"
  end

  description do
    desc = "have dependency injection for #{dependency_name}"
    desc += " of type #{expected_type}" if expected_type
    desc
  end
end

# Matcher to test if a container has all required registrations
#
# @example
#   expect(container).to have_all_registrations(['git_wrapper', 'logger', 'config'])
RSpec::Matchers.define :have_all_registrations do |required_keys|
  match do |container|
    @missing_keys = required_keys.reject { |key| container.registered?(key.to_s) }
    @missing_keys.empty?
  end

  failure_message do |container|
    "expected container to have all required registrations, but missing: #{@missing_keys.join(', ')}"
  end

  failure_message_when_negated do |container|
    "expected container not to have all required registrations, but it does"
  end

  description do
    "have all required registrations: #{required_keys.join(', ')}"
  end
end

# Matcher to test configuration object behavior
#
# @example
#   expect(config).to be_valid_configuration
#   expect(config).to be_valid_configuration.with_settings([:level, :path])
RSpec::Matchers.define :be_valid_configuration do
  chain :with_settings do |required_settings|
    @required_settings = required_settings
  end

  match do |config_object|
    return false unless config_object.respond_to?(:config)
    
    if @required_settings
      @missing_settings = @required_settings.reject do |setting|
        config_object.config.respond_to?(setting)
      end
      return false unless @missing_settings.empty?
    end
    
    # Test validation if available
    if config_object.respond_to?(:validate!)
      begin
        config_object.validate!
        true
      rescue => e
        @validation_error = e
        false
      end
    else
      true
    end
  end

  failure_message do |config_object|
    if @validation_error
      "expected #{config_object.class} to be a valid configuration, but validation failed: #{@validation_error.message}"
    elsif @missing_settings && @missing_settings.any?
      "expected #{config_object.class} to have settings #{@required_settings.join(', ')}, but missing: #{@missing_settings.join(', ')}"
    else
      "expected #{config_object.class} to be a valid configuration, but it was not"
    end
  end

  failure_message_when_negated do |config_object|
    "expected #{config_object.class} not to be a valid configuration, but it was"
  end

  description do
    desc = "be a valid configuration"
    desc += " with settings #{@required_settings.join(', ')}" if @required_settings
    desc
  end
end

# Matcher to test if dependencies can be mocked properly
#
# @example
#   expect(MyClass).to be_mockable_with_dependencies(['git_wrapper', 'logger'])
RSpec::Matchers.define :be_mockable_with_dependencies do |dependency_names|
  include DITestHelpers

  match do |klass|
    with_test_container do |container|
      # Register mocks for all dependencies
      dependency_names.each do |dep_name|
        container.register_mock(dep_name, double(dep_name))
      end

      # Try to create instance with mocked dependencies
      begin
        dependencies = dependency_names.map { |name| [name.to_sym, container[name]] }.to_h
        instance = create_with_dependencies(klass, dependencies)
        
        # Verify dependencies were injected
        dependency_names.all? do |dep_name|
          verify_dependency_injection(instance, dep_name)
        end
      rescue => e
        @error = e
        false
      end
    end
  end

  failure_message do |klass|
    if @error
      "expected #{klass} to be mockable with dependencies #{dependency_names.join(', ')}, but got error: #{@error.message}"
    else
      "expected #{klass} to be mockable with dependencies #{dependency_names.join(', ')}, but dependency injection failed"
    end
  end

  failure_message_when_negated do |klass|
    "expected #{klass} not to be mockable with dependencies #{dependency_names.join(', ')}, but it was"
  end

  description do
    "be mockable with dependencies: #{dependency_names.join(', ')}"
  end
end