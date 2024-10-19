# frozen_string_literal: true

require 'net/http'
require 'json'
require 'xxhash'

module Tggl
  class LocalClient
    def initialize(api_key = nil, options = {})
      @api_key = api_key
      @config = options[:config] || {}
      @url = options[:url] || 'https://api.tggl.io/config'
      @reporter = api_key.nil? || options[:reporting] == false ? nil :  Reporting.new(
        api_key,
        app_prefix: "ruby-client:#{VERSION}/LocalClient",
        url: options[:reporting] == true ? nil : options[:reporting]&.[](:url),
        app: options[:reporting] == true ? nil : options[:reporting]&.[](:app)
      )
    end

    def fetch_config
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.path, {
        'X-Tggl-Api-Key' => @api_key,
      })

      response = http.request(request)
      result = JSON.parse(response.body, symbolize_names: true)

      if response.code.to_i > 200
        if result.nil?
          raise StandardError.new "Invalid response from Tggl: #{response.code}"
        end
        raise StandardError.new result['error']
      end

      @config = Hash.new

      result.each do |flag|
        @config[flag[:slug].to_sym] = flag
      end

      @config
    end

    def is_active?(context, slug)
      result = @config.key?(slug.to_sym) ? LocalClient.eval_flag(@config[slug.to_sym], context) : { active: false, value: nil }

      if @reporter != nil
        @reporter.report_flag(slug, result[:active], result[:value])
        @reporter.report_context(context)
      end

      result[:active]
    end

    def get(context, slug, default_value = nil)
      result = @config.key?(slug.to_sym) ? LocalClient.eval_flag(@config[slug.to_sym], context) : { active: false, value: nil }
      value = result[:active] ? result[:value] : default_value

      if @reporter != nil
        @reporter.report_flag(slug, result[:active], result[:value], default_value)
        @reporter.report_context(context)
      end

      value
    end

    def all_active_flags(context)
      if @reporter != nil
        @reporter.report_context(context)
      end

      @config.map do |slug, flag|
        result = LocalClient.eval_flag(flag, context)
        result[:active] ? [slug, result[:value]] : nil
      end.compact.to_h
    end

    def LocalClient.eval_flag(flag, context)
      flag[:conditions].each do |condition|
        if LocalClient.eval_condition(condition, context)
          return condition[:variation][:active] ? condition[:variation] : { active: false, value: nil }
        end
      end

      flag[:defaultVariation][:active] ? flag[:defaultVariation] : { active: false, value: nil }
    end

    def LocalClient.eval_condition(condition, context)
      condition[:rules].each do |rule|
        unless LocalClient.eval_rule(rule, context)
          return false
        end
      end

      true
    end

    def LocalClient.eval_rule(rule, context)
      value = context[rule[:key].to_sym]

      if rule[:operator] === "EMPTY"
        is_empty = value === nil || value === ""
        return is_empty != rule[:negate]
      end

      if value === nil
        return false
      end

      if rule[:operator] === "STR_EQUAL"
        return false unless value.is_a?(String)
        return rule[:values].include?(value) != rule[:negate]
      end

      if rule[:operator] === "STR_EQUAL_SOFT"
        return false unless value.is_a?(String) || value.is_a?(Integer) || value.is_a?(Float)
        return rule[:values].include?(value.to_s.downcase) != rule[:negate]
      end

      if rule[:operator] === "STR_CONTAINS"
        return false unless value.is_a?(String)
        return rule[:values].any? { |val| value.include?(val) } != rule[:negate]
      end

      if rule[:operator] === "STR_STARTS_WITH"
        return false unless value.is_a?(String)
        return rule[:values].any? { |val| value.start_with?(val) } != rule[:negate]
      end

      if rule[:operator] === "STR_ENDS_WITH"
        return false unless value.is_a?(String)
        return rule[:values].any? { |val| value.end_with?(val) } != rule[:negate]
      end

      if rule[:operator] === "STR_AFTER"
        return false unless value.is_a?(String)
        return (value >= rule[:value]) != (rule[:negate].nil? ? false : rule[:negate])
      end

      if rule[:operator] === "STR_BEFORE"
        return false unless value.is_a?(String)
        return (value <= rule[:value]) != (rule[:negate].nil? ? false : rule[:negate])
      end

      if rule[:operator] === "REGEXP"
        return false unless value.is_a?(String)
        return (/#{rule[:value]}/.match?(value)) != rule[:negate]
      end

      if rule[:operator] === "TRUE"
        return value == !rule[:negate]
      end

      if rule[:operator] === "EQ"
        return false unless value.is_a?(Integer) || value.is_a?(Float)
        return (value == rule[:value]) != rule[:negate]
      end

      if rule[:operator] === "LT"
        return false unless value.is_a?(Integer) || value.is_a?(Float)
        return (value < rule[:value]) != rule[:negate]
      end

      if rule[:operator] === "GT"
        return false unless value.is_a?(Integer) || value.is_a?(Float)
        return (value > rule[:value]) != rule[:negate]
      end

      if rule[:operator] === "ARR_OVERLAP"
        return false unless value.is_a?(Array)
        return value.any? { |val| rule[:values].include?(val) } != rule[:negate]
      end

      if rule[:operator] === "DATE_AFTER"
        if value.is_a?(String)
          val = value[0, '2000-01-01T23:59:59'.length] + ('2000-01-01T23:59:59'[value.length..] || "")
          return (rule[:iso] <= val) != (rule[:negate].nil? ? false : rule[:negate])
        elsif value.is_a?(Integer) || value.is_a?(Float)
          return (value < 631_152_000_000 ? (value * 1000 >= rule[:timestamp]) : (value >= rule[:timestamp])) != (rule[:negate].nil? ? false : rule[:negate])
        end
        return false
      end

      if rule[:operator] === "DATE_BEFORE"
        if value.is_a?(String)
          val = value[0, '2000-01-01T00:00:00'.length] + ('2000-01-01T00:00:00'[value.length..] || "")
          return (rule[:iso] >= val) != (rule[:negate].nil? ? false : rule[:negate])
        elsif value.is_a?(Integer) || value.is_a?(Float)
          return (value < 631_152_000_000 ? (value * 1000 <= rule[:timestamp]) : (value <= rule[:timestamp])) != (rule[:negate].nil? ? false : rule[:negate])
        end
        return false
      end

      if rule[:operator] === "SEMVER_EQ"
        return false unless value.is_a?(String)
        sem_ver = value.split('.').map(&:to_i)
        return rule[:version].each_with_index.all? do |v, i|
          sem_ver[i] == v
        end != rule[:negate]
      end

      if rule[:operator] === "SEMVER_GTE"
        return false unless value.is_a?(String)
        sem_ver = value.split('.').map(&:to_i)
        rule[:version].each_with_index do |v, i|
          if i >= sem_ver.length
            return rule[:negate]
          end

          if sem_ver[i] > v
            return !rule[:negate]
          end

          if sem_ver[i] < v
            return rule[:negate]
          end
        end

        return !rule[:negate]
      end

      if rule[:operator] === "SEMVER_LTE"
        return false unless value.is_a?(String)
        sem_ver = value.split('.').map(&:to_i)
        rule[:version].each_with_index do |v, i|
          if i >= sem_ver.length
            return rule[:negate]
          end

          if sem_ver[i] < v
            return !rule[:negate]
          end

          if sem_ver[i] > v
            return rule[:negate]
          end
        end

        return !rule[:negate]
      end

      if rule[:operator] === "PERCENTAGE"
        return false unless value.is_a?(String) || value.is_a?(Integer) || value.is_a?(Float)
        probability = XXhash.xxh32(value.to_s, rule[:seed]) / 0xFFFFFFFF.to_f
        probability -= 1.0e-8 if probability == 1
        return (probability >= rule[:rangeStart] && probability < rule[:rangeEnd]) != (rule[:negate].nil? ? false : rule[:negate])
      end

      raise StandardError.new "Unsupported operator #{rule[:operator]}"
    end
  end
end
