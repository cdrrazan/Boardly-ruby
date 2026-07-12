# frozen_string_literal: true

module Boardly
  # Normalized view of a Projects (v2) board, decoupled from the raw GraphQL shape.
  # Mirrors the TypeScript `types.ts` model.

  IterationInfo = Struct.new(:id, :title, :start_date, :duration, keyword_init: true)

  # dataType is one of: SINGLE_SELECT, ITERATION, NUMBER, TEXT, DATE, OTHER
  ProjectField = Struct.new(
    :id, :name, :data_type, :options, :iterations, :completed_iterations,
    keyword_init: true
  )

  SingleSelectValue = Struct.new(:name, :option_id, keyword_init: true)
  IterationValue    = Struct.new(:title, :iteration_id, keyword_init: true)

  # Exactly one of single_select/iteration/number/text/date is set.
  FieldValue = Struct.new(
    :field_name, :updated_at, :single_select, :iteration, :number, :text, :date,
    keyword_init: true
  )

  SubIssues = Struct.new(:total, :completed, :percent_completed, keyword_init: true)
  ParentRef = Struct.new(:number, :title, :url, keyword_init: true)

  IssueContent = Struct.new(
    :type, :node_id, :number, :title, :url, :state, :merged, :closed_at,
    :updated_at, :repo_owner, :repo_name, :assignees, :labels, :sub_issues, :parent,
    keyword_init: true
  )

  ProjectItem = Struct.new(:id, :updated_at, :field_values, :content, keyword_init: true)

  ProjectGraph = Struct.new(:id, :title, :fields, :items, keyword_init: true)

  # Everything a feature needs to run. Built once per invocation.
  RunContext = Struct.new(
    :cfg, :client, :graph, :audit, :notifier, :dry_run, :now, :run_repo,
    keyword_init: true
  ) do
    def dry_run? = dry_run
  end
end
