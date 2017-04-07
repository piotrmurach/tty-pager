# coding: utf-8

require 'tty-which'

module TTY
  class Pager
    # A system pager is used  on systems where native
    # pagination exists
    #
    # @api public
    class SystemPager < Pager
      # Find first available system command for paging
      #
      # @example Basic usage
      #   available # => 'less'
      #
      # @example Usage with commands
      #   available('less', 'cat')  # => 'less'
      #
      # @param [Array[String]] commands
      #
      # @return [String]
      #
      # @api public
      def self.available(*commands)
        commands = commands.empty? ? executables : commands
        commands.
          compact.map(&:strip).reject(&:empty?).uniq.
          find { |cmd| command_exists?(cmd.split.first) }
      end

      # Check if command is available
      #
      # @example Basic usage
      #   available?  # => true
      #
      # @example Usage with command
      #   available?('less') # => true
      #
      # @return [Boolean]
      #
      # @api public
      def self.available?(*commands)
        !available(*commands).nil?
      end

      # Use system command to page output text
      #
      # @example
      #   page('some long text...')
      #
      # @param [String] text
      #   the text to paginate
      #
      # @return [Boolean]
      #   the success status of launching a process
      #
      # @api public
      def page(text, &callback)
        read_io, write_io = IO.pipe

        pid = fork do
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
        end

        read_io.close
        write_io.write(text)
        write_io.close

        _, status = Process.waitpid2(pid)
        status.success?
      end

      private

      # List possible executables for output paging
      #
      # @return [Array[String]]
      #
      # @api private
      def self.executables
        [ENV['GIT_PAGER'], ENV['PAGER'],
         `git config --get-all core.pager`,
         'less', 'more', 'cat', 'pager']
      end
      private_class_method :executables

      # Check if command exists
      #
      # @example
      #   command_exists?('less) # => true
      #
      # @param [String] command
      #   the command to check
      #
      # @return [Boolean]
      #
      # @api private
      def self.command_exists?(command)
        TTY::Which.exist?(command)
      end

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
