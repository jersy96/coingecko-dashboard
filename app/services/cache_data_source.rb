class CacheDataSource
  STALE_RETENTION = 24.hours
  DEFAULT_TTL_SECONDS = 60

  def initialize(namespace:, store: Rails.cache)
    @namespace = namespace
    @store = store
  end

  def fetch(key:, ttl_seconds: DEFAULT_TTL_SECONDS, serve_stale_if: ->(_error) { false })
    entry = store.read(namespaced(key))
    return Result.success(entry[:payload]) if fresh?(entry, ttl_seconds)

    provider_result = yield
    return store_payload(key, provider_result.data) if provider_result.success?
    return Result.success(entry[:payload]) if serve_stale?(entry, provider_result, serve_stale_if)

    provider_result
  end

  private

  attr_reader :namespace, :store

  def fresh?(entry, ttl_seconds)
    entry.present? && entry[:cached_at] > ttl_seconds.seconds.ago
  end

  def serve_stale?(entry, provider_result, serve_stale_if)
    entry.present? && serve_stale_if.call(provider_result.error)
  end

  def store_payload(key, payload)
    store.write(namespaced(key), { payload: payload, cached_at: Time.current }, expires_in: STALE_RETENTION)

    Result.success(payload)
  end

  def namespaced(key)
    "#{namespace}/#{key}"
  end
end
