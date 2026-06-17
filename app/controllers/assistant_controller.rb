# LUMA Concierge — a standalone, installable (PWA) mobile-first chat app for
# SELLERS to log client feedback they gathered at the point of sale. Each message
# is ingested as a RawFeedback via FeedbackIngestor (which then triggers the same
# AI analysis pipeline the dashboard reads). This is the ingestion counterpart to
# the dashboard Concierge, which only ANALYZES feedback — the two are distinct.
class AssistantController < ApplicationController
  layout "assistant"

  SOURCE_KEY = "seller_app"

  def show
  end

  def create
    message = params[:message].to_s.strip

    if message.blank?
      head :no_content
      return
    end

    # Deterministically detect which product/location the seller referenced so we
    # can link the feedback; the message text itself is stored as the content.
    @detected = FeedbackFilterParser.new(message).call
    @result = FeedbackIngestor.new(
      content: message,
      source_adapter_key: SOURCE_KEY,
      channel: :pos,
      product_ids: [ @detected.product_id ].compact,
      location_id: @detected.location_id
    ).call

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_path }
    end
  end
end
