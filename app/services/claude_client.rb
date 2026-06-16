# Thin wrapper around the Anthropic Ruby SDK.
#
# Returns nil from #answer whenever Claude is unavailable (no API key, gem not
# loaded, or an API error) so callers can fall back to a deterministic answer.
# Model defaults to Claude Opus 4.8 per current guidance.
class ClaudeClient
  MODEL = :"claude-opus-4-8"
  MAX_TOKENS = 1024

  def self.available?
    ENV["ANTHROPIC_API_KEY"].present? && defined?(Anthropic::Client).present?
  end

  # system_prompt: String, user_prompt: String -> String | nil
  def self.answer(system_prompt:, user_prompt:)
    return nil unless available?

    client = Anthropic::Client.new
    message = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system_: [ { type: "text", text: system_prompt } ],
      messages: [ { role: "user", content: user_prompt } ]
    )
    message.content.filter_map { |block| block.text if block.type == :text }.join.presence
  rescue => e
    Rails.logger.warn("[ClaudeClient] falling back to deterministic answer: #{e.class} #{e.message}")
    nil
  end
end
