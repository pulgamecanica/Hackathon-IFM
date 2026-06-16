# Derived analytics for the dashboard panels (beyond the headline counts in
# DashboardStats). Powers:
#   - Feedback Focus       : volume + sentiment per feedback point
#   - Reasons for Negativity: most common themes among negative insights
#   - Key Insights         : auto-generated narrative observations
class DashboardInsights
  FOCUSES = %w[product distribution visibility].freeze

  # [{ focus:, count:, avg_sentiment:, negative_share: }] for all three points.
  # Grouping by an enum column yields string-label keys, so index by `focus`.
  def focus_breakdown
    counts = AiInsight.group(:focus).count
    avg = AiInsight.group(:focus).average(:sentiment_score)
    neg = AiInsight.negative_sentiment.group(:focus).count

    FOCUSES.map do |focus|
      total = counts[focus] || 0
      {
        focus: focus,
        count: total,
        avg_sentiment: avg[focus]&.to_f&.round(2),
        negative_share: total.zero? ? 0 : ((neg[focus] || 0).to_f / total * 100).round
      }
    end
  end

  # Top themes pulled from the topics jsonb of NEGATIVE insights, ranked by frequency.
  def negativity_reasons(limit: 6)
    tally = Hash.new(0)
    AiInsight.negative_sentiment.pluck(:topics).each do |topics|
      next if topics.blank?

      topics.each_key { |theme| tally[theme.tr("-", " ")] += 1 }
    end
    tally.sort_by { |_, n| -n }.first(limit)
  end

  # A handful of plain-language observations the demo can show as "Key Insights".
  def key_insights
    insights = []
    insights << worst_focus_line
    insights << top_negative_product_line
    insights << best_rated_product_line
    insights << synthetic_volume_line
    insights.compact
  end

  private

  def worst_focus_line
    ranked = focus_breakdown.select { _1[:count].positive? }
    worst = ranked.min_by { _1[:avg_sentiment] || 0 }
    return unless worst

    "“#{worst[:focus].capitalize}” is the weakest feedback point " \
      "(#{worst[:negative_share]}% negative across #{worst[:count]} insights)."
  end

  def top_negative_product_line
    row = Rating.overall
                .where("score < ?", 2.5)
                .group(:product_id)
                .count
                .max_by { |_, n| n }
    return unless row

    product = Product.find_by(id: row.first)
    return unless product

    "#{product.name} is drawing the most low ratings (#{row.last} under 2.5★)."
  end

  def best_rated_product_line
    row = Rating.overall.group(:product_id).average(:score).max_by { |_, avg| avg }
    return unless row && row.last

    product = Product.find_by(id: row.first)
    return unless product

    "#{product.name} leads on satisfaction at #{row.last.to_f.round(2)}★ overall."
  end

  def synthetic_volume_line
    total = RawFeedback.count
    return if total.zero?

    share = (RawFeedback.synthetic.count.to_f / total * 100).round
    "#{total} feedback items processed so far (#{share}% from synthetic sources)."
  end
end
