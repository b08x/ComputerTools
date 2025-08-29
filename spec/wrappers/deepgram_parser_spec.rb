# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Wrappers::DeepgramParser do
  let(:json_file) { 'spec/fixtures/deepgram_transcript.json' }
  let(:parser) { described_class.new(json_file) }

  # Mock data for testing speaker-related functionality
  let(:mock_transcript_with_speakers) do
    {
      'results' => {
        'channels' => [{
          'alternatives' => [{
            'words' => [
              { 'word' => 'Hello', 'start' => 0.0, 'end' => 0.5, 'speaker' => 1, 'confidence' => 0.95 },
              { 'word' => 'world', 'start' => 0.5, 'end' => 1.0, 'speaker' => 1, 'confidence' => 0.92 },
              { 'word' => 'How', 'start' => 1.5, 'end' => 2.0, 'speaker' => 2, 'confidence' => 0.88 },
              { 'word' => 'are', 'start' => 2.0, 'end' => 2.5, 'speaker' => 2, 'confidence' => 0.90 },
              { 'word' => 'you', 'start' => 2.5, 'end' => 3.0, 'speaker' => 2, 'confidence' => 0.93 }
            ]
          }]
        }]
      }
    }
  end

  let(:mock_transcript_no_speakers) do
    {
      'results' => {
        'channels' => [{
          'alternatives' => [{
            'words' => [
              { 'word' => 'Hello', 'start' => 0.0, 'end' => 0.5, 'confidence' => 0.95 },
              { 'word' => 'world', 'start' => 0.5, 'end' => 1.0, 'confidence' => 0.92 }
            ]
          }]
        }]
      }
    }
  end

  # Remove global mocking to let fixture file be used by default

  describe '#words_with_speaker_info' do
    context 'with transcript containing speaker data' do
      it 'extracts words with speaker information' do
        result = parser.words_with_speaker_info

        expect(result.length).to eq(7)
        expect(result[0]).to include(
          word: 'Hello', 
          start_raw: 0.0, 
          end_raw: 0.5, 
          speaker: 1, 
          speaker_confidence: 0.95
        )
      end
    end

    context 'with transcript without speaker data' do
      let(:parser_no_speakers) { described_class.new(json_file) }
      
      before do
        allow(File).to receive(:read).with(json_file).and_return(mock_transcript_no_speakers.to_json)
      end

      it 'returns empty array when no speaker information available' do
        result = parser_no_speakers.words_with_speaker_info

        expect(result.length).to eq(0)
      end
    end

    context 'with malformed JSON' do
      before do
        allow(File).to receive(:read).and_return('invalid json')
      end

      it 'raises an error when parsing fails' do
        expect { parser }.to raise_error(RuntimeError, /Invalid JSON file/)
      end
    end
  end

  describe '#has_speaker_data?' do
    context 'with transcript containing speaker data' do
      it 'returns true' do
        expect(parser.has_speaker_data?).to be true
      end
    end

    context 'with transcript without speaker data' do
      let(:parser_no_speakers) { described_class.new(json_file) }
      
      before do
        allow(File).to receive(:read).with(json_file).and_return(mock_transcript_no_speakers.to_json)
      end

      it 'returns false' do
        expect(parser_no_speakers.has_speaker_data?).to be false
      end
    end
  end

  describe '#speaker_segments' do
    context 'with confidence filtering' do
      it 'returns segments filtered by confidence threshold' do
        result = parser.speaker_segments(min_confidence: 0.9)

        expect(result.length).to eq(2)  # Speaker 1: Hello,world; Speaker 2: How,are,you,doing,today
        expect(result[0][:speaker_id]).to eq(1)
        expect(result[0][:confidence]).to be_within(0.001).of(0.935)
        expect(result[1][:speaker_id]).to eq(2)
      end

      it 'returns no segments when no words meet confidence threshold' do
        result = parser.speaker_segments(min_confidence: 0.99)

        expect(result).to be_empty
      end
    end

    context 'with multiple speakers' do
      it 'groups words by speaker' do
        result = parser.speaker_segments(min_confidence: 0.8)

        expect(result.length).to eq(2)  # Two segments: Speaker 1, Speaker 2
        expect(result[0][:speaker_id]).to eq(1)
        expect(result[1][:speaker_id]).to eq(2)
      end
    end

    context 'with edge cases' do
      context 'when no words have speaker information' do
        let(:parser_no_speakers) { described_class.new(json_file) }
        
        before do
          allow(File).to receive(:read).with(json_file).and_return(mock_transcript_no_speakers.to_json)
        end

        it 'returns an empty array' do
          result = parser_no_speakers.speaker_segments(min_confidence: 0.8)

          expect(result).to be_empty
        end
      end
    end
  end

  describe '#speaker_statistics' do
    it 'calculates speaker statistics' do
      result = parser.speaker_statistics

      expect(result[:speaker_count]).to eq(2)
      expect(result[:total_words_with_speaker_data]).to eq(7)
      expect(result[:speakers]).to have_key(1)
      expect(result[:speakers]).to have_key(2)
      expect(result[:speakers][1][:word_count]).to eq(2)
      expect(result[:speakers][2][:word_count]).to eq(5)
      expect(result[:speakers][1][:avg_confidence]).to be_within(0.001).of(0.935)
      expect(result[:speakers][2][:avg_confidence]).to be_within(0.01).of(0.902)
      expect(result[:overall_avg_confidence]).to be_within(0.01).of(0.913)
    end

    context 'with no speaker data' do
      let(:parser_no_speakers) { described_class.new(json_file) }
      
      before do
        allow(File).to receive(:read).with(json_file).and_return(mock_transcript_no_speakers.to_json)
      end

      it 'returns empty statistics structure' do
        result = parser_no_speakers.speaker_statistics

        expect(result[:speaker_count]).to eq(0)
        expect(result[:total_words_with_speaker_data]).to eq(0)
        expect(result[:speakers]).to be_empty
        expect(result[:overall_avg_confidence]).to eq(0.0)
      end
    end
  end
end