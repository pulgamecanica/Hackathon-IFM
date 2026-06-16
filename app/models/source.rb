# Sources describe ingestion adapters.
# source_type drives the synthetic denorm flag on downstream records.
# source_type: 0=real, 1=synthetic
class Source < ApplicationRecord
  enum :source_type, { real: 0, synthetic: 1 }, validate: true

  has_many :raw_feedbacks, dependent: :restrict_with_error
  has_many :purchase_data, class_name: "PurchaseDatum", dependent: :restrict_with_error

  validates :name, presence: true
  validates :adapter_key, presence: true, uniqueness: true
  validates :source_type, presence: true

  scope :active, -> { where(active: true) }
  scope :synthetic, -> { where(source_type: :synthetic) }
  scope :real, -> { where(source_type: :real) }
end
