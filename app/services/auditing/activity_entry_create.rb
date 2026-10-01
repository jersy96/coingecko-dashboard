module Auditing
  class ActivityEntryCreate
    def initialize(activity_entry_repository: Auditing::ActivityEntryRepository.new)
      @activity_entry_repository = activity_entry_repository
    end

    def call(user:, action:, subject:, details: {})
      activity_entry_repository.add(
        user: user,
        action: action,
        subject: subject,
        details: details,
        occurred_at: Time.current
      )
    end

    private

    attr_reader :activity_entry_repository
  end
end
