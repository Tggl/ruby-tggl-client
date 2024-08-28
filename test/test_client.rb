# frozen_string_literal: true

require "test_helper"
require 'webmock/minitest'

class TestClient < Minitest::Test
  def test_eval_single_context
    stub_request(:post, "https://api.tggl.io/flags")
      .with(
        body: [{ foo: "bar" }].to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ flagA: "foo", flagB: "bar" }].to_json)

    client = Tggl::Client.new("API_KEY")
    active_flags = client.eval_context({ foo: "bar" }).all_active_flags

    assert_equal ({ flagA: "foo", flagB: "bar" }), active_flags
  end

  def test_eval_multiple_contexts
    stub_request(:post, "https://api.tggl.io/flags")
      .with(
        body: [{ foo: "bar" }, { baz: "qux" }].to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ flagA: "foo" }, { flagB: "bar" }].to_json)

    client = Tggl::Client.new("API_KEY")
    response1, response2 = client.eval_contexts([{ foo: "bar" }, { baz: "qux" }])

    assert_equal ({ flagA: "foo" }), response1.all_active_flags
    assert_equal ({ flagB: "bar" }), response2.all_active_flags
  end

  def test_fullstack
    stub_request(:post, "https://api.tggl.io/flags")
      .with(
        body: [{ foo: "bar" }].to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ flagA: "foo" }].to_json)

    client = Tggl::Client.new("API_KEY")
    flags = client.eval_context({ foo: "bar" })

    assert_equal true, flags.is_active?("flagA")
    assert_equal "foo", flags.get("flagA")
  end
end
