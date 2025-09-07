# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Actions::DeepgramConvertAction do
  let(:json_file) { 'test_transcript.json' }
  let(:action) { described_class.new(json_file: json_file, format: 'srt') }
  let(:mock_parser) { instance_double(ComputerTools::Wrappers::DeepgramParser) }
  let(:mock_formatter) { instance_double(ComputerTools::Wrappers::DeepgramFormatter) }

  before do
    allow(ComputerTools::Wrappers::DeepgramParser).to receive(:new).and_return(mock_parser)
    allow(ComputerTools::Wrappers::DeepgramFormatter).to receive(:new).and_return(mock_formatter)
    allow(File).to receive(:write)
    allow(File).to receive_messages(exist?: true, basename: 'test_transcript', dirname: '/tmp')
  end

  describe '#call' do
    context 'when converting to SRT format' do
      let(:speaker_config) do
        {
          enable: true,
          confidence_threshold: 0.8,
          label_format: "[Speaker %d]: ",
          merge_consecutive_segments: true,
          min_segment_duration: 1.0,
          max_speakers: 10
        }
      end

      before do
        allow(mock_formatter).to receive(:to_srt).and_return('Mock SRT content')
        allow(action).to receive(:load_speaker_configuration).and_return(speaker_config)
        allow(mock_parser).to receive_messages(has_speaker_data?: true, speaker_segments: [
          { speaker: 0, text: 'Hello' },
          { speaker: 1, text: 'World' }
        ])
      end

      it 'passes speaker configuration to formatter' do
        expect(mock_formatter).to receive(:to_srt).with(speaker_options: speaker_config)
        
        action.call
      end

      it 'displays speaker information in success message' do
        expect { action.call }.to output(/Speaker diarization applied/).to_stdout
      end
    end

    context 'when speaker diarization is disabled' do
      before do
        allow(mock_formatter).to receive(:to_srt).and_return('Mock SRT content')
        allow(action).to receive(:load_speaker_configuration).and_return(nil)
      end

      it 'calls formatter without speaker options' do
        expect(mock_formatter).to receive(:to_srt).with(speaker_options: nil)
        
        action.call
      end
    end

    context 'with invalid speaker configuration' do
      let(:invalid_config) do
        {
          'enable' => true,
          'confidence_threshold' => 2.0,  # Invalid: > 1.0
          'label_format' => 'Invalid format'  # Invalid: no %d placeholder
        }
      end
      let(:expected_config_file) { '/home/b08x/Workspace/RubyAI/ComputerTools/lib/ComputerTools/config/deepgram.yml' }

      before do
        allow(File).to receive(:join).and_call_original
        allow(File).to receive(:join).with(anything, '..', '..', 'config', 'deepgram.yml').and_return(expected_config_file)
        allow(File).to receive(:exist?).with(expected_config_file).and_return(true)
        allow(YAML).to receive(:load_file).with(expected_config_file).and_return({
          'speaker_diarization' => invalid_config
        })
        allow(mock_formatter).to receive(:to_srt).and_return('Mock SRT content')
      end

      it 'falls back to nil configuration with validation error' do
        expect(mock_formatter).to receive(:to_srt).with(speaker_options: nil)
        
        expect { action.call }.to output(/Invalid speaker configuration/).to_stdout
      end
    end
  end

  describe '#load_speaker_configuration' do
    let(:expected_config_file) { '/home/b08x/Workspace/RubyAI/ComputerTools/lib/ComputerTools/config/deepgram.yml' }
    
    before do
      # Mock the path construction within the method
      allow(File).to receive(:join).and_call_original
      allow(File).to receive(:join).with(anything, '..', '..', 'config', 'deepgram.yml').and_return(expected_config_file)
    end
    
    context 'when configuration file exists with valid speaker config' do
      let(:config_data) do
        {
          'speaker_diarization' => {
            'enable' => true,
            'confidence_threshold' => 0.7,
            'label_format' => 'Speaker %d: ',
            'merge_consecutive_segments' => false,
            'min_segment_duration' => 2.0,
            'max_speakers' => 5
          }
        }
      end

      before do
        allow(File).to receive(:exist?).with(expected_config_file).and_return(true)
        allow(YAML).to receive(:load_file).with(expected_config_file).and_return(config_data)
      end

      it 'returns validated configuration with symbolized keys' do
        result = action.send(:load_speaker_configuration)
        
        expect(result).to eq({
          enable: true,
          confidence_threshold: 0.7,
          label_format: 'Speaker %d: ',
          merge_consecutive_segments: false,
          min_segment_duration: 2.0,
          max_speakers: 5
        })
      end
    end

    context 'when speaker diarization is disabled' do
      let(:config_data) do
        {
          'speaker_diarization' => {
            'enable' => false,
            'confidence_threshold' => 0.8
          }
        }
      end

      before do
        allow(File).to receive(:exist?).with(expected_config_file).and_return(true)
        allow(YAML).to receive(:load_file).with(expected_config_file).and_return(config_data)
      end

      it 'returns nil when disabled' do
        result = action.send(:load_speaker_configuration)
        expect(result).to be_nil
      end
    end

    context 'when configuration file does not exist' do
      before do
        allow(File).to receive(:exist?).with(expected_config_file).and_return(false)
      end

      it 'returns nil and shows debug message when DEBUG is enabled' do
        original_debug = ENV['DEBUG']
        ENV['DEBUG'] = 'true'
        
        expect {
          result = action.send(:load_speaker_configuration)
          expect(result).to be_nil
        }.to output(/configuration file not found/).to_stdout
        
        ENV['DEBUG'] = original_debug
      end

      it 'returns nil without debug message when DEBUG is not set' do
        ENV.delete('DEBUG')
        
        result = action.send(:load_speaker_configuration)
        expect(result).to be_nil
      end
    end
  end

  describe '#validate_speaker_configuration' do
    context 'with valid configuration' do
      let(:valid_config) do
        {
          'confidence_threshold' => 0.9,
          'label_format' => '[Person %d]: ',
          'merge_consecutive_segments' => true,
          'min_segment_duration' => 0.5,
          'max_speakers' => 8
        }
      end

      it 'returns validated configuration with defaults' do
        result = action.send(:validate_speaker_configuration, valid_config)
        
        expect(result[:enable]).to be true
        expect(result[:confidence_threshold]).to eq 0.9
        expect(result[:label_format]).to eq '[Person %d]: '
        expect(result[:merge_consecutive_segments]).to be true
        expect(result[:min_segment_duration]).to eq 0.5
        expect(result[:max_speakers]).to eq 8
      end
    end

    context 'with invalid confidence threshold' do
      let(:invalid_config) { { 'confidence_threshold' => 1.5 } }

      it 'returns nil and shows error message' do
        expect { action.send(:validate_speaker_configuration, invalid_config) }.to output(/Invalid speaker configuration/).to_stdout
        
        result = action.send(:validate_speaker_configuration, invalid_config)
        expect(result).to be_nil
      end
    end

    context 'with invalid label format' do
      let(:invalid_config) { { 'label_format' => 'No placeholder' } }

      it 'returns nil and shows error message' do
        expect { action.send(:validate_speaker_configuration, invalid_config) }.to output(/Invalid speaker configuration/).to_stdout
        
        result = action.send(:validate_speaker_configuration, invalid_config)
        expect(result).to be_nil
      end
    end

    context 'with missing values' do
      let(:minimal_config) { {} }

      it 'uses default values' do
        result = action.send(:validate_speaker_configuration, minimal_config)
        
        expect(result[:confidence_threshold]).to eq 0.8
        expect(result[:label_format]).to eq "[Speaker %d]: "
        expect(result[:merge_consecutive_segments]).to be true
        expect(result[:min_segment_duration]).to eq 1.0
        expect(result[:max_speakers]).to eq 10
      end
    end
  end
end