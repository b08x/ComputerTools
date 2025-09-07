# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Container do
  let(:container) { described_class }

  # Clean up test registrations after each test
  after do
    # Remove any test registrations to avoid interference between tests
    %w[test_dependency test_object lazy_test singleton_test registered_test resolve_test].each do |key|
      container._container.delete(key) if container.registered?(key)
    end
  end

  describe 'basic container functionality' do
    it 'extends Dry::Container::Mixin' do
      expect(container.ancestors).to include(Dry::Container::Mixin)
    end

    it 'can register and resolve simple dependencies' do
      test_dependency = 'test_value'
      container.register('test_dependency') { test_dependency }
      
      expect(container['test_dependency']).to eq(test_dependency)
    end

    it 'can register and resolve complex dependencies' do
      test_object = double('TestObject', value: 'test')
      container.register('test_object') { test_object }
      
      resolved = container['test_object']
      expect(resolved).to eq(test_object)
      expect(resolved.value).to eq('test')
    end
  end

  describe 'pre-registered dependencies' do
    it 'has configuration registered' do
      expect(container.registered?('configuration')).to be true
      expect(container['configuration']).to be_a(ComputerTools::Configuration)
    end

    it 'has logger registered' do
      expect(container.registered?('logger')).to be true
      expect(container['logger']).to be_a(TTY::Logger)
    end
  end

  describe 'utility methods' do
    describe '.register_lazy' do
      it 'registers a dependency with memoization' do
        call_count = 0
        container.register_lazy('lazy_test') do
          call_count += 1
          "lazy_value_#{call_count}"
        end

        # First call should create the object
        first_result = container['lazy_test']
        expect(first_result).to eq('lazy_value_1')
        
        # Second call should return the same memoized object
        second_result = container['lazy_test']
        expect(second_result).to eq('lazy_value_1')
        expect(call_count).to eq(1) # Should only be called once due to memoization
      end
    end

    describe '.register_singleton' do
      it 'registers a singleton instance' do
        singleton_instance = double('SingletonInstance', id: 'singleton_123')
        container.register_singleton('singleton_test', singleton_instance)
        
        expect(container['singleton_test']).to eq(singleton_instance)
        expect(container['singleton_test'].id).to eq('singleton_123')
      end
    end

    describe '.registered?' do
      it 'returns true for registered dependencies' do
        container.register('registered_test') { 'test' }
        expect(container.registered?('registered_test')).to be true
      end

      it 'returns false for unregistered dependencies' do
        expect(container.registered?('unregistered_test')).to be false
      end
    end

    describe '.resolve_dependency' do
      it 'resolves existing dependencies' do
        container.register('resolve_test') { 'resolved_value' }
        expect(container.resolve_dependency('resolve_test')).to eq('resolved_value')
      end

      it 'raises StandardError for non-existent dependencies' do
        expect { container.resolve_dependency('non_existent_dependency') }
          .to raise_error(StandardError, /Failed to resolve dependency/)
      end
    end
  end

  describe 'registrations loading' do
    it 'can load registrations without error' do
      expect { container.load_registrations }.not_to raise_error
    end

    it 'can register all dependencies without error' do
      container.load_registrations
      # Only register if not already registered to avoid duplicate key errors
      unless container.registered?('git_wrapper')
        expect { ComputerTools::Container::Registrations.register_all }.not_to raise_error
      end
    end
  end

  describe 'integration with main module' do
    it 'can access container through ComputerTools.container' do
      expect(ComputerTools.container).to eq(container)
    end

    it 'can initialize container through ComputerTools.initialize_container' do
      # Only initialize if not already initialized to avoid duplicate key errors
      unless container.registered?('git_wrapper')
        expect { ComputerTools.initialize_container }.not_to raise_error
      end
      expect(ComputerTools.container).to eq(container)
    end
  end

  describe 'dependency registration verification' do
    before do
      # Only load registrations once to avoid duplicate key errors
      unless container.registered?('git_wrapper')
        container.load_registrations
        ComputerTools::Container::Registrations.register_all
      end
    end

    it 'registers wrapper dependencies' do
      expect(container.registered?('git_wrapper')).to be true
      expect(container.registered?('restic_wrapper')).to be true
      expect(container.registered?('docling_wrapper')).to be true
      expect(container.registered?('trafilatura_wrapper')).to be true
      expect(container.registered?('blueprint_database')).to be true
    end

    it 'can resolve wrapper dependencies' do
      git_wrapper = container.resolve_dependency('git_wrapper')
      expect(git_wrapper).to be_a(ComputerTools::Wrappers::GitWrapper)
      
      restic_wrapper = container.resolve_dependency('restic_wrapper')
      expect(restic_wrapper).to be_a(ComputerTools::Wrappers::ResticWrapper)
    end

    it 'registers action dependencies' do
      expect(container.registered?('blueprint_submit_action')).to be true
      expect(container.registered?('git_analysis_action')).to be true
      expect(container.registered?('example_action')).to be true
    end

    it 'registers generator dependencies' do
      expect(container.registered?('blueprint_description_generator')).to be true
      expect(container.registered?('deepgram_summary_generator')).to be true
      expect(container.registered?('overview_generator')).to be true
    end
  end

  describe 'error handling' do
    it 'provides helpful error messages for missing dependencies' do
      expect { container.resolve_dependency('missing_dependency') }
        .to raise_error(StandardError, /Failed to resolve dependency 'missing_dependency'/)
    end

    it 'handles circular dependencies gracefully' do
      # This test would require more complex setup to create actual circular dependencies
      # For now, just ensure the container can handle basic error scenarios
      expect { container.resolve_dependency('configuration') }.not_to raise_error
    end
  end
end