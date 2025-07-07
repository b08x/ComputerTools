# frozen_string_literal: true

require 'json'

module ComputerTools
  module Wrappers
    module Audio
      class DeepgramAnalyzer
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

      attr_reader :segments, :available_fields

      def initialize(json_file_path)
        raise ArgumentError, "File not found: #{json_file_path}" unless File.exist?(json_file_path)

        @json_file_path = json_file_path
        @segments = load_segments_data(json_file_path)
        @available_fields = detect_available_fields
      rescue JSON::ParserError => e
        raise "Invalid JSON file: #{e.message}"
      end

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

      def get_field_options
        FIELD_MAPPING.keys.select { |field| field_has_data?(field) }
      end

      def summary_stats
        {
          total_segments: @segments.count,
          available_fields: @available_fields.count,
          fields_with_data: get_field_options.count
        }
      end

      def has_ai_analysis?
        @segments.any? { |segment| segment["gemini_analysis"] }
      end

      def has_software_detection?
        @segments.any? { |segment| segment["software_detected"] || segment["software_detections"] }
      end

      def get_all_topics
        @segments.map { |segment| segment["topic"] }.compact.uniq
      end

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

      def filter_by_topic(topic)
        @segments.select { |segment| segment["topic"] == topic }
      end

      def filter_by_software(software)
        @segments.select do |segment|
          segment["software_detected"] == software ||
            (segment["software_detections"].is_a?(Array) && segment["software_detections"].include?(software))
        end
      end

      private

      def load_segments_data(file_path)
        data = JSON.parse(File.read(file_path))

        # Handle both array and single segment formats
        data.is_a?(Array) ? data : [data]
      end

      def detect_available_fields
        return [] if @segments.empty?

        all_keys = @segments.flat_map(&:keys).uniq
        all_keys.map { |key| FIELD_MAPPING.key(key) }.compact
      end

      def field_has_data?(field_name)
        json_key = FIELD_MAPPING[field_name]
        return false unless json_key

        @segments.any? { |segment| segment[json_key] && !segment[json_key].to_s.strip.empty? }
      end
    end
    end
  end
end