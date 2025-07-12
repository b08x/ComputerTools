# frozen_string_literal: true

# Shared examples for testing interface compliance
#
# These shared examples can be used to verify that classes properly
# implement their interface contracts and work correctly with dependency injection.

# Tests that an object implements a specific interface
#
# @param interface_module [Module] the interface module to test against
# @param required_methods [Array<Symbol>] list of methods that must be implemented
#
# @example
#   RSpec.describe MyWrapper do
#     include_examples 'interface compliance', 
#       ComputerTools::Interfaces::GitInterface,
#       [:commit, :push, :current_branch]
#   end
RSpec.shared_examples 'interface compliance' do |interface_module, required_methods = []|
  describe 'interface compliance' do
    it 'includes the interface module' do
      expect(subject).to be_a(interface_module)
    end

    it 'implements all required methods' do
      required_methods.each do |method_name|
        expect(subject).to respond_to(method_name)
      end
    end

    it 'passes interface validation' do
      if defined?(ComputerTools::Interfaces::Validation)
        validation_method = "implements_#{interface_module.name.split('::').last.downcase}?"
        if ComputerTools::Interfaces::Validation.respond_to?(validation_method)
          expect(ComputerTools::Interfaces::Validation.public_send(validation_method, subject)).to be(true)
        end
      end
    end
  end
end

# Tests dependency injection compatibility
#
# @param dependency_keys [Array<String, Symbol>] required dependency keys
# @param interface_type [Symbol] the interface type for validation (:git, :backup, etc.)
#
# @example
#   RSpec.describe MyAction do
#     include_examples 'dependency injection compatible',
#       ['git_wrapper', 'logger'],
#       :git
#   end
RSpec.shared_examples 'dependency injection compatible' do |dependency_keys = [], interface_type = nil|
  describe 'dependency injection compatibility' do
    include DITestHelpers

    it 'can be instantiated with injected dependencies' do
      with_test_container do |container|
        dependency_keys.each do |key|
          container.register_mock(key, double(key))
        end

        expect {
          if dependency_keys.any?
            dependencies = dependency_keys.map { |key| [key.to_sym, container[key]] }.to_h
            create_with_dependencies(described_class, dependencies)
          else
            described_class.new
          end
        }.not_to raise_error
      end
    end

    it 'properly stores injected dependencies' do
      with_test_container do |container|
        dependency_keys.each do |key|
          mock_dep = double(key)
          container.register_mock(key, mock_dep)
        end

        if dependency_keys.any?
          dependencies = dependency_keys.map { |key| [key.to_sym, container[key]] }.to_h
          instance = create_with_dependencies(described_class, dependencies)
          
          dependency_keys.each do |key|
            expect(verify_dependency_injection(instance, key)).to be(true)
          end
        end
      end
    end

    if interface_type
      it 'validates dependency injection compatibility' do
        instance = described_class.new
        validation_result = ComputerTools::Interfaces::Validation.validate_di_compatibility(instance, interface_type)
        
        expect(validation_result).to be_a(Hash)
        expect(validation_result).to have_key(:interface_implemented)
        expect(validation_result).to have_key(:errors)
        expect(validation_result).to have_key(:warnings)
      end
    end
  end
end

# Tests container registration functionality
#
# @param registration_key [String, Symbol] the key used for container registration
# @param expected_class [Class] the expected class of the resolved dependency
#
# @example
#   RSpec.describe 'GitWrapper registration' do
#     include_examples 'container registration',
#       'git_wrapper',
#       ComputerTools::Wrappers::GitWrapper
#   end
RSpec.shared_examples 'container registration' do |registration_key, expected_class = nil|
  describe 'container registration' do
    include DITestHelpers

    before do
      ComputerTools.initialize_container unless ComputerTools.container.registered?('configuration')
    end

    it 'is registered in the container' do
      expect(ComputerTools.container.registered?(registration_key.to_s)).to be(true)
    end

    it 'can be resolved from the container' do
      expect { ComputerTools.container[registration_key.to_s] }.not_to raise_error
    end

    if expected_class
      it 'resolves to the expected class' do
        resolved = ComputerTools.container[registration_key.to_s]
        expect(resolved).to be_a(expected_class)
      end
    end

    it 'returns the same instance on repeated access' do
      first_resolution = ComputerTools.container[registration_key.to_s]
      second_resolution = ComputerTools.container[registration_key.to_s]
      
      # For singletons, should be the same instance
      # For factories, should be equivalent but potentially different instances
      expect(first_resolution.class).to eq(second_resolution.class)
    end
  end
end

# Tests configuration object functionality
#
# @param config_class [Class] the configuration class to test
# @param required_settings [Array<Symbol>] list of required configuration settings
#
# @example
#   RSpec.describe LoggingConfiguration do
#     include_examples 'configuration object',
#       ComputerTools::Configurations::LoggingConfiguration,
#       [:level, :file_logging, :file_path]
#   end
RSpec.shared_examples 'configuration object' do |config_class, required_settings = []|
  describe 'configuration object behavior' do
    include DITestHelpers

    let(:config_instance) { config_class.new }

    it 'can be instantiated' do
      expect { config_class.new }.not_to raise_error
    end

    it 'responds to config method' do
      expect(config_instance).to respond_to(:config)
    end

    it 'has all required settings' do
      required_settings.each do |setting|
        expect(config_instance.config).to respond_to(setting)
      end
    end

    it 'can be created from YAML data' do
      if config_class.respond_to?(:from_yaml)
        expect { config_class.from_yaml({}) }.not_to raise_error
        expect { config_class.from_yaml(nil) }.not_to raise_error
      end
    end

    it 'supports validation' do
      if config_instance.respond_to?(:validate!)
        expect { config_instance.validate! }.not_to raise_error
      end
    end

    it 'can be configured programmatically' do
      expect {
        config_instance.configure do |c|
          # Basic configuration test - just ensure the block executes
        end
      }.not_to raise_error
    end
  end
end

# Tests action class patterns
#
# @param required_methods [Array<Symbol>] methods the action should implement
# @param dependencies [Array<String>] required dependencies for the action
#
# @example
#   RSpec.describe MyAction do
#     include_examples 'action class',
#       [:execute],
#       ['git_wrapper', 'logger']
#   end
RSpec.shared_examples 'action class' do |required_methods = [:execute], dependencies = []|
  describe 'action class behavior' do
    include DITestHelpers

    it 'implements required action methods' do
      required_methods.each do |method|
        expect(subject).to respond_to(method)
      end
    end

    if dependencies.any?
      it 'works with dependency injection' do
        with_test_container do |container|
          dependencies.each do |dep|
            container.register_mock(dep, double(dep))
          end

          dependency_hash = dependencies.map { |dep| [dep.to_sym, container[dep]] }.to_h
          
          expect {
            create_with_dependencies(described_class, dependency_hash)
          }.not_to raise_error
        end
      end
    end
  end
end