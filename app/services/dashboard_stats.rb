# Aggregates the headline numbers shown on the dashboard.
#
# Used by DashboardController#index for the initial render and by
# DashboardBroadcaster to push an updated stats panel over Turbo Streams
# whenever feedback is ingested or finishes processing.
class DashboardStats
  def total_feedback   = RawFeedback.count
  def processed        = RawFeedback.processed.count
  def pending          = RawFeedback.where(processing_status: %i[pending processing]).count
  def synthetic_share  = total_feedback.zero? ? 0 : ((RawFeedback.synthetic.count.to_f / total_feedback) * 100).round
  def insights         = AiInsight.count

  def average_overall
    Rating.overall.average(:score)&.round(2)
  end

  # { "positive" => 12, "neutral" => 3, ... } for the sentiment bar.
  def sentiment_breakdown
    AiInsight.group(:sentiment).count.transform_keys { AiInsight.sentiments.key(_1) || _1.to_s }
  end
end
