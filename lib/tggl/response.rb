# frozen_string_literal: true

module Tggl
  class Response
    def initialize(flags, reporter = nil)
      @flags = flags
      @reporter = reporter
    end

    def is_active?(slug)
      active = @flags.key?(slug.to_sym)

      if @reporter != nil
        @reporter.report_flag(slug, active, active ? @flags[slug.to_sym] : nil)
      end

      active
    end

    def get(slug, default_value = nil)
      value = @flags.key?(slug.to_sym) ? @flags[slug.to_sym] : default_value

      if @reporter != nil
        @reporter.report_flag(slug, @flags.key?(slug.to_sym), value, default_value)
      end

      value
    end

    def all_active_flags
      @flags
    end
  end
end