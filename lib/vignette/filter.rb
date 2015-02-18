if defined?(Haml)
  module Haml::Filters::Vignette
    include Haml::Filters::Base


    # TODO: We need to find a way to disable caching
    def render_with_options(text, options)
      splitter = "\n"
      splitter = '->' if text.include?('->')
      lines = text.split splitter

      # Allow first line to be name of test, if desired
      if options[:name] && options[:name] =~ /vignette_(\w+)/i
        lines.vignette($1)

      # Otherwise, try to use filename and line
      elsif options[:filename] && options[:line]
        if options[:filename] == "(haml)"
          lines.vignette("(haml:#{options[:line]})", expect_consistent_name: false)
        else
          lines.vignette("(#{Vignette::strip_path(options[:filename])}:#{options[:line]})", expect_consistent_name: false)
        end
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
      node = compiler.instance_variable_get('@node')

      filename = compiler.options[:filename]
      line = node.line
      name = node.value[:name]

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
find_and_preserve(#{filter.inspect}.render_with_options(#{text}, _hamlout.options.merge(filename: "#{filename}", line: #{line}, name: "#{name}")))
RUBY
        return
      end

      rendered = Haml::Helpers::find_and_preserve(filter.render_with_options(text, compiler.options, filename, line), compiler.options[:preserve])
      rendered.rstrip!
      rendered.gsub!("\n", "\n#{'  ' * @output_tabs}") unless options[:ugly]
      push_text(rendered)
    end
  end

  # This is hack to allow us to pull names from filters
  module HamlCompilerHack

    def compile_filter
      if @node.value[:name] =~ /vignette_(\w+)/i
        Haml::Filters::Vignette.internal_compile(self, @node.value[:text])
      else
        super
      end

    end
  end

  Haml::Compiler.prepend(HamlCompilerHack)
end