# frozen_string_literal: true

require 'spec_helper'

# Simple, focused tests for the DI testing framework
RSpec.describe 'DI Framework Core Functionality' do
  describe 'TestContainer' do
    let(:test_container) { ComputerTools::TestContainer.new_instance }

    it 'creates a new container instance' do
      expect(test_container).to respond_to(:register)
      expect(test_container).to respond_to(:registered?)
      expect(test_container).to respond_to(:keys)
    end

    it 'can register and resolve dependencies' do
      test_container.register('test_dep') { 'test_value' }
      
      expect(test_container.registered?('test_dep')).to be(true)
      expect(test_container['test_dep']).to eq('test_value')
    end

    it 'has helper methods' do
      expect(test_container).to respond_to(:register_mock)
      expect(test_container).to respond_to(:register_double)
      expect(test_container).to respond_to(:register_spy)
      expect(test_container).to respond_to(:stats)
      expect(test_container).to respond_to(:reset!)
    end

    it 'can register mocks' do
      mock_obj = double('test_mock')
      test_container.register_mock('mock_dep', mock_obj)
      
      expect(test_container.registered?('mock_dep')).to be(true)
      expect(test_container['mock_dep']).to eq(mock_obj)
    end

    it 'can register simple test doubles' do
      test_double = double('api_client')
      allow(test_double).to receive_messages(get: { status: 'success' }, post: true)
      
      test_container.register_mock('api_client', test_double)
      
      expect(test_container['api_client'].get).to eq({ status: 'success' })
      expect(test_container['api_client'].post).to be(true)
      expect(test_container['api_client']).to eq(test_double)
    end

    it 'provides stats' do
      test_container.register('dep1') { 'value1' }
      test_container.register('dep2') { 'value2' }
      
      stats = test_container.stats
      
      expect(stats[:registered_count]).to eq(2)
      expect(stats[:keys]).to include('dep1', 'dep2')
      expect(stats[:keys]).to eq(stats[:keys].sort)
    end

    it 'can reset container' do
      test_container.register('temp1') { 'value1' }
      test_container.register('temp2') { 'value2' }
      
      expect(test_container.keys).not_to be_empty
      
      test_container.reset!
      
      expect(test_container.keys).to be_empty
      expect(test_container.empty?).to be(true)
    end
  end

  describe 'DITestHelpers' do
    include DITestHelpers

    describe '#with_test_container' do
      it 'provides isolated container' do
        original_container = ComputerTools.container
        
        with_test_container do |test_container|
          expect(test_container).not_to eq(original_container)
          expect(ComputerTools.container).to eq(test_container)
          
          test_container.register('test_dependency') { 'test_value' }
          expect(ComputerTools.container['test_dependency']).to eq('test_value')
        end
        
        expect(ComputerTools.container).to eq(original_container)
      end
    end

    describe '#register_test_double' do
      it 'creates and registers test double' do
        with_test_container do |container|
          git_double = register_test_double('git_wrapper', {
            commit: true,
            current_branch: 'main'
          })
          
          expect(git_double.commit).to be(true)
          expect(git_double.current_branch).to eq('main')
          expect(container['git_wrapper']).to eq(git_double)
        end
      end
    end

    describe '#create_test_config' do
      it 'creates test configuration with overrides' do
        test_config = create_test_config(
          ComputerTools::Configurations::LoggingConfiguration,
          { level: 'debug', file_logging: true }
        )
        
        expect(test_config.config.level).to eq('debug')
        expect(test_config.config.file_logging).to be(true)
      end
    end
  end

  describe 'Custom Matchers' do
    before do
      ComputerTools.initialize_container unless ComputerTools.container.registered?('configuration')
    end

    describe 'be_resolvable_from_container' do
      it 'matches when dependency is resolvable' do
        expect('configuration').to be_resolvable_from_container
      end

      it 'does not match when dependency is not resolvable' do
        expect('non_existent_dependency').not_to be_resolvable_from_container
      end
    end

    describe 'be_valid_configuration' do
      it 'matches valid configuration objects' do
        config = ComputerTools::Configurations::LoggingConfiguration.new
        expect(config).to be_valid_configuration
      end
    end
  end
end