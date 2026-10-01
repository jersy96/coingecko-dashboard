class User < ApplicationRecord
  enum :role, { viewer: 0, trader: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
end
