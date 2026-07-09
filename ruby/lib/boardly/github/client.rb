# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require_relative "queries"
require_relative "normalize"
require_relative "../model"

module Boardly
  module GitHub
    class ApiError < StandardError; end

    # Thin wrapper over the GitHub GraphQL + REST APIs, using only the stdlib.
    class Client
      API = "https://api.github.com"
      # Sub-issue fields (`subIssuesSummary`, `parent`) live behind a feature flag header.
      SUB_ISSUE_HEADER = { "GraphQL-Features" => "sub_issues" }.freeze

      def initialize(token)
        @token = token
      end

      # Fetch the whole project (all fields + all items, paged) as a normalized graph.
      def fetch_project(owner, type, number)
        query = Queries.project_query(type)
        items = []
        cursor = nil
        head = nil

        loop do
          data = graphql(query, { owner: owner, number: number, cursor: cursor }, headers: SUB_ISSUE_HEADER)
          root = type == "org" ? data.dig("organization", "projectV2") : data.dig("user", "projectV2")
          unless root
            raise ApiError, %(Project ##{number} not found for #{type} "#{owner}". Check project.owner/type/number and that the token can read it.)
          end

          head ||= { id: root["id"], title: root["title"], fields: Normalize.fields(root.dig("fields", "nodes")) }
          (root.dig("items", "nodes") || []).each { |n| items << Normalize.item(n) }

          page = root.dig("items", "pageInfo")
          cursor = page && page["hasNextPage"] ? page["endCursor"] : nil
          break unless cursor
        end

        ProjectGraph.new(id: head[:id], title: head[:title], fields: head[:fields], items: items)
      end

      def set_single_select(project_id, item_id, field_id, option_id)
        graphql(Queries::SET_SINGLE_SELECT, { projectId: project_id, itemId: item_id, fieldId: field_id, optionId: option_id })
      end

      def set_iteration(project_id, item_id, field_id, iteration_id)
        graphql(Queries::SET_ITERATION, { projectId: project_id, itemId: item_id, fieldId: field_id, iterationId: iteration_id })
      end

      def set_number(project_id, item_id, field_id, value)
        graphql(Queries::SET_NUMBER, { projectId: project_id, itemId: item_id, fieldId: field_id, number: value })
      end

      # afterId nil moves the item to the top.
      def set_position(project_id, item_id, after_id)
        graphql(Queries::SET_POSITION, { projectId: project_id, itemId: item_id, afterId: after_id })
      end

      def comment(owner, repo, issue_number, body)
        rest(:post, "/repos/#{owner}/#{repo}/issues/#{issue_number}/comments", { body: body })
      end

      # Returns [{ body:, created_at: }, ...] for de-duplicating nudges.
      def list_comments(owner, repo, issue_number)
        rest(:get, "/repos/#{owner}/#{repo}/issues/#{issue_number}/comments?per_page=100")
          .map { |c| { body: c["body"].to_s, created_at: c["created_at"] } }
      end

      def create_issue(owner, repo, title, body, labels)
        rest(:post, "/repos/#{owner}/#{repo}/issues", { title: title, body: body, labels: labels })["number"]
      end

      private

      def graphql(query, variables, headers: {})
        resp = post_json("#{API}/graphql", { query: query, variables: variables }, headers)
        body = JSON.parse(resp.body)
        if body["errors"]
          raise ApiError, "GraphQL error: #{body["errors"].map { |e| e["message"] }.join("; ")}"
        end

        body["data"]
      end

      def rest(method, path, payload = nil)
        uri = URI("#{API}#{path}")
        resp =
          if method == :get
            request(Net::HTTP::Get.new(uri))
          else
            post_json(uri.to_s, payload, {})
          end
        raise ApiError, "REST #{method.upcase} #{path} -> #{resp.code}: #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

        resp.body.empty? ? {} : JSON.parse(resp.body)
      end

      def post_json(url, payload, headers)
        req = Net::HTTP::Post.new(URI(url))
        req.body = JSON.generate(payload)
        req["Content-Type"] = "application/json"
        headers.each { |k, v| req[k] = v }
        request(req)
      end

      def request(req)
        uri = req.uri
        req["Authorization"] = "Bearer #{@token}"
        req["Accept"] = "application/vnd.github+json"
        req["User-Agent"] = "boardly-ruby"
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      end
    end
  end
end
