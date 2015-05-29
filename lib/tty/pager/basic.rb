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
          chunk = leftover.dup unless leftover.empty?
          wrapped_line = Verse.wrap(line, @width)
          wrapped_line.lines.map(&:chomp).each do |line_part|
            if lines_left > 0
              chunk << line_part.chomp
              lines_left -= 1
            else
              leftover << line_part.chomp
            end
          end
          output.puts chunk.join("\n")

          if lines_left == 0
            break unless continue_paging?(page_num)
            lines_left = @height
            lines_left -= leftover.size
            page_num += 1
            return !callback.call(page_num) unless callback.nil?
          end
        end

        if lines_left > 0
          output.print leftover.join("\n")
          output.puts unless leftover.empty?
        end
      end

      private

      def continue_paging?(page_num)
        instance_exec(page_num, &@prompt)
        !@input.gets.chomp[/q/i]
      end
    end # BasicPager
  end # Pager
end # TTY
