# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Wrappers::DeepgramFormatter do
  let(:mock_parser) { instance_double(ComputerTools::Wrappers::DeepgramParser) }
  let(:formatter) { described_class.new(mock_parser) }

  # Sample paragraph data
  let(:sample_paragraphs) do
    [
      { text: "Hello there, how are you doing today?", start: "00:00:00", end: "00:00:05" },
      { text: "I'm doing great, thanks for asking!", start: "00:00:05", end: "00:00:10" },
      { text: "That's wonderful to hear.", start: "00:00:10", end: "00:00:13" }
    ]
  end

  # Sample speaker segments data - matches the structure after parser.finalize_segment
  let(:sample_speaker_segments) do
    [
      {
        speaker_id: 1,
        text: "Hello there, how are you doing today?",
        start: "00:00:00",
        end: "00:00:05",
        confidence: 0.925,
        word_count: 7
      },
      {
        speaker_id: 2,
        text: "I'm doing great, thanks for asking!",
        start: "00:00:05",
        end: "00:00:10", 
        confidence: 0.913,
        word_count: 6
      },
      {
        speaker_id: 1,
        text: "That's wonderful to hear.",
        start: "00:00:10",
        end: "00:00:13",
        confidence: 0.922,
        word_count: 4
      }
    ]
  end

  before do
    allow(mock_parser).to receive(:paragraphs).and_return(sample_paragraphs)
  end

  describe '#to_srt' do
    context 'when called without speaker_options (backward compatibility)' do
      it 'generates standard SRT format from paragraphs' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          That's wonderful to hear.
        SRT

        expect(formatter.to_srt).to eq(expected_output)
      end
    end

    context 'when called with speaker_options disabled' do
      let(:speaker_options) { { enable: false } }

      it 'generates standard SRT format from paragraphs' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          That's wonderful to hear.
        SRT

        expect(formatter.to_srt(speaker_options: speaker_options)).to eq(expected_output)
      end
    end

    context 'when parser lacks speaker support' do
      let(:speaker_options) { { enable: true } }

      before do
        allow(mock_parser).to receive(:respond_to?).with(:has_speaker_data?).and_return(false)
      end

      it 'falls back to paragraph-based SRT' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          That's wonderful to hear.
        SRT

        expect(formatter.to_srt(speaker_options: speaker_options)).to eq(expected_output)
      end
    end

    context 'when speaker data is not available' do
      let(:speaker_options) { { enable: true } }

      before do
        allow(mock_parser).to receive(:respond_to?).with(:has_speaker_data?).and_return(true)
        allow(mock_parser).to receive(:has_speaker_data?).and_return(false)
      end

      it 'falls back to paragraph-based SRT' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          That's wonderful to hear.
        SRT

        expect(formatter.to_srt(speaker_options: speaker_options)).to eq(expected_output)
      end
    end

    context 'when speaker data is available' do
      let(:speaker_options) { { enable: true, confidence_threshold: 0.8 } }

      before do
        allow(mock_parser).to receive(:respond_to?).with(:has_speaker_data?).and_return(true)
        allow(mock_parser).to receive(:has_speaker_data?).and_return(true)
        allow(mock_parser).to receive(:speaker_segments).with(min_confidence: 0.8).and_return(sample_speaker_segments)
      end

      it 'generates speaker-aware SRT format' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          [Speaker 2]: Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          [Speaker 3]: I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          [Speaker 2]: That's wonderful to hear.
        SRT

        expect(formatter.to_srt(speaker_options: speaker_options)).to eq(expected_output)
      end

      context 'with custom label format' do
        let(:speaker_options) do
          { 
            enable: true, 
            confidence_threshold: 0.8, 
            label_format: "Speaker %d: ",
            merge_consecutive_segments: false
          }
        end

        it 'uses the custom label format' do
          result = formatter.to_srt(speaker_options: speaker_options)
          
          expect(result).to include("Speaker 2: Hello there, how are you doing today?")
          expect(result).to include("Speaker 3: I'm doing great, thanks for asking!")
        end
      end

      context 'with consecutive segment merging enabled' do
        let(:consecutive_segments) do
          [
            {
              speaker_id: 1,
              text: "Hello",
              start: "00:00:00",
              end: "00:00:02",
              confidence: 0.95,
              word_count: 1
            },
            {
              speaker_id: 1,
              text: "world!",
              start: "00:00:02",
              end: "00:00:04",
              confidence: 0.92,
              word_count: 1
            }
          ]
        end

        let(:speaker_options) do
          { 
            enable: true, 
            confidence_threshold: 0.8, 
            merge_consecutive_segments: true
          }
        end

        before do
          allow(mock_parser).to receive(:speaker_segments).with(min_confidence: 0.8).and_return(consecutive_segments)
        end

        it 'merges consecutive segments from the same speaker' do
          result = formatter.to_srt(speaker_options: speaker_options)
          
          # Should have only one segment instead of two
          expect(result.scan(/^\d+$/).length).to eq(1)
          expect(result).to include("Hello world!")
        end
      end

      context 'with minimum segment duration filtering' do
        let(:short_segments) do
          [
            {
              speaker_id: 1,
              text: "Hi",
              start: "00:00:00",
              end: "00:00:00",  # Very short segment (0.5 seconds)
              confidence: 0.95,
              word_count: 1
            },
            {
              speaker_id: 2,
              text: "Hello there, how are you doing today?",
              start: "00:00:01",
              end: "00:00:03",  # Long enough segment (2.0 seconds)
              confidence: 0.92,
              word_count: 7
            }
          ]
        end

        let(:speaker_options) do
          { 
            enable: true, 
            confidence_threshold: 0.8, 
            min_segment_duration: 1.0,
            merge_consecutive_segments: false
          }
        end

        before do
          allow(mock_parser).to receive(:speaker_segments).with(min_confidence: 0.8).and_return(short_segments)
        end

        it 'filters out segments shorter than minimum duration' do
          result = formatter.to_srt(speaker_options: speaker_options)
          
          # Should only have the longer segment
          expect(result.scan(/^\d+$/).length).to eq(1)
          expect(result).to include("Hello there, how are you doing today?")
          expect(result).not_to include("Hi")
        end
      end

      context 'with maximum speakers limit' do
        let(:multi_speaker_segments) do
          [
            { speaker_id: 1, start: "00:00:00", end: "00:00:02", text: "Speaker one", confidence: 0.90, word_count: 2 },
            { speaker_id: 2, start: "00:00:02", end: "00:00:04", text: "Speaker two", confidence: 0.85, word_count: 2 },
            { speaker_id: 3, start: "00:00:04", end: "00:00:06", text: "Speaker three", confidence: 0.88, word_count: 2 },
            { speaker_id: 1, start: "00:00:06", end: "00:00:08", text: "Speaker one again", confidence: 0.92, word_count: 3 }
          ]
        end

        let(:speaker_options) do
          { 
            enable: true, 
            confidence_threshold: 0.8, 
            max_speakers: 2,
            merge_consecutive_segments: false,
            min_segment_duration: 0.0
          }
        end

        before do
          allow(mock_parser).to receive(:speaker_segments).with(min_confidence: 0.8).and_return(multi_speaker_segments)
        end

        it 'limits the number of speakers handled' do
          result = formatter.to_srt(speaker_options: speaker_options)
          
          # Should have 3 segments (2 from speaker 1, 1 from speaker 2, but 0 from speaker 3)
          expect(result.scan(/^\d+$/).length).to eq(3)
          expect(result).to include("Speaker one")
          expect(result).to include("Speaker two")
          expect(result).to include("Speaker one again")
          expect(result).not_to include("Speaker three")
        end
      end
    end

    context 'when speaker processing fails' do
      let(:speaker_options) { { enable: true } }

      before do
        allow(mock_parser).to receive(:respond_to?).with(:has_speaker_data?).and_return(true)
        allow(mock_parser).to receive(:has_speaker_data?).and_return(true)
        allow(mock_parser).to receive(:speaker_segments).and_raise(StandardError.new("Processing error"))
      end

      it 'gracefully falls back to paragraph-based SRT' do
        expected_output = <<~SRT.strip
          1
          00:00:00,000 --> 00:00:05,000
          Hello there, how are you doing today?

          2
          00:00:05,000 --> 00:00:10,000
          I'm doing great, thanks for asking!

          3
          00:00:10,000 --> 00:00:13,000
          That's wonderful to hear.
        SRT

        expect(formatter.to_srt(speaker_options: speaker_options)).to eq(expected_output)
      end
    end
  end

  describe 'private helper methods' do
    describe '#format_timestamp_for_srt_raw' do
      it 'converts seconds to SRT timestamp format' do
        # Access the private method for testing
        timestamp = formatter.send(:format_timestamp_for_srt_raw, 125.750)
        expect(timestamp).to eq("00:02:05,750")
      end

      it 'handles edge cases' do
        expect(formatter.send(:format_timestamp_for_srt_raw, nil)).to eq("00:00:00,000")
        expect(formatter.send(:format_timestamp_for_srt_raw, 0.0)).to eq("00:00:00,000")
        expect(formatter.send(:format_timestamp_for_srt_raw, 3661.123)).to eq("01:01:01,123")
      end
    end

    describe '#format_speaker_label' do
      it 'formats speaker labels correctly' do
        label = formatter.send(:format_speaker_label, 1, "[Speaker %d]: ")
        expect(label).to eq("[Speaker 2]: ")
      end

      it 'handles invalid format strings gracefully' do
        label = formatter.send(:format_speaker_label, 1, "invalid format")
        expect(label).to eq("[Speaker 2]: ")
      end
    end
  end
end