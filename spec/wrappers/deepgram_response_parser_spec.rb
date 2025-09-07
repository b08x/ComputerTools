# frozen_string_literal: true

require 'json'
require 'tempfile'
require_relative '../../lib/ComputerTools/wrappers/deepgram_response_parser'

RSpec.describe ComputerTools::Wrappers::DeepgramResponseParser do
  let(:parser) { described_class.new }
  
  # Sample raw Deepgram response structure
  let(:raw_deepgram_response) do
    {
      "metadata" => {
        "request_id" => "test-123",
        "transaction_key" => "deprecated",
        "sha256" => "test-hash",
        "created" => "2025-08-29T03:00:15.232Z",
        "duration" => 359.67706,
        "channels" => 1
      },
      "results" => {
        "channels" => [
          {
            "alternatives" => [
              {
                "transcript" => "Hello world, this is a test transcript.",
                "confidence" => 0.95,
                "words" => [
                  { "word" => "Hello", "start" => 0.0, "end" => 0.5, "confidence" => 0.98, "speaker" => 0 },
                  { "word" => "world", "start" => 0.6, "end" => 1.0, "confidence" => 0.95, "speaker" => 0 },
                  { "word" => "this", "start" => 2.0, "end" => 2.3, "confidence" => 0.92, "speaker" => 1 },
                  { "word" => "is", "start" => 2.4, "end" => 2.6, "confidence" => 0.97, "speaker" => 1 }
                ]
              }
            ]
          }
        ],
        "utterances" => [
          {
            "start" => 0.0,
            "end" => 1.0,
            "confidence" => 0.965,
            "speaker" => 0,
            "transcript" => "Hello world,",
            "words" => [
              { "word" => "Hello", "start" => 0.0, "end" => 0.5, "confidence" => 0.98, "speaker" => 0 },
              { "word" => "world", "start" => 0.6, "end" => 1.0, "confidence" => 0.95, "speaker" => 0 }
            ]
          },
          {
            "start" => 2.0,
            "end" => 2.6,
            "confidence" => 0.945,
            "speaker" => 1,
            "transcript" => "this is a test transcript.",
            "words" => [
              { "word" => "this", "start" => 2.0, "end" => 2.3, "confidence" => 0.92, "speaker" => 1 },
              { "word" => "is", "start" => 2.4, "end" => 2.6, "confidence" => 0.97, "speaker" => 1 }
            ]
          }
        ],
        "topics" => [
          { "topic" => "Technology", "confidence" => 0.87 },
          { "topic" => "Testing", "confidence" => 0.65 }
        ],
        "summary" => {
          "short" => "This is a test conversation about technology and testing."
        }
      }
    }
  end
  
  let(:legacy_processed_segments) do
    [
      {
        "segment_id" => "test_1",
        "transcript" => "Hello world",
        "topic" => "Greeting",
        "gemini_analysis" => "This is a greeting segment"
      }
    ]
  end

  describe '#parse_response' do
    context 'with valid Deepgram response containing utterances' do
      it 'parses utterances into segments' do
        segments = parser.parse_response(raw_deepgram_response)
        
        expect(segments).to be_an(Array)
        expect(segments.length).to eq(2)
        
        # Check first segment (speaker 0)
        first_segment = segments[0]
        expect(first_segment['segment_id']).to eq('utterance_0')
        expect(first_segment['transcript']).to eq('Hello world,')
        expect(first_segment['speaker']).to eq(0)
        expect(first_segment['start_time']).to eq(0.0)
        expect(first_segment['end_time']).to eq(1.0)
        expect(first_segment['confidence']).to eq(0.965)
        
        # Check shared metadata
        expect(first_segment['topics']).to eq(['Technology', 'Testing'])
        expect(first_segment['topic']).to eq('Technology')
        expect(first_segment['summary']).to eq('This is a test conversation about technology and testing.')
      end
    end
    
    context 'with Deepgram response containing only words (no utterances)' do
      let(:words_only_response) do
        {
          "results" => {
            "channels" => [
              {
                "alternatives" => [
                  {
                    "transcript" => "Hello world test",
                    "confidence" => 0.95,
                    "words" => [
                      { "word" => "Hello", "start" => 0.0, "end" => 0.5, "confidence" => 0.98, "speaker" => 0 },
                      { "word" => "world", "start" => 0.6, "end" => 1.0, "confidence" => 0.95, "speaker" => 0 },
                      { "word" => "test", "start" => 2.0, "end" => 2.5, "confidence" => 0.92, "speaker" => 1 }
                    ]
                  }
                ]
              }
            ]
          }
        }
      end
      
      it 'groups words by speaker into segments' do
        segments = parser.parse_response(words_only_response)
        
        expect(segments).to be_an(Array)
        expect(segments.length).to eq(2) # Two speakers
        
        # First segment (speaker 0)
        expect(segments[0]['speaker']).to eq(0)
        expect(segments[0]['transcript']).to eq('Hello world')
        expect(segments[0]['start_time']).to eq(0.0)
        expect(segments[0]['end_time']).to eq(1.0)
        
        # Second segment (speaker 1)
        expect(segments[1]['speaker']).to eq(1)
        expect(segments[1]['transcript']).to eq('test')
        expect(segments[1]['start_time']).to eq(2.0)
        expect(segments[1]['end_time']).to eq(2.5)
      end
    end
    
    context 'with basic transcript only' do
      let(:transcript_only_response) do
        {
          "results" => {
            "channels" => [
              {
                "alternatives" => [
                  {
                    "transcript" => "Basic transcript without words or utterances",
                    "confidence" => 0.89
                  }
                ]
              }
            ]
          }
        }
      end
      
      it 'creates a single segment from transcript' do
        segments = parser.parse_response(transcript_only_response)
        
        expect(segments).to be_an(Array)
        expect(segments.length).to eq(1)
        expect(segments[0]['segment_id']).to eq('transcript_0')
        expect(segments[0]['transcript']).to eq('Basic transcript without words or utterances')
        expect(segments[0]['confidence']).to eq(0.89)
      end
    end
    
    context 'with invalid response data' do
      it 'raises ArgumentError for missing results' do
        expect { parser.parse_response({}) }.to raise_error(ArgumentError, /Invalid Deepgram response/)
      end
      
      it 'raises ArgumentError for non-hash input' do
        expect { parser.parse_response("not a hash") }.to raise_error(ArgumentError, /Invalid Deepgram response/)
      end
    end
  end
  
  describe '#parse_from_file' do
    let(:temp_file) { Tempfile.new(['test_deepgram', '.json']) }
    
    after do
      temp_file.close
      temp_file.unlink
    end
    
    it 'parses response from JSON file' do
      temp_file.write(raw_deepgram_response.to_json)
      temp_file.rewind
      
      segments = parser.parse_from_file(temp_file.path)
      
      expect(segments).to be_an(Array)
      expect(segments.length).to eq(2)
      expect(segments[0]['transcript']).to eq('Hello world,')
    end
    
    it 'raises error for invalid JSON' do
      temp_file.write('invalid json content')
      temp_file.rewind
      
      expect { parser.parse_from_file(temp_file.path) }.to raise_error(JSON::ParserError)
    end
  end
  
  describe '.raw_deepgram_response?' do
    it 'returns true for valid raw Deepgram response' do
      expect(described_class.raw_deepgram_response?(raw_deepgram_response)).to be true
    end
    
    it 'returns false for legacy processed segments' do
      expect(described_class.raw_deepgram_response?(legacy_processed_segments)).to be false
    end
    
    it 'returns false for invalid data structures' do
      expect(described_class.raw_deepgram_response?({})).to be false
      expect(described_class.raw_deepgram_response?([])).to be false
      expect(described_class.raw_deepgram_response?("string")).to be false
      expect(described_class.raw_deepgram_response?(nil)).to be false
    end
    
    it 'returns true for minimal valid structure' do
      minimal_response = { "results" => { "channels" => [] } }
      expect(described_class.raw_deepgram_response?(minimal_response)).to be true
    end
  end
  
  describe 'metadata extraction' do
    it 'extracts topics correctly' do
      segments = parser.parse_response(raw_deepgram_response)
      
      expect(segments[0]['topics']).to eq(['Technology', 'Testing'])
      expect(segments[0]['topic']).to eq('Technology') # First topic for compatibility
    end
    
    it 'extracts summary correctly' do
      segments = parser.parse_response(raw_deepgram_response)
      
      expect(segments[0]['summary']).to eq('This is a test conversation about technology and testing.')
    end
    
    it 'handles complex topic structure with segments' do
      complex_topics_response = {
        "results" => {
          "channels" => [
            {
              "alternatives" => [
                { "transcript" => "Complex test", "confidence" => 0.9 }
              ]
            }
          ],
          "topics" => {
            "segments" => [
              {
                "start_word" => 0,
                "end_word" => 10,
                "topics" => [
                  { "topic" => "AI Systems", "confidence" => 0.9 },
                  { "topic" => "Machine Learning", "confidence" => 0.8 }
                ]
              }
            ]
          }
        }
      }
      
      segments = parser.parse_response(complex_topics_response)
      
      expect(segments[0]['topics']).to eq(['AI Systems', 'Machine Learning'])
      expect(segments[0]['topic']).to eq('AI Systems')
    end
    
    it 'handles missing metadata gracefully' do
      minimal_response = {
        "results" => {
          "channels" => [
            {
              "alternatives" => [
                { "transcript" => "Simple test", "confidence" => 0.9 }
              ]
            }
          ]
        }
      }
      
      segments = parser.parse_response(minimal_response)
      
      expect(segments[0]['topics']).to be_nil
      expect(segments[0]['summary']).to be_nil
    end
  end
end