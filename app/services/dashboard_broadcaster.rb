# Single place that pushes the recomputed dashboard panels over Turbo Streams.
# Called after every ingest and after every analysis so the stats bar and the
# analytics panels (focus / negativity / key insights) stay live without polling.
class DashboardBroadcaster
  STREAM = "feedback_stream"

  def self.refresh
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "stats",
      partial: "dashboard/stats", locals: { stats: DashboardStats.new }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "analytics",
      partial: "dashboard/analytics", locals: { insights: DashboardInsights.new }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "charts",
      partial: "dashboard/charts_default", locals: { chart_data: ChartData.new }
    )
  end
end
