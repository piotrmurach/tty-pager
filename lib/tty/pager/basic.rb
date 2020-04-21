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
        init
        write(text, &callback)
        wait
      end

      def init
        @page_num = 1
        @leftover = []
        @lines_left = @height

        @queue = Queue.new
        @thread = Thread.new do
          loop do
            message = @queue.pop
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

      # TODO (2020-04-21) Encapsulate thread, queue, etc in a "State" struct
      def write(text, &callback)
        raise "Pager was not initialized" if @thread.nil? || @queue.nil? || @page_num.nil? || @leftover.nil? || @lines_left.nil?

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
          @queue << [:print, chunk.join]

          if @lines_left == 0
            return false unless continue_paging?
            @lines_left = @height
            if @leftover.size > 0
              @lines_left -= @leftover.size
            end
            @page_num += 1
            return !callback.call(@page_num) unless callback.nil?
          end
        end

        if @leftover.size > 0
          @queue << [:print, @leftover.join]
        end

        true
      end

      def wait
        @queue << [:quit, nil]
        @thread.join

        @queue = nil
        @thread = nil
        @page_num = nil
        @leftover = nil
        @lines_left = nil
      end

      private

      # @api private
      def continue_paging?
        @queue << [:prompt, @page_num]
        !@input.gets.chomp[/q/i]
      end
    end # BasicPager
  end # Pager
end # TTY
