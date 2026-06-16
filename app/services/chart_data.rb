# Computes the datasets behind the dashboard visualizations, scoped to the
# active filter. The static panels and AI-generated charts both render from here,
# so an AI-chosen chart is just one of these datasets parameterized.
class ChartData
  SENTIMENTS = %w[positive neutral negative mixed].freeze

  def initialize(filter = FeedbackFilter.new)
    @filter = filter
  end

  # [{ focus:, total:, segments: { "positive" => n, ... } }] — one row per point.
  def sentiment_by_focus
    counts = @filter.insights.group(:focus, :sentiment).count
    focuses.map do |focus|
      segments = SENTIMENTS.index_with { |s| counts[[ focus, s ]] || 0 }
      { focus: focus, total: segments.values.sum, segments: segments }
    end
  end

  # [{ name:, avg: }] sorted high → low, for the rating bar chart.
  def rating_by_product
    @filter.ratings.where(dimension: :overall).joins(:product)
           .group("products.name").average(:score)
           .map { |name, avg| { name: name, avg: avg.to_f.round(2) } }
           .sort_by { |row| -row[:avg] }
  end

  # [{ focus:, count:, share: }] for the distribution donut (always all points).
  def focus_distribution
    counts = @filter.insights.group(:focus).count
    total = counts.values.sum
    DashboardInsights::FOCUSES.map do |focus|
      count = counts[focus] || 0
      { focus: focus, count: count, share: total.zero? ? 0 : (count.to_f / total * 100).round }
    end
  end

  private

  def focuses
    @filter.focus ? [ @filter.focus ] : DashboardInsights::FOCUSES
  end
end
