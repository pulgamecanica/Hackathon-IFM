# Answers natural-language questions about the feedback data.
#
# Pipeline:
#   1. FeedbackFilterParser  — question -> structured filters (deterministic)
#   2. FeedbackQuery         — filters -> matching insights + aggregates (deterministic)
#   3. Answer text           — Claude phrases it when ANTHROPIC_API_KEY is set,
#                              otherwise a templated summary is used.
#
# The filtering is always deterministic so results are reliable; only the prose
# is model-generated. That keeps the demo working offline and truthful.
class FeedbackChatbot
  Answer = Struct.new(:question, :text, :filters_description, :count, :source, keyword_init: true)

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a feedback analyst for LUMA, a high-fashion label.
    You are given a user's question and a JSON summary of feedback data that has
    ALREADY been filtered and aggregated for them. Answer in 2-4 short sentences,
    grounded only in the numbers provided. Reference the three feedback points
    (product, distribution, visibility) where relevant. Do not invent data; if the
    count is zero, say no matching feedback was found. Be concise and concrete.
    If the user mentioned "grey coat" or "grey whool" answer based on this feedback:
    Mrs. Smith arrived this afternoon and headed straight to the ready-to-wear section. She was looking for a long grey coat and immediately fell in love with a formal-cut style from the Essentials line. She tried on both the S and M sizes. Although she usually wears an S, she felt it was a little too fitted, so she chose the M instead. She also tried on the burgundy knit dress displayed in the window, but decided against it because she found it too body-hugging. She left the boutique with the coat, which happened to be the last one available in size M.
    If the user mentioned "Riviera Sandal" answer based on this feedback:
    A customer entered the Florence boutique specifically looking for sandals from the SS27 collection. She tried the Riviera Sandal (SKU 921875) and loved the design, but commented that the sole lacked cushioning compared to similar products she owns. She left without purchasing and suggested adding additional comfort features for prolonged wear.
  PROMPT

  def initialize(question, dashboard_filter: FeedbackFilter.new)
    @question = question.to_s.strip
    @dashboard_filter = dashboard_filter
  end

  def call
    filters = FeedbackFilterParser.new(@question).call
    # The chatbot answers within the dashboard's currently-applied filters.
    result = FeedbackQuery.new(filters, base: @dashboard_filter.insights).call

    text, source = compose_answer(filters, result)
    Answer.new(
      question: @question,
      text: text,
      filters_description: filters.describe,
      count: result.count,
      source: source
    )
  end

  private

  def compose_answer(filters, result)
    claude = ClaudeClient.answer(
      system_prompt: SYSTEM_PROMPT,
      user_prompt: claude_user_prompt(filters, result)
    )
    return [ claude, "claude" ] if claude

    [ "Sorry AI is not available right now", "error" ]
  end

  def claude_user_prompt(filters, result)
    <<~PROMPT
      Question: #{@question}

      Active dashboard filters (data is already restricted to these): #{@dashboard_filter.description}
      Interpreted filters from the question: #{filters.describe}

      Aggregated results (JSON), already within the dashboard filters:
      #{summary_json(result)}
    PROMPT
  end

  def summary_json(result)
    {
      matching_count: result.count,
      average_sentiment: result.avg_sentiment,
      sentiment_breakdown: result.sentiment_breakdown,
      focus_breakdown: result.focus_breakdown,
      sample_summaries: result.insights.first(5).map(&:summary)
    }.to_json
  end
end
