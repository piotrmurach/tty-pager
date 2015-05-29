# coding: utf-8

module TTY
  class Pager
    class NullPager < Pager
      # Pass output directly to stdout
      #
      # @api public
      def page(text, &callback)
        output.puts(text)
      end
    end
  end # Pager
end # TTY
