# frozen_string_literal: true

module TTY
  module Pager
    class Abstract
      UndefinedMethodError = Class.new(StandardError)

      # Paginate content through null, basic or system pager.
      #
      # @param [String] text
      #   an optional blob of content
      # @param [String] path
      #   a path to a file
      #
      # @api public
      def self.page(text = nil, path: nil, **options, &block)
        validate_arguments(text, path, block)

        instance = new(**options)

        begin
          if block_given?
            block.call(instance)
          else
            instance.page(text, path: path)
          end
        rescue PagerClosed
          # do nothing
        ensure
          instance.close
        end
      end

      # Disallow mixing input arguments
      #
      # @raise [IvalidArgument]
      #
      # @api private
      def self.validate_arguments(text, path, block)
        message = if !text.nil? && !block.nil?
                    "Cannot give text argument and block at the same time."
                  elsif !text.nil? && !path.nil?
                    "Cannot give text and :path arguments at the same time."
                  elsif !path.nil? && !block.nil?
                    "Cannot give :path argument and block at the same time."
                  end
        raise(InvalidArgument, message) if message
      end
      private_class_method :validate_arguments

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
      def initialize(input: $stdin, output: $stdout, enabled: true, **_options)
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
      def page(text = nil, path: nil)
        if path
          IO.foreach(path) do |line|
            write(line)
          end
        else
          write(text)
        end
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

      def write(*)
        raise UndefinedMethodError
      end

      def puts(*)
        raise UndefinedMethodError
      end

      def close(*)
        raise UndefinedMethodError
      end

      protected

      attr_reader :output

      attr_reader :input
    end # Abstract
  end # Pager
end # TTY
