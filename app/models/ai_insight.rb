# AI-derived analysis for a single RawFeedback (1:1, Decision #4).
# product_id is intentionally absent (dropped per design resolution):
#   - RawFeedback spans N products
#   - AiInsight is per-feedback (not per-product)
#   - Per-product scores live in ratings (one Rating per product per dimension)
# Creation of an AiInsight MUST trigger creation of one Rating per product
# linked to the parent raw_feedback via raw_feedback_products.
# synthetic denormalized from raw_feedback -> source.source_type — intentional debt.
#
# sentiment: 0=negative, 1=neutral, 2=positive, 3=mixed
class AiInsight < ApplicationRecord
  belongs_to :raw_feedback
  has_many :ratings, dependent: :destroy

  # Convenience: reach through to the products covered by the parent feedback.
  # raw_feedback -> raw_feedback_products -> products
  delegate :products, to: :raw_feedback

  # sentiment: 0=negative, 1=neutral, 2=positive, 3=mixed
  enum :sentiment, { negative: 0, neutral: 1, positive: 2, mixed: 3 }, validate: true

  # The three feedback points the business tracks. prefix avoids clashing with
  # the `products` delegation and keeps scopes explicit (e.g. focus_product).
  # focus: 0=product, 1=distribution, 2=visibility
  enum :focus, { product: 0, distribution: 1, visibility: 2 }, prefix: true, validate: true

  validates :raw_feedback, presence: true
  validates :model_version, presence: true
  validates :generated_at, presence: true
  validates :sentiment_score, numericality: { greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0 }, allow_nil: true
  validates :confidence, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }, allow_nil: true

  scope :synthetic, -> { where(synthetic: true) }
  scope :real, -> { where(synthetic: false) }
  scope :by_sentiment, ->(s) { where(sentiment: s) }
  scope :by_focus, ->(f) { where(focus: f) }
  scope :negative_sentiment, -> { where(sentiment: :negative) }
  scope :recent, -> { order(generated_at: :desc) }
end
