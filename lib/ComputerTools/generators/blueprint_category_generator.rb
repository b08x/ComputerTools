# frozen_string_literal: true

module ComputerTools
  module Generators
    class BlueprintCategoryGenerator < Sublayer::Generators::Base
      llm_output_adapter type: :list_of_strings,
        name: "categories",
        description: "Relevant categories and tags for this code blueprint"

      def initialize(code:, description: nil)
        @code = code
        @description = description
      end

      def generate
        super
      end

      def prompt
        content_to_analyze = [@description, @code].compact.join("\n\n")

        <<-PROMPT
          Analyze this code and generate relevant categories/tags for organization and discovery.

          #{@description ? "Description: #{@description}" : ""}

          Code:
          ```
          #{@code}
          ```

          Please categorize this code with 2-4 relevant tags from the following categories:

          **Programming Languages & Frameworks:**
          ruby, python, javascript, rails, react, vue, express, flask, django

          **Application Types:**
          web-app, api, cli-tool, library, script, microservice, database-migration

          **Domain Areas:**
          authentication, authorization, data-processing, file-handling, web-scraping, 
          text-processing, image-processing, email, notifications, logging, monitoring

          **Patterns & Concepts:**
          mvc, rest-api, graphql, async, background-jobs, caching, testing, validation,
          error-handling, configuration, security, performance-optimization

          **Technical Areas:**
          database, orm, sql, nosql, redis, elasticsearch, docker, kubernetes, 
          json, xml, csv, pdf, encryption, oauth, jwt

          **Utility Types:**
          utility, helper, wrapper, adapter, parser, formatter, converter, generator

          Return only the most relevant 2-4 categories that best describe this code.
          Choose existing categories when possible rather than creating new ones.
        PROMPT
      end
    end
  end
end