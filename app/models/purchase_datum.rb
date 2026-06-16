# Rails pluralizes PurchaseDatum -> purchase_data, matching the table name.
# synthetic is denormalized from source.source_type — intentional debt.
# Keep in sync when source.source_type changes (use a callback or data job).
class PurchaseDatum < ApplicationRecord
  self.table_name = "purchase_data"

  belongs_to :user
  belongs_to :product
  belongs_to :location, optional: true
  belongs_to :source, optional: true
  has_many :raw_feedbacks, dependent: :nullify

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, presence: true, length: { is: 3 }
  validates :purchased_at, presence: true

  scope :synthetic, -> { where(synthetic: true) }
  scope :real, -> { where(synthetic: false) }
  scope :recent, -> { order(purchased_at: :desc) }
end
