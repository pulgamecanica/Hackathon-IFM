# Feedback chatbot endpoint. Takes a natural-language question, runs it through
# FeedbackChatbot, and appends the answer to the chat log via Turbo Stream. Any
# filters detected in the question are merged over the dashboard's currently-
# applied filters so the floating Concierge can drive the dashboard.
class ChatController < ApplicationController
  def create
    question = params[:question].to_s.strip

    if question.blank?
      head :no_content
      return
    end

    # Filters detected in the question, mapped to dashboard filter params.
    @applied_filters = detected_filters(question)
    # Answer within the resulting view: active dashboard filters + the detected ones.
    @filter = FeedbackFilter.from_params(current_filter_params.merge(@applied_filters))
    @answer = FeedbackChatbot.new(question, dashboard_filter: @filter).call

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path(@filter.to_params) }
    end
  end

  private

  # The dashboard's currently-applied filters, carried by the chat form.
  def current_filter_params
    { focus: params[:focus], theme: params[:theme], sentiment: params[:sentiment],
      sku: params[:sku], location: params[:location] }
  end

  # Question -> dashboard filter params (only the dimensions the question names).
  def detected_filters(question)
    parsed = FeedbackFilterParser.new(question).call
    filters = {}
    filters[:focus] = parsed.focus if parsed.focus
    filters[:sentiment] = parsed.sentiment if parsed.sentiment
    filters[:location] = parsed.location_id if parsed.location_id
    if parsed.product_id && (sku = Product.where(id: parsed.product_id).pick(:sku))
      filters[:sku] = sku
    end
    filters
  end
end
