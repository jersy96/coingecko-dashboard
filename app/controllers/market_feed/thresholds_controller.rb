module MarketFeed
  class ThresholdsController < ApplicationController
    requires_permission :manage_thresholds

    def index
      @thresholds = MarketFeed::Threshold::KINDS.keys.filter_map { |kind| prefilled_threshold(kind) }
    end

    def update
      updated_threshold = threshold_repository.upsert(
        kind: params[:id],
        alert_value: params[:alert_value].presence,
        good_value: params[:good_value].presence
      )
      return report_failure_and_redirect(updated_threshold) if updated_threshold.failure?

      record_activity(updated_threshold.data)
      redirect_to thresholds_path
    end

    private

    def prefilled_threshold(kind)
      threshold = threshold_repository.find_or_prefill(kind)
      return report_failure_and_discard(threshold) if threshold.failure?

      threshold.data
    end

    def record_activity(threshold)
      Auditing::ActivityEntryCreate.new.call(
        user: Current.user,
        action: "threshold.updated",
        subject: threshold.kind,
        details: { alert_value: threshold.alert_value, good_value: threshold.good_value }
      )
    end

    def report_failure_and_redirect(result)
      report_failure(result)

      redirect_to thresholds_path
    end

    def report_failure_and_discard(result)
      report_failure(result)

      nil
    end

    def threshold_repository
      @threshold_repository ||= MarketFeed::ThresholdRepository.new
    end
  end
end
