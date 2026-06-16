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
#   key_themes       -> Array<String>
#   topics           -> Hash{String => Float}  (theme => weight, for ai_insights.topics jsonb)
#   confidence       -> Float in [0.0, 1.0]
#   dimension_scores -> Hash{Symbol => Float}  (Rating.dimension => 1.0..5.0 score)
#   model_version    -> String
class StubAiAnalyzer
  MODEL_VERSION = "stub-analyzer-v2"

  POSITIVE_WORDS = %w[love stunning gorgeous elegant flawless perfect fast luxurious soft chic impeccable].freeze
  NEGATIVE_WORDS = %w[cheap itchy disappointed defective late torn faded misleading flimsy overpriced poor].freeze

  # Themes grouped by the three feedback points (Decision: product/distribution/visibility).
  # The dominant theme's group becomes the insight's focus.
  FOCUS_THEMES = {
    product:      %w[fit fabric quality stitching design comfort sizing color material craftsmanship],
    distribution: %w[delivery shipping packaging restock availability returns logistics price],
    visibility:   %w[website lookbook campaign styling discovery brand sizing-guide support service]
  }.freeze

  THEME_POOL = FOCUS_THEMES.values.flatten.freeze

  # Dimensions every insight scores. Mirrors a subset of Rating.dimension.
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
    found = themes
    Result.new(
      sentiment: sentiment_label(score),
      sentiment_score: score,
      focus: classify_focus(found),
      summary: build_summary(score, found),
      key_themes: found,
      topics: found.index_with { rand(0.4..1.0).round(2) },
      confidence: rand(0.6..0.98).round(3),
      dimension_scores: dimension_scores(score),
      model_version: MODEL_VERSION
    )
  end

  private

  attr_reader :feedback, :text

  # Lexicon-based score nudged by random noise so repeated runs vary slightly.
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

  def themes
    found = THEME_POOL.select { text.include?(_1.tr("-", " ")) }
    found.presence || THEME_POOL.sample(rand(1..3))
  end

  # Focus = the feedback point that owns the most of the detected themes.
  def classify_focus(found)
    counts = FOCUS_THEMES.transform_values { |themes| (found & themes).size }
    best = counts.max_by { |_, n| n }
    best && best.last.positive? ? best.first : FOCUS_THEMES.keys.sample
  end

  def build_summary(score, found)
    tone = sentiment_label(score)
    subject = found.first&.tr("-", " ") || "the item"
    "Customer expressed #{tone} sentiment, primarily about #{subject}."
  end

  # Map the [-1, 1] sentiment onto a 1.0..5.0 scale, with per-dimension jitter.
  def dimension_scores(score)
    base = (3.0 + score * 2.0)
    SCORED_DIMENSIONS.index_with do
      (base + rand(-0.4..0.4)).clamp(1.0, 5.0).round(2)
    end
  end
end
