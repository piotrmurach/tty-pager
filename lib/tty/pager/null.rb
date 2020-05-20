# frozen_string_literal: true

require_relative "abstract"

module TTY
  module Pager
    class NullPager < Abstract
      # Pass output directly to stdout
      #
      # @api public
      def write(text)
        return text unless output.tty?

        output.write(text)
      end
      alias << write

      # Pass output directly to stdout
      #
      # @api public
      def puts(text)
        return text unless output.tty?

        output.puts(text)
      end

      # Do nothing, always return success
      #
      # @api public
      def close
        true
      end
    end
  end # Pager
end # TTY
