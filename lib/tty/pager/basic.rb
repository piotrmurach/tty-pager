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

        @printer = nil
      end

      # Default prompt for paging
      #
      # @return [Proc]
      #
      # @api private
      def default_prompt
        proc { |page_num| output.puts Strings.wrap(PAGE_BREAK % page_num, width) }
      end

      # Page text
      #
      # @api public
      def page(text, &callback)
        write(text, &callback)
        wait
      end

      def start
        # In case there's a previous pager running:
        wait
        Printer.new(@width, @height, @output, @prompt)
      end

      def write(text, &callback)
        @printer ||= start

        text.lines.each do |line|
          chunk = []
          unless @printer.leftover.empty?
            chunk = @printer.leftover
            @printer.leftover = []
          end
          wrapped_line = Strings.wrap(line, @width)
          wrapped_line.lines.each do |line_part|
            if @printer.lines_left.positive?
              chunk << line_part
              @printer.lines_left -= 1
            else
              @printer.leftover << line_part
            end
          end
          @printer.print(chunk.join)

          if @printer.lines_left.zero?
            return false unless continue_paging?
            @printer.lines_left = @height
            unless @printer.leftover.empty?
              @printer.lines_left -= @printer.leftover.size
            end
            @printer.page_num += 1
            return !callback.call(@printer.page_num) unless callback.nil?
          end
        end

        unless @printer.leftover.empty?
          @printer.print(@printer.leftover.join)
        end

        true
      end

      def wait
        return unless @printer
        @printer.quit
        @printer = nil
      end

      private

      # @api private
      def continue_paging?
        @printer.prompt(@printer.page_num)
        !@input.gets.chomp[/q/i]
      end

      class Printer
        attr_accessor :lines_left, :page_num, :leftover
        attr_reader :output, :width, :height

        def initialize(width, height, output, prompt)
          @width  = width
          @height = height
          @output = output
          @prompt = prompt

          @page_num   = 1
          @leftover   = []
          @lines_left = height

          @fiber = Fiber.new do |command, message|
            loop do
              case command
              when :quit then break
              when :print then @output.print(message)
              when :prompt then instance_exec(message, &@prompt)
              else
                raise "Unknown command type: #{command}"
              end

              command, message = Fiber.yield
            end
          end
        end

        def print(message)
          @fiber.resume(:print, message)
        end

        def prompt(message)
          @fiber.resume(:prompt, message)
        end

        def quit
          @fiber.resume(:quit, nil)
        end
      end
    end # BasicPager
  end # Pager
end # TTY
