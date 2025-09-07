#!/usr/bin/env ruby
# frozen_string_literal: true

TOOLS_ROOT = File.expand_path('..', __dir__)

require 'httparty'
require 'nokogiri'
require 'google/apis/customsearch_v1'
require 'tty-option'
require 'dotenv/load'
require 'table_tennis'

# Attempts to load the .env file, overwriting existing environment variables.
# If an error occurs, it displays an error message.
begin
  Dotenv.load('.env', overwrite: true)
rescue StandardError => e
  puts "Error loading .env file: #{e.message}"
end

class GoogleCustomSearch
  def initialize(query)
    @query = query
    # @redis = Redis.new
    @service = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
    @service.key = ENV.fetch('GOOGLE_CUSTOM_SEARCH_API_KEY', nil)
  end

  def call
    search_results = fetch_search_results
    search_results.items.each do |item|
      fetch_page_text(item.link)
      # store_in_redis(item.link, page_text)
      p item.formatted_url
    end
  end

  private

  def fetch_search_results
    @service.list_cses(q: @query, cx: ENV.fetch('GOOGLE_SEARCH_ENGINE_ID', nil))
  end

  def fetch_page_text(url)
    response = HTTParty.get(url)
    document = Nokogiri::HTML(response.body)
    document.text
  end

  def store_in_redis(key, value)
    @redis.set(key, value)
  end
end

query = ARGV[0]

search = GoogleCustomSearch.new(query)

search.call
