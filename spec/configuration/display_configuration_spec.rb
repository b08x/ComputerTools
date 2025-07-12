# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Configurations::DisplayConfiguration do
  describe '.from_yaml' do
    context 'with valid YAML data' do
      let(:yaml_data) do
        {
          'display' => {
            'time_format' => '%d/%m/%Y %H:%M'
          }
        }
      end

      it 'creates configuration from YAML' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.time_format).to eq('%d/%m/%Y %H:%M')
      end
    end

    context 'with no display section' do
      let(:yaml_data) { {} }

      it 'uses default values' do
        config = described_class.from_yaml(yaml_data)
        expect(config.config.time_format).to eq('%Y-%m-%d %H:%M:%S')
      end
    end

    context 'with nil YAML data' do
      it 'uses default values' do
        config = described_class.from_yaml(nil)
        expect(config.config.time_format).to eq('%Y-%m-%d %H:%M:%S')
      end
    end
  end

  describe 'validation' do
    let(:config) { described_class.new }

    describe '#validate_time_format' do
      it 'accepts valid time format' do
        config.configure { |c| c.time_format = '%Y-%m-%d %H:%M:%S' }
        expect { config.validate_time_format }.not_to raise_error
      end

      it 'accepts alternative valid time format' do
        config.configure { |c| c.time_format = '%d/%m/%Y' }
        expect { config.validate_time_format }.not_to raise_error
      end

      it 'accepts any string as time format' do
        config.configure { |c| c.time_format = '%Q' }  # Ruby's strftime accepts unknown directives
        expect { config.validate_time_format }.not_to raise_error
      end
    end
  end

  describe 'utility methods' do
    let(:config) { described_class.new }
    let(:test_time) { Time.new(2023, 12, 25, 15, 30, 45) }

    describe '#format_time' do
      it 'formats time with default format' do
        result = config.format_time(test_time)
        expect(result).to eq('2023-12-25 15:30:45')
      end

      it 'formats time with custom format' do
        config.configure { |c| c.time_format = '%d/%m/%Y %H:%M' }
        result = config.format_time(test_time)
        expect(result).to eq('25/12/2023 15:30')
      end

      it 'formats time with date only format' do
        config.configure { |c| c.time_format = '%Y-%m-%d' }
        result = config.format_time(test_time)
        expect(result).to eq('2023-12-25')
      end
    end
  end
end