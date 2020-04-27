# frozen_string_literal: true

require 'tty-which'

module TTY
  class Pager
    # A system pager is used  on systems where native
    # pagination exists
    #
    # @api public
    class SystemPager < Pager
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

      # Run pager command silently with no input and capture output
      #
      # @return [nil, String]
      #   command output or nil if command fails to run
      #
      # @api private
      def self.run_command(*args)
        require 'tempfile'
        out = Tempfile.new('tty-pager')
        result = system(*args, out: out.path, err: out.path, in: ::File::NULL)
        return if result.nil?
        out.rewind
        out.read
      ensure
        out.close
        out.unlink
      end

      # List possible executables for output paging
      #
      # @return [Array[String]]
      #
      # @api private
      def self.executables
        [ENV['GIT_PAGER'], ENV['PAGER'],
         command_exists?('git') ? `git config --get-all core.pager` : nil,
         'less -r', 'more -r', 'most', 'cat', 'pager', 'pg'].compact
      end

      # Find first available termainal pager program executable
      #
      # @example Basic usage
      #   find_executable # => 'less'
      #
      # @example Usage with commands
      #   find_executable('less', 'cat')  # => 'less'
      #
      # @param [Array[String]] commands
      #
      # @return [String, nil]
      #   the found executable or nil when not found
      #
      # @api public
      def self.find_executable(*commands)
        execs = commands.empty? ? executables : commands
        execs
          .compact.map(&:strip).reject(&:empty?).uniq
          .find { |cmd| command_exists?(cmd.split.first) }
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
      def self.exec_available?(*commands)
        !find_executable(*commands).nil?
      end

      # Create a system pager
      #
      # @param [Hash] options
      # @option options [String] :command
      #   the command to use for paging
      #
      # @api public
      def initialize(**options)
        super
        @pager_io = nil
        @pager_command = nil
        commands = Array(options[:command])
        pager_command(*commands)

        if @pager_command.nil?
          raise TTY::Pager::Error, "#{self.class.name} cannot be used on your" \
                                   " system due to lack of appropriate pager" \
                                   " executable. Install `less` like pager or" \
                                   " try using `BasicPager` instead." \
        end
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
      def page(text, &_callback)
        write(text)
        wait
      end

      # Spawn the pager process
      #
      # @return [PagerIO]
      #   A wrapper for the external pager
      #
      # @api private
      def start
        # In case there's a previous pager running:
        wait

        command = pager_command
        out = self.class.run_command(command)
        # Issue running command, e.g. unsupported flag, fallback to just command
        unless out.empty?
          command = pager_command.split.first
        end

        PagerIO.new(command)
      end

      # Send text to the pager process. Starts a new process if it hasn't been
      # started yet. Returns false if the pager was closed.
      #
      # @return [Boolean]
      #   the success status of writing to the pager process
      #
      # @api public
      def write(text)
        @pager_io ||= start
        @pager_io.write(text)
        true
      rescue Errno::EPIPE
        # pager has likely been closed before output was done
        false
      end

      # Stop the pager, wait for the process to finish. If no pager has been
      # started, returns true.
      #
      # @return [Boolean]
      #   the exit status of the child process
      #
      # @api public
      def wait
        return true unless @pager_io
        status = @pager_io.close
        @pager_io = nil
        status.success?
      rescue Errno::ECHILD
        # on jruby 9x waiting on pid raises
        true
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
                           self.class.find_executable(*commands)
                         end
      end

      # A wrapper for an external process.
      #
      # @api private
      class PagerIO
        def initialize(command)
          @io  = IO.popen(command, 'w')
          @pid = @io.pid
        end

        def write(*args)
          @io.write(*args)
        end

        def close
          @io.close
          _, status = Process.waitpid2(@pid, Process::WNOHANG)
          status
        end
      end
    end # SystemPager
  end # Pager
end # TTY
