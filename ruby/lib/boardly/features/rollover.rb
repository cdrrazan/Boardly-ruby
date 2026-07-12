# frozen_string_literal: true

require_relative "../util/project"

module Boardly
  module Features
    # Sprint rollover: when an iteration ends, move every item still in it and not
    # "done" into the next (current) iteration.
    module Rollover
      module_function

      def run(ctx)
        cfg = ctx.cfg
        graph = ctx.graph
        field = Util::Project.require_field(graph, cfg.fields[:iteration], "rollover")

        completed = field.completed_iterations || []
        upcoming = field.iterations || []
        if completed.empty?
          puts "rollover: no completed iterations — nothing to roll over."
          return
        end
        if upcoming.empty?
          puts "::warning::rollover: an iteration has completed but there is no next iteration to roll into. Add one to the project."
          return
        end

        from = completed.first
        to = upcoming.first
        only = cfg.features[:rollover][:only_statuses].map(&:downcase)
        add_label = cfg.features[:rollover][:add_sprint_label]
        label_color = cfg.features[:rollover][:sprint_label_color]
        sprint_label = to.title # label named after the iteration items roll into
        ensured = {} # repos where the sprint label has been created this run
        # Fuzzy label key: case-insensitive, ignoring spaces/hyphens/underscores, so a single
        # "pulled-in" entry also matches "Pulled In", "pulled_in", etc. ("pull"/"pulled" differ.)
        norm_label = ->(s) { s.to_s.downcase.gsub(/[^a-z0-9]+/, "") }
        remove_norms = cfg.features[:rollover][:remove_labels].map { |l| norm_label.call(l) }

        graph.items.each do |item|
          it = Util::Project.iteration_of(item, cfg)
          next unless it && it.iteration_id == from.id
          next if Util::Project.done?(item, cfg)

          status = Util::Project.status_of(item, cfg)
          next if !only.empty? && !(status && only.include?(status.downcase))

          label = item.content ? "##{item.content.number} #{item.content.title}" : item.id
          ctx.audit.record("rollover", "move-iteration", label, "#{from.title} → #{to.title}#{status ? " (status: #{status})" : ""}")
          ctx.client.set_iteration(graph.id, item.id, field.id, to.id) unless ctx.dry_run

          # Draft items have no issue/PR, so there is nothing to label.
          c = item.content
          next unless c

          # Optionally tag the rolled item with the new sprint's label (additive; existing kept).
          if add_label && !Array(c.labels).include?(sprint_label)
            ctx.audit.record("rollover", "add-label", label, "+#{sprint_label}")
            unless ctx.dry_run
              repo_key = "#{c.repo_owner}/#{c.repo_name}"
              unless ensured[repo_key]
                ctx.client.ensure_label(c.repo_owner, c.repo_name, sprint_label, label_color)
                ensured[repo_key] = true
              end
              ctx.client.add_labels(c.repo_owner, c.repo_name, c.number, [sprint_label])
            end
          end

          # Strip stale labels (e.g. "pulled-in") from each rolled card, any casing/spacing.
          next if remove_norms.empty?

          Array(c.labels).each do |existing|
            next unless remove_norms.include?(norm_label.call(existing))

            ctx.audit.record("rollover", "remove-label", label, "-#{existing}")
            ctx.client.remove_label(c.repo_owner, c.repo_name, c.number, existing) unless ctx.dry_run
          end
        end
      end
    end
  end
end
