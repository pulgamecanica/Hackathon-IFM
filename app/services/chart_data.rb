# Computes the datasets behind the dashboard visualizations.
#
# Deterministic and reusable: the static "Visualizations" panels and the
# AI-generated charts both render from these same methods, so an AI-chosen chart
# is just one of these datasets parameterized — never model-fabricated numbers.
class ChartData
  SENTIMENTS = %w[positive neutral negative mixed].freeze

  def initialize(focus: nil)
    @focus = focus.presence # optional restriction to one feedback point
  end

  # [{ focus:, total:, segments: { "positive" => n, ... } }] — one row per point.
  def sentiment_by_focus
    counts = scope.group(:focus, :sentiment).count
    focuses.map do |focus|
      segments = SENTIMENTS.index_with { |s| counts[[focus, s]] || 0 }
      { focus: focus, total: segments.values.sum, segments: segments }
    end
  end

  # [{ name:, avg: }] sorted high → low, for the rating bar chart.
  def rating_by_product
    rel = Rating.overall.joins(:product)
    rel = rel.where(ai_insight_id: scope.select(:id)) if @focus
    rel.group("products.name").average(:score)
       .map { |name, avg| { name: name, avg: avg.to_f.round(2) } }
       .sort_by { |row| -row[:avg] }
  end

  # [{ focus:, count:, share: }] for the distribution donut.
  def focus_distribution
    counts = AiInsight.group(:focus).count
    total = counts.values.sum
    DashboardInsights::FOCUSES.map do |focus|
      count = counts[focus] || 0
      { focus: focus, count: count, share: total.zero? ? 0 : (count.to_f / total * 100).round }
    end
  end

  private

  def scope
    @focus ? AiInsight.where(focus: @focus) : AiInsight.all
  end

  def focuses
    @focus ? [ @focus ] : DashboardInsights::FOCUSES
  end
end
