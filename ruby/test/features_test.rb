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

  def test_rollover_strips_pulled_in_label_variants_keeps_others
    cfg = make_config(features: { rollover: { enabled: true, remove_labels: ["pulled-in", "pull-in"] } })
    fields = [status_field(%w[Todo Done]), iteration_field([{ id: "it2", title: "S6" }], [{ id: "it1", title: "S5" }])]
    a = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S5")], { number: 1, labels: ["Pulled In", "keep"] })
    b = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S5")], { number: 2, labels: ["pulled-in"] })
    c = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S5")], { number: 3, labels: ["pull in"] })
    d = make_item([status_value("Todo", "2026-07-01T00:00:00Z"), iteration_value("it1", "S5")], { number: 4, labels: ["PULL_IN"] })
    client = FakeClient.new

    Boardly::Features::Rollover.run(make_ctx(make_graph(fields, [a, b, c, d]), cfg, client))

    assert_equal(
      [{ number: 1, name: "Pulled In" }, { number: 2, name: "pulled-in" }, { number: 3, name: "pull in" }, { number: 4, name: "PULL_IN" }],
      client.labels_removed
    )
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

  def test_sprint_start_promotes_pre_parked_cards
    cfg = make_config(features: { sprint_start: { enabled: true, from_statuses: ["Backlog"], to_status: "Ready" } })
    # iteration_field start date is 2026-06-01, before NOW (2026-07-09) → the sprint has started.
    fields = [status_field(%w[Backlog Ready Done]), iteration_field([{ id: "it1", title: "2026-S08" }], [])]
    parked = make_item([status_value("Backlog", "2026-05-01T00:00:00Z"), iteration_value("it1", "2026-S08")], { number: 1 })
    moved_back = make_item([status_value("Backlog", "2026-07-01T00:00:00Z"), iteration_value("it1", "2026-S08")], { number: 2 })
    ready = make_item([status_value("Ready", "2026-05-01T00:00:00Z"), iteration_value("it1", "2026-S08")], { number: 3 })
    client = FakeClient.new

    Boardly::Features::SprintStart.run(make_ctx(make_graph(fields, [parked, moved_back, ready]), cfg, client))

    assert_equal [{ item_id: parked.id, option_id: "opt-Ready" }], client.single_selects
  end

  def test_sprint_start_noop_before_iteration_starts
    cfg = make_config(features: { sprint_start: { enabled: true } })
    future = Boardly::ProjectField.new(
      id: "F_sprint", name: "Sprint", data_type: "ITERATION",
      iterations: [Boardly::IterationInfo.new(id: "it1", title: "2026-S09", start_date: "2026-08-01", duration: 14)],
      completed_iterations: []
    )
    fields = [status_field(%w[Backlog Ready]), future]
    parked = make_item([status_value("Backlog", "2026-05-01T00:00:00Z"), iteration_value("it1", "2026-S09")], { number: 1 })
    client = FakeClient.new

    Boardly::Features::SprintStart.run(make_ctx(make_graph(fields, [parked]), cfg, client))

    assert_equal 0, client.single_selects.length
  end

  def test_sprint_start_dry_run_records_but_does_not_mutate
    cfg = make_config(features: { sprint_start: { enabled: true } })
    fields = [status_field(%w[Backlog Ready Done]), iteration_field([{ id: "it1", title: "2026-S08" }], [])]
    parked = make_item([status_value("Backlog", "2026-05-01T00:00:00Z"), iteration_value("it1", "2026-S08")], { number: 1 })
    ctx = make_ctx(make_graph(fields, [parked]), cfg, FakeClient.new, dry_run: true)

    Boardly::Features::SprintStart.run(ctx)

    assert_equal 0, ctx.client.single_selects.length
    assert_equal 1, ctx.audit.count
  end

  def test_sprint_runway_warns_when_no_future_iteration_planned
    cfg = make_config(features: { sprint_runway: { enabled: true, min_future: 1 } })
    # Helper iterations start 2026-06-01 (before NOW) → current only, zero future planned.
    fields = [iteration_field([{ id: "it1", title: "2026-S08" }], [])]
    ctx = make_ctx(make_graph(fields, []), cfg, FakeClient.new)

    Boardly::Features::SprintRunway.run(ctx)

    assert_equal 1, ctx.audit.count
  end

  def test_sprint_runway_quiet_when_enough_future_planned
    cfg = make_config(features: { sprint_runway: { enabled: true, min_future: 1 } })
    field = Boardly::ProjectField.new(
      id: "F_sprint", name: "Sprint", data_type: "ITERATION",
      iterations: [
        Boardly::IterationInfo.new(id: "it1", title: "2026-S08", start_date: "2026-06-01", duration: 14),
        Boardly::IterationInfo.new(id: "it2", title: "2026-S09", start_date: "2026-08-01", duration: 14)
      ],
      completed_iterations: []
    )
    ctx = make_ctx(make_graph([field], []), cfg, FakeClient.new)

    Boardly::Features::SprintRunway.run(ctx)

    assert_equal 0, ctx.audit.count
  end

  def test_auto_assign_maps_labels_and_unions_matches
    cfg = make_config(features: {
      auto_assign: {
        enabled: true, only_statuses: ["Ready"],
        rules: [{ label: "UI", assignees: ["zach"] }, { label: "security", assignees: ["rajan"] }]
      }
    })
    fields = [status_field(%w[Ready Backlog Done])]
    ui = make_item([status_value("Ready", NOW.iso8601)], { number: 1, labels: ["UI"] })
    both = make_item([status_value("Ready", NOW.iso8601)], { number: 2, labels: %w[UI security] })
    owned = make_item([status_value("Ready", NOW.iso8601)], { number: 3, labels: ["UI"], assignees: ["someone"] })
    not_ready = make_item([status_value("Backlog", NOW.iso8601)], { number: 4, labels: ["UI"] })
    unmapped = make_item([status_value("Ready", NOW.iso8601)], { number: 5, labels: ["docs"] })
    client = FakeClient.new

    Boardly::Features::AutoAssign.run(make_ctx(make_graph(fields, [ui, both, owned, not_ready, unmapped]), cfg, client))

    assert_equal [{ number: 1, assignees: ["zach"] }, { number: 2, assignees: %w[zach rajan] }], client.assignees_added
  end

  def test_auto_assign_matches_labels_case_insensitively
    cfg = make_config(features: {
      auto_assign: { enabled: true, only_statuses: ["Ready"], rules: [{ label: "uI", assignees: ["zach"] }] }
    })
    fields = [status_field(%w[Ready])]
    # Rule says "uI"; board labels use assorted casings — all must match.
    a = make_item([status_value("Ready", NOW.iso8601)], { number: 1, labels: ["UI"] })
    b = make_item([status_value("Ready", NOW.iso8601)], { number: 2, labels: ["ui"] })
    c = make_item([status_value("Ready", NOW.iso8601)], { number: 3, labels: ["Ui"] })
    client = FakeClient.new

    Boardly::Features::AutoAssign.run(make_ctx(make_graph(fields, [a, b, c]), cfg, client))

    assert_equal [{ number: 1, assignees: ["zach"] }, { number: 2, assignees: ["zach"] }, { number: 3, assignees: ["zach"] }], client.assignees_added
  end

  def test_auto_assign_dry_run_records_but_does_not_mutate
    cfg = make_config(features: {
      auto_assign: { enabled: true, only_statuses: ["Ready"], rules: [{ label: "UI", assignees: ["zach"] }] }
    })
    item = make_item([status_value("Ready", NOW.iso8601)], { number: 1, labels: ["UI"] })
    ctx = make_ctx(make_graph([status_field(%w[Ready])], [item]), cfg, FakeClient.new, dry_run: true)

    Boardly::Features::AutoAssign.run(ctx)

    assert_equal 0, ctx.client.assignees_added.length
    assert_equal 1, ctx.audit.count
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

  def test_stale_nudge_notifies_assignees_plus_extra_logins
    cfg = make_config(features: { stale_nudge: { enabled: true, rules: [{ status: "In Progress", days: 3, notify: ["assignees", "project-manager", "@alice"] }] } })
    stale = make_item([status_value("In Progress", "2026-07-01T00:00:00Z")], { number: 5, assignees: ["alice"] })
    client = FakeClient.new.with_comments([])

    Boardly::Features::StaleNudge.run(make_ctx(make_graph([status_field(["In Progress"])], [stale]), cfg, client))

    body = client.comments[0][:body]
    assert_match(/@alice/, body)
    assert_match(/@project-manager/, body)
    assert_equal 1, body.scan("@alice").length, "assignee should not be mentioned twice"
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
