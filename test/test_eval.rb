# frozen_string_literal: true

require "test_helper"
require 'json'

class TestEval < Minitest::Test
  JSON_DATA = JSON.parse(File.read('test/standard_tests.json'), symbolize_names: true)

  JSON_DATA.each_with_index do |test_case, index|
    define_method("test_#{index}_#{test_case[:name].gsub(/[^A-Z0-9]+/i, '_').downcase}") do
      assert_equal test_case[:expected], Tggl::LocalClient.eval_flag(test_case[:flag], test_case[:context])
    end
  end
end
