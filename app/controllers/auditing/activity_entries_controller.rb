module Auditing
  class ActivityEntriesController < ApplicationController
    requires_permission :view_audit_log

    def index
      fetched_entries = activity_entry_repository.fetch(page: requested_page)
      @activity_page = fetched_entries.failure? ? report_failure_and_discard(fetched_entries) : fetched_entries.data
    end

    private

    def requested_page
      [ params[:page].to_i, 1 ].max
    end

    def activity_entry_repository
      @activity_entry_repository ||= Auditing::ActivityEntryRepository.new
    end

    def report_failure_and_discard(result)
      report_failure(result)

      OpenStruct.new(entries: [], page: 1, page_size: 0, total_count: 0)
    end
  end
end
