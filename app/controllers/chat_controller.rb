# Feedback chatbot endpoint. Takes a natural-language question, runs it through
# FeedbackChatbot, and appends the question + answer to the chat log via Turbo Stream.
class ChatController < ApplicationController
  def create
    question = params[:question].to_s.strip

    if question.blank?
      head :no_content
      return
    end

    @filter = FeedbackFilter.from_params(params)
    @answer = FeedbackChatbot.new(question, dashboard_filter: @filter).call

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path }
    end
  end
end
