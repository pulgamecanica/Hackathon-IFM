# Generates a chart from a natural-language request. ChartSpecGenerator picks
# and parameterizes one of the procedural charts; we render it deterministically
# and stream it into the dashboard.
class ChartsController < ApplicationController
  def create
    prompt = params[:prompt].to_s.strip

    if prompt.blank?
      head :no_content
      return
    end

    @spec = ChartSpecGenerator.new(prompt).call
    @prompt = prompt

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path }
    end
  end
end
