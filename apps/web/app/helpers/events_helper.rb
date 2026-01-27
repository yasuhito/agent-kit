# frozen_string_literal: true

require 'kramdown'

module EventsHelper
  def render_markdown_preview(text)
    return ''.html_safe if text.blank?

    html = Kramdown::Document.new(
      text.to_s,
      input: 'GFM',
      hard_wrap: true,
      auto_ids: false
    ).to_html

    sanitize(
      html,
      tags: %w[p strong em b i code a br ul ol li],
      attributes: %w[href title]
    ).html_safe
  rescue StandardError
    ERB::Util.html_escape(text)
  end
end
