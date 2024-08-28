# frozen_string_literal: true

require 'net/http'
require 'json'

module Tggl
  class Reporting
    def initialize(api_key = nil, options = {})
      @api_key = api_key
      @url = options[:url] || 'https://api.tggl.io/report'
      @app = options[:app]
      @app_prefix = options[:app_prefix]
      @last_report_time = Time.now.to_i
    end

    def send_report

    end

    def report_flag(slug, active, value = nil, default = nil)

    end

    def report_context(context)

    end
  end
end
