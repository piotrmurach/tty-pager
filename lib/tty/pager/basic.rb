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
          wrapped_line = Strings.wrap(line, @width)
          wrapped_line.lines.each do |line_part|
            @pagination.push(line_part)
          end

          output.print(@pagination.take_lines.join)

          if @pagination.at_page_end?
            return false if stop_paging?
            @pagination.start_next_page(@height)

            return !callback.call(@pagination.page_num) unless callback.nil?
          end
        end

        if @pagination.has_leftover?
          output.print(@pagination.leftover.join)
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
        @pagination = Pagination.new(@height)
      end

      # @api private
      def stop_paging?
        @prompt.call(@pagination.page_num)
        @input.gets.chomp =~ /q/i
      end

      class Pagination
        attr_reader :page_num, :leftover

        def initialize(lines_per_page)
          @page_num     = 1
          @current_page = []
          @leftover     = []
          @lines_left   = lines_per_page
        end

        def at_page_end?
          @lines_left.zero?
        end

        def has_leftover?
          !@leftover.empty?
        end

        def take_lines
          lines = @current_page
          @current_page = []
          lines
        end

        def start_next_page(lines_per_page)
          @current_page = []
          @lines_left = lines_per_page
          @lines_left -= @leftover.size
          @page_num += 1
        end

        def push(line)
          if @lines_left > 0
            @current_page << line
            @lines_left -= 1
          else
            @leftover << line
          end
        end
      end
    end # BasicPager
  end # Pager
end # TTY
