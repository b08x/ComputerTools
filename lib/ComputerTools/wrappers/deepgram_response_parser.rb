# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # Parses raw Deepgram API responses into a normalized format that can be analyzed
    # by the DeepgramAnalyzer. This parser handles the standard Deepgram JSON structure
    # including channels, alternatives, words, utterances, and metadata like topics,
    # summaries, and sentiment analysis.
    #
    # The parser converts the nested Deepgram structure into a flattened array of
    # segments that contain the necessary fields for analysis, making it compatible
    # with the existing DeepgramAnalyzer workflow.
    #
    # @example Basic usage
    #   parser = ComputerTools::Wrappers::DeepgramResponseParser.new
    #   segments = parser.parse_response(deepgram_json_data)
    #
    # @example Parse from file
    #   parser = ComputerTools::Wrappers::DeepgramResponseParser.new
    #   segments = parser.parse_from_file('deepgram_response.json')
    class DeepgramResponseParser
      # Parses a Deepgram API response hash into normalized segments
      #
      # @param [Hash] response_data the raw Deepgram API response
      # @return [Array<Hash>] array of normalized segment hashes
      # @raise [ArgumentError] if response_data is not a valid Deepgram response
      def parse_response(response_data)
        validate_response(response_data)
        
        segments = []
        
        # Extract metadata once for all segments
        metadata = extract_metadata(response_data)
        
        # Try to extract from utterances first (speaker diarization)
        if has_utterances?(response_data)
          segments = parse_utterances(response_data, metadata)
        elsif has_words?(response_data)
          # Fall back to word-level parsing if no utterances
          segments = parse_words(response_data, metadata)
        elsif has_transcript?(response_data)
          # Final fallback to basic transcript
          segments = parse_transcript(response_data, metadata)
        else
          # Create a single segment with just metadata
          segments = [metadata]
        end
        
        segments
      end
      
      # Parses a Deepgram response from a JSON file
      #
      # @param [String] file_path path to the JSON file
      # @return [Array<Hash>] array of normalized segment hashes
      # @raise [Errno::ENOENT] if file doesn't exist
      # @raise [JSON::ParserError] if file contains invalid JSON
      def parse_from_file(file_path)
        response_data = JSON.parse(File.read(file_path))
        parse_response(response_data)
      end
      
      # Checks if the given data looks like a raw Deepgram API response
      #
      # @param [Hash] data the data to check
      # @return [Boolean] true if it appears to be a raw Deepgram response
      def self.raw_deepgram_response?(data)
        return false unless data.is_a?(Hash)
        
        # Check for key Deepgram response structure
        data.key?('results') && 
          data['results'].is_a?(Hash) &&
          (data['results'].key?('channels') || 
           data['results'].key?('utterances') ||
           data['results'].key?('summary') ||
           data['results'].key?('topics'))
      end
      
      private
      
      # Validates that the response data has the expected Deepgram structure
      #
      # @param [Hash] response_data the response to validate
      # @raise [ArgumentError] if the response is invalid
      def validate_response(response_data)
        unless response_data.is_a?(Hash) && response_data['results']
          raise ArgumentError, "Invalid Deepgram response: missing 'results' key"
        end
      end
      
      # Extracts top-level metadata from the Deepgram response
      #
      # @param [Hash] response_data the Deepgram response
      # @return [Hash] extracted metadata
      def extract_metadata(response_data)
        metadata = {}
        results = response_data['results'] || {}
        
        # Extract topics if available - handle both formats
        topics_list = extract_topics_from_response(results)
        if topics_list.any?
          metadata['topics'] = topics_list
          metadata['topic'] = topics_list.first # For compatibility
        end
        
        # Extract summary if available
        if results['summary'].is_a?(Hash)
          metadata['summary'] = results['summary']['short'] || results['summary']['result']
        end
        
        # Extract sentiment if available
        if results['sentiments']
          metadata['sentiment'] = extract_sentiment(results['sentiments'])
        end
        
        # Extract intents if available
        if results['intents']
          metadata['intents'] = extract_intents(results['intents'])
        end
        
        metadata
      end
      
      # Extracts topics from response handling both simple array and complex segment formats
      #
      # @param [Hash] results the results section of the response
      # @return [Array<String>] array of unique topics
      def extract_topics_from_response(results)
        topics_list = []
        
        # Handle simple array format: results.topics = [{"topic": "...", "confidence": ...}]
        if results['topics'].is_a?(Array) && results['topics'].any?
          topics_list.concat(results['topics'].map { |topic| topic['topic'] }.compact)
        # Handle complex segment format: results.topics.segments = [{"topics": [...]}]
        elsif results['topics'].is_a?(Hash) && results['topics']['segments'].is_a?(Array)
          results['topics']['segments'].each do |segment|
            next unless segment['topics'].is_a?(Array)
            
            segment['topics'].each do |topic_data|
              topics_list << topic_data['topic'] if topic_data['topic']
            end
          end
        end
        
        topics_list.compact.uniq
      end
      
      # Extracts sentiment information from the response
      #
      # @param [Hash, Array] sentiments the sentiment data
      # @return [String, nil] the dominant sentiment
      def extract_sentiment(sentiments)
        return nil unless sentiments
        
        if sentiments.is_a?(Array) && sentiments.any?
          # Get the first sentiment with highest confidence
          sentiment = sentiments.max_by { |s| s['confidence'] || 0 }
          sentiment&.dig('sentiment')
        elsif sentiments.is_a?(Hash)
          sentiments['sentiment']
        end
      end
      
      # Extracts intent information from the response
      #
      # @param [Hash, Array] intents the intent data
      # @return [Array<String>] array of detected intents
      def extract_intents(intents)
        return [] unless intents
        
        if intents.is_a?(Array)
          intents.map { |intent| intent['intent'] }.compact
        elsif intents.is_a?(Hash) && intents['intent']
          [intents['intent']]
        else
          []
        end
      end
      
      # Checks if the response has utterances (speaker diarization)
      #
      # @param [Hash] response_data the response data
      # @return [Boolean] true if utterances are present
      def has_utterances?(response_data)
        response_data.dig('results', 'utterances').is_a?(Array) &&
          response_data.dig('results', 'utterances').any?
      end
      
      # Checks if the response has word-level data
      #
      # @param [Hash] response_data the response data
      # @return [Boolean] true if words are present
      def has_words?(response_data)
        channels = response_data.dig('results', 'channels')
        return false unless channels.is_a?(Array) && channels.any?
        
        alternatives = channels.first&.dig('alternatives')
        return false unless alternatives.is_a?(Array) && alternatives.any?
        
        words = alternatives.first&.dig('words')
        words.is_a?(Array) && words.any?
      end
      
      # Checks if the response has a basic transcript
      #
      # @param [Hash] response_data the response data
      # @return [Boolean] true if transcript is present
      def has_transcript?(response_data)
        channels = response_data.dig('results', 'channels')
        return false unless channels.is_a?(Array) && channels.any?
        
        alternatives = channels.first&.dig('alternatives')
        return false unless alternatives.is_a?(Array) && alternatives.any?
        
        alternatives.first&.dig('transcript')&.to_s&.strip&.length&.positive?
      end
      
      # Parses utterances into normalized segments
      #
      # @param [Hash] response_data the response data
      # @param [Hash] metadata shared metadata for all segments
      # @return [Array<Hash>] array of segment hashes
      def parse_utterances(response_data, metadata)
        utterances = response_data.dig('results', 'utterances') || []
        
        # Extract topic segments for mapping
        topic_segments = extract_topic_segments(response_data)
        
        utterances.map.with_index do |utterance, index|
          segment = {
            'segment_id' => "utterance_#{index}",
            'transcript' => utterance['transcript']&.strip,
            'speaker' => utterance['speaker'],
            'start_time' => utterance['start'],
            'end_time' => utterance['end'],
            'confidence' => utterance['confidence'],
            'words' => utterance['words']&.size || 0
          }.merge(metadata)
          
          # Map topics to this utterance if available
          mapped_topics = map_topics_to_utterance(utterance, topic_segments)
          if mapped_topics.any?
            segment['topic'] = mapped_topics.first # For compatibility
            segment['utterance_topics'] = mapped_topics # Full list
          end
          
          segment
        end
      end
      
      # Parses word-level data into normalized segments  
      #
      # @param [Hash] response_data the response data
      # @param [Hash] metadata shared metadata for all segments
      # @return [Array<Hash>] array of segment hashes
      def parse_words(response_data, metadata)
        words = extract_words(response_data)
        return [metadata] if words.empty?
        
        # Group words by speaker if speaker diarization is available
        if words.any? { |word| word['speaker'] }
          group_words_by_speaker(words, metadata)
        else
          # Create chunks of words for analysis
          create_word_chunks(words, metadata)
        end
      end
      
      # Extracts words array from the response
      #
      # @param [Hash] response_data the response data
      # @return [Array<Hash>] array of word hashes
      def extract_words(response_data)
        channels = response_data.dig('results', 'channels') || []
        return [] if channels.empty?
        
        alternatives = channels.first&.dig('alternatives') || []
        return [] if alternatives.empty?
        
        alternatives.first&.dig('words') || []
      end
      
      # Groups words by speaker into segments
      #
      # @param [Array<Hash>] words array of word data
      # @param [Hash] metadata shared metadata
      # @return [Array<Hash>] array of segment hashes grouped by speaker
      def group_words_by_speaker(words, metadata)
        segments = []
        current_segment = nil
        current_speaker = nil
        
        words.each_with_index do |word, index|
          speaker = word['speaker']
          
          # Start new segment if speaker changes or this is the first word
          if current_speaker != speaker
            # Finish previous segment
            if current_segment
              finalize_word_segment(current_segment)
              segments << current_segment
            end
            
            # Start new segment
            current_segment = {
              'segment_id' => "speaker_#{speaker}_#{segments.size}",
              'speaker' => speaker,
              'words_data' => [],
              'start_time' => word['start'],
              'word_count' => 0
            }.merge(metadata)
            
            current_speaker = speaker
          end
          
          # Add word to current segment
          current_segment['words_data'] << word
          current_segment['word_count'] += 1
          current_segment['end_time'] = word['end']
        end
        
        # Don't forget the last segment
        if current_segment
          finalize_word_segment(current_segment)
          segments << current_segment
        end
        
        segments
      end
      
      # Creates fixed-size chunks of words when no speaker diarization
      #
      # @param [Array<Hash>] words array of word data
      # @param [Hash] metadata shared metadata
      # @param [Integer] chunk_size number of words per chunk
      # @return [Array<Hash>] array of segment hashes
      def create_word_chunks(words, metadata, chunk_size = 50)
        segments = []
        
        words.each_slice(chunk_size).with_index do |chunk, index|
          segment = {
            'segment_id' => "chunk_#{index}",
            'words_data' => chunk,
            'start_time' => chunk.first['start'],
            'end_time' => chunk.last['end'],
            'word_count' => chunk.size
          }.merge(metadata)
          
          finalize_word_segment(segment)
          segments << segment
        end
        
        segments
      end
      
      # Finalizes a word-based segment by building transcript and calculating confidence
      #
      # @param [Hash] segment the segment to finalize
      def finalize_word_segment(segment)
        words_data = segment.delete('words_data') || []
        
        # Build transcript from words
        transcript = words_data.map { |word| word['word'] || word['punctuated_word'] }.join(' ')
        segment['transcript'] = transcript.strip
        
        # Calculate average confidence
        confidences = words_data.map { |word| word['confidence'] }.compact
        if confidences.any?
          segment['confidence'] = confidences.sum.to_f / confidences.size
        end
      end
      
      # Parses basic transcript into a single segment
      #
      # @param [Hash] response_data the response data
      # @param [Hash] metadata shared metadata
      # @return [Array<Hash>] array with single segment hash
      def parse_transcript(response_data, metadata)
        channels = response_data.dig('results', 'channels') || []
        return [metadata] if channels.empty?
        
        alternatives = channels.first&.dig('alternatives') || []
        return [metadata] if alternatives.empty?
        
        alternative = alternatives.first
        
        segment = {
          'segment_id' => 'transcript_0',
          'transcript' => alternative['transcript']&.strip,
          'confidence' => alternative['confidence']
        }.merge(metadata)
        
        [segment]
      end
      
      # Extracts topic segments with word ranges from the response
      #
      # @param [Hash] response_data the response data
      # @return [Array<Hash>] array of topic segment data with word ranges
      def extract_topic_segments(response_data)
        topic_segments = []
        
        results = response_data['results'] || {}
        topics_data = results['topics']
        
        return topic_segments unless topics_data.is_a?(Hash)
        
        segments = topics_data['segments']
        return topic_segments unless segments.is_a?(Array)
        
        segments.each do |segment|
          next unless segment['topics'].is_a?(Array)
          
          segment['topics'].each do |topic_data|
            topic_segments << {
              'topic' => topic_data['topic'],
              'confidence' => topic_data['confidence'],
              'start_word' => segment['start_word'],
              'end_word' => segment['end_word']
            }
          end
        end
        
        topic_segments
      end
      
      # Maps topics to utterance based on word ranges and timing
      #
      # @param [Hash] utterance the utterance data
      # @param [Array<Hash>] topic_segments array of topic segment data
      # @return [Array<String>] array of topics that apply to this utterance
      def map_topics_to_utterance(utterance, topic_segments)
        return [] if topic_segments.empty?
        
        utterance_topics = []
        
        # If utterance has words data, try to match by word positions
        if utterance['words'].is_a?(Array) && utterance['words'].any?
          utterance_start_word = find_utterance_word_position(utterance, :start)
          utterance_end_word = find_utterance_word_position(utterance, :end)
          
          if utterance_start_word && utterance_end_word
            topic_segments.each do |topic_segment|
              # Check if topic segment overlaps with utterance word range
              if ranges_overlap?(
                utterance_start_word, utterance_end_word,
                topic_segment['start_word'], topic_segment['end_word']
              )
                utterance_topics << topic_segment['topic']
              end
            end
          end
        end
        
        # Fallback: try to match by timing if no word position mapping worked
        if utterance_topics.empty? && utterance['start'] && utterance['end']
          topic_segments.each do |topic_segment|
            # For timing-based matching, we'll be more liberal and include topics
            # that might be contextually relevant (this is a heuristic approach)
            utterance_topics << topic_segment['topic']
          end
        end
        
        utterance_topics.uniq
      end
      
      # Finds the word position of an utterance in the global word sequence
      #
      # @param [Hash] utterance the utterance data
      # @param [Symbol] position :start or :end
      # @return [Integer, nil] the word position or nil if not found
      def find_utterance_word_position(utterance, position)
        # This is a simplified approach - in a real implementation you would
        # need to map utterance timing to global word positions
        # For now, we'll use a heuristic based on timing
        case position
        when :start
          # Estimate word position based on timing (rough approximation)
          (utterance['start'] * 3).to_i # Assuming ~3 words per second
        when :end
          (utterance['end'] * 3).to_i
        end
      end
      
      # Checks if two ranges overlap
      #
      # @param [Integer] start1 first range start
      # @param [Integer] end1 first range end
      # @param [Integer] start2 second range start
      # @param [Integer] end2 second range end
      # @return [Boolean] true if ranges overlap
      def ranges_overlap?(start1, end1, start2, end2)
        return false if start1.nil? || end1.nil? || start2.nil? || end2.nil?
        
        start1 <= end2 && end1 >= start2
      end
    end
  end
end