# coding: utf-8

module TTY
  class Pager
    # A basic pager is used to work on systems where
    # system pager is not supported.
    #
    # @api public
    class BasicPager < Pager
      # Page text
      #
      # @api public
      def page(text, &callback)
        page_num = 1
        leftover = []
        lines_left = @height

        text.lines.each do |line|
          chunk = []
          if !leftover.empty?
            chunk = leftover
            leftover = []
          end
          wrapped_line = Verse.wrap(line, @width)
          wrapped_line.lines.each do |line_part|
            if lines_left > 0
              chunk << line_part
              lines_left -= 1
            else
              leftover << line_part
            end
          end
          output.print(chunk.join)

          if lines_left == 0
            break unless continue_paging?(page_num)
            lines_left = @height
            if leftover.size > 0
              lines_left -= leftover.size
            end
            page_num += 1
            return !callback.call(page_num) unless callback.nil?
          end
        end

        if leftover.size > 0
          output.print(leftover.join)
        end
      end

      private

      # @api private
      def continue_paging?(page_num)
        instance_exec(page_num, &@prompt)
        !@input.gets.chomp[/q/i]
      end
    end # BasicPager
  end # Pager
end # TTY
