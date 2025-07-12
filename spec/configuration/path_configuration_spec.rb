# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::PathConfiguration do
  describe '.from_yaml' do
    context 'with valid YAML data' do
      let(:yaml_data) do
        {
          'paths' => {
            'home_dir' => '/tmp/test_home',
            'restic_mount_point' => '/tmp/test_mount',
            'restic_repo' => '/tmp/test_repo'
          }
        }
      end

      it 'creates configuration from YAML' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.home_dir).to eq('/tmp/test_home')
        expect(config.config.restic_mount_point).to eq('/tmp/test_mount')
        expect(config.config.restic_repo).to eq('/tmp/test_repo')
      end
    end

    context 'with no paths section' do
      let(:yaml_data) { {} }

      it 'uses default values' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.home_dir).to eq(File.expand_path('~'))
        expect(config.config.restic_mount_point).to eq(File.expand_path('~/mnt/restic'))
      end
    end

    context 'with nil YAML data' do
      it 'uses default values' do
        config = described_class.from_yaml(nil)
        expect(config.config.home_dir).to eq(File.expand_path('~'))
        expect(config.config.restic_mount_point).to eq(File.expand_path('~/mnt/restic'))
      end
    end
  end

  describe 'validation' do
    let(:config) { described_class.new }

    describe '#validate_home_dir' do
      it 'passes for existing directory' do
        config.configure { |c| c.home_dir = File.expand_path('~') }
        expect { config.validate_home_dir }.not_to raise_error
      end

      it 'fails for non-existent directory' do
        config.configure { |c| c.home_dir = '/non/existent/path' }
        expect { config.validate_home_dir }.to raise_error(ArgumentError, /Home directory does not exist/)
      end
    end

    describe '#validate_restic_mount_point' do
      it 'passes when parent directory exists' do
        config.configure { |c| c.restic_mount_point = '/tmp/test_mount' }
        expect { config.validate_restic_mount_point }.not_to raise_error
      end

      it 'fails when parent directory does not exist' do
        config.configure { |c| c.restic_mount_point = '/non/existent/path/mount' }
        expect { config.validate_restic_mount_point }.to raise_error(ArgumentError, /Parent directory for restic mount point does not exist/)
      end
    end

    describe '#validate_restic_repo' do
      it 'passes for non-empty repository path' do
        config.configure { |c| c.restic_repo = '/tmp/test_repo' }
        expect { config.validate_restic_repo }.not_to raise_error
      end

      it 'fails for empty repository path' do
        config.configure { |c| c.restic_repo = '' }
        expect { config.validate_restic_repo }.to raise_error(ArgumentError, /Restic repository path must be specified/)
      end

      it 'fails for nil repository path' do
        config.configure { |c| c.restic_repo = nil }
        expect { config.validate_restic_repo }.to raise_error(ArgumentError, /Restic repository path must be specified/)
      end
    end
  end

  describe 'utility methods' do
    let(:config) { described_class.new }

    describe '#expanded_home_dir' do
      it 'returns expanded home directory' do
        expect(config.expanded_home_dir).to eq(File.expand_path('~'))
      end
    end

    describe '#expanded_restic_mount_point' do
      it 'returns expanded restic mount point' do
        expect(config.expanded_restic_mount_point).to eq(File.expand_path('~/mnt/restic'))
      end
    end

    describe '#ensure_restic_mount_point' do
      it 'creates mount point directory if it does not exist' do
        config.configure { |c| c.restic_mount_point = '/tmp/test_mount_ensure' }
        
        # Clean up first
        FileUtils.rm_rf('/tmp/test_mount_ensure')
        
        result = config.ensure_restic_mount_point
        
        expect(File.directory?('/tmp/test_mount_ensure')).to be(true)
        expect(result).to eq('/tmp/test_mount_ensure')
        
        # Clean up
        FileUtils.rm_rf('/tmp/test_mount_ensure')
      end

      it 'returns existing mount point directory' do
        config.configure { |c| c.restic_mount_point = '/tmp' }
        result = config.ensure_restic_mount_point
        expect(result).to eq('/tmp')
      end
    end
  end
end