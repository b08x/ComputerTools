# frozen_string_literal: true

require 'ruby_llm/schema'

module ComputerTools
  module Schemas
    ##
    # Schema for Deepgram insights analysis responses.
    #
    # This schema defines the structure for strategic insights and actionable
    # intelligence derived from conversation transcripts. It ensures that
    # LLM responses contain the expected insights data in a validated format.
    #
    class DeepgramInsightsResponse < RubyLLM::Schema
      ##
      # The strategic insights and analysis derived from the transcript.
      #
      # This field should contain a comprehensive analysis covering:
      # - Strategic analysis with business/technical patterns
      # - Behavioral insights about communication dynamics  
      # - Actionable recommendations for improvements
      # - Content intelligence about information hierarchy
      #
      string :insights, description: "Strategic insights and analysis derived from the transcript, formatted as structured markdown with clear sections for Strategic Analysis, Behavioral Insights, Actionable Recommendations, and Content Intelligence"
    end
  end
end