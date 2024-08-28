# frozen_string_literal: true

require "test_helper"
require 'webmock/minitest'

class TestLocalClient < Minitest::Test
  def test_fetch_config
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    config = client.fetch_config

    assert_equal ({ flagA: { slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] } }), config
  end

  def test_get
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_equal "foo", client.get({}, "flagA")
    assert_equal "foo", client.get({}, "flagA", "bar")
  end

  def test_get_nil
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: nil }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_nil client.get({}, "flagA")
    assert_nil client.get({}, "flagA", "bar")
  end

  def test_get_inactive
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: false, value: "foo" }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_nil client.get({}, "flagA")
    assert_equal "bar", client.get({}, "flagA", "bar")
  end

  def test_get_unknown
    client = Tggl::LocalClient.new("API_KEY")

    assert_nil client.get({}, "flagA")
    assert_equal "bar", client.get({}, "flagA", "bar")
  end

  def test_is_active
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_equal true, client.is_active?({}, "flagA")
  end

  def test_is_active_nil
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: nil }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_equal true, client.is_active?({}, "flagA")
  end

  def test_is_inactive
    stub_request(:get, "https://api.tggl.io/config")
      .with(
        headers: {
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: false, value: "foo" }, conditions: [] }].to_json)

    client = Tggl::LocalClient.new("API_KEY")
    client.fetch_config

    assert_equal false, client.is_active?({}, "flagA")
  end

  def test_is_active_unknown
    client = Tggl::LocalClient.new("API_KEY")

    assert_equal false, client.is_active?({}, "flagA")
  end
end
