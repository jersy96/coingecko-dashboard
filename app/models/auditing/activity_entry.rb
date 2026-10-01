module Auditing
  class ActivityEntry < ApplicationRecord
    self.table_name = "auditing_activity_entries"

    belongs_to :user

    validates :action, presence: true
    validates :subject, presence: true
    validates :occurred_at, presence: true
  end
end
