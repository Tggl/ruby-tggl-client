# frozen_string_literal: true

require 'net/http'
require 'json'

def constant_case(str)
  str
    .gsub(/([a-z])([A-Z])/, '\1_\2')
    .gsub(/[\W_]+/, '_')
    .upcase
end

module Tggl
  class Reporting
    def initialize(api_key = nil, options = {})
      @api_key = api_key
      @url = options[:url] || 'https://api.tggl.io/report'
      @app = options[:app]
      @app_prefix = options[:app_prefix]
      @last_report_time = Time.now.to_i
      @flags_to_report = Hash.new
      @received_properties_to_report = Hash.new
      @received_values_to_report = Hash.new
    end

    def send_report
      payload = {}

      unless @flags_to_report.empty?
        flags_to_report = @flags_to_report
        @flags_to_report = Hash.new

        client_id = (@app_prefix || '') + (!@app.nil? && !@app_prefix.nil? ? '/' : '') + (@app || '')
        payload[:clients] = [
          {
            flags: flags_to_report.keys.reduce({}) do |acc, key|
              acc[key] = flags_to_report[key].values
              acc
            end
          }
        ]

        unless client_id.empty?
          payload[:clients][0][:id] = client_id
        end
      end

      unless @received_properties_to_report.empty?
        received_properties = @received_properties_to_report
        @received_properties_to_report = Hash.new

        payload[:receivedProperties] = received_properties
      end

      unless @received_values_to_report.empty?
        received_values = @received_values_to_report
        @received_values_to_report = Hash.new

        data = received_values.keys.reduce([]) do |acc, key|
          received_values[key].keys.each do |value|
            label = received_values[key][value]
            if label.nil?
              acc << [key, value]
            else
              acc << [key, value, label]
            end
          end
          acc
        end

        page_size = 2000

        payload[:receivedValues] = data.first(page_size).reduce({}) do |acc, cur|
          acc[cur[0]] ||= []
          acc[cur[0]] << cur.drop(1).map { |v| v[0...240] }
          acc
        end

        (page_size...data.size).step(page_size) do |i|
          # @api_client.call(@url, true, @api_key, {
          #   receivedValues: data.slice(i, page_size).reduce({}) do |acc, cur|
          #     acc[cur[0]] ||= []
          #     acc[cur[0]] << cur.drop(1).map { |v| v[0...240] }
          #     acc
          #   end
          # })
        end
      end

      unless payload.empty?
        uri = URI(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path, {
          'X-Tggl-Api-Key' => @api_key,
          'Content-Type' => 'application/json'
        })
        request.body = payload.to_json

        http.request(request)
      end
    end

    def report_flag(slug, active, value = nil, default = nil)
      key = "#{active ? '1' : '0'}#{value.to_json}#{default.to_json}"

      @flags_to_report[slug] ||= Hash.new

      if @flags_to_report[slug].key?(key)
        @flags_to_report[slug][key][:count] += 1
      else
        @flags_to_report[slug][key] = {
          active: active,
          value: value,
          default: default,
          count: 1
        }
      end
    end

    def report_context(context)
      now = Time.now.to_i

      context.each do |key, value|
        if @received_properties_to_report.key?(key)
          @received_properties_to_report[key][1] = now
        else
          @received_properties_to_report[key] = [now, now]
        end

        if value.is_a?(String) && !value.empty?
          constant_case_key = constant_case(key.to_s).gsub(/_I_D$/, '_ID')
          label_key_target = constant_case_key.end_with?('_ID') ? constant_case_key.gsub(/_ID$/, '_NAME') : nil
          label_key = label_key_target.nil? ? nil : context.keys.find { |k| constant_case(k.to_s) == label_key_target }

          @received_values_to_report[key] ||= Hash.new
          @received_values_to_report[key][value] = label_key && context[label_key].is_a?(String) ? context[label_key] : nil
        end
      end
    end
  end
end
