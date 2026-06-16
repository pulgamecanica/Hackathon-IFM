# Filtering-only loyalty record. No transaction ledger (Decision #5).
# points_balance and lifetime_points are display columns only — not a running total
# from a transactions table. Update these directly when needed.
# tier: 0=none, 1=bronze, 2=silver, 3=gold, 4=platinum
class LoyaltyAccount < ApplicationRecord
  belongs_to :user

  # tier: 0=none, 1=bronze, 2=silver, 3=gold, 4=platinum
  # prefix avoids clash with AR's `none` relation method (e.g. `tier_none?`)
  enum :tier, { none: 0, bronze: 1, silver: 2, gold: 3, platinum: 4 }, prefix: true, validate: true

  validates :program_name, presence: true
  validates :tier, presence: true
  validates :points_balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :lifetime_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :by_tier, ->(tier) { where(tier: tier) }
  scope :by_program, ->(program) { where(program_name: program) }
end
