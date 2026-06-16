# Join model connecting RawFeedback to Products (Decision #3).
# One feedback can reference many products; position orders them within the feedback.
# The (raw_feedback_id, product_id) pair is unique — no duplicate product refs per feedback.
class RawFeedbackProduct < ApplicationRecord
  belongs_to :raw_feedback
  belongs_to :product

  validates :raw_feedback, presence: true
  validates :product, presence: true
  validates :product_id, uniqueness: { scope: :raw_feedback_id, message: "already referenced in this feedback" }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position) }
end
