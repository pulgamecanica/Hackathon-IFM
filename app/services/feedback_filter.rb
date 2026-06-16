# Shared filter applied across the whole dashboard. Every data service derives
# its numbers from these scopes, so the entire page reflects the active filters.
#
# Dimensions: focus, sub-theme (key_themes token), sentiment, and SKU (product).
class FeedbackFilter
  attr_reader :focus, :theme, :sentiment, :sku, :product

  def self.from_params(params)
    new(focus: params[:focus], theme: params[:theme], sentiment: params[:sentiment], sku: params[:sku])
  end

  def initialize(focus: nil, theme: nil, sentiment: nil, sku: nil)
    @focus = allow(focus, AiInsight.focus.keys)
    @sentiment = allow(sentiment, AiInsight.sentiments.keys)
    @theme = allow(theme, StubAiAnalyzer::ALL_TOKENS)
    @sku = sku.to_s.presence
    @sku = nil if @sku == "all"
    @product = @sku && Product.find_by(sku: @sku)
  end

  def active?
    [ focus, theme, sentiment, product ].any?(&:present?)
  end

  # AiInsight relation honoring every active dimension.
  def insights
    rel = AiInsight.all
    rel = rel.where(focus: focus) if focus
    rel = rel.where(sentiment: sentiment) if sentiment
    rel = rel.where("ai_insights.key_themes LIKE ?", "%#{theme}%") if theme
    rel = rel.joins(raw_feedback: :raw_feedback_products)
             .where(raw_feedback_products: { product_id: product.id }) if product
    rel
  end

  # RawFeedback relation honoring every active dimension.
  def feedbacks
    rel = RawFeedback.all
    if focus || sentiment || theme
      rel = rel.joins(:ai_insight)
      rel = rel.where(ai_insights: { focus: focus }) if focus
      rel = rel.where(ai_insights: { sentiment: sentiment }) if sentiment
      rel = rel.where("ai_insights.key_themes LIKE ?", "%#{theme}%") if theme
    end
    rel = rel.joins(:raw_feedback_products)
             .where(raw_feedback_products: { product_id: product.id }) if product
    rel
  end

  # Ratings tied to the filtered insights (for averages / product charts).
  def ratings
    Rating.where(ai_insight_id: insights.select(:id))
  end

  def to_params
    { focus: focus, theme: theme, sentiment: sentiment, sku: sku }.compact
  end

  # [[label, value], ...] for display chips.
  def chips
    list = []
    list << [ "Focus", focus.capitalize ] if focus
    list << [ "Sub-filter", theme.tr("_", " ") ] if theme
    list << [ "Sentiment", sentiment.capitalize ] if sentiment
    list << [ "SKU", product&.name || sku ] if sku
    list
  end

  def description
    active? ? chips.map { |_, v| v }.join(" · ") : "No filters applied"
  end

  private

  def allow(value, permitted)
    value = value.to_s
    permitted.include?(value) ? value : nil
  end
end
