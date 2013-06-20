module Haml::Filters::Vignette
  include Haml::Filters::Base

  # TODO: We need to find a way to disable caching
  def render_with_options(text, options)
    splitter = "\n"
    splitter = '->' if text.include?('->')
    lines = text.split splitter
    lines.vignette
  end
end