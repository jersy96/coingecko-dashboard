require "ostruct"

module Auditing
  class ActivityEntryRepository
    DEFAULT_PAGE_SIZE = 50

    def add(user:, action:, subject:, details:, occurred_at:)
      Result.try do
        Auditing::ActivityEntry.create!(
          user: user,
          action: action,
          subject: subject,
          details: details,
          occurred_at: occurred_at
        )
      end
    end

    def fetch(page: 1, page_size: DEFAULT_PAGE_SIZE)
      Result.try do
        OpenStruct.new(
          entries: page_of(page, page_size).to_a,
          page: page.to_i,
          page_size: page_size.to_i,
          total_count: entries.count
        )
      end
    end

    private

    def page_of(page, page_size)
      entries.offset((page.to_i - 1) * page_size.to_i).limit(page_size.to_i)
    end

    def entries
      Auditing::ActivityEntry.includes(:user).order(occurred_at: :desc)
    end
  end
end
