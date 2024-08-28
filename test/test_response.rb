# frozen_string_literal: true

require "test_helper"
require 'webmock/minitest'

class TestResponse < Minitest::Test
  def test_active_flag
    response = Tggl::Response.new({ flagA: "foo", flagB: "bar" })

    assert_equal true, response.is_active?("flagA")
  end

  def test_inactive_flag
    response = Tggl::Response.new({ flagA: "foo", flagB: "bar" })

    assert_equal false, response.is_active?("flagC")
  end

  def test_active_falsy_flag
    response = Tggl::Response.new({ flagA: false, flagB: "" , flagC: 0 , flagD: nil })

    assert_equal true, response.is_active?("flagA")
    assert_equal true, response.is_active?("flagB")
    assert_equal true, response.is_active?("flagC")
    assert_equal true, response.is_active?("flagD")
  end

  def test_get_active_flag
    response = Tggl::Response.new({ flagA: false, flagB: "foo", flagC: 0 })

    assert_equal false, response.get("flagA")
    assert_equal "foo", response.get("flagB")
    assert_equal 0, response.get("flagC")
  end

  def test_get_active_flag_with_default
    response = Tggl::Response.new({ flagA: false, flagB: "foo", flagC: 0 })

    assert_equal false, response.get("flagA", "default")
    assert_equal "foo", response.get("flagB", "default")
    assert_equal 0, response.get("flagC", "default")
  end

  def test_get_inactive_flag
    response = Tggl::Response.new({ })

    assert_nil response.get("flagA")
  end

  def test_get_inactive_flag_with_default
    response = Tggl::Response.new({ })

    assert_equal "default", response.get("flagA", "default")
  end
end
