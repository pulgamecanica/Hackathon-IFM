# Derived analytics panels (Feedback Focus / Reasons for Negativity / Key
# Insights). All scoped to the active filter so they reflect the current view.
class DashboardInsights
  FOCUSES = %w[product distribution visibility].freeze

  def initialize(filter = FeedbackFilter.new)
    @filter = filter
    @insights = filter.insights
  end

  # [{ focus:, count:, avg_sentiment:, negative_share: }] for each point.
  def focus_breakdown
    counts = @insights.group(:focus).count
    avg = @insights.group(:focus).average(:sentiment_score)
    neg = @insights.where(sentiment: :negative).group(:focus).count

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

  # Top themes among negative insights, ranked by frequency.
  def negativity_reasons(limit: 6)
    tally = Hash.new(0)
    @insights.where(sentiment: :negative).pluck(:topics).each do |topics|
      next if topics.blank?

      topics.each_key { |theme| tally[theme.tr("_-", "  ").strip] += 1 }
    end
    tally.sort_by { |_, n| -n }.first(limit)
  end

  def key_insights
    [ worst_focus_line, top_negative_product_line, best_rated_product_line, volume_line ].compact
  end

  private

  def worst_focus_line
    worst = focus_breakdown.select { _1[:count].positive? }.min_by { _1[:avg_sentiment] || 0 }
    return unless worst

    "“#{worst[:focus].capitalize}” is the weakest feedback point " \
      "(#{worst[:negative_share]}% negative across #{worst[:count]} insights)."
  end

  def top_negative_product_line
    row = overall_ratings.where("score < ?", 2.5).group(:product_id).count.max_by { |_, n| n }
    return unless row

    product = Product.find_by(id: row.first)
    product && "#{product.name} is drawing the most low ratings (#{row.last} under 2.5)."
  end

  def best_rated_product_line
    row = overall_ratings.group(:product_id).average(:score).max_by { |_, avg| avg }
    return unless row && row.last

    product = Product.find_by(id: row.first)
    product && "#{product.name} leads on satisfaction at #{row.last.to_f.round(2)} overall."
  end

  def volume_line
    total = @filter.feedbacks.count
    return if total.zero?

    share = (@filter.feedbacks.where(synthetic: true).count.to_f / total * 100).round
    "#{total} feedback items in view (#{share}% from synthetic sources)."
  end

  def overall_ratings
    @filter.ratings.where(dimension: :overall)
  end
end
