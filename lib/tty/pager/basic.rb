# frozen_string_literal: true

require "strings"
require "tty-screen"

require_relative "abstract"

module TTY
  module Pager
    # A basic pager is used to work on systems where
    # system pager is not supported.
    #
    # @api public
    class BasicPager < Abstract
      PAGE_BREAK = "\n--- Page -%<page>s- Press enter/return to continue " \
                    "(or q to quit) ---"

      # Default prompt for paging
      #
      # @return [Proc]
      #
      # @api private
      DEFAULT_PROMPT = ->(page) { format(PAGE_BREAK, page: page) }

      # Create a basic pager
      #
      # @param [Integer] :height
      #   the terminal height
      # @param [Integer] :width
      #   the terminal width
      # @param [Proc] :prompt
      #   a proc object that accepts page number
      #
      # @api public
      def initialize(height: TTY::Screen.height, width: TTY::Screen.width,
                     prompt: DEFAULT_PROMPT, **options)
        super(**options)
        @height  = height
        @width   = width
        @prompt  = prompt
        prompt_height = PAGE_BREAK.lines.to_a.size
        @height -= prompt_height

        reset
      end

      # Write text to the pager, prompting on page end.
      #
      # @raise [PagerClosed]
      #   if the pager was closed
      #
      # @return [TTY::Pager::BasicPager]
      #
      # @api public
      def write(*args)
        args.each do |text|
          send_text(:write, text)
        end
        self
      end
      alias << write

      # Print a line of text to the pager, prompting on page end.
      #
      # @raise [PagerClosed]
      #   if the pager was closed
      #
      # @api public
      def puts(text)
        send_text(:puts, text)
      end

      # Stop the pager, wait for it to clean up
      #
      # @api public
      def close
        reset
        true
      end

      private

      # Reset internal state
      #
      # @api private
      def reset
        @page_num = 1
        @leftover = []
        @lines_left = @height
      end

      # The lower-level common implementation of printing methods
      #
      # @return [Boolean]
      #   the success status of writing to the screen
      #
      # @api private
      def send_text(write_method, text)
        text.lines.each do |line|
          chunk = []

          if !@leftover.empty?
            chunk.concat(@leftover)
            @leftover.clear
          end

          Strings.wrap(line, @width).lines.each do |line_part|
            if @lines_left > 0
              chunk << line_part
              @lines_left -= 1
            else
              @leftover << line_part
            end
          end

          output.public_send(write_method, chunk.join)

          next unless @lines_left.zero?

          unless continue_paging?(@page_num)
            raise PagerClosed.new("The pager tool was closed")
          end

          @lines_left = @height
          if @leftover.size > 0
            @lines_left -= @leftover.size
          end
          @page_num += 1
        end

        if !@leftover.empty?
          output.public_send(write_method, @leftover.join)
        end
      end

      # Check if paging should be continued
      #
      # @param [Integer] page
      #   the page number
      #
      # @return [Boolean]
      #
      # @api private
      def continue_paging?(page)
        output.puts(Strings.wrap(@prompt.call(page), @width))
        !@input.gets.chomp[/q/i]
      end
    end # BasicPager
  end # Pager
end # TTY
