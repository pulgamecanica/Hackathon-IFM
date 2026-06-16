# Live, interactive feedback dashboard. Every section is derived from the active
# FeedbackFilter, so changing a filter (which reloads the dashboard-body Turbo
# Frame) updates the entire page.
class DashboardController < ApplicationController
  def index
    @filter = FeedbackFilter.from_params(params)
    @stats = DashboardStats.new(@filter)
    @insights = DashboardInsights.new(@filter)
    @chart_data = ChartData.new(@filter)
    @raw_feedbacks = @filter.feedbacks.recent.includes(:source, :products, :ai_insight).limit(20)
    @ai_insights = @filter.insights.recent.includes(raw_feedback: :products).limit(20)
  end

  # Polled by the map controller; honors the active filter.
  def map_data
    render json: LocationFeedbackSummary.as_json(FeedbackFilter.from_params(params))
  end
end
