# Turns an analyst's natural-language request into a chart specification.
#
# Like the chatbot, the AI only *chooses and parameterizes* one of our supported
# procedural charts — it never fabricates data. Claude is used when available;
# a deterministic keyword parser is the fallback.
class ChartSpecGenerator
  KINDS = %w[sentiment_by_focus rating_by_product focus_distribution].freeze
  TITLES = {
    "sentiment_by_focus" => "Sentiment by Focus",
    "rating_by_product"  => "Rating by Product",
    "focus_distribution" => "Focus Distribution"
  }.freeze

  Spec = Struct.new(:kind, :focus, :title, :source, keyword_init: true) do
    def chart_data = ChartData.new(focus: focus)
  end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You translate an analyst's request into a chart spec for LUMA's feedback
    dashboard. Reply with ONLY a JSON object, no prose:
    {"kind": one of ["sentiment_by_focus","rating_by_product","focus_distribution"],
     "focus": one of ["product","distribution","visibility"] or null}
    Choose the chart that best answers the request. Set "focus" only to restrict to
    a single feedback point when the request clearly names one; otherwise null.
    Never set focus for focus_distribution.
  PROMPT

  def initialize(prompt)
    @prompt = prompt.to_s.strip
  end

  def call
    spec = from_claude || from_rules
    spec.title = [ TITLES[spec.kind], spec.focus&.capitalize ].compact.join(" — ")
    spec
  end

  private

  def from_claude
    raw = ClaudeClient.answer(system_prompt: SYSTEM_PROMPT, user_prompt: @prompt)
    return nil unless raw

    json = JSON.parse(raw[/\{.*\}/m].to_s)
    kind = json["kind"]
    return nil unless KINDS.include?(kind)

    focus = json["focus"]
    focus = nil unless DashboardInsights::FOCUSES.include?(focus)
    focus = nil if kind == "focus_distribution"
    Spec.new(kind: kind, focus: focus, source: "claude")
  rescue JSON::ParserError
    nil
  end

  def from_rules
    text = @prompt.downcase
    kind =
      if text.match?(/share|breakdown|proportion|split|distribution of|how many|volume|mix/)
        "focus_distribution"
      elsif text.match?(/rating|score|star|best|worst|satisf/)
        "rating_by_product"
      else
        "sentiment_by_focus"
      end

    # Focus restriction only makes sense for the sentiment chart here.
    focus = kind == "sentiment_by_focus" ? detect_focus(text) : nil
    Spec.new(kind: kind, focus: focus, source: "rule-based")
  end

  def detect_focus(text)
    DashboardInsights::FOCUSES.find { |f| text.match?(/\b#{f}\b/) }
  end
end
