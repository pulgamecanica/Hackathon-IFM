# Stub AI analyzer — produces fake-but-plausible analysis for a RawFeedback.
#
# This is the swap point for a real LLM (e.g. Anthropic Claude): replace #call
# with a model request and map the response onto the same Result struct. Nothing
# downstream (FeedbackAnalysisJob, AiInsight, Rating) needs to change.
#
# Output contract:
#   sentiment        -> Symbol matching AiInsight.sentiment enum
#   sentiment_score  -> Float in [-1.0, 1.0]
#   summary          -> String
#   key_themes       -> Array<String>
#   topics           -> Hash{String => Float}  (theme => weight, for ai_insights.topics jsonb)
#   confidence       -> Float in [0.0, 1.0]
#   dimension_scores -> Hash{Symbol => Float}  (Rating.dimension => 1.0..5.0 score)
#   model_version    -> String
class StubAiAnalyzer
  MODEL_VERSION = "stub-analyzer-v1"

  POSITIVE_WORDS = %w[great love excellent amazing perfect fast helpful reliable smooth brilliant].freeze
  NEGATIVE_WORDS = %w[broke terrible slow awful hate disappointed defective late cheap useless].freeze
  THEME_POOL = %w[quality price delivery support packaging usability durability value design].freeze

  # Dimensions every insight scores. Mirrors a subset of Rating.dimension.
  SCORED_DIMENSIONS = %i[overall quality value].freeze

  Result = Struct.new(
    :sentiment, :sentiment_score, :summary, :key_themes,
    :topics, :confidence, :dimension_scores, :model_version,
    keyword_init: true
  )

  def initialize(raw_feedback)
    @feedback = raw_feedback
    @text = raw_feedback.content.to_s.downcase
  end

  def call
    score = compute_sentiment_score
    Result.new(
      sentiment: sentiment_label(score),
      sentiment_score: score,
      summary: build_summary(score),
      key_themes: themes,
      topics: topic_weights,
      confidence: confidence,
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
    raw = (pos - neg) + rand(-1.0..1.0)
    raw.clamp(-1.0, 1.0).round(3)
  end

  def sentiment_label(score)
    return :mixed   if score.abs < 0.15 && text.match?(/but|however|though/)
    return :positive if score > 0.2
    return :negative if score < -0.2

    :neutral
  end

  def themes
    THEME_POOL.select { text.include?(_1) }.presence || THEME_POOL.sample(rand(1..3))
  end

  def topic_weights
    themes.index_with { rand(0.4..1.0).round(2) }
  end

  def confidence
    rand(0.6..0.98).round(3)
  end

  def build_summary(score)
    tone = sentiment_label(score)
    subject = themes.first || "the product"
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
