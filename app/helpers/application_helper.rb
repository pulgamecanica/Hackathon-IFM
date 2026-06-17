module ApplicationHelper
  # Renders the assistant's markdown answer to sanitized HTML. Claude replies in
  # markdown (bold, lists, etc.); this turns it into safe, styled HTML.
  def markdown(text)
    return "".html_safe if text.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true,
                                           link_attributes: { rel: "noopener", target: "_blank" })
    parser = Redcarpet::Markdown.new(renderer, autolink: true, tables: true,
                                     strikethrough: true, no_intra_emphasis: true,
                                     fenced_code_blocks: true, lax_spacing: true)
    sanitize(
      parser.render(text),
      tags: %w[p br strong em b i ul ol li a code pre h1 h2 h3 h4 blockquote hr table thead tbody tr th td],
      attributes: %w[href rel target]
    )
  end
end
