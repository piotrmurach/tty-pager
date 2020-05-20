# frozen_string_literal: true

require_relative "pager/basic"
require_relative "pager/null"
require_relative "pager/system"
require_relative "pager/version"

module TTY
  module Pager
    Error = Class.new(StandardError)
    PagerClosed = Class.new(Error)

    module ClassMethods
      # Create a pager
      #
      # @param [Hash] options
      # @option options [Proc] :prompt
      #   a proc object that accepts page number
      # @option options [IO] :input
      #   the object to send input to
      # @option options [IO] :output
      #   the object to send output to
      # @option options [Boolean] :enabled
      #   disable/enable text paging
      #
      # @api public
      def new(**options)
        select_pager(**options).new(**options)
      end

      # Paginate content through null, basic or system pager.
      #
      # @example
      #   TTY::Pager.page do |pager|
      #     pager.write "some text"
      #   end
      #
      # @param [String] text
      #   an optional blob of content
      # @param [String] path
      #   a path to a file
      #
      # @api public
      def page(text = nil, enabled: true, command: nil, **options, &block)
        select_pager(enabled: enabled, command: command).
          page(text, command: command, **options, &block)
      end

      # Select an appriopriate pager
      #
      # If the user disabled paging then a NullPager is returned,
      # otherwise a check is performed to find native system
      # command to perform pagination with SystemPager. Finally,
      # if no system command is found, a BasicPager is used which
      # is a pure Ruby implementation known to work on any platform.
      #
      # @param [Boolean] enabled
      #   whether or not to allow paging
      # @param [String] command
      #   the command to run if available
      #
      # @api private
      def select_pager(enabled: true, command: nil)
        commands = Array(command)

        if !enabled
          NullPager
        elsif SystemPager.exec_available?(*commands)
          SystemPager
        else
          BasicPager
        end
      end
    end

    extend ClassMethods

    private_class_method :select_pager
  end # Pager
end # TTY
