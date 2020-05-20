# frozen_string_literal: true

module TTY
  module Pager
    class Abstract
      UndefinedMethodError = Class.new(StandardError)

      # Paginate content through null, basic or system pager.
      #
      # @api public
      def self.page(**options, &block)
        instance = new(**options)

        begin
          block.call(instance)
        rescue PagerClosed
          # do nothing
        ensure
          instance.close
        end
      end

      # Create a pager
      #
      # @param [IO] :input
      #   the object to send input to
      # @param [IO] :output
      #   the object to send output to
      # @param [Boolean] :enabled
      #   disable/enable text paging
      #
      # @api public
      def initialize(input: $stdin, output: $stdout, enabled: true)
        @input   = input
        @output  = output
        @enabled = enabled
      end

      # Check if pager is enabled
      #
      # @return [Boolean]
      #
      # @api public
      def enabled?
        !!@enabled
      end

      # Page text
      #
      # @example
      #   page('some long text...')
      #
      # @param [String] text
      #   the text to paginate
      #
      # @api public
      def page(text)
        write(text)
      rescue PagerClosed
        # do nothing
      ensure
        close
      end

      # Try writing to the pager. Return false if the pager was closed.
      #
      # In case of system pager, send text to
      # the pager process. Start a new process if it hasn't been
      # started yet.
      #
      # @param [Array<String>] *args
      #   strings to send to the pager
      #
      # @return [Boolean]
      #   the success status of writing to the pager process
      #
      # @api public
      def try_write(*args)
        write(*args)
        true
      rescue PagerClosed
        false
      end

      def write(*args)
        raise UndefinedMethodError
      end

      def puts(*args)
        raise UndefinedMethodError
      end

      def close(*args)
        raise UndefinedMethodError
      end

      protected

      attr_reader :output

      attr_reader :input

    end # Abstract
  end # Pager
end # TTY
