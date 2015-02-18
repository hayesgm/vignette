if defined?(Haml)
  module Haml::Filters::Vignette
    include Haml::Filters::Base


    # TODO: We need to find a way to disable caching
    def render_with_options(text, options)
      splitter = "\n"
      splitter = '->' if text.include?('->')
      lines = text.split splitter

      # Allow first line to be name of test, if desired
      if lines.first.strip =~ /^\[(\w+)\]$/
        lines[1..-1].vignette($1)

      # Otherwise, try to use filename and line
      elsif options[:filename] && options[:line]
        lines.vignette("(#{strip_path(options[:filename])}:#{options[:line]})")

      # If not given, raise an error
      else
        Vignette::Errors::TemplateRequiresNameError.new("Missing filename or [test_name] in Vignette test")
      end
    end

    # Note, this is copied from haml/filter.rb
    # Unless the text contained interpolation, haml seems
    # to naturally cache the result.  This was impossible,
    # then to run a test based on session, etc.
    # I removed that check from below.
    def compile(compiler, text)
      filter = self
      filename = compiler.options[:filename]
      line = compiler.instance_variable_get('@node').line

      compiler.instance_eval do
        return if options[:suppress_eval]

        text = unescape_interpolation(text).gsub(/(\\+)n/) do |s|
          escapes = $1.size
          next s if escapes % 2 == 0
          "#{'\\' * (escapes - 1)}\n"
        end
        # We need to add a newline at the beginning to get the
        # filter lines to line up (since the Haml filter contains
        # a line that doesn't show up in the source, namely the
        # filter name). Then we need to escape the trailing
        # newline so that the whole filter block doesn't take up
        # too many.
        text = %[\n#{text.sub(/\n"\Z/, "\\n\"")}]
        push_script <<RUBY.rstrip, :escape_html => false
find_and_preserve(#{filter.inspect}.render_with_options(#{text}, _hamlout.options.merge(filename: "#{filename}", line: #{line})))
RUBY
        return
      end

      rendered = Haml::Helpers::find_and_preserve(filter.render_with_options(text, compiler.options, filename, line), compiler.options[:preserve])
      rendered.rstrip!
      rendered.gsub!("\n", "\n#{'  ' * @output_tabs}") unless options[:ugly]
      push_text(rendered)
    end
  end

end