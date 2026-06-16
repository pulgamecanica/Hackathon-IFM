# Stub AI analyzer — produces fake-but-plausible analysis for a RawFeedback.
#
# This is the swap point for a real LLM (e.g. Anthropic Claude): replace #call
# with a model request and map the response onto the same Result struct. Nothing
# downstream (FeedbackAnalysisJob, AiInsight, Rating) needs to change.
#
# Output contract:
#   sentiment        -> Symbol matching AiInsight.sentiment enum
#   sentiment_score  -> Float in [-1.0, 1.0]
#   focus            -> Symbol matching AiInsight.focus enum (product/distribution/visibility)
#   summary          -> String
#   key_themes       -> Array<String>  (canonical theme tokens — drive the filters)
#   topics           -> Hash{String => Float}  (theme => weight, for ai_insights.topics jsonb)
#   confidence       -> Float in [0.0, 1.0]
#   dimension_scores -> Hash{Symbol => Float}  (Rating.dimension => 1.0..5.0 score)
#   model_version    -> String
class StubAiAnalyzer
  MODEL_VERSION = "stub-analyzer-v3"

  POSITIVE_WORDS = %w[love stunning gorgeous elegant flawless perfect fast luxurious soft chic impeccable].freeze
  NEGATIVE_WORDS = %w[cheap itchy disappointed defective late torn faded misleading flimsy overpriced poor].freeze

  # Canonical theme tokens grouped by the three feedback points. These match the
  # sub-filters in the dashboard filter panel one-to-one. The dominant token's
  # group becomes the insight's focus.
  FOCUS_THEMES = {
    product: {
      # Note: fabric-type words (silk/leather/…) are intentionally excluded —
      # they appear in product names and would over-match.
      "material" => %w[material fabric textile woven],
      "fit"      => %w[fit sizing size tailoring],
      "color"    => %w[color colour shade hue],
      "design"   => %w[design silhouette cut aesthetic],
      "comfort"  => %w[comfort comfortable cosy],
      "function" => %w[function versatile practical utility],
      "quality"  => %w[quality stitching craftsmanship seams durable]
    },
    distribution: {
      "stock_availability" => %w[stock restock availability sold-out unavailable],
      "delivery_delays"    => %w[delivery shipping late delay arrived logistics]
    },
    visibility: {
      "in_store"        => %w[store boutique in-store counter],
      "online_campaign" => %w[online website campaign digital social ecommerce],
      "ooh_campaign"    => %w[ooh billboard outdoor lookbook poster print]
    }
  }.freeze

  # token => its owning focus, and the flat token list, derived once.
  TOKEN_FOCUS = FOCUS_THEMES.flat_map { |focus, t| t.keys.map { |tok| [ tok, focus ] } }.to_h.freeze
  TOKEN_KEYWORDS = FOCUS_THEMES.values.reduce(:merge).freeze
  ALL_TOKENS = TOKEN_KEYWORDS.keys.freeze

  SCORED_DIMENSIONS = %i[overall quality value].freeze

  Result = Struct.new(
    :sentiment, :sentiment_score, :focus, :summary, :key_themes,
    :topics, :confidence, :dimension_scores, :model_version,
    keyword_init: true
  )

  def initialize(raw_feedback)
    @feedback = raw_feedback
    @text = raw_feedback.content.to_s.downcase
  end

  def call
    score = compute_sentiment_score
    tokens = detect_tokens
    Result.new(
      sentiment: sentiment_label(score),
      sentiment_score: score,
      focus: classify_focus(tokens),
      summary: build_summary(score, tokens),
      key_themes: tokens,
      topics: tokens.index_with { rand(0.4..1.0).round(2) },
      confidence: rand(0.6..0.98).round(3),
      dimension_scores: dimension_scores(score),
      model_version: MODEL_VERSION
    )
  end

  private

  attr_reader :feedback, :text

  def compute_sentiment_score
    pos = POSITIVE_WORDS.count { |w| text.include?(w) }
    neg = NEGATIVE_WORDS.count { |w| text.include?(w) }
    ((pos - neg) + rand(-1.0..1.0)).clamp(-1.0, 1.0).round(3)
  end

  def sentiment_label(score)
    return :mixed    if score.abs < 0.15 && text.match?(/but|however|though/)
    return :positive if score > 0.2
    return :negative if score < -0.2

    :neutral
  end

  def detect_tokens
    found = ALL_TOKENS.select do |token|
      TOKEN_KEYWORDS[token].any? { |kw| text.include?(kw.tr("-", " ")) || text.include?(kw) }
    end
    found.presence || [ ALL_TOKENS.sample ]
  end

  # Focus = the point that owns the most detected tokens.
  def classify_focus(tokens)
    counts = tokens.group_by { |t| TOKEN_FOCUS[t] }.transform_values(&:size)
    counts.max_by { |_, n| n }&.first || FOCUS_THEMES.keys.sample
  end

  def build_summary(score, tokens)
    tone = sentiment_label(score)
    subject = tokens.first&.tr("_", " ") || "the piece"
    "Customer expressed #{tone} sentiment, primarily about #{subject}."
  end

  def dimension_scores(score)
    base = (3.0 + score * 2.0)
    SCORED_DIMENSIONS.index_with do
      (base + rand(-0.4..0.4)).clamp(1.0, 5.0).round(2)
    end
  end
end
