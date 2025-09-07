# frozen_string_literal: true

require 'json'
require 'tempfile'
require_relative '../../lib/ComputerTools/wrappers/deepgram_analyzer'

RSpec.describe ComputerTools::Wrappers::DeepgramAnalyzer do
  let(:temp_file) { Tempfile.new(['test_deepgram', '.json']) }
  let(:analyzer) { described_class.new(temp_file.path) }
  
  after do
    temp_file.close
    temp_file.unlink
  end
  
  # Legacy processed format (existing tests)
  let(:legacy_segments_data) do
    [
      {
        "segment_id" => "seg_1",
        "start_time" => 0.0,
        "end_time" => 5.2,
        "transcript" => "Hello world, welcome to our presentation",
        "topic" => "Greeting",
        "keywords" => ["hello", "world", "presentation"],
        "gemini_analysis" => "This is an introductory greeting",
        "software_detected" => "PowerPoint",
        "software_detections" => ["PowerPoint", "Zoom"]
      },
      {
        "segment_id" => "seg_2",
        "start_time" => 5.3,
        "end_time" => 10.1,
        "transcript" => "Today we will discuss Ruby programming concepts",
        "topic" => "Programming",
        "keywords" => ["ruby", "programming", "concepts"],
        "gemini_analysis" => "Introduction to programming topic",
        "software_detected" => "Ruby",
        "software_detections" => ["Ruby", "VS Code"]
      }
    ]
  end
  
  # Raw Deepgram API response format 
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
                "transcript" => "Hello world, welcome to Ruby programming.",
                "confidence" => 0.95,
                "words" => [
                  { "word" => "Hello", "start" => 0.0, "end" => 0.5, "confidence" => 0.98, "speaker" => 0 },
                  { "word" => "world", "start" => 0.6, "end" => 1.0, "confidence" => 0.95, "speaker" => 0 },
                  { "word" => "welcome", "start" => 1.2, "end" => 1.8, "confidence" => 0.92, "speaker" => 0 },
                  { "word" => "to", "start" => 1.9, "end" => 2.1, "confidence" => 0.97, "speaker" => 0 },
                  { "word" => "Ruby", "start" => 3.0, "end" => 3.5, "confidence" => 0.94, "speaker" => 1 },
                  { "word" => "programming", "start" => 3.6, "end" => 4.2, "confidence" => 0.96, "speaker" => 1 }
                ]
              }
            ]
          }
        ],
        "utterances" => [
          {
            "start" => 0.0,
            "end" => 2.1,
            "confidence" => 0.955,
            "speaker" => 0,
            "transcript" => "Hello world, welcome to",
            "words" => 4
          },
          {
            "start" => 3.0,
            "end" => 4.2,
            "confidence" => 0.95,
            "speaker" => 1,
            "transcript" => "Ruby programming.",
            "words" => 2
          }
        ],
        "topics" => [
          { "topic" => "Programming", "confidence" => 0.87 },
          { "topic" => "Ruby", "confidence" => 0.78 }
        ],
        "summary" => {
          "short" => "Introduction to Ruby programming concepts."
        }
      }
    }
  end

  describe 'initialization' do
    context 'with legacy processed data' do
      before do
        temp_file.write(legacy_segments_data.to_json)
        temp_file.rewind
      end
      
      it 'initializes successfully with valid JSON file' do
        expect { analyzer }.not_to raise_error
        expect(analyzer.segments).to be_an(Array)
        expect(analyzer.segments.length).to eq(2)
      end
      
      it 'loads available fields correctly' do
        expect(analyzer.available_fields).to include(
          'Segment Identifier',
          'Start Time of Segment',
          'End Time of Segment',
          'Segment Transcript',
          'Segment Topic'
        )
      end
    end
    
    context 'with raw Deepgram response' do
      before do
        temp_file.write(raw_deepgram_response.to_json)
        temp_file.rewind
      end
      
      it 'initializes and parses raw Deepgram format' do
        expect { analyzer }.not_to raise_error
        expect(analyzer.segments).to be_an(Array)
        expect(analyzer.segments.length).to eq(2) # Two utterances
      end
      
      it 'extracts speaker information from utterances' do
        first_segment = analyzer.segments[0]
        expect(first_segment['speaker']).to eq(0)
        expect(first_segment['transcript']).to eq('Hello world, welcome to')
        
        second_segment = analyzer.segments[1]
        expect(second_segment['speaker']).to eq(1)
        expect(second_segment['transcript']).to eq('Ruby programming.')
      end
      
      it 'includes metadata fields in available fields' do
        expect(analyzer.available_fields).to include(
          'Speaker',
          'Confidence Score',
          'Topics',
          'Summary'
        )
      end
    end
    
    context 'with invalid data' do
      it 'raises ArgumentError for non-existent file' do
        expect { described_class.new('/non/existent/file.json') }.to raise_error(ArgumentError, /File not found/)
      end
      
      it 'raises RuntimeError for invalid JSON' do
        temp_file.write('invalid json content')
        temp_file.rewind
        
        expect { analyzer }.to raise_error(/Invalid JSON file/)
      end
    end
  end

  describe '#extract_fields' do
    context 'with legacy processed data' do
      before do
        temp_file.write(legacy_segments_data.to_json)
        temp_file.rewind
      end
      
      it 'extracts specified fields from all segments' do
        selected_fields = ['Segment Transcript', 'Segment Topic', 'AI Analysis of Segment']
        results = analyzer.extract_fields(selected_fields)
        
        expect(results).to be_an(Array)
        expect(results.length).to eq(2)
        
        expect(results[0]).to include(
          'Segment Transcript' => 'Hello world, welcome to our presentation',
          'Segment Topic' => 'Greeting',
          'AI Analysis of Segment' => 'This is an introductory greeting'
        )
        
        expect(results[1]).to include(
          'Segment Transcript' => 'Today we will discuss Ruby programming concepts',
          'Segment Topic' => 'Programming',
          'AI Analysis of Segment' => 'Introduction to programming topic'
        )
      end
      
      it 'handles array values by joining them' do
        selected_fields = ['Relevant Keywords', 'List of Software Detections']
        results = analyzer.extract_fields(selected_fields)
        
        expect(results[0]['Relevant Keywords']).to eq('hello, world, presentation')
        expect(results[0]['List of Software Detections']).to eq('PowerPoint, Zoom')
      end
    end
    
    context 'with raw Deepgram data' do
      before do
        temp_file.write(raw_deepgram_response.to_json)
        temp_file.rewind
      end
      
      it 'extracts fields from parsed raw data' do
        selected_fields = ['Segment Transcript', 'Speaker', 'Confidence Score']
        results = analyzer.extract_fields(selected_fields)
        
        expect(results).to be_an(Array)
        expect(results.length).to eq(2)
        
        expect(results[0]).to include(
          'Segment Transcript' => 'Hello world, welcome to',
          'Speaker' => 0,
          'Confidence Score' => 0.955
        )
        
        expect(results[1]).to include(
          'Segment Transcript' => 'Ruby programming.',
          'Speaker' => 1,
          'Confidence Score' => 0.95
        )
      end
      
      it 'extracts metadata fields' do
        selected_fields = ['Topics', 'Summary']
        results = analyzer.extract_fields(selected_fields)
        
        # Both segments should have the same metadata
        expect(results[0]['Topics']).to eq('Programming, Ruby')
        expect(results[0]['Summary']).to eq('Introduction to Ruby programming concepts.')
        expect(results[1]['Topics']).to eq('Programming, Ruby')
        expect(results[1]['Summary']).to eq('Introduction to Ruby programming concepts.')
      end
    end
  end

  describe '#get_field_options' do
    context 'with legacy processed data' do
      before do
        temp_file.write(legacy_segments_data.to_json)
        temp_file.rewind
      end
      
      it 'returns only fields that have data' do
        field_options = analyzer.get_field_options
        
        expect(field_options).to include(
          'Segment Identifier',
          'Start Time of Segment',
          'End Time of Segment',
          'Segment Transcript',
          'Segment Topic',
          'Relevant Keywords',
          'AI Analysis of Segment',
          'Software Detected in Segment',
          'List of Software Detections'
        )
      end
    end
    
    context 'with raw Deepgram data' do
      before do
        temp_file.write(raw_deepgram_response.to_json)
        temp_file.rewind
      end
      
      it 'returns fields available in raw data' do
        field_options = analyzer.get_field_options
        
        expect(field_options).to include(
          'Segment Identifier',
          'Start Time of Segment',
          'End Time of Segment',
          'Segment Transcript',
          'Speaker',
          'Confidence Score',
          'Topics',
          'Summary'
        )
      end
    end
  end

  describe '#summary_stats' do
    before do
      temp_file.write(legacy_segments_data.to_json)
      temp_file.rewind
    end
    
    it 'returns correct summary statistics' do
      stats = analyzer.summary_stats
      
      expect(stats[:total_segments]).to eq(2)
      expect(stats[:available_fields]).to be > 0
      expect(stats[:fields_with_data]).to be > 0
    end
  end

  describe '#has_ai_analysis?' do
    it 'returns true when AI analysis is present in legacy data' do
      temp_file.write(legacy_segments_data.to_json)
      temp_file.rewind
      
      expect(analyzer.has_ai_analysis?).to be true
    end
    
    it 'returns false when no AI analysis is present in raw data' do
      temp_file.write(raw_deepgram_response.to_json)
      temp_file.rewind
      
      expect(analyzer.has_ai_analysis?).to be false
    end
  end

  describe '#has_software_detection?' do
    it 'returns true when software detection is present in legacy data' do
      temp_file.write(legacy_segments_data.to_json)
      temp_file.rewind
      
      expect(analyzer.has_software_detection?).to be true
    end
    
    it 'returns false when no software detection is present in raw data' do
      temp_file.write(raw_deepgram_response.to_json)
      temp_file.rewind
      
      expect(analyzer.has_software_detection?).to be false
    end
  end

  describe '#get_all_topics' do
    context 'with legacy processed data' do
      before do
        temp_file.write(legacy_segments_data.to_json)
        temp_file.rewind
      end
      
      it 'returns unique topics from segments' do
        topics = analyzer.get_all_topics
        expect(topics).to contain_exactly('Greeting', 'Programming')
      end
    end
    
    context 'with raw Deepgram data' do
      before do
        temp_file.write(raw_deepgram_response.to_json)
        temp_file.rewind
      end
      
      it 'returns topics from metadata' do
        topics = analyzer.get_all_topics
        expect(topics).to contain_exactly('Programming', 'Ruby')
      end
    end
  end

  describe '#filter_by_topic' do
    before do
      temp_file.write(legacy_segments_data.to_json)
      temp_file.rewind
    end
    
    it 'filters segments by specified topic' do
      filtered = analyzer.filter_by_topic('Programming')
      
      expect(filtered.length).to eq(1)
      expect(filtered[0]['topic']).to eq('Programming')
      expect(filtered[0]['transcript']).to eq('Today we will discuss Ruby programming concepts')
    end
    
    it 'returns empty array for non-existent topic' do
      filtered = analyzer.filter_by_topic('NonExistent')
      expect(filtered).to be_empty
    end
  end

  describe '#filter_by_software' do
    before do
      temp_file.write(legacy_segments_data.to_json)
      temp_file.rewind
    end
    
    it 'filters segments by software detected' do
      filtered = analyzer.filter_by_software('Ruby')
      
      expect(filtered.length).to eq(1)
      expect(filtered[0]['software_detected']).to eq('Ruby')
    end
    
    it 'filters segments by software in detections array' do
      filtered = analyzer.filter_by_software('Zoom')
      
      expect(filtered.length).to eq(1)
      expect(filtered[0]['software_detections']).to include('Zoom')
    end
  end
end