module MarketFeed
  module ProviderFailureStatus
    extend ActiveSupport::Concern

    private

    def provider_failure_status(result, service)
      return :too_many_requests if service.rate_limited?(result.error)

      :bad_gateway
    end
  end
end
