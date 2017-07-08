# coding: utf-8

require 'tty-screen'

require_relative "pager/basic"
require_relative "pager/null"
require_relative "pager/system"
require_relative "pager/version"

module TTY
  class Pager
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
    def initialize(options = {})
      @input   = options.fetch(:input)  { $stdin }
      @output  = options.fetch(:output) { $stdout }
      @enabled = options.fetch(:enabled) { true }

      if self.class == TTY::Pager
        @pager = find_available(options)
      end
    end

    # Check if pager is enabled
    #
    # @return [Boolean]
    #
    # @api public
    def enabled?
      !!@enabled
    end

    # Page the given text through the available pager
    #
    # @param [String] text
    #   the text to run through a pager
    #
    # @yield [Integer] page number
    #
    # @return [TTY::Pager]
    #
    # @api public
    def page(text, &callback)
      pager.page(text, &callback)
      self
    end

    # The terminal height
    #
    # @api public
    def page_height
      TTY::Screen.height
    end

    # The terminal width
    #
    # @api public
    def page_width
      TTY::Screen.width
    end

    protected

    attr_reader :output

    attr_reader :input

    attr_reader :pager

    # Find available pager
    #
    # If the user disabled paging then a NullPager is returned,
    # otherwise a check is performed to find native system
    # utility to perform pagination with SystemPager. Finally,
    # if no system utility exists a BasicPager is used which
    # is pure Ruby implementation.
    #
    # @api private
    def find_available(options)
      if !enabled?
        NullPager.new
      elsif SystemPager.available? && !Pager.jruby?
        SystemPager.new(options)
      else
        BasicPager.new(options)
      end
    end

    # Check if running on jruby
    #
    # @api private
    def self.jruby?
      RbConfig::CONFIG['ruby_install_name'] == 'jruby'
    end
  end # Pager
end # TTY
