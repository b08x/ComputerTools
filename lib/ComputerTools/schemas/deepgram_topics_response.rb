# frozen_string_literal: true

require 'ruby_llm/schema'

module ComputerTools
  module Schemas
    ##
    # Schema for Deepgram topic extraction responses.
    #
    # This schema defines the structure for enhanced topic extraction
    # from conversation transcripts. It ensures that LLM responses
    # contain a validated list of relevant topics.
    #
    class DeepgramTopicsResponse < RubyLLM::Schema
      ##
      # Enhanced topic extraction and categorization.
      #
      # This field should contain an array of specific, actionable topic names
      # covering various categories such as:
      # - Business & Strategy topics
      # - Technical & Engineering topics  
      # - Process & Operations topics
      # - Communication & Collaboration topics
      # - Problem Solving & Issues
      # - Planning & Decision Making
      #
      array :topics, of: :string, description: "An array of enhanced topics extracted from the transcript, each topic should be specific and actionable, avoiding overly generic terms, ordered by relevance and importance"
    end
  end
end