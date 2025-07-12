# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::TerminalConfiguration do
  describe '.from_yaml' do
    context 'with valid YAML data' do
      let(:yaml_data) do
        {
          'terminal' => {
            'command' => 'gnome-terminal',
            'args' => '--'
          }
        }
      end

      it 'creates configuration from YAML' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.command).to eq('gnome-terminal')
        expect(config.config.args).to eq('--')
      end
    end

    context 'with no terminal section' do
      let(:yaml_data) { {} }

      it 'uses default values' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.command).to eq('kitty')
        expect(config.config.args).to eq('-e')
      end
    end

    context 'with nil YAML data' do
      it 'uses default values' do
        config = described_class.from_yaml(nil)
        expect(config.config.command).to eq('kitty')
        expect(config.config.args).to eq('-e')
      end
    end
  end

  describe 'validation' do
    let(:config) { described_class.new }

    describe '#validate_terminal_command' do
      it 'passes for available terminal command' do
        config.configure { |c| c.command = 'bash' }  # bash should be available
        expect { config.validate_terminal_command }.not_to raise_error
      end

      it 'fails for unavailable terminal command' do
        config.configure { |c| c.command = 'non_existent_terminal_xyz' }
        expect { config.validate_terminal_command }.to raise_error(ArgumentError, /Terminal command .* not found in PATH/)
      end
    end
  end

  describe 'utility methods' do
    let(:config) { described_class.new }

    describe '#build_command_line' do
      it 'builds command line with single command' do
        config.configure do |c|
          c.command = 'kitty'
          c.args = '-e'
        end
        
        result = config.build_command_line('ls -la')
        expect(result).to eq(['kitty', '-e', 'ls -la'])
      end

      it 'builds command line with array command' do
        config.configure do |c|
          c.command = 'kitty'
          c.args = '-e'
        end
        
        result = config.build_command_line(['ls', '-la'])
        expect(result).to eq(['kitty', '-e', 'ls', '-la'])
      end

      it 'handles nil args' do
        config.configure do |c|
          c.command = 'kitty'
          c.args = nil
        end
        
        result = config.build_command_line('ls')
        expect(result).to eq(['kitty', 'ls'])
      end
    end

    describe '#terminal_available?' do
      it 'returns true for available terminal' do
        config.configure { |c| c.command = 'bash' }  # bash should be available
        expect(config.terminal_available?).to be(true)
      end

      it 'returns false for unavailable terminal' do
        config.configure { |c| c.command = 'non_existent_terminal_xyz' }
        expect(config.terminal_available?).to be(false)
      end
    end

    describe '#execute_in_terminal' do
      let(:config) { described_class.new }

      it 'executes command in terminal' do
        config.configure do |c|
          c.command = 'echo'  # Use echo as a safe terminal command
          c.args = 'test_output'
        end
        
        # Mock system call to avoid actually executing
        expect(config).to receive(:system).with('echo', 'test_output', 'test_command')
        config.execute_in_terminal('test_command')
      end
    end
  end
end