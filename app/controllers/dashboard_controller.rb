# Live feedback intelligence dashboard.
#
# The initial page renders current state; thereafter all updates arrive over
# the "feedback_stream" Turbo channel, broadcast by FeedbackIngestor and
# FeedbackAnalysisJob. No polling.
class DashboardController < ApplicationController
  def index
    @stats = DashboardStats.new
    @raw_feedbacks = RawFeedback.recent.includes(:source, :products).limit(20)
    @ai_insights = AiInsight.recent.includes(raw_feedback: :products).limit(20)
  end
end
