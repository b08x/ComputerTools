# frozen_string_literal: true

module MediaTools
  module Actions
    class FFmpegWrapper < Base
      attr_reader :input_file, :output_file

      def initialize(input_file, output_file)
        @input_file = input_file
        @output_file = output_file
      end

      # Method to extract audio from the video file
      def extract_audio
        system("ffmpeg -i #{@input_file} -q:a 0 -map a #{@output_file}.mp3")
      end

      # Method to normalize audio
      def normalize_audio
        system("ffmpeg -i #{@input_file} -af 'volume=normalize' #{@output_file}")
      end

      # Method to convert and process video
      def process_video(video_codec: "libx264", bitrate: "1000k")
        system("ffmpeg -i #{@input_file} -vcodec #{video_codec} -b:v #{bitrate} #{@output_file}")
      end
    end
  end
end

