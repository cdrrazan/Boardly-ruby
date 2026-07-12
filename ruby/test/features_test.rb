# frozen_string_literal: true

require_relative "test_helper"

class FeaturesTest < Minitest::Test
  include Builders

  def test_rollover_moves_unfinished_into_active_iteration
    cfg = make_config(features: { rollover: { enabled: true } })
    fields = [status_field(%w[Todo] + ["In Progress", "Done"]), iteration_field([{ id: "it2", title: "Sprint 2" }], [{ id: "it1", title: "Sprint 1" }])]
    to_move = make_item([status_value("In Progress", "2026-07-01T00:00:00Z"), iteration_value("it1", "Sprint 1")], { number: 1 })
    done = make_item([status_value("Done", "2026-07-01T00:00:00Z"), iteration_value("it1", "Sprint 1")], { number: 2 })
    nxt = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it2", "Sprint 2")], { number: 3 })
    client = FakeClient.new

    Boardly::Features::Rollover.run(make_ctx(make_graph(fields, [to_move, done, nxt]), cfg, client))

    assert_equal [{ item_id: to_move.id, iteration_id: "it2" }], client.iterations
  end

  def test_rollover_dry_run_records_but_does_not_mutate
    cfg = make_config(features: { rollover: { enabled: true } })
    fields = [status_field(%w[Todo Done]), iteration_field([{ id: "it2", title: "S2" }], [{ id: "it1", title: "S1" }])]
    item = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S1")], { number: 1 })
    client = FakeClient.new
    ctx = make_ctx(make_graph(fields, [item]), cfg, client, dry_run: true)

    Boardly::Features::Rollover.run(ctx)

    assert_equal 0, client.iterations.length
    assert_equal 1, ctx.audit.count
  end

  def test_rollover_adds_sprint_label_once_per_repo_and_skips_already_labelled
    cfg = make_config(features: { rollover: { enabled: true, add_sprint_label: true, sprint_label_color: "772fd1" } })
    fields = [status_field(%w[Todo Done]), iteration_field([{ id: "it2", title: "2026-S06" }], [{ id: "it1", title: "2026-S05" }])]
    needs = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "2026-S05")], { number: 1 })
    labelled = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "2026-S05")], { number: 2, labels: ["2026-S06"] })
    client = FakeClient.new

    Boardly::Features::Rollover.run(make_ctx(make_graph(fields, [needs, labelled]), cfg, client))

    assert_equal 2, client.iterations.length
    assert_equal [{ name: "2026-S06", color: "772fd1" }], client.ensured_labels
    assert_equal [{ number: 1, labels: ["2026-S06"] }], client.labels_added
  end

  def test_rollover_label_add_dry_run_records_but_does_not_mutate
    cfg = make_config(features: { rollover: { enabled: true, add_sprint_label: true } })
    fields = [status_field(%w[Todo Done]), iteration_field([{ id: "it2", title: "S6" }], [{ id: "it1", title: "S5" }])]
    item = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S5")], { number: 1 })
    ctx = make_ctx(make_graph(fields, [item]), cfg, FakeClient.new, dry_run: true)

    Boardly::Features::Rollover.run(ctx)

    assert_equal 0, ctx.client.ensured_labels.length
    assert_equal 0, ctx.client.labels_added.length
    assert_equal 2, ctx.audit.count # move-iteration + add-label
  end

  def test_stale_nudge_comments_and_mentions_assignees
    cfg = make_config(features: { stale_nudge: { enabled: true, rules: [{ status: "In Progress", days: 3, notify: "assignees" }] } })
    stale = make_item([status_value("In Progress", "2026-07-01T00:00:00Z")], { number: 5, assignees: ["alice"] })
    fresh = make_item([status_value("In Progress", "2026-07-08T12:00:00Z")], { number: 6, assignees: ["bob"] })
    client = FakeClient.new.with_comments([])

    Boardly::Features::StaleNudge.run(make_ctx(make_graph([status_field(["In Progress"])], [stale, fresh]), cfg, client))

    assert_equal 1, client.comments.length
    assert_equal 5, client.comments[0][:number]
    assert_match(/@alice/, client.comments[0][:body])
  end

  def test_stale_nudge_skips_when_marker_exists_for_stint
    cfg = make_config(features: { stale_nudge: { enabled: true, rules: [{ status: "In Progress", days: 3, notify: "assignees" }] } })
    stale = make_item([status_value("In Progress", "2026-07-01T00:00:00Z")], { number: 5, assignees: ["alice"] })
    client = FakeClient.new.with_comments([{ "body" => "<!-- boardly:stale-nudge:in progress -->\nnudge", "created_at" => "2026-07-05T00:00:00Z" }].map { |h| { body: h["body"], created_at: h["created_at"] } })

    Boardly::Features::StaleNudge.run(make_ctx(make_graph([status_field(["In Progress"])], [stale]), cfg, client))

    assert_equal 0, client.comments.length
  end

  def test_sub_issue_gate_warns_and_rolls_up
    cfg = make_config(features: { sub_issue_gate: { enabled: true, guard_statuses: ["Done"], action: "comment" } })
    item = make_item([status_value("Done", "2026-07-08T00:00:00Z")], { number: 7, sub_issues: Boardly::SubIssues.new(total: 3, completed: 1, percent_completed: 33) })
    client = FakeClient.new.with_comments([])

    Boardly::Features::SubIssueGate.run(make_ctx(make_graph([status_field(["Done", "In Progress"]), number_field("Progress")], [item]), cfg, client))

    assert_equal 1, client.comments.length
    assert_match(%r{1/3 sub-issues}, client.comments[0][:body])
    assert_equal [{ item_id: item.id, value: 33 }], client.numbers
  end

  def test_sub_issue_gate_reverts
    cfg = make_config(features: { sub_issue_gate: { enabled: true, guard_statuses: ["Done"], action: "revert", revert_status: "In Progress" } })
    item = make_item([status_value("Done", "2026-07-08T00:00:00Z")], { number: 8, sub_issues: Boardly::SubIssues.new(total: 2, completed: 0, percent_completed: 0) })
    client = FakeClient.new.with_comments([])

    Boardly::Features::SubIssueGate.run(make_ctx(make_graph([status_field(["Done", "In Progress"])], [item]), cfg, client))

    assert_equal [{ item_id: item.id, option_id: "opt-In Progress" }], client.single_selects
  end

  def test_priority_sort_orders_high_first_unknown_last
    cfg = make_config(features: { priority_sort: { enabled: true, order: %w[High Medium Low] } })
    low = make_item([priority_value("Low")], { number: 1 })
    high = make_item([priority_value("High")], { number: 2 })
    none = make_item([], { number: 3 })
    medium = make_item([priority_value("Medium")], { number: 4 })
    client = FakeClient.new

    Boardly::Features::PrioritySort.run(make_ctx(make_graph([priority_field(%w[High Medium Low])], [low, high, none, medium]), cfg, client))

    assert_equal [high.id, medium.id, low.id, none.id], client.positions.map { |p| p[:item_id] }
    assert_nil client.positions[0][:after_id]
    assert_equal high.id, client.positions[1][:after_id]
  end

  def test_priority_sort_noop_when_ordered
    cfg = make_config(features: { priority_sort: { enabled: true, order: %w[High Low] } })
    high = make_item([priority_value("High")], { number: 1 })
    low = make_item([priority_value("Low")], { number: 2 })
    client = FakeClient.new

    Boardly::Features::PrioritySort.run(make_ctx(make_graph([priority_field(%w[High Low])], [high, low]), cfg, client))

    assert_equal 0, client.positions.length
  end

  def test_digest_reports_counts_and_velocity
    cfg = make_config(features: { digest: { enabled: true, post_to: { issue: 42 } } })
    fields = [status_field(%w[Todo Done]), iteration_field([], [{ id: "it1", title: "Sprint 1" }]), number_field("Estimate")]
    done = make_item([status_value("Done", "2026-07-08T00:00:00Z"), iteration_value("it1", "Sprint 1"), estimate_value(5)], { number: 1 })
    carried = make_item([status_value("Todo", "2026-07-08T00:00:00Z"), iteration_value("it1", "Sprint 1"), estimate_value(3)], { number: 2 })
    client = FakeClient.new

    Boardly::Features::Digest.run(make_ctx(make_graph(fields, [done, carried]), cfg, client))

    assert_equal 1, client.comments.length
    body = client.comments[0][:body]
    assert_match(%r{Completed:\*\* 1 / 2}, body)
    assert_match(/Carried over:\*\* 1/, body)
    assert_match(/Velocity:\*\* 5 of 8/, body)
  end

  def test_stale_nudge_broadcasts_to_channels
    cfg = make_config(features: { stale_nudge: { enabled: true, rules: [{ status: "In Progress", days: 1 }] } })
    item = make_item([status_value("In Progress", "2026-07-01T00:00:00Z")], { number: 5, assignees: ["alice"] })
    ch = FakeChannel.new("slack")

    Boardly::Features::StaleNudge.run(make_ctx(make_graph([status_field(["In Progress"])], [item]), cfg, FakeClient.new.with_comments([]), channels: [ch]))

    assert_equal 1, ch.sent.length
    assert_match(/In Progress/, ch.sent[0].markdown)
  end
end
