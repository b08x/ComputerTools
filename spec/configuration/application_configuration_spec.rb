# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::ApplicationConfiguration do
  describe 'initialization' do
    let(:config) { described_class.new }

    it 'initializes all configuration objects' do
      expect(config.logging_config).to be_a(ComputerTools::Configurations::LoggingConfiguration)
      expect(config.path_config).to be_a(ComputerTools::Configurations::PathConfiguration)
      expect(config.terminal_config).to be_a(ComputerTools::Configurations::TerminalConfiguration)
      expect(config.display_config).to be_a(ComputerTools::Configurations::DisplayConfiguration)
      expect(config.backup_config).to be_a(ComputerTools::Configurations::BackupConfiguration)
    end
  end

  describe '.from_yaml_files' do
    context 'with valid YAML files' do
      let(:yaml_data) do
        {
          'logger' => { 'level' => 'debug' },
          'paths' => { 'home_dir' => '/tmp/test' },
          'terminal' => { 'command' => 'bash' },
          'display' => { 'time_format' => '%d/%m/%Y' },
          'restic' => { 'mount_timeout' => 120 }
        }
      end

      before do
        allow(ComputerTools::Configurations::ConfigurationFactory).to receive(:load_yaml_data).and_return(yaml_data)
      end

      it 'creates configuration from YAML files' do
        config = described_class.from_yaml_files(['config.yml'])
        expect(config.logging_config.config.level).to eq('debug')
        expect(config.path_config.config.home_dir).to eq('/tmp/test')
        expect(config.terminal_config.config.command).to eq('bash')
        expect(config.display_config.config.time_format).to eq('%d/%m/%Y')
        expect(config.backup_config.config.mount_timeout).to eq(120)
      end
    end

    context 'with no files' do
      it 'uses default values' do
        config = described_class.from_yaml_files(nil)
        expect(config.logging_config.config.level).to eq('info')
        expect(config.terminal_config.config.command).to eq('kitty')
        expect(config.display_config.config.time_format).to eq('%Y-%m-%d %H:%M:%S')
        expect(config.backup_config.config.mount_timeout).to eq(60)
      end
    end
  end

  describe '#validate_all!' do
    let(:config) { described_class.new }

    it 'validates all configuration objects' do
      expect(config.logging_config).to receive(:validate!)
      expect(config.path_config).to receive(:validate!)
      expect(config.terminal_config).to receive(:validate!)
      expect(config.display_config).to receive(:validate!)
      expect(config.backup_config).to receive(:validate!)
      
      config.validate_all!
    end
  end

  describe '#interactive_setup' do
    let(:config) { described_class.new }

    it 'runs interactive setup and validation' do
      expect(config).to receive(:validate_all!)
      expect { config.interactive_setup }.to output(/Setting up ComputerTools configuration/).to_stdout
    end
  end

  describe 'backward compatibility' do
    let(:config) { described_class.new }

    describe '#fetch' do
      it 'delegates logger configuration' do
        expect(config.fetch(:logger, :level)).to eq('info')
        expect(config.fetch(:logger, :file_logging)).to be(false)
      end

      it 'delegates path configuration' do
        expect(config.fetch(:paths, :home_dir)).to eq(File.expand_path('~'))
        expect(config.fetch(:paths, :restic_mount_point)).to eq(File.expand_path('~/mnt/restic'))
      end

      it 'delegates terminal configuration' do
        expect(config.fetch(:terminal, :command)).to eq('kitty')
        expect(config.fetch(:terminal, :args)).to eq('-e')
      end

      it 'delegates display configuration' do
        expect(config.fetch(:display, :time_format)).to eq('%Y-%m-%d %H:%M:%S')
      end

      it 'delegates backup configuration' do
        expect(config.fetch(:restic, :mount_timeout)).to eq(60)
      end

      it 'raises error for unknown section' do
        expect { config.fetch(:unknown_section, :key) }.to raise_error(ArgumentError, /Unknown configuration section/)
      end

      it 'raises error for unknown key within section' do
        expect { config.fetch(:logger, :unknown_key) }.to raise_error(ArgumentError, /Unknown logging configuration key/)
      end
    end
  end
end