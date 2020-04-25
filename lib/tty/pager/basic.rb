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

      def write(text, &callback)
        text.lines.each do |line|
          chunk = []
          unless @state.leftover.empty?
            chunk = @state.leftover
            @state.leftover = []
          end
          wrapped_line = Strings.wrap(line, @width)
          wrapped_line.lines.each do |line_part|
            if @state.lines_left.positive?
              chunk << line_part
              @state.lines_left -= 1
            else
              @state.leftover << line_part
            end
          end
          output.print(chunk.join)

          if @state.lines_left.zero?
            return false unless continue_paging?
            @state.lines_left = @height
            unless @state.leftover.empty?
              @state.lines_left -= @state.leftover.size
            end
            @state.page_num += 1
            return !callback.call(@state.page_num) unless callback.nil?
          end
        end

        unless @state.leftover.empty?
          output.print(@state.leftover.join)
        end

        true
      end

      def wait
        reset
      end

      def reset
        @state = State.new(@height)
      end

      private

      # @api private
      def continue_paging?
        @prompt.call(@state.page_num)
        !@input.gets.chomp[/q/i]
      end

      class State
        attr_accessor :page_num, :leftover, :lines_left

        def initialize(height)
          @page_num   = 1
          @leftover   = []
          @lines_left = height
        end
      end
    end # BasicPager
  end # Pager
end # TTY
