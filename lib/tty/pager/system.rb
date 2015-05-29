# coding: utf-8

module TTY
  class Pager
    # A system pager is used  on systems where native
    # pagination exists
    #
    # @api public
    class SystemPager < Pager
      # Find first available system command for paging
      #
      # @param [Array[String]] commands
      #
      # @return [String]
      #
      # @api public
      def self.available(*commands)
        commands = commands.empty? ? executables : commands
        commands.compact.uniq.find { |cmd| command_exists?(cmd) }
      end

      # Check if command is available
      #
      # @api public
      def self.available?
        !available.nil?
      end

      # Use system command to page output text
      #
      # @param [String] text
      #
      # @api public
      def page(text, &callback)
        read_io, write_io = IO.pipe

        if fork
          # parent process
          write_io.close
          input.reopen(read_io)
          read_io.close

          # Wait until we have input before we start the pager
          IO.select [input]

          begin
            exec(pager_command)
          rescue SystemCallError
            exit 1
          end
        else
          # child process
          read_io.close
          write_io.write(text)
          write_io.close
        end
      end

      private

      # List possible executables for output paging
      #
      # @return [Array[String]]
      #
      # @api private
      def self.executables
        [ENV['GIT_PAGER'], ENV['PAGER'],
         `git config --get-all core.pager`.split.first,
        'less', 'more', 'cat', 'pager']
      end
      private_class_method :executables

      # Check if command exists
      #
      # @param [String] command
      #   the command to check
      #
      # @return [Boolean]
      #
      # @api private
      def self.command_exists?(command)
        !system(command).nil?
      end
      private_class_method :command_exists?

      # The pager command to run
      #
      # @return [String]
      #   the name of executable to run
      #
      # @api private
      def pager_command(*commands)
        @pager_command = if @pager_command && commands.empty?
          @pager_command
        else
          self.class.available(*commands)
        end
      end
    end # SystemPager
  end # Pager
end # TTY
