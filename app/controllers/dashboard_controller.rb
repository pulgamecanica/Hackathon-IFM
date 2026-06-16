# Live feedback intelligence dashboard.
#
# The initial page renders current state; thereafter all updates arrive over
# the "feedback_stream" Turbo channel, broadcast by FeedbackIngestor and
# FeedbackAnalysisJob. No polling.
class DashboardController < ApplicationController
  def index
    @stats = DashboardStats.new
    @insights = DashboardInsights.new
    @raw_feedbacks = RawFeedback.recent.includes(:source, :products).limit(20)
    @ai_insights = AiInsight.recent.includes(raw_feedback: :products).limit(20)
  end

  # Polled by the map Stimulus controller for live marker updates.
  def map_data
    render json: LocationFeedbackSummary.as_json
  end
end
