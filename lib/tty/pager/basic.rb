# frozen_string_literal: true

require 'strings'

module TTY
  class Pager
    # A basic pager is used to work on systems where
    # system pager is not supported.
    #
    # @api public
    class BasicPager < Pager
      PAGE_BREAK = "\n--- Page -%s- " \
                    "Press enter/return to continue " \
                    "(or q to quit) ---"

      # Create a basic pager
      #
      # @option options [Integer] :height
      #   the terminal height
      # @option options [Integer] :width
      #   the terminal width
      #
      # @api public
      def initialize(**options)
        super
        @height  = options.fetch(:height) { page_height }
        @width   = options.fetch(:width)  { page_width }
        @prompt  = options.fetch(:prompt) { default_prompt }
        prompt_height = PAGE_BREAK.lines.to_a.size
        @height -= prompt_height

        reset
      end

      # Default prompt for paging
      #
      # @return [Proc]
      #
      # @api private
      def default_prompt
        proc { |page_num| output.puts Strings.wrap(PAGE_BREAK % page_num, @width) }
      end

      # Page text
      #
      # @api public
      def page(text, &callback)
        write(text, &callback)
        reset
      end

      # Write text to the pager, prompting on page end. Returns false if the
      # pager was closed.
      #
      # @return [Boolean]
      #   the success status of writing to the screen
      #
      # @api public
      def write(text, &callback)
        text.lines.each do |line|
          chunk = []
          if !@leftover.empty?
            chunk = @leftover
            @leftover = []
          end
          wrapped_line = Strings.wrap(line, @width)
          wrapped_line.lines.each do |line_part|
            if @lines_left > 0
              chunk << line_part
              @lines_left -= 1
            else
              @leftover << line_part
            end
          end
          output.print(chunk.join)

          if @lines_left == 0
            return false unless continue_paging?(@page_num)
            @lines_left = @height
            if @leftover.size > 0
              @lines_left -= @leftover.size
            end
            @page_num += 1
            return !callback.call(@page_num) unless callback.nil?
          end
        end

        if @leftover.size > 0
          output.print(@leftover.join)
        end

        true
      end

      # Stop the pager, wait for it to clean up
      #
      # @api public
      def wait
        reset
        true
      end

      private

      def reset
        @page_num = 1
        @leftover = []
        @lines_left = @height
      end

      # @api private
      def continue_paging?(page_num)
        @prompt.call(page_num)
        !@input.gets.chomp[/q/i]
      end
    end # BasicPager
  end # Pager
end # TTY
