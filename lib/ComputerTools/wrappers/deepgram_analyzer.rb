# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # Analyzes Deepgram transcription JSON files to extract structured information about segments,
    # topics, software mentions, and other metadata. This class provides methods to filter,
    # summarize, and extract specific data fields from Deepgram analysis results.
    #
    # The analyzer works with JSON files containing transcription segments that may include
    # various metadata fields. It standardizes field names through FIELD_MAPPING and provides
    # convenient methods to work with the transcription data.
    #
    # @example Basic usage
    #   analyzer = ComputerTools::Wrappers::DeepgramAnalyzer.new('transcript.json')
    #   topics = analyzer.get_all_topics
    #   segments = analyzer.filter_by_topic('Ruby Programming')
    #
    # @example Extracting specific fields
    #   analyzer = ComputerTools::Wrappers::DeepgramAnalyzer.new('transcript.json')
    #   results = analyzer.extract_fields(['Segment Transcript', 'Segment Topic'])
    class DeepgramAnalyzer
      # Mapping of user-friendly field names to JSON keys used in the Deepgram data
      # @return [Hash{String => String}] the field name mapping
      FIELD_MAPPING = {
        "Segment Identifier" => "segment_id",
        "Start Time of Segment" => "start_time",
        "End Time of Segment" => "end_time",
        "Segment Transcript" => "transcript",
        "Segment Topic" => "topic",
        "Relevant Keywords" => "keywords",
        "AI Analysis of Segment" => "gemini_analysis",
        "Software Detected in Segment" => "software_detected",
        "List of Software Detections" => "software_detections"
      }.freeze

      # @return [Array<Hash>] the loaded segments data
      attr_reader :segments

      # @return [Array<String>] the available field names
      attr_reader :available_fields

      # Initializes a new DeepgramAnalyzer with data from a JSON file
      #
      # @param [String] json_file_path path to the JSON file containing Deepgram analysis data
      # @raise [ArgumentError] if the file doesn't exist
      # @raise [RuntimeError] if the JSON file is invalid
      def initialize(json_file_path)
        raise ArgumentError, "File not found: #{json_file_path}" unless File.exist?(json_file_path)

        @json_file_path = json_file_path
        @segments = load_segments_data(json_file_path)
        @available_fields = detect_available_fields
      rescue JSON::ParserError => e
        raise "Invalid JSON file: #{e.message}"
      end

      # Extracts specific fields from all segments
      #
      # @param [Array<String>] selected_fields array of field names to extract (must match FIELD_MAPPING keys)
      # @return [Array<Hash{String => String}>] array of hashes containing the requested fields
      # @example Extracting transcript and topic
      #   analyzer.extract_fields(['Segment Transcript', 'Segment Topic'])
      #   # => [{'Segment Transcript' => 'Hello world', 'Segment Topic' => 'Greeting'}, ...]
      def extract_fields(selected_fields)
        results = []

        @segments.each do |segment|
          segment_data = {}

          selected_fields.each do |field_name|
            json_key = FIELD_MAPPING[field_name]
            next unless json_key

            value = segment[json_key]
            next if value.nil?

            # Format arrays nicely
            formatted_value = value.is_a?(Array) ? value.join(", ") : value
            segment_data[field_name] = formatted_value
          end

          results << segment_data unless segment_data.empty?
        end

        results
      end

      # Returns the list of field names that actually contain data in the segments
      #
      # @return [Array<String>] array of field names with data
      def get_field_options
        FIELD_MAPPING.keys.select { |field| field_has_data?(field) }
      end

      # Provides summary statistics about the loaded data
      #
      # @return [Hash{Symbol => Integer}] hash containing summary statistics
      # @option return [Integer] :total_segments total number of segments
      # @option return [Integer] :available_fields number of available field types
      # @option return [Integer] :fields_with_data number of fields that actually contain data
      def summary_stats
        {
          total_segments: @segments.count,
          available_fields: @available_fields.count,
          fields_with_data: get_field_options.count
        }
      end

      # Checks if any segment contains AI analysis
      #
      # @return [Boolean] true if any segment has AI analysis, false otherwise
      def has_ai_analysis?
        @segments.any? { |segment| segment["gemini_analysis"] }
      end

      # Checks if any segment contains software detection information
      #
      # @return [Boolean] true if any segment has software detection data, false otherwise
      def has_software_detection?
        @segments.any? { |segment| segment["software_detected"] || segment["software_detections"] }
      end

      # Retrieves all unique topics found in the segments
      #
      # @return [Array<String>] array of unique topic strings
      def get_all_topics
        @segments.map { |segment| segment["topic"] }.compact.uniq
      end

      # Retrieves all unique software mentions found in the segments
      #
      # @return [Array<String>] array of unique software names
      def get_all_software
        software_list = []

        @segments.each do |segment|
          # Handle software_detections array
          software_list.concat(segment["software_detections"]) if segment["software_detections"].is_a?(Array)

          # Handle software_detected string
          software_list << segment["software_detected"] if segment["software_detected"]
        end

        software_list.compact.uniq
      end

      # Filters segments by a specific topic
      #
      # @param [String] topic the topic to filter by
      # @return [Array<Hash>] array of segments that match the topic
      def filter_by_topic(topic)
        @segments.select { |segment| segment["topic"] == topic }
      end

      # Filters segments by a specific software mention
      #
      # @param [String] software the software name to filter by
      # @return [Array<Hash>] array of segments that mention the software
      def filter_by_software(software)
        @segments.select do |segment|
          segment["software_detected"] == software ||
            (segment["software_detections"].is_a?(Array) && segment["software_detections"].include?(software))
        end
      end

      private

      # Loads and normalizes segment data from a JSON file
      #
      # @param [String] file_path path to the JSON file
      # @return [Array<Hash>] array of segment hashes
      def load_segments_data(file_path)
        data = JSON.parse(File.read(file_path))

        # Handle both array and single segment formats
        data.is_a?(Array) ? data : [data]
      end

      # Detects which fields are available in the segments data
      #
      # @return [Array<String>] array of available field names
      def detect_available_fields
        return [] if @segments.empty?

        all_keys = @segments.flat_map(&:keys).uniq
        all_keys.map { |key| FIELD_MAPPING.key(key) }.compact
      end

      # Checks if a specific field has data in any segment
      #
      # @param [String] field_name the field name to check
      # @return [Boolean] true if the field has data in any segment, false otherwise
      def field_has_data?(field_name)
        json_key = FIELD_MAPPING[field_name]
        return false unless json_key

        @segments.any? { |segment| segment[json_key] && !segment[json_key].to_s.strip.empty? }
      end
    end
  end
end
