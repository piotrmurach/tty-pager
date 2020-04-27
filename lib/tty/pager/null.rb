# frozen_string_literal: true

module TTY
  class Pager
    class NullPager < Pager
      # Pass output directly to stdout
      #
      # @api public
      def page(text, &callback)
        write(text, &callback)
      end

      # Pass output directly to stdout
      #
      # @api public
      def write(text, &_callback)
        return text unless output.tty?

        output.write(text)
      end

      # Do nothing, always return success
      #
      # @api public
      def wait
        true
      end
    end
  end # Pager
end # TTY
