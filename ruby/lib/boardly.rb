# frozen_string_literal: true

require "time"
require_relative "boardly/model"
require_relative "boardly/config"
require_relative "boardly/audit"
require_relative "boardly/github/client"
require_relative "boardly/notify/notifier"
require_relative "boardly/features/rollover"
require_relative "boardly/features/sprint_start"
require_relative "boardly/features/stale_nudge"
require_relative "boardly/features/sub_issue_gate"
require_relative "boardly/features/digest"
require_relative "boardly/features/standup"
require_relative "boardly/features/priority_sort"

# Boardly — config-driven automation for GitHub Projects (v2), Ruby edition.
module Boardly
  RUNNERS = {
    "rollover" => Features::Rollover,
    "sprint-start" => Features::SprintStart,
    "stale-nudge" => Features::StaleNudge,
    "sub-issue-gate" => Features::SubIssueGate,
    "digest" => Features::Digest,
    "standup" => Features::Standup,
    "priority-sort" => Features::PrioritySort
  }.freeze

  # Whether a feature is turned on in config.
  def self.enabled?(cfg, key)
    case key
    when "rollover" then cfg.features[:rollover][:enabled]
    when "sprint-start" then cfg.features[:sprint_start][:enabled]
    when "stale-nudge" then cfg.features[:stale_nudge][:enabled]
    when "sub-issue-gate" then cfg.features[:sub_issue_gate][:enabled]
    when "digest" then !(cfg.features[:digest] && cfg.features[:digest][:enabled]).nil? && cfg.features[:digest][:enabled] == true
    when "standup" then !(cfg.features[:standup] && cfg.features[:standup][:enabled]).nil? && cfg.features[:standup][:enabled] == true
    when "priority-sort" then !(cfg.features[:priority_sort] && cfg.features[:priority_sort][:enabled]).nil? && cfg.features[:priority_sort][:enabled] == true
    end
  end

  # Entry point: read inputs (from env), load + validate config, fetch the project
  # once, then run either the single feature named by `only` or every enabled one.
  def self.run(env: ENV)
    token = (env["BOARDLY_TOKEN"] || "").strip
    raise "token input is required" if token.empty?

    config_path = env["BOARDLY_CONFIG_PATH"]
    config_path = ".github/project-automation.yml" if config_path.nil? || config_path.empty?
    only = (env["BOARDLY_ONLY"] || "").strip
    dry_run = %w[true 1 yes].include?((env["BOARDLY_DRY_RUN"] || "").strip.downcase)

    if !only.empty? && !RUNNERS.key?(only)
      raise %(Unknown "only" value "#{only}". Valid: #{RUNNERS.keys.join(", ")}.)
    end

    cfg = Config.load_file(config_path)
    client = GitHub::Client.new(token)

    puts "Fetching project ##{cfg.project[:number]} (#{cfg.project[:type]}: #{cfg.project[:owner]})…"
    graph = client.fetch_project(cfg.project[:owner], cfg.project[:type], cfg.project[:number])
    puts %(Loaded "#{graph.title}" — #{graph.items.length} items, #{graph.fields.length} fields.)

    audit = Audit.new(dry_run)
    notifier = Notify::Notifier.build(cfg, env, dry_run, audit)
    puts "Notifications: #{notifier.channel_count} external channel(s) active." if notifier.channel_count.positive?

    owner, repo = (env["GITHUB_REPOSITORY"] || "/").split("/", 2)
    ctx = RunContext.new(
      cfg: cfg, client: client, graph: graph, audit: audit, notifier: notifier,
      dry_run: dry_run, now: Time.now.utc, run_repo: { owner: owner, repo: repo }
    )

    selected = only.empty? ? RUNNERS.keys : [only]
    failed = false
    selected.each do |key|
      next if only.empty? && !enabled?(cfg, key)

      puts %(::warning::Feature "#{key}" requested via "only" but is not enabled in config; running it anyway.) if !only.empty? && !enabled?(cfg, key)
      puts "::group::Feature: #{key}"
      begin
        RUNNERS[key].run(ctx)
      rescue StandardError => e
        puts %(::error::Feature "#{key}" failed: #{e.message})
        failed = true
      ensure
        puts "::endgroup::"
      end
    end

    audit.flush(graph.title)
    write_output("actions-count", audit.count, env)
    puts "Done. #{audit.count} action(s)#{dry_run ? " (dry-run)" : ""}."
    exit(1) if failed
  end

  def self.write_output(name, value, env)
    out = env["GITHUB_OUTPUT"]
    File.write(out, "#{name}=#{value}\n", mode: "a") if out && !out.empty?
  end
end
