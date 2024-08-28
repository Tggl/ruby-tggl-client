# frozen_string_literal: true

require 'net/http'
require 'json'

module Tggl
  class Client
    def initialize(api_key = nil, options = {})
      @api_key = api_key
      @url = options[:url] || 'https://api.tggl.io/flags'
      @reporter = api_key.nil? || options[:reporting] == false ? nil :  Reporting.new(
        api_key,
        app_prefix: 'ruby-client:1.0.0/Client',
        url: options[:reporting] == true ? nil : options[:reporting]&.[](:url),
        app: options[:reporting] == true ? nil : options[:reporting]&.[](:app)
      )
    end

    def eval_context(context)
      response = eval_contexts([context]).first
      raise "Unexpected empty response from Tggl" if response.nil?

      response
    end

    def eval_contexts(contexts)
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path, {
        'X-Tggl-Api-Key' => @api_key,
        'Content-Type' => 'application/json'
      })
      request.body = contexts.to_json

      response = http.request(request)
      result = JSON.parse(response.body, symbolize_names: true)

      if response.code.to_i > 200
        if result.nil?
          raise "Invalid response from Tggl: #{response.code}"
        end
        raise result['error']
      end

      result.map { |flags| Response.new(flags) }
    end
  end
end
