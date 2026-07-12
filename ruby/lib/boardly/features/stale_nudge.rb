# frozen_string_literal: true

require "time"
require_relative "../util/project"
require_relative "../util/dates"
require_relative "../notify/slack"

module Boardly
  module Features
    # Stale-card nudges: @-mention owners when a card sits in a status too long.
    # A hidden marker prevents re-nudging until the status changes.
    module StaleNudge
      module_function

      def marker(status) = "<!-- boardly:stale-nudge:#{status.downcase} -->"

      def run(ctx)
        cfg = ctx.cfg
        graph = ctx.graph
        rules = cfg.features[:stale_nudge][:rules]
        if rules.empty?
          puts "stale-nudge: no rules configured."
          return
        end

        graph.items.each do |item|
          content = item.content
          next unless content

          status = Util::Project.status_of(item, cfg)
          next unless status

          rule = rules.find { |r| r[:status].downcase == status.downcase }
          next unless rule

          since = Util::Project.status_updated_at(item, cfg) || item.updated_at
          age = Util::Dates.days_between(since, ctx.now)
          next if age < rule[:days]

          existing = ctx.client.list_comments(content.repo_owner, content.repo_name, content.number)
          already = existing.any? { |c| c[:body].include?(marker(status)) && Time.iso8601(c[:created_at]) >= Time.iso8601(since) }
          next if already

          mentions = resolve_mentions(rule[:notify], content.assignees)
          template = rule[:message] || "This item has been in **{status}** for {days} day(s) with no status change. Any update?"
          body = "#{marker(status)}\n#{fill(template, status: status, days: age.floor, number: content.number, title: content.title)}"
          body += "\n\n#{mentions}" unless mentions.empty?

          label = "##{content.number} #{content.title}"
          ctx.audit.record("stale-nudge", "comment", label, %(in "#{status}" for #{age.floor}d#{mentions.empty? ? "" : ", pinged #{mentions}"}))
          ctx.client.comment(content.repo_owner, content.repo_name, content.number, body) unless ctx.dry_run

          ctx.notifier.broadcast(Notify::Report.new(
            feature: "stale-nudge",
            title: "Stale card: #{label}",
            markdown: "⏳ [##{content.number}](#{content.url}) **#{content.title}** has been in **#{status}** for #{age.floor} day(s)#{mentions.empty? ? "" : " — #{mentions}"}."
          ))
        end
      end

      # `notify` is either the literal "assignees" or a list of logins. Inside the
      # list, an "assignees" entry expands to the item's assignees, so a rule can
      # ping assignees *and* extra people (a reviewer, a project manager, …):
      #   notify: [assignees, project-manager, some-reviewer]
      def resolve_mentions(notify, assignees)
        logins = notify == "assignees" ? assignees : notify.flat_map { |l| l == "assignees" ? assignees : l }
        logins.map { |l| "@#{l.sub(/\A@/, "")}" }.uniq.join(" ")
      end

      def fill(template, vars)
        template.gsub(/\{(\w+)\}/) { vars.key?(Regexp.last_match(1).to_sym) ? vars[Regexp.last_match(1).to_sym].to_s : "{#{Regexp.last_match(1)}}" }
      end
    end
  end
end
