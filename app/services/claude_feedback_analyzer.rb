# Claude-backed feedback analysis. Same contract as StubAiAnalyzer (returns a
# StubAiAnalyzer::Result) so it's a drop-in. In addition to sentiment / focus /
# themes it performs real product detection from the free text, returning the
# catalog SKUs the note discusses.
#
# Returns nil if Claude is unavailable or errors, so callers can fall back to
# the lexical stub.
class ClaudeFeedbackAnalyzer
  MODEL_VERSION = "claude-opus-4-8"
  SENTIMENTS = %w[negative neutral positive mixed].freeze
  FOCUSES = %w[product distribution visibility].freeze
  THEMES = StubAiAnalyzer::ALL_TOKENS

  def initialize(raw_feedback)
    @feedback = raw_feedback
  end

  def call
    raw = ClaudeClient.answer(system_prompt: system_prompt, user_prompt: @feedback.content.to_s)
    return nil if raw.blank?

    json = JSON.parse(raw[/\{.*\}/m].to_s)
    build_result(json)
  rescue JSON::ParserError => e
    Rails.logger.warn("[ClaudeFeedbackAnalyzer] unparseable response: #{e.message}")
    nil
  end

  private

  def build_result(json)
    themes = Array(json["themes"]).map(&:to_s).select { THEMES.include?(_1) }
    dims = json["ratings"].is_a?(Hash) ? json["ratings"] : {}

    StubAiAnalyzer::Result.new(
      sentiment: allow(json["sentiment"], SENTIMENTS, "neutral").to_sym,
      sentiment_score: json["sentiment_score"].to_f.clamp(-1.0, 1.0).round(3),
      focus: allow(json["focus"], FOCUSES, "product").to_sym,
      summary: json["summary"].to_s.presence || "Client feedback analyzed.",
      key_themes: themes,
      topics: themes.index_with { |_| 1.0 },
      confidence: json["confidence"].to_f.clamp(0.0, 1.0).round(3),
      dimension_scores: {
        overall: score(dims["overall"]),
        quality: score(dims["quality"]),
        value: score(dims["value"])
      },
      model_version: MODEL_VERSION,
      detected_skus: Array(json["product_skus"]).map(&:to_s).select { catalog_skus.include?(_1) }
    )
  end

  def allow(value, permitted, fallback)
    permitted.include?(value.to_s) ? value.to_s : fallback
  end

  def score(value)
    (value.presence || 3).to_f.clamp(1.0, 5.0).round(2)
  end

  def catalog_skus
    @catalog_skus ||= Product.active.pluck(:sku)
  end

  def catalog_lines
    Product.active.includes(:category).order(:sku)
           .map { |p| "#{p.sku} — #{p.name} — #{p.category&.name}" }
           .join("\n")
  end

  def theme_vocab
    THEMES.map { |t| t.tr("_", " ") }.join(", ")
  end

  def system_prompt
    <<~PROMPT
      You are a feedback analyst for LUMA, a luxury fashion house. A boutique seller
      logs a note describing a client interaction. Analyze it and respond with ONLY a
      JSON object (no prose, no code fences):

      {
        "sentiment": "negative" | "neutral" | "positive" | "mixed",
        "sentiment_score": number from -1.0 to 1.0,
        "focus": "product" | "distribution" | "visibility",
        "themes": array of tokens from this exact set: [#{THEMES.map { |t| %("#{t}") }.join(', ')}],
        "summary": one concise sentence (max 22 words),
        "confidence": number from 0.0 to 1.0,
        "ratings": { "overall": 1-5, "quality": 1-5, "value": 1-5 },
        "product_skus": array of catalog SKUs the note discusses (may be several; [] if none)
      }

      Guidance:
      - focus = "distribution" when the core issue is stock, availability, sizing
        out-of-stock, or delivery; "visibility" when it is about campaigns, store
        window/display, or online discovery; otherwise "product" (fit, material,
        quality, design, comfort, function).
      - Tokens for "themes" (use the exact snake_case form): #{theme_vocab.tr(' ', '_')}.
      - ratings reflect how satisfied the client was overall, and with quality and value.
      - product_skus: match the garments the note describes against the catalog below,
        even when the note uses a different name. Include every product mentioned.

      Catalog (SKU — Name — Category):
      #{catalog_lines}
    PROMPT
  end
end
