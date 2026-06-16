# Turns a pending RawFeedback into an AiInsight plus one Rating per product
# per scored dimension (the fan-out from Decision #3/#4).
#
# Flow:
#   pending -> processing -> (AiInsight + Ratings created) -> processed
# On any failure the feedback is marked `failed` and the error re-raised so
# the queue can record/retry it.
#
# Broadcasts the processed card + new insight + refreshed stats to the
# "feedback_stream" Turbo channel.
class FeedbackAnalysisJob < ApplicationJob
  queue_as :default

  def perform(raw_feedback)
    return unless raw_feedback.pending?

    raw_feedback.processing!
    analysis = StubAiAnalyzer.new(raw_feedback).call

    AiInsight.transaction do
      insight = create_insight(raw_feedback, analysis)
      create_ratings(insight, raw_feedback, analysis)
      raw_feedback.processed!
      broadcast(raw_feedback, insight)
    end
  rescue => e
    raw_feedback.failed!
    raw_feedback.broadcast_replace_to(
      "feedback_stream", target: dom_id(raw_feedback),
      partial: "dashboard/raw_feedback", locals: { raw_feedback: raw_feedback }
    )
    raise e
  end

  private

  def create_insight(raw_feedback, analysis)
    raw_feedback.create_ai_insight!(
      synthetic: raw_feedback.synthetic?,
      model_version: analysis.model_version,
      sentiment: analysis.sentiment,
      focus: analysis.focus,
      sentiment_score: analysis.sentiment_score,
      summary: analysis.summary,
      key_themes: analysis.key_themes.join(", "),
      topics: analysis.topics,
      confidence: analysis.confidence,
      language_detected: raw_feedback.language,
      generated_at: Time.current
    )
  end

  # One Rating per (product, dimension). Products come from the parent feedback.
  def create_ratings(insight, raw_feedback, analysis)
    raw_feedback.products.each do |product|
      analysis.dimension_scores.each do |dimension, score|
        insight.ratings.create!(
          product: product,
          dimension: dimension,
          score: score,
          synthetic: insight.synthetic?,
          rated_at: Time.current
        )
      end
    end
  end

  def broadcast(raw_feedback, insight)
    raw_feedback.broadcast_replace_to(
      "feedback_stream", target: dom_id(raw_feedback),
      partial: "dashboard/raw_feedback", locals: { raw_feedback: raw_feedback }
    )
    insight.broadcast_prepend_to(
      "feedback_stream", target: "insights",
      partial: "dashboard/ai_insight", locals: { ai_insight: insight }
    )
    DashboardBroadcaster.refresh
  end

  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
