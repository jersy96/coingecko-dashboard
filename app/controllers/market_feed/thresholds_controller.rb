module MarketFeed
  class ThresholdsController < ApplicationController
    requires_permission :manage_thresholds

    def index
      @thresholds = MarketFeed::Metrics.keys.filter_map { |metric| prefilled_threshold(metric) }
    end

    def update
      updated_threshold = threshold_repository.upsert(
        metric: params[:id],
        alert_value: params[:alert_value].presence,
        good_value: params[:good_value].presence
      )
      return report_failure_and_redirect(updated_threshold) if updated_threshold.failure?

      record_activity(updated_threshold.data)
      redirect_to thresholds_path
    end

    private

    def prefilled_threshold(metric)
      threshold = threshold_repository.find_or_prefill(metric)
      return report_failure_and_discard(threshold) if threshold.failure?

      threshold.data
    end

    def record_activity(threshold)
      Auditing::ActivityEntryCreate.new.call(
        user: Current.user,
        action: "threshold.updated",
        subject: threshold.metric,
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
