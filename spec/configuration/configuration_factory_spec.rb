# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::ConfigurationFactory do
  describe 'configuration creation methods' do
    let(:yaml_data) do
      {
        'logger' => { 'level' => 'debug' },
        'paths' => { 'home_dir' => '/tmp/test' },
        'terminal' => { 'command' => 'bash' },
        'display' => { 'time_format' => '%d/%m/%Y' },
        'restic' => { 'mount_timeout' => 120 }
      }
    end

    describe '.create_logging_config' do
      it 'creates logging configuration without YAML data' do
        config = described_class.create_logging_config
        expect(config).to be_a(ComputerTools::Configurations::LoggingConfiguration)
        expect(config.config.level).to eq('info')
      end

      it 'creates logging configuration with YAML data' do
        config = described_class.create_logging_config(yaml_data)
        expect(config).to be_a(ComputerTools::Configurations::LoggingConfiguration)
        expect(config.config.level).to eq('debug')
      end
    end

    describe '.create_path_config' do
      it 'creates path configuration without YAML data' do
        config = described_class.create_path_config
        expect(config).to be_a(ComputerTools::Configurations::PathConfiguration)
        expect(config.config.home_dir).to eq(File.expand_path('~'))
      end

      it 'creates path configuration with YAML data' do
        config = described_class.create_path_config(yaml_data)
        expect(config).to be_a(ComputerTools::Configurations::PathConfiguration)
        expect(config.config.home_dir).to eq('/tmp/test')
      end
    end

    describe '.create_terminal_config' do
      it 'creates terminal configuration without YAML data' do
        config = described_class.create_terminal_config
        expect(config).to be_a(ComputerTools::Configurations::TerminalConfiguration)
        expect(config.config.command).to eq('kitty')
      end

      it 'creates terminal configuration with YAML data' do
        config = described_class.create_terminal_config(yaml_data)
        expect(config).to be_a(ComputerTools::Configurations::TerminalConfiguration)
        expect(config.config.command).to eq('bash')
      end
    end

    describe '.create_display_config' do
      it 'creates display configuration without YAML data' do
        config = described_class.create_display_config
        expect(config).to be_a(ComputerTools::Configurations::DisplayConfiguration)
        expect(config.config.time_format).to eq('%Y-%m-%d %H:%M:%S')
      end

      it 'creates display configuration with YAML data' do
        config = described_class.create_display_config(yaml_data)
        expect(config).to be_a(ComputerTools::Configurations::DisplayConfiguration)
        expect(config.config.time_format).to eq('%d/%m/%Y')
      end
    end

    describe '.create_backup_config' do
      it 'creates backup configuration without YAML data' do
        config = described_class.create_backup_config
        expect(config).to be_a(ComputerTools::Configurations::BackupConfiguration)
        expect(config.config.mount_timeout).to eq(60)
      end

      it 'creates backup configuration with YAML data' do
        config = described_class.create_backup_config(yaml_data)
        expect(config).to be_a(ComputerTools::Configurations::BackupConfiguration)
        expect(config.config.mount_timeout).to eq(120)
      end
    end

    describe '.create_application_config' do
      it 'creates application configuration' do
        config = described_class.create_application_config
        expect(config).to be_a(ComputerTools::Configurations::ApplicationConfiguration)
      end
    end
  end

  describe '.load_yaml_data' do
    let(:temp_file_1) { Tempfile.new(['config1', '.yml']) }
    let(:temp_file_2) { Tempfile.new(['config2', '.yml']) }

    before do
      temp_file_1.write(YAML.dump({ 'logger' => { 'level' => 'debug' } }))
      temp_file_1.close
      
      temp_file_2.write(YAML.dump({ 'paths' => { 'home_dir' => '/tmp/test' } }))
      temp_file_2.close
    end

    after do
      temp_file_1.unlink
      temp_file_2.unlink
    end

    it 'loads YAML data from multiple files' do
      yaml_data = described_class.load_yaml_data([temp_file_1.path, temp_file_2.path])
      
      expect(yaml_data['logger']['level']).to eq('debug')
      expect(yaml_data['paths']['home_dir']).to eq('/tmp/test')
    end

    it 'returns empty hash for nil file paths' do
      yaml_data = described_class.load_yaml_data(nil)
      expect(yaml_data).to eq({})
    end

    it 'skips non-existent files' do
      yaml_data = described_class.load_yaml_data([temp_file_1.path, '/non/existent/file.yml'])
      expect(yaml_data['logger']['level']).to eq('debug')
    end

    it 'merges data from multiple files' do
      yaml_data = described_class.load_yaml_data([temp_file_1.path, temp_file_2.path])
      
      expect(yaml_data).to have_key('logger')
      expect(yaml_data).to have_key('paths')
    end
  end
end