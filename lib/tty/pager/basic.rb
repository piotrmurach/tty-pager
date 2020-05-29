# frozen_string_literal: true

require "io/console"
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
        @width   = width
        @prompt  = prompt
        prompt_height = Strings.wrap(prompt.call(100).to_s, width).lines.count
        @page_cursor = PageCursor.new(height - prompt_height)

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
        @page_cursor.reset
        @leftover = []
      end

      # Tracks page cursor
      #
      # @api private
      class PageCursor
        attr_reader :page_num

        def initialize(height)
          @height = height
          reset
        end

        def reset
          @page_num = 1
          @lines_left = @height
        end

        # Move cursor to the next page
        #
        # @api public
        def next_page
          @page_num += 1
          @lines_left = @height
        end

        # Move coursor down the page by count
        #
        # @param [Integer] count
        #
        # @api public
        def down_by(count)
          @lines_left -= count
        end

        # Check if time to break a page
        #
        # @return [Boolean]
        #
        # @api private
        def page_break?
          @lines_left.zero?
        end
      end

      # The lower-level common implementation of printing methods
      #
      # @return [Boolean]
      #   the success status of writing to the screen
      #
      # @api private
      def send_text(write_method, text)
        text.lines.each do |line|
          chunk = create_chunk_from(line)

          output.public_send(write_method, chunk)

          next unless @page_cursor.page_break?

          output.puts(page_break_prompt)

          continue_paging?(input)

          next_page
        end

        if !remaining_content.empty?
          output.public_send(write_method, remaining_content)
        end
      end

      # Convert line to a chunk of text to fit display
      #
      # @param [String] line
      #
      # @return [String]
      #
      # @api private
      def create_chunk_from(line)
        chunk = []

        if !@leftover.empty?
          chunk.concat(@leftover)
          @leftover.clear
        end

        Strings.wrap(line, @width).lines.each do |line_part|
          if !@page_cursor.page_break?
            chunk << line_part
            @page_cursor.down_by(1)
          else
            @leftover << line_part
          end
        end

        chunk.join
      end

      # Any remaining content
      #
      # @return [String]
      #
      # @api private
      def remaining_content
        @leftover.join
      end

      # Switch over to the next page
      #
      # @api private
      def next_page
        @page_cursor.next_page
        if @leftover.size > 0
          @page_cursor.down_by(@leftover.size)
        end
      end

      # Dispaly prompt at page break
      #
      # @api private
      def page_break_prompt
        Strings.wrap(@prompt.call(@page_cursor.page_num), @width)
      end

      # Check if paging should be continued
      #
      # @param [Integer] page
      #   the page number
      #
      # @return [Boolean]
      #
      # @api private
      def continue_paging?(input)
        if getchar.chomp[/q/i]
          raise PagerClosed.new("The pager tool was closed")
        end
      end

      # Find available character reading method
      #
      # @api private
      def getchar
        input.respond_to?(:getch) ? input.getch : input.getc
      end
    end # BasicPager
  end # Pager
end # TTY
