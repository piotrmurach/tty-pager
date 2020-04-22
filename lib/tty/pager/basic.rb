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

        @running = false
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
        wait
      end

      def start
        @running = true
        @state = State.new(@height)

        @state.queue = Queue.new
        @state.thread = Thread.new do
          loop do
            message = @state.queue.pop
            if message.nil?
              sleep 0.1
              next
            end

            type    = message[0]
            payload = message[1]

            case type
            when :quit then break
            when :print then output.print(payload)
            when :prompt then instance_exec(payload, &@prompt)
            else
              raise "Unknown message type: #{type}"
            end
          end
        end
      end

      def write(text, &callback)
        start unless running?

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
          @state.queue << [:print, chunk.join]

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
          @state.queue << [:print, @state.leftover.join]
        end

        true
      end

      def wait
        return unless running?
        @state.queue << [:quit, nil]
        @state.thread.join

        @state = nil
        @running = nil
      end

      private

      # @api private
      def continue_paging?
        @state.queue << [:prompt, @state.page_num]
        !@input.gets.chomp[/q/i]
      end

      class State
        attr_accessor :queue, :thread, :lines_left, :page_num, :leftover

        def initialize(height)
          @page_num = 1
          @leftover = []
          @lines_left = height
        end
      end
    end # BasicPager
  end # Pager
end # TTY
