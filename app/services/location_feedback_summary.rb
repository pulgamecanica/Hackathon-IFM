# Aggregates feedback metrics per geocoded location for the live map.
#
# Returns one entry per location that has coordinates, including locations with
# zero feedback (so the full footprint is always visible on the map).
class LocationFeedbackSummary
  def self.as_json = new.as_json

  def as_json
    counts = RawFeedback.where.not(location_id: nil).group(:location_id).count
    avg_sentiment = AiInsight
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
