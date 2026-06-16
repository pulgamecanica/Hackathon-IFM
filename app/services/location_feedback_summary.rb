# Aggregates feedback metrics per geocoded location for the live map, scoped to
# the active filter. Returns one entry per location with coordinates (including
# zero-feedback locations so the full footprint stays visible).
class LocationFeedbackSummary
  def self.as_json(filter = FeedbackFilter.new) = new(filter).as_json

  def initialize(filter = FeedbackFilter.new)
    @filter = filter
  end

  def as_json
    counts = @filter.feedbacks.where.not(location_id: nil).group(:location_id).count
    avg_sentiment = @filter.insights
                           .joins(:raw_feedback)
                           .where.not(raw_feedbacks: { location_id: nil })
                           .group("raw_feedbacks.location_id")
                           .average(:sentiment_score)

    Location.where.not(lat: nil).map do |location|
      count = counts[location.id] || 0
      sentiment = avg_sentiment[location.id]&.to_f
      {
        id: location.id,
        name: location.name,
        city: location.city,
        lat: location.lat.to_f,
        long: location.long.to_f,
        feedback_count: count,
        avg_sentiment: sentiment&.round(3),
        sentiment_label: label_for(sentiment, count)
      }
    end
  end

  private

  def label_for(sentiment, count)
    return "none" if count.zero? || sentiment.nil?
    return "positive" if sentiment > 0.2
    return "negative" if sentiment < -0.2

    "neutral"
  end
end
