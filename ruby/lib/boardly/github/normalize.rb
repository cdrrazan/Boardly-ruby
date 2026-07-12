# frozen_string_literal: true

require_relative "../model"

module Boardly
  module GitHub
    # Pure translators from raw Projects (v2) GraphQL JSON (String-keyed hashes)
    # into the normalized domain model. Kept free of I/O so they're unit-testable.
    module Normalize
      module_function

      def fields(nodes)
        (nodes || []).select { |n| n && n["id"] }.map do |n|
          field = ProjectField.new(id: n["id"], name: n["name"], data_type: n["dataType"] || "OTHER")
          field.options = n["options"].map { |o| { id: o["id"], name: o["name"] } } if n["options"]
          if (cfg = n["configuration"])
            field.iterations = (cfg["iterations"] || []).map { |i| map_iteration(i) }
            # GitHub returns completed iterations oldest-first; expose most-recent-first.
            field.completed_iterations = (cfg["completedIterations"] || []).map { |i| map_iteration(i) }.reverse
          end
          field
        end
      end

      def item(node)
        field_values = []
        (node.dig("fieldValues", "nodes") || []).each do |fv|
          name = fv.dig("field", "name")
          next unless name

          base = FieldValue.new(field_name: name, updated_at: fv["updatedAt"])
          case fv["__typename"]
          when "ProjectV2ItemFieldSingleSelectValue"
            base.single_select = SingleSelectValue.new(name: fv["name"], option_id: fv["optionId"])
          when "ProjectV2ItemFieldIterationValue"
            base.iteration = IterationValue.new(title: fv["title"], iteration_id: fv["iterationId"])
          when "ProjectV2ItemFieldNumberValue" then base.number = fv["number"]
          when "ProjectV2ItemFieldTextValue" then base.text = fv["text"]
          when "ProjectV2ItemFieldDateValue" then base.date = fv["date"]
          else next
          end
          field_values << base
        end

        content = nil
        c = node["content"]
        if c && %w[Issue PullRequest].include?(c["__typename"])
          content = IssueContent.new(
            type: c["__typename"], node_id: c["id"], number: c["number"], title: c["title"],
            url: c["url"], state: c["state"], merged: c["merged"], closed_at: c["closedAt"],
            updated_at: c["updatedAt"], repo_owner: c.dig("repository", "owner", "login"),
            repo_name: c.dig("repository", "name"),
            assignees: (c.dig("assignees", "nodes") || []).map { |a| a["login"] },
            labels: (c.dig("labels", "nodes") || []).map { |l| l["name"] },
            sub_issues: sub_issues(c["subIssuesSummary"]),
            parent: c["parent"] && ParentRef.new(number: c["parent"]["number"], title: c["parent"]["title"], url: c["parent"]["url"])
          )
        end

        ProjectItem.new(id: node["id"], updated_at: node["updatedAt"], field_values: field_values, content: content)
      end

      def map_iteration(i)
        IterationInfo.new(id: i["id"], title: i["title"], start_date: i["startDate"], duration: i["duration"])
      end

      def sub_issues(s)
        return nil unless s

        SubIssues.new(total: s["total"], completed: s["completed"], percent_completed: s["percentCompleted"])
      end
    end
  end
end
