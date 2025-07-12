# Dependency Injection Testing Guide

This guide explains how to write tests for components that use dependency injection in the ComputerTools application.

## Table of Contents

1. [Overview](#overview)
2. [Testing Infrastructure](#testing-infrastructure)
3. [Basic Testing Patterns](#basic-testing-patterns)
4. [Advanced Testing Techniques](#advanced-testing-techniques)
5. [Custom Matchers](#custom-matchers)
6. [Shared Examples](#shared-examples)
7. [Best Practices](#best-practices)
8. [Common Patterns](#common-patterns)

## Overview

The ComputerTools application uses dependency injection (DI) to improve testability, maintainability, and loose coupling. This testing framework provides utilities to make testing DI components straightforward and consistent.

### Key Benefits

- **Isolation**: Test components in isolation with mocked dependencies
- **Flexibility**: Easy switching between real and mock dependencies
- **Consistency**: Standardized patterns for DI testing
- **Maintainability**: Clear separation of concerns in tests

## Testing Infrastructure

### DITestHelpers Module

The `DITestHelpers` module provides the core testing utilities and is automatically included in all RSpec examples.

#### Key Methods

- `with_test_container`: Creates isolated test environment
- `register_test_double`: Creates and registers test doubles
- `register_spy`: Creates and registers spies for interaction testing
- `create_test_config`: Creates test configuration objects
- `setup_minimal_container`: Sets up basic mocks for testing

### TestContainer Class

The `TestContainer` class provides an isolated container for testing that doesn't interfere with the main application container.

#### Features

- Independent container instance
- Easy mock registration
- Automatic cleanup between tests
- Container state verification
- Registration copying from other containers

## Basic Testing Patterns

### 1. Testing with Isolated Container

```ruby
RSpec.describe MyAction do
  it 'processes data correctly' do
    with_test_container do |container|
      # Register test dependencies
      git_mock = register_test_double('git_wrapper', {
        commit: true,
        current_branch: 'main'
      })
      
      # Test your component
      action = MyAction.new(git_wrapper: container['git_wrapper'])
      result = action.execute
      
      expect(result).to be_successful
    end
  end
end
```

### 2. Testing with Spies for Interaction Verification

```ruby
RSpec.describe MyService do
  it 'logs operations correctly' do
    with_test_container do |container|
      logger_spy = register_spy('logger', [:info, :error])
      
      service = MyService.new(logger: container['logger'])
      service.perform_operation
      
      expect(logger_spy).to have_received(:info).with('Operation started')
    end
  end
end
```

### 3. Testing Configuration Integration

```ruby
RSpec.describe ConfigurableComponent do
  it 'uses configuration correctly' do
    with_test_container do |container|
      test_config = create_test_config(
        ComputerTools::Configurations::LoggingConfiguration,
        { level: 'debug', file_logging: true }
      )
      container.register('logging_configuration') { test_config }
      
      component = ConfigurableComponent.new(
        config: container['logging_configuration']
      )
      
      expect(component.log_level).to eq('debug')
    end
  end
end
```

## Advanced Testing Techniques

### Container State Management

```ruby
RSpec.describe ComplexWorkflow do
  let(:test_container) { ComputerTools::TestContainer.new_instance }
  
  before do
    # Set up complex dependency graph
    test_container.register_mock('database', database_mock)
    test_container.register_mock('api_client', api_mock)
    test_container.register_mock('cache', cache_mock)
    
    # Verify all dependencies are ready
    test_container.verify_registrations(['database', 'api_client', 'cache'])
  end
  
  after do
    test_container.reset!
  end
  
  it 'coordinates between multiple services' do
    workflow = ComplexWorkflow.new(
      database: test_container['database'],
      api_client: test_container['api_client'],
      cache: test_container['cache']
    )
    
    result = workflow.execute
    expect(result).to be_successful
  end
end
```

### Testing Interface Compliance

```ruby
RSpec.describe MyWrapper do
  subject { described_class.new }
  
  it 'implements the required interface' do
    expect(subject).to implement_interface(ComputerTools::Interfaces::GitInterface)
  end
  
  it 'passes interface validation' do
    validation_result = ComputerTools::Interfaces::Validation.validate_di_compatibility(
      subject, :git
    )
    
    expect(validation_result[:valid]).to be(true)
    expect(validation_result[:interface_implemented]).to be(true)
  end
end
```

### Integration Testing with Real Dependencies

```ruby
RSpec.describe IntegrationWorkflow do
  before do
    # Initialize full container for integration testing
    ComputerTools.initialize_container
  end
  
  it 'works with real dependencies' do
    # Use real container with actual implementations
    workflow = IntegrationWorkflow.new(
      git_wrapper: ComputerTools.container['git_wrapper'],
      config: ComputerTools.container['path_configuration']
    )
    
    # Test with real dependencies
    result = workflow.execute
    expect(result).to be_successful
  end
end
```

## Custom Matchers

### be_resolvable_from_container

Tests if a dependency can be resolved from the container:

```ruby
expect('git_wrapper').to be_resolvable_from_container
expect('git_wrapper').to be_resolvable_from_container(test_container)
```

### implement_interface

Tests if an object implements a specific interface:

```ruby
expect(git_wrapper).to implement_interface(ComputerTools::Interfaces::GitInterface)
```

### have_dependency_injection_for

Tests if an object has proper dependency injection setup:

```ruby
expect(action_instance).to have_dependency_injection_for(:git_wrapper)
expect(action_instance).to have_dependency_injection_for('logger', Logger)
```

### have_all_registrations

Tests if a container has all required registrations:

```ruby
expect(container).to have_all_registrations(['git_wrapper', 'logger', 'config'])
```

### be_valid_configuration

Tests configuration object behavior:

```ruby
expect(config).to be_valid_configuration
expect(config).to be_valid_configuration.with_settings([:level, :path])
```

### be_mockable_with_dependencies

Tests if a class can be properly mocked with dependencies:

```ruby
expect(MyClass).to be_mockable_with_dependencies(['git_wrapper', 'logger'])
```

## Shared Examples

### Interface Compliance

```ruby
RSpec.describe MyWrapper do
  include_examples 'interface compliance',
    ComputerTools::Interfaces::GitInterface,
    [:commit, :push, :current_branch]
end
```

### Dependency Injection Compatible

```ruby
RSpec.describe MyAction do
  include_examples 'dependency injection compatible',
    ['git_wrapper', 'logger'],
    :git
end
```

### Container Registration

```ruby
RSpec.describe 'GitWrapper registration' do
  include_examples 'container registration',
    'git_wrapper',
    ComputerTools::Wrappers::GitWrapper
end
```

### Configuration Object

```ruby
RSpec.describe LoggingConfiguration do
  include_examples 'configuration object',
    ComputerTools::Configurations::LoggingConfiguration,
    [:level, :file_logging, :file_path]
end
```

### Action Class

```ruby
RSpec.describe MyAction do
  include_examples 'action class',
    [:execute],
    ['git_wrapper', 'logger']
end
```

## Best Practices

### 1. Use Isolated Containers for Unit Tests

Always use `with_test_container` for unit tests to ensure isolation:

```ruby
# Good
it 'processes data' do
  with_test_container do |container|
    # Test with isolated dependencies
  end
end

# Avoid - uses global container
it 'processes data' do
  # Test directly with ComputerTools.container
end
```

### 2. Mock External Dependencies

Mock external services, file systems, and network calls:

```ruby
it 'handles API failures gracefully' do
  with_test_container do |container|
    api_mock = register_test_double('api_client', {
      get: -> { raise StandardError, 'Network error' }
    })
    
    service = MyService.new(api_client: container['api_client'])
    expect { service.fetch_data }.not_to raise_error
  end
end
```

### 3. Use Spies for Interaction Testing

Use spies to verify method calls and arguments:

```ruby
it 'logs the correct messages' do
  with_test_container do |container|
    logger_spy = register_spy('logger', [:info, :error])
    
    service = MyService.new(logger: container['logger'])
    service.perform_task
    
    expect(logger_spy).to have_received(:info).with('Task started')
    expect(logger_spy).to have_received(:info).with('Task completed')
  end
end
```

### 4. Test Both Success and Failure Paths

Ensure your tests cover both happy paths and error conditions:

```ruby
describe '#execute' do
  context 'when git operations succeed' do
    it 'returns success' do
      with_test_container do |container|
        register_test_double('git_wrapper', { commit: true })
        # Test success path
      end
    end
  end
  
  context 'when git operations fail' do
    it 'handles errors gracefully' do
      with_test_container do |container|
        git_mock = register_test_double('git_wrapper', {
          commit: -> { raise StandardError, 'Git error' }
        })
        # Test error handling
      end
    end
  end
end
```

### 5. Verify Interface Compliance

Always test that your components implement their interfaces correctly:

```ruby
RSpec.describe MyWrapper do
  include_examples 'interface compliance',
    ComputerTools::Interfaces::MyInterface,
    [:required_method1, :required_method2]
    
  include_examples 'dependency injection compatible',
    ['required_dependency'],
    :my_interface_type
end
```

### 6. Use Shared Examples for Common Patterns

Leverage shared examples to ensure consistency:

```ruby
# For all action classes
RSpec.describe MyAction do
  include_examples 'action class', [:execute], ['git_wrapper']
end

# For all configuration classes
RSpec.describe MyConfiguration do
  include_examples 'configuration object',
    described_class,
    [:setting1, :setting2]
end
```

## Common Patterns

### Testing Action Classes

```ruby
RSpec.describe MyAction do
  include_examples 'action class', [:execute], ['git_wrapper', 'logger']
  include_examples 'dependency injection compatible', ['git_wrapper', 'logger']
  
  describe '#execute' do
    it 'performs the action correctly' do
      with_test_container do |container|
        git_spy = register_spy('git_wrapper', [:commit])
        logger_spy = register_spy('logger', [:info])
        
        action = MyAction.new(
          git_wrapper: container['git_wrapper'],
          logger: container['logger']
        )
        
        result = action.execute
        
        expect(git_spy).to have_received(:commit)
        expect(logger_spy).to have_received(:info)
        expect(result).to be_successful
      end
    end
  end
end
```

### Testing Wrapper Classes

```ruby
RSpec.describe MyWrapper do
  include_examples 'interface compliance',
    ComputerTools::Interfaces::MyInterface,
    [:method1, :method2]
    
  include_examples 'container registration',
    'my_wrapper',
    described_class
    
  describe 'wrapper functionality' do
    subject { described_class.new }
    
    it 'implements interface correctly' do
      expect(subject).to implement_interface(ComputerTools::Interfaces::MyInterface)
    end
  end
end
```

### Testing Configuration Classes

```ruby
RSpec.describe MyConfiguration do
  include_examples 'configuration object',
    described_class,
    [:setting1, :setting2]
    
  describe 'configuration behavior' do
    it 'loads from YAML correctly' do
      yaml_data = { 'my_section' => { 'setting1' => 'value1' } }
      config = described_class.from_yaml(yaml_data)
      
      expect(config.config.setting1).to eq('value1')
    end
    
    it 'validates configuration' do
      config = described_class.new
      expect { config.validate! }.not_to raise_error
    end
  end
end
```

## Troubleshooting

### Container Not Initialized

If you get errors about missing dependencies:

```ruby
# Make sure container is initialized in your test
before do
  ComputerTools.initialize_container unless ComputerTools.container.registered?('configuration')
end
```

### Test Isolation Issues

If tests interfere with each other:

```ruby
# Use with_test_container for isolation
it 'isolated test' do
  with_test_container do |container|
    # Your test code here
  end
end

# Or manually reset between tests
after do
  ComputerTools::TestContainer.reset!
end
```

### Mock Expectations Not Working

Ensure you're setting up mocks correctly:

```ruby
# Good - specific expectations
git_mock = register_test_double('git_wrapper', {
  commit: true,
  current_branch: 'main'
})

# Good - spy for interaction testing
git_spy = register_spy('git_wrapper', [:commit, :push])
```

This testing framework provides comprehensive support for testing dependency injection components. Use these patterns and utilities to write robust, maintainable tests for your DI-enabled code.