module Kronos
  # Jira
  # A simple JIRA client that we use to extract capex numbers and add time
  # to Issues.
  class Jira
    attr_reader :client

    def initialize(options = {})
      @client = JIRA::Client.new(client_defaults.merge(options))
    end

    def capex_numbers
      # Capex Code is a custom field with Id 10103
      issues_with_capex
        .map { |i| i.fields["customfield_10103"] }
        .compact
        .uniq
    end

    def issues_with_capex
      client.Issue.jql(
        "project=\"CP\" AND \"CapEx Code\" is not empty",
        max_results: 1500,
      )
    end

    def add_timeslip(_key, _hours, _date)
      # noop
    end

    private

    def client_defaults
      {
        site:         "https://collectplus.atlassian.net/",
        context_path: "",
        auth_type:    :basic,
      }
    end
  end
end
