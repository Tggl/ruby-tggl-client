# frozen_string_literal: true

require "test_helper"
require 'webmock/minitest'

class TestReporting < Minitest::Test
  def test_report_single_flag
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: { clients: [{ flags: { flagA: [
          { active: true, value: nil, default: nil, count: 1 }
        ] } }] }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    reporter.report_flag("flagA", true)
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end

  def test_report_single_flag_multiple_times
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: { clients: [{ flags: { flagA: [
          { active: true, value: nil, default: nil, count: 3 },
          { active: false, value: nil, default: nil, count: 2 },
        ] } }] }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    reporter.report_flag("flagA", true)
    reporter.report_flag("flagA", false)
    reporter.report_flag("flagA", false)
    reporter.report_flag("flagA", true)
    reporter.report_flag("flagA", true)
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end

  def test_report_multiple_flags_multiple_times
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: { clients: [{ flags: {
          flagA: [
            { active: true, value: nil, default: nil, count: 1 },
            { active: false, value: nil, default: nil, count: 1 },
          ],
          flagB: [
            { active: false, value: nil, default: nil, count: 1 },
            { active: true, value: nil, default: nil, count: 2 },
          ],
        } }] }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    reporter.report_flag("flagA", true)
    reporter.report_flag("flagA", false)
    reporter.report_flag("flagB", false)
    reporter.report_flag("flagB", true)
    reporter.report_flag("flagB", true)
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end

  def test_context_with_string_value
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: {
          receivedProperties: { foo: [123456789, 123456789] },
          receivedValues: { foo: [["bar"]] }
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    Time.stub(:now, 123456789) do
      reporter.report_context({ foo: "bar" })
    end
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end

  def test_context_with_non_string_value
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: {
          receivedProperties: {
            foo: [123456789, 123456789],
            bar: [123456789, 123456789],
          },
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    Time.stub(:now, 123456789) do
      reporter.report_context({ foo: true, bar: 5 })
    end
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end

  def test_context_with_label
    stub_request(:post, "https://api.tggl.io/report")
      .with(
        body: {
          receivedProperties: {
            userId: [123456789, 123456789],
            userName: [123456789, 123456789],
          },
          receivedValues: {
            userId: [["abc", "Alan Turing"], ["def"], ["ghi", "Jeff Bezos"], ["jkl"]],
            userName: [["Elon Musk"], ["Jeff Bezos"], ["Alan Turing"]],
          }
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Tggl-Api-Key' => 'API_KEY'
        })
      .to_return(status: 200, body: [{ slug: "flagA", defaultVariation: { active: true, value: "foo" }, conditions: [] }].to_json)

    reporter = Tggl::Reporting.new("API_KEY")
    Time.stub(:now, 123456789) do
      reporter.report_context({ userId: 'abc', userName: 'Elon Musk' })
      reporter.report_context({ userId: 'def' })
      reporter.report_context({ userId: 'ghi', userName: 'Jeff Bezos' })
      reporter.report_context({ userId: 'jkl', userName: 9 })
      reporter.report_context({ userId: 'abc', userName: 'Alan Turing' })
    end
    reporter.send_report
    assert_requested :post, "https://api.tggl.io/report"
  end
end
