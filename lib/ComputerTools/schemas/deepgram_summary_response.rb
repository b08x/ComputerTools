# frozen_string_literal: true

require 'ruby_llm/schema'

module ComputerTools
  module Schemas
    ##
    # Schema for Deepgram summary generation responses.
    #
    # This schema defines the structure for comprehensive summaries
    # of conversation transcripts. It ensures that LLM responses
    # contain properly formatted summary content.
    #
    class DeepgramSummaryResponse < RubyLLM::Schema
      ##
      # A comprehensive summary of the transcript content.
      #
      # This field should contain a well-structured, professional summary
      # that includes:
      # - Main topics and themes discussed
      # - Key points and takeaways
      # - Important decisions or action items
      # - Overall tone and context
      # - Notable patterns or insights
      #
      string :summary, description: "A comprehensive, professional summary of the transcript suitable for executive briefings, meeting minutes, or documentation purposes. Should include main topics, key points, decisions, action items, and overall context"
    end
  end
end