# frozen_string_literal: true

require 'forwardable'
require 'tty-screen'

require_relative 'pager/basic'
require_relative 'pager/null'
require_relative 'pager/system'
require_relative 'pager/version'

module TTY
  class Pager
    extend Forwardable

    Error = Class.new(StandardError)
    PagerClosed = Class.new(Error)

    # Select an appriopriate pager
    #
    # If the user disabled paging then a NullPager is returned,
    # otherwise a check is performed to find native system
    # command to perform pagination with SystemPager. Finally,
    # if no system command is found, a BasicPager is used which
    # is a pure Ruby implementation known to work on any platform.
    #
    # @api private
    def self.select_pager(enabled, commands)
      if !enabled
        NullPager
      elsif SystemPager.exec_available?(*commands)
        SystemPager
      else
        BasicPager
      end
    end

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
    def initialize(**options)
      @input   = options.fetch(:input)  { $stdin }
      @output  = options.fetch(:output) { $stdout }
      @enabled = options.fetch(:enabled) { true }
      commands = Array(options[:command])

      if self.class == TTY::Pager
        @pager = self.class.select_pager(@enabled, commands).new(**options)
      end
    end

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
    def page(text)
      pager.page(text)
      self
    end

    # Write the given text to the available pager
    #
    # @param [Array<String>] *args
    #   strings to send to the pager
    #
    # @raise [PagerClosed]
    #   if the write failed due to a closed pager tool
    #
    # @return [TTY::Pager]
    #
    # @api public
    def write(*args)
      pager.write(*args)
      self
    end
    alias << :write

    # Write a newline-ended line to the available pager
    #
    # @param [String] text
    #   the text to send to the pager
    #
    # @return [TTY::Pager]
    #
    # @api public
    def puts(text)
      pager.puts(text)
      self
    end

    # Close the pager tool, wait for it to finish
    #
    # @return [Boolean]
    #   whether the pager exited successfully
    #
    # @api public
    def_delegator :pager, :close

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
  end # Pager
end # TTY
