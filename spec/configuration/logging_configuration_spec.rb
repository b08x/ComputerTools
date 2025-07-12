# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::LoggingConfiguration do
  describe '.from_yaml' do
    context 'with valid YAML data' do
      let(:yaml_data) do
        {
          'logger' => {
            'level' => 'debug',
            'file_logging' => true,
            'file_path' => '/tmp/test.log',
            'file_level' => 'info'
          }
        }
      end

      it 'creates configuration from YAML' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.level).to eq('debug')
        expect(config.config.file_logging).to be(true)
        expect(config.config.file_path).to eq('/tmp/test.log')
        expect(config.config.file_level).to eq('info')
      end
    end

    context 'with no logger section' do
      let(:yaml_data) { {} }

      it 'uses default values' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.level).to eq('info')
        expect(config.config.file_logging).to be(false)
        expect(config.config.file_level).to eq('debug')
      end
    end

    context 'with nil YAML data' do
      it 'uses default values' do
        config = described_class.from_yaml(nil)
        expect(config.config.level).to eq('info')
        expect(config.config.file_logging).to be(false)
        expect(config.config.file_level).to eq('debug')
      end
    end
  end

  describe 'validation' do
    let(:config) { described_class.new }

    describe '#validate_level' do
      it 'accepts valid log levels' do
        %w[debug info warn error fatal].each do |level|
          config.configure { |c| c.level = level }
          expect { config.validate_level }.not_to raise_error
        end
      end

      it 'rejects invalid log levels' do
        config.configure { |c| c.level = 'invalid' }
        expect { config.validate_level }.to raise_error(ArgumentError, /Invalid log level/)
      end
    end

    describe '#validate_file_level' do
      it 'accepts valid file log levels' do
        %w[debug info warn error fatal].each do |level|
          config.configure { |c| c.file_level = level }
          expect { config.validate_file_level }.not_to raise_error
        end
      end

      it 'rejects invalid file log levels' do
        config.configure { |c| c.file_level = 'invalid' }
        expect { config.validate_file_level }.to raise_error(ArgumentError, /Invalid file log level/)
      end
    end

    describe '#validate_file_path' do
      it 'passes when file logging is disabled' do
        config.configure do |c|
          c.file_logging = false
          c.file_path = nil
        end
        expect { config.validate_file_path }.not_to raise_error
      end

      it 'passes when file logging is enabled and default path is used' do
        config.configure do |c|
          c.file_logging = true
          c.file_path = nil
        end
        expect { config.validate_file_path }.not_to raise_error
      end
    end

    describe '#validate!' do
      it 'runs all validations' do
        expect(config).to receive(:validate_level)
        expect(config).to receive(:validate_file_level)
        expect(config).to receive(:validate_file_path)
        config.validate!
      end
    end
  end

  describe '#configure_tty_logger' do
    let(:config) { described_class.new }

    it 'returns logger configuration hash' do
      logger_config = config.configure_tty_logger
      expect(logger_config).to be_a(Hash)
      expect(logger_config).to have_key(:level)
      expect(logger_config).to have_key(:output)
    end

    it 'includes console output' do
      logger_config = config.configure_tty_logger
      expect(logger_config[:output]).to include($stdout)
    end

    it 'includes file output when file logging is enabled' do
      config.configure do |c|
        c.file_logging = true
        c.file_path = '/tmp/test.log'
      end
      logger_config = config.configure_tty_logger
      expect(logger_config[:output]).to include('/tmp/test.log')
    end
  end
end