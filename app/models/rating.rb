# Ratings are ALWAYS AI-derived — ai_insight_id is NOT NULL (Decision #2).
# No human-submitted rating path exists.
#
# Fan-out model: one AiInsight produces one Rating PER product referenced
# in the parent RawFeedback. For a feedback touching N products, N ratings
# are created per dimension.
#
# Uniqueness: one score per (ai_insight, product, dimension) triple.
# Enforce at the DB level via idx_ratings_insight_product_dimension.
#
# dimension: 0=overall, 1=quality, 2=value, 3=service, 4=delivery
# score: 1.0–5.0 scale (not enforced to allow future flexibility)
# synthetic denormalized from ai_insight -> raw_feedback -> source — intentional debt.
class Rating < ApplicationRecord
  belongs_to :product
  belongs_to :ai_insight

  # dimension: 0=overall, 1=quality, 2=value, 3=service, 4=delivery
  enum :dimension, { overall: 0, quality: 1, value: 2, service: 3, delivery: 4 }, validate: true

  validates :product, presence: true
  validates :ai_insight, presence: true
  validates :score, presence: true,
                    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :dimension, presence: true
  validates :rated_at, presence: true
  validates :dimension, uniqueness: { scope: [ :ai_insight_id, :product_id ],
                                      message: "already rated for this insight and product" }

  scope :synthetic, -> { where(synthetic: true) }
  scope :real, -> { where(synthetic: false) }
  scope :by_dimension, ->(d) { where(dimension: d) }
  scope :overall, -> { where(dimension: :overall) }
  scope :recent, -> { order(rated_at: :desc) }

  # Convenience: average score for a product across all real ratings.
  def self.average_score_for(product, dimension: :overall)
    real.by_dimension(dimension).where(product: product).average(:score)
  end
end
