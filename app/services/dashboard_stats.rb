# Headline numbers for the dashboard — all derived from the active filter's
# scopes, so the figures reflect exactly what the analyst has filtered to.
class DashboardStats
  def initialize(filter = FeedbackFilter.new)
    @filter = filter
  end

  def total_feedback = @filter.feedbacks.count
  def processed      = @filter.feedbacks.where(processing_status: :processed).count
  def pending        = @filter.feedbacks.where(processing_status: %i[pending processing]).count
  def insights       = @filter.insights.count

  def synthetic_share
    total = total_feedback
    total.zero? ? 0 : ((@filter.feedbacks.where(synthetic: true).count.to_f / total) * 100).round
  end

  def average_overall
    @filter.ratings.where(dimension: :overall).average(:score)&.round(2)
  end

  def sentiment_breakdown
    @filter.insights.group(:sentiment).count.transform_keys { |k| AiInsight.sentiments.key(k) || k.to_s }
  end
end
