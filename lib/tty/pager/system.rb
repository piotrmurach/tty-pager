# frozen_string_literal: true

require "open3"

require_relative "abstract"

module TTY
  module Pager
    # A system pager is used  on systems where native
    # pagination exists
    #
    # @api public
    class SystemPager < Abstract
      # Check if command exists
      #
      # @example
      #   command_exist?("less") # => true
      #
      # @param [String] command
      #   the command to check
      #
      # @return [Boolean]
      #
      # @api private
      def self.command_exist?(command)
        exts = ENV.fetch("PATHEXT", "").split(::File::PATH_SEPARATOR)
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
          file = ::File.join(dir, command)
          ::File.exist?(file) || exts.any? { |ext| ::File.exist?("#{file}#{ext}") }
        end
      end

      # Run pager command silently with no input and capture output
      #
      # @return [Boolean]
      #   true if command runs successfully, false otherwise
      #
      # @api private
      def self.run_command(*args)
        _, err, status = Open3.capture3(*args)
        err.empty? && status.success?
      rescue Errno::ENOENT
        false
      end

      # List possible executables for output paging
      #
      # The UNIX systems often come with "pg" and "more" but no "less" utility.
      # The Linux usually provides "less" and "more" pager, but often no "pg".
      # MacOS comes with "less" and "more" pager and no "pg".
      # Windows provides "more".
      # The "more" pager is the oldest utility and thus most compatible
      # with many systems.
      #
      # @return [Array[String]]
      #
      # @api private
      def self.executables
        [ENV["GIT_PAGER"], ENV["PAGER"], git_pager,
         "less -r", "more -r", "most", "pg", "cat", "pager"].compact
      end

      # Finds git pager configuration
      #
      # @api private
      def self.git_pager
        command_exist?("git") ? `git config --get-all core.pager` : nil
      end
      private_class_method :git_pager

      # Find first available termainal pager program executable
      #
      # @example Basic usage
      #   find_executable # => "less"
      #
      # @example Usage with commands
      #   find_executable("less", "cat")  # => "less"
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
          .find { |cmd| command_exist?(cmd.split.first) }
      end

      # Check if command is available
      #
      # @example Basic usage
      #   available?  # => true
      #
      # @example Usage with command
      #   available?("less") # => true
      #
      # @return [Boolean]
      #
      # @api public
      def self.exec_available?(*commands)
        !find_executable(*commands).nil?
      end

      # Create a system pager
      #
      # @param [String] :command
      #   the command to use for paging
      #
      # @api public
      def initialize(command: nil, **options)
        super(**options)
        @pager_io = nil
        @pager_command = nil
        pager_command(*Array(command))

        if pager_command.nil?
          raise TTY::Pager::Error,
                "#{self.class.name} cannot be used on your system due to " \
                "lack of appropriate pager executable. Install `less` like " \
                "pager or try using `BasicPager` instead."
        end
      end

      # Send text to the pager process. Starts a new process if it hasn't been
      # started yet.
      #
      # @param [Array<String>] *args
      #   strings to send to the pager
      #
      # @raise [PagerClosed]
      #   strings to send to the pager
      #
      # @api public
      def write(*args)
        @pager_io ||= spawn_pager
        @pager_io.write(*args)
        self
      end
      alias << write

      # Send a line of text, ending in a newline, to the pager process. Starts
      # a new process if it hasn't been started yet.
      #
      # @raise [PagerClosed]
      #   if the pager was closed
      #
      # @return [SystemPager]
      #
      # @api public
      def puts(text)
        @pager_io ||= spawn_pager
        @pager_io.puts(text)
        self
      end

      # Stop the pager, wait for the process to finish. If no pager has been
      # started, returns true.
      #
      # @return [Boolean]
      #   the exit status of the child process
      #
      # @api public
      def close
        return true unless @pager_io

        success = @pager_io.close
        @pager_io = nil
        success
      end

      private

      # The pager command to run
      #
      # @return [String]
      #   the name of executable to run
      #
      # @api private
      def pager_command(*commands)
        if @pager_command && commands.empty?
          @pager_command
        else
          @pager_command = self.class.find_executable(*commands)
        end
      end

      # Spawn the pager process
      #
      # @return [PagerIO]
      #   A wrapper for the external pager
      #
      # @api private
      def spawn_pager
        # In case there's a previous pager running:
        close

        command = pager_command
        status = self.class.run_command(command)
        # Issue running command, e.g. unsupported flag, fallback to just command
        unless status
          command = pager_command.split.first
        end

        PagerIO.new(command)
      end

      # A wrapper for an external process.
      #
      # @api private
      class PagerIO
        def initialize(command)
          @command = command
          @io      = IO.popen(@command, "w")
          @pid     = @io.pid
        end

        def write(*args)
          io_call(:write, *args)
        end

        def puts(*args)
          io_call(:puts, *args)
        end

        def close
          return true if @io.closed?

          @io.close
          _, status = Process.waitpid2(@pid, Process::WNOHANG)
          status.success?
        rescue Errno::ECHILD, Errno::EPIPE
          # on jruby 9x waiting on pid raises ECHILD
          # on ruby 2.5/2.6, closing a closed pipe raises EPIPE
          true
        end

        private

        def io_call(method_name, *args)
          @io.public_send(method_name, *args)
        rescue Errno::EPIPE
          raise PagerClosed.new("The pager process (`#{@command}`) was closed")
        end
      end
    end # SystemPager
  end # Pager
end # TTY
