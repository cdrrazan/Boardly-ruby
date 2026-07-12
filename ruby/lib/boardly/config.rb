# frozen_string_literal: true

require "yaml"

module Boardly
  class ConfigError < StandardError; end

  # Loads, validates, and exposes the YAML config (mirrors the TS zod schema).
  # Access via readers; defaults match the TypeScript version.
  class Config
    attr_reader :project, :fields, :done_statuses, :features, :notifications

    def initialize(raw)
      @errors = []
      data = deep_symbolize(raw || {})

      @project = validate_project(data[:project])
      @fields = with_defaults(data[:fields], {
        status: "Status", iteration: "Iteration", priority: "Priority",
        estimate: nil, progress: nil
      })
      @done_statuses = array_of_strings(data[:done_statuses], default: ["Done"], path: "doneStatuses")
      @features = validate_features(data[:features] || {})
      @notifications = validate_notifications(data[:notifications])

      raise ConfigError, "Config is invalid:\n#{@errors.map { |e| "  - #{e}" }.join("\n")}" unless @errors.empty?
    end

    # Reads and parses a config file from disk.
    def self.load_file(path)
      raw = File.read(path)
      new(YAML.safe_load(raw, permitted_classes: [], aliases: false))
    rescue Errno::ENOENT
      raise ConfigError, %(Could not read config file at "#{path}". Set the "config-path" input if it lives elsewhere.)
    rescue Psych::SyntaxError => e
      raise ConfigError, %(Config file "#{path}" is not valid YAML: #{e.message})
    end

    private

    def validate_project(p)
      unless p.is_a?(Hash)
        @errors << "project: is required"
        return { owner: nil, type: "org", number: nil }
      end
      @errors << "project.owner: is required" if blank?(p[:owner])
      @errors << "project.number: must be a positive integer" unless p[:number].is_a?(Integer) && p[:number].positive?
      type = p[:type] || "org"
      @errors << %(project.type: must be "org" or "user") unless %w[org user].include?(type.to_s)
      { owner: p[:owner], type: type.to_s, number: p[:number] }
    end

    def validate_features(f)
      {
        rollover: {
          enabled: truthy(f.dig(:rollover, :enabled)),
          only_statuses: array_of_strings(f.dig(:rollover, :only_statuses) || f.dig(:rollover, :onlyStatuses), default: [], path: "rollover.onlyStatuses"),
          add_sprint_label: truthy(f.dig(:rollover, :add_sprint_label) || f.dig(:rollover, :addSprintLabel)),
          sprint_label_color: validate_hex_color(f.dig(:rollover, :sprint_label_color) || f.dig(:rollover, :sprintLabelColor))
        },
        stale_nudge: {
          enabled: truthy(f.dig(:stale_nudge, :enabled) || f.dig(:staleNudge, :enabled)),
          rules: validate_rules(f.dig(:stale_nudge, :rules) || f.dig(:staleNudge, :rules) || [])
        },
        sub_issue_gate: validate_gate(f[:sub_issue_gate] || f[:subIssueGate] || {}),
        digest: validate_post_feature(f[:digest], "digest"),
        standup: validate_standup(f[:standup]),
        priority_sort: validate_priority(f[:priority_sort] || f[:prioritySort])
      }
    end

    def validate_rules(rules)
      Array(rules).map.with_index do |r, i|
        @errors << "staleNudge.rules[#{i}].status: is required" if blank?(r[:status])
        @errors << "staleNudge.rules[#{i}].days: must be > 0" unless numeric_positive?(r[:days])
        notify = r[:notify] || "assignees"
        notify = notify == "assignees" ? "assignees" : array_of_strings(notify, default: [], path: "staleNudge.rules[#{i}].notify")
        { status: r[:status], days: r[:days], notify: notify, message: r[:message] }
      end
    end

    def validate_gate(g)
      action = (g[:action] || "comment").to_s
      @errors << %(subIssueGate.action: must be "comment" or "revert") unless %w[comment revert].include?(action)
      {
        enabled: truthy(g[:enabled]),
        guard_statuses: array_of_strings(g[:guard_statuses] || g[:guardStatuses], default: ["Done"], path: "subIssueGate.guardStatuses"),
        action: action,
        revert_status: g[:revert_status] || g[:revertStatus]
      }
    end

    def validate_post_feature(d, name)
      return nil if d.nil?
      { enabled: truthy(d[:enabled]), post_to: validate_post_to(d[:post_to] || d[:postTo], name) }
    end

    def validate_standup(s)
      return nil if s.nil?
      hours = s[:since_hours] || s[:sinceHours] || 24
      @errors << "standup.sinceHours: must be > 0" unless numeric_positive?(hours)
      { enabled: truthy(s[:enabled]), since_hours: hours, post_to: validate_post_to(s[:post_to] || s[:postTo], "standup") }
    end

    def validate_priority(p)
      return nil if p.nil?
      order = array_of_strings(p[:order], default: [], path: "prioritySort.order")
      @errors << "prioritySort.order: needs at least one value" if order.empty?
      { enabled: truthy(p[:enabled]), order: order }
    end

    def validate_post_to(pt, feature)
      pt ||= {}
      issue = pt[:issue]
      title = pt[:create_issue_title] || pt[:createIssueTitle]
      if issue.nil? && blank?(title)
        @errors << "#{feature}.postTo: requires either `issue` or `createIssueTitle`"
      end
      { issue: issue, create_issue_title: title, labels: array_of_strings(pt[:labels], default: [], path: "#{feature}.postTo.labels") }
    end

    def validate_notifications(n)
      return nil if n.nil?
      out = {}
      if n[:slack]
        out[:slack] = { enabled: truthy(n.dig(:slack, :enabled)), webhook_env: n.dig(:slack, :webhook_env) || n.dig(:slack, :webhookEnv) || "SLACK_WEBHOOK_URL" }
      end
      if (e = n[:email])
        @errors << "notifications.email.host: is required" if blank?(e[:host])
        @errors << "notifications.email.from: is required" if blank?(e[:from])
        to = array_of_strings(e[:to], default: [], path: "notifications.email.to")
        @errors << "notifications.email.to: needs at least one address" if to.empty?
        out[:email] = {
          enabled: truthy(e[:enabled]), host: e[:host], port: e[:port] || 587,
          secure: truthy(e[:secure]),
          user_env: e[:user_env] || e[:userEnv], password_env: e[:password_env] || e[:passwordEnv],
          from: e[:from], to: to
        }
      end
      out
    end

    # -- helpers --

    def with_defaults(hash, defaults)
      h = (hash || {})
      defaults.each_with_object({}) { |(k, v), acc| acc[k] = h.fetch(k, v) }
    end

    def validate_hex_color(val)
      return "772fd1" if val.nil?
      s = val.to_s
      unless s.match?(/\A[0-9a-fA-F]{6}\z/)
        @errors << "rollover.sprintLabelColor: must be a 6-digit hex color without a leading '#'"
        return "772fd1"
      end
      s
    end

    def array_of_strings(val, default:, path:)
      return default if val.nil?
      unless val.is_a?(Array)
        @errors << "#{path}: must be a list"
        return default
      end
      val.map(&:to_s)
    end

    def truthy(v) = v == true
    def blank?(v) = v.nil? || (v.respond_to?(:empty?) && v.empty?)
    def numeric_positive?(v) = v.is_a?(Numeric) && v.positive?

    def deep_symbolize(obj)
      case obj
      when Hash then obj.each_with_object({}) { |(k, v), acc| acc[k.to_sym] = deep_symbolize(v) }
      when Array then obj.map { |e| deep_symbolize(e) }
      else obj
      end
    end
  end
end
