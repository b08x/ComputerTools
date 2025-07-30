# frozen_string_literal: true

require 'shellwords'

module ComputerTools
  module Actions
    class FFmpegAction < Sublayer::Actions::Base
      attr_reader :input_file, :output_file

      def initialize(input_file:, output_file:)
        @input_file = Shellwords.escape(input_file)
        @output_file = Shellwords.escape(output_file)
      end

      def extract_audio
        execute_ffmpeg_command("-i #{@input_file} -q:a 0 -map a #{@output_file}.mp3")
      end

      def normalize_audio
        execute_ffmpeg_command("-i #{@input_file} -af 'volume=normalize' #{@output_file}")
      end

      def process_video(video_codec: 'libx264', bitrate: '1000k')
        codec = Shellwords.escape(video_codec)
        rate = Shellwords.escape(bitrate)
        execute_ffmpeg_command("-i #{@input_file} -vcodec #{codec} -b:v #{rate} #{@output_file}")
      end

      private

      def execute_ffmpeg_command(args)
        command = "ffmpeg #{args}"
        success = system(command)
        raise "FFmpeg command failed: #{command}" unless success
        success
      end
    end
  end
end

