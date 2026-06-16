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
  PROMPT

  def initialize(question)
    @question = question.to_s.strip
  end

  def call
    filters = FeedbackFilterParser.new(@question).call
    result = FeedbackQuery.new(filters).call

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

      Interpreted filters: #{filters.describe}

      Aggregated results (JSON):
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
