# Applies a FeedbackFilterParser::Filters to the analyzed feedback and returns
# both the matching insights and a small aggregate summary the chatbot answers from.
#
# Centered on AiInsight because that's where sentiment/focus live; it joins back
# to raw_feedback for location and through to products for product filtering.
class FeedbackQuery
  Result = Struct.new(:insights, :count, :avg_sentiment, :sentiment_breakdown,
                      :focus_breakdown, keyword_init: true)

  def initialize(filters)
    @filters = filters
  end

  def call
    scope = base_scope
    insights = scope.recent.limit(25).to_a
    Result.new(
      insights: insights,
      count: scope.count,
      avg_sentiment: scope.average(:sentiment_score)&.to_f&.round(2),
      sentiment_breakdown: humanize(scope.group(:sentiment).count, AiInsight.sentiments),
      focus_breakdown: humanize(scope.group(:focus).count, AiInsight.focus)
    )
  end

  private

  def base_scope
    scope = AiInsight.includes(raw_feedback: %i[location products])
    scope = scope.where(sentiment: @filters.sentiment) if @filters.sentiment
    scope = scope.where(focus: @filters.focus) if @filters.focus
    scope = scope.where(synthetic: @filters.synthetic) unless @filters.synthetic.nil?

    if @filters.location_id
      scope = scope.joins(:raw_feedback).where(raw_feedbacks: { location_id: @filters.location_id })
    end

    if @filters.product_id
      scope = scope.joins(raw_feedback: :raw_feedback_products)
                   .where(raw_feedback_products: { product_id: @filters.product_id })
    end

    scope
  end

  # Convert integer-enum group keys back to their string labels.
  def humanize(counts, mapping)
    counts.transform_keys { |k| mapping.key(k) || k.to_s }
  end
end
