# frozen_string_literal: true

require "time"
require_relative "../util/project"

module Boardly
  module Features
    # Sprint start: promote pre-parked backlog cards when their sprint becomes active.
    #
    # Teams often assign tickets to a *future* iteration while the current one is
    # still running; those tickets sit in a "Backlog" status. Once that iteration
    # becomes the active sprint, move each such card into a "Ready" status — but
    # only cards parked **before** the sprint started, so a card deliberately
    # moved back to Backlog mid-sprint is left alone.
    module SprintStart
      module_function

      def run(ctx)
        cfg = ctx.cfg
        graph = ctx.graph
        iteration_field = Util::Project.require_field(graph, cfg.fields[:iteration], "sprintStart")
        status_field = Util::Project.require_field(graph, cfg.fields[:status], "sprintStart")

        current = (iteration_field.iterations || []).first
        if current.nil?
          puts "sprintStart: no active/upcoming iteration — nothing to promote."
          return
        end

        start = Time.iso8601("#{current.start_date}T00:00:00Z")
        if start > ctx.now
          puts %(sprintStart: iteration "#{current.title}" hasn't started yet (starts #{current.start_date}).)
          return
        end

        to_status = cfg.features[:sprint_start][:to_status]
        to_option_id = Util::Project.option_id(status_field, to_status)
        if to_option_id.nil?
          available = (status_field.options || []).map { |o| o[:name] }.join(", ")
          raise Boardly::ConfigError, %(sprintStart: target status "#{to_status}" not found on the "#{status_field.name}" field. Available: #{available})
        end

        from_lower = cfg.features[:sprint_start][:from_statuses].map(&:downcase)

        graph.items.each do |item|
          it = Util::Project.iteration_of(item, cfg)
          next unless it && it.iteration_id == current.id
          next if Util::Project.done?(item, cfg)

          status = Util::Project.status_of(item, cfg)
          next unless status && from_lower.include?(status.downcase)

          # Promote only cards parked before the sprint began; a mid-sprint move
          # back to Backlog (status changed on/after the start date) is respected.
          changed_at = Util::Project.status_updated_at(item, cfg)
          next if changed_at.nil? || Time.iso8601(changed_at) >= start

          label = item.content ? "##{item.content.number} #{item.content.title}" : item.id
          ctx.audit.record("sprintStart", "promote-status", label, "#{status} → #{to_status} (#{current.title})")
          ctx.client.set_single_select(graph.id, item.id, status_field.id, to_option_id) unless ctx.dry_run
        end
      end
    end
  end
end
