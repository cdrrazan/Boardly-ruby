# frozen_string_literal: true

require "minitest/autorun"
require "time"
require "boardly"

NOW = Time.iso8601("2026-07-09T00:00:00Z")

# Records every mutating call so tests can assert on them.
class FakeClient
  attr_reader :positions, :iterations, :single_selects, :numbers, :comments, :created_issues,
              :ensured_labels, :labels_added

  def initialize
    @positions = []
    @iterations = []
    @single_selects = []
    @numbers = []
    @comments = []
    @created_issues = []
    @ensured_labels = []
    @labels_added = []
    @canned = []
  end

  def with_comments(comments)
    @canned = comments
    self
  end

  def set_position(_p, item_id, after_id) = @positions << { item_id: item_id, after_id: after_id }
  def set_iteration(_p, item_id, _f, iteration_id) = @iterations << { item_id: item_id, iteration_id: iteration_id }
  def set_single_select(_p, item_id, _f, option_id) = @single_selects << { item_id: item_id, option_id: option_id }
  def set_number(_p, item_id, _f, value) = @numbers << { item_id: item_id, value: value }
  def ensure_label(_o, _r, name, color) = @ensured_labels << { name: name, color: color }
  def add_labels(_o, _r, number, labels) = @labels_added << { number: number, labels: labels }
  def comment(_o, _r, number, body) = @comments << { number: number, body: body }
  def list_comments(*) = @canned
  def create_issue(_o, _r, title, _b, _l)
    @created_issues << { title: title }
    999
  end
end

# Records every broadcast report.
class FakeChannel
  attr_reader :sent, :name

  def initialize(name = "fake")
    @name = name
    @sent = []
  end

  def target = "fake"
  def send(report) = @sent << report
end

module Builders
  def make_config(overrides = {})
    raw = {
      project: { owner: "acme", type: "org", number: 1 },
      fields: { status: "Status", iteration: "Sprint", priority: "Priority", estimate: "Estimate", progress: "Progress" },
      done_statuses: ["Done"],
      features: {}
    }.merge(overrides)
    Boardly::Config.new(raw)
  end

  def status_value(name, updated_at)
    Boardly::FieldValue.new(field_name: "Status", updated_at: updated_at, single_select: Boardly::SingleSelectValue.new(name: name, option_id: "opt-#{name}"))
  end

  def iteration_value(iteration_id, title)
    Boardly::FieldValue.new(field_name: "Sprint", updated_at: NOW.iso8601, iteration: Boardly::IterationValue.new(title: title, iteration_id: iteration_id))
  end

  def priority_value(name)
    Boardly::FieldValue.new(field_name: "Priority", updated_at: NOW.iso8601, single_select: Boardly::SingleSelectValue.new(name: name, option_id: "p-#{name}"))
  end

  def estimate_value(num)
    Boardly::FieldValue.new(field_name: "Estimate", updated_at: NOW.iso8601, number: num)
  end

  def make_item(field_values, content = nil)
    @seq = (@seq || 0) + 1
    c = nil
    if content
      c = Boardly::IssueContent.new(
        type: "Issue", node_id: "I_#{content[:number]}", number: content[:number],
        title: content[:title] || "Item #{content[:number]}",
        url: content[:url] || "https://github.com/acme/repo/issues/#{content[:number]}",
        state: "OPEN", closed_at: nil, updated_at: NOW.iso8601, repo_owner: "acme", repo_name: "repo",
        assignees: content[:assignees] || [], labels: content[:labels] || [], sub_issues: content[:sub_issues], parent: nil
      )
    end
    Boardly::ProjectItem.new(id: "PVTI_#{@seq}", updated_at: NOW.iso8601, field_values: field_values, content: c)
  end

  def status_field(opts) = Boardly::ProjectField.new(id: "F_status", name: "Status", data_type: "SINGLE_SELECT", options: opts.map { |o| { id: "opt-#{o}", name: o } })
  def priority_field(opts) = Boardly::ProjectField.new(id: "F_priority", name: "Priority", data_type: "SINGLE_SELECT", options: opts.map { |o| { id: "p-#{o}", name: o } })
  def number_field(name) = Boardly::ProjectField.new(id: "F_#{name}", name: name, data_type: "NUMBER")

  def iteration_field(active, completed)
    map = ->(i) { Boardly::IterationInfo.new(id: i[:id], title: i[:title], start_date: "2026-06-01", duration: 14) }
    Boardly::ProjectField.new(id: "F_sprint", name: "Sprint", data_type: "ITERATION", iterations: active.map(&map), completed_iterations: completed.map(&map))
  end

  def make_graph(fields, items) = Boardly::ProjectGraph.new(id: "PVT_1", title: "Test Board", fields: fields, items: items)

  def make_ctx(graph, cfg, client, dry_run: false, channels: [])
    audit = Boardly::Audit.new(dry_run)
    Boardly::RunContext.new(
      cfg: cfg, client: client, graph: graph, audit: audit,
      notifier: Boardly::Notify::Notifier.new(channels, dry_run, audit),
      dry_run: dry_run, now: NOW, run_repo: { owner: "acme", repo: "repo" }
    )
  end
end
