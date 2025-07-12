# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::BackupConfiguration do
  describe '.from_yaml' do
    context 'with valid YAML data' do
      let(:yaml_data) do
        {
          'restic' => {
            'mount_timeout' => 120
          }
        }
      end

      it 'creates configuration from YAML' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.mount_timeout).to eq(120)
      end
    end

    context 'with no restic section' do
      let(:yaml_data) { {} }

      it 'uses default values' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.mount_timeout).to eq(60)
      end
    end

    context 'with nil YAML data' do
      it 'uses default values' do
        config = described_class.from_yaml(nil)
        expect(config.config.mount_timeout).to eq(60)
      end
    end
  end

  describe 'validation' do
    let(:config) { described_class.new }

    describe '#validate_timeout' do
      it 'accepts positive integer timeout' do
        config.configure { |c| c.mount_timeout = 30 }
        expect { config.validate_timeout }.not_to raise_error
      end

      it 'accepts large positive integer timeout' do
        config.configure { |c| c.mount_timeout = 3600 }
        expect { config.validate_timeout }.not_to raise_error
      end

      it 'rejects zero timeout' do
        config.configure { |c| c.mount_timeout = 0 }
        expect { config.validate_timeout }.to raise_error(ArgumentError, /Mount timeout must be a positive integer/)
      end

      it 'rejects negative timeout' do
        config.configure { |c| c.mount_timeout = -10 }
        expect { config.validate_timeout }.to raise_error(ArgumentError, /Mount timeout must be a positive integer/)
      end

      it 'rejects non-integer timeout' do
        config.configure { |c| c.mount_timeout = 'not_an_integer' }
        expect { config.validate_timeout }.to raise_error(ArgumentError, /Mount timeout must be a positive integer/)
      end

      it 'rejects float timeout' do
        config.configure { |c| c.mount_timeout = 30.5 }
        expect { config.validate_timeout }.to raise_error(ArgumentError, /Mount timeout must be a positive integer/)
      end
    end
  end
end