# frozen_string_literal: true

require_relative "test_helper"
require "boardly/github/normalize"

class NormalizeTest < Minitest::Test
  N = Boardly::GitHub::Normalize

  def test_fields_maps_options_and_drops_empty
    fields = N.fields([
                        { "id" => "F1", "name" => "Status", "dataType" => "SINGLE_SELECT", "options" => [{ "id" => "o1", "name" => "Todo" }] },
                        {}
                      ])
    assert_equal 1, fields.length
    assert_equal [{ id: "o1", name: "Todo" }], fields[0].options
  end

  def test_fields_reverses_completed_iterations
    field = N.fields([{
                       "id" => "F2", "name" => "Sprint", "dataType" => "ITERATION",
                       "configuration" => {
                         "iterations" => [{ "id" => "it3", "title" => "S3", "startDate" => "2026-07-01", "duration" => 14 }],
                         "completedIterations" => [
                           { "id" => "it1", "title" => "S1", "startDate" => "2026-06-01", "duration" => 14 },
                           { "id" => "it2", "title" => "S2", "startDate" => "2026-06-15", "duration" => 14 }
                         ]
                       }
                     }]).first
    assert_equal %w[it3], field.iterations.map(&:id)
    assert_equal %w[it2 it1], field.completed_iterations.map(&:id)
  end

  def test_item_extracts_typed_values_and_skips_unknown
    item = N.item(
      "id" => "PVTI_1", "updatedAt" => "2026-07-08T00:00:00Z",
      "fieldValues" => { "nodes" => [
        { "__typename" => "ProjectV2ItemFieldSingleSelectValue", "name" => "In Progress", "optionId" => "opt1", "updatedAt" => "t", "field" => { "name" => "Status" } },
        { "__typename" => "ProjectV2ItemFieldNumberValue", "number" => 5, "updatedAt" => "t", "field" => { "name" => "Estimate" } },
        { "__typename" => "ProjectV2ItemFieldSingleSelectValue", "name" => "orphan", "updatedAt" => "t" },
        { "__typename" => "Unknown", "updatedAt" => "t", "field" => { "name" => "X" } }
      ] },
      "content" => nil
    )
    assert_equal 2, item.field_values.length
    assert_equal "In Progress", item.field_values.find { |v| v.field_name == "Status" }.single_select.name
    assert_equal 5, item.field_values.find { |v| v.field_name == "Estimate" }.number
    assert_nil item.content
  end

  def test_item_maps_issue_with_subissues_and_parent
    item = N.item(
      "id" => "PVTI_2", "updatedAt" => "t", "fieldValues" => { "nodes" => [] },
      "content" => {
        "__typename" => "Issue", "id" => "I_10", "number" => 10, "title" => "Epic", "url" => "u",
        "state" => "OPEN", "closedAt" => nil, "updatedAt" => "t",
        "repository" => { "owner" => { "login" => "acme" }, "name" => "repo" },
        "assignees" => { "nodes" => [{ "login" => "alice" }, { "login" => "bob" }] },
        "labels" => { "nodes" => [{ "name" => "pulled-in" }, { "name" => "2026-S06" }] },
        "subIssuesSummary" => { "total" => 4, "completed" => 3, "percentCompleted" => 75 },
        "parent" => { "number" => 2, "title" => "Parent", "url" => "pu" }
      }
    )
    assert_equal "Issue", item.content.type
    assert_equal %w[alice bob], item.content.assignees
    assert_equal ["pulled-in", "2026-S06"], item.content.labels
    assert_equal 75, item.content.sub_issues.percent_completed
    assert_equal 2, item.content.parent.number
  end

  def test_item_treats_draft_as_no_content
    item = N.item("id" => "d", "updatedAt" => "t", "fieldValues" => { "nodes" => [] }, "content" => { "__typename" => "DraftIssue", "title" => "idea" })
    assert_nil item.content
  end
end
