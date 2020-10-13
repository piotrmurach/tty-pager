# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager do
  describe ".close" do
    before :each do
      allow(described_class).to receive(:find_executable) { "less" }
    end

    it "succeeds if a pager hasn't been spawned" do
      pager = described_class.new

      expect(pager).to receive(:spawn_pager).never
      expect(pager.close).to eq(true)
    end

    it "succeeds if the pager exits successfully" do
      pager = described_class.new
      pager_io = double("PagerIO", write: nil, close: true)
      expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

      pager.write("test")

      expect(pager.close).to eq(true)
    end

    it "fails if the pager exits with a failure" do
      pager = described_class.new
      pager_io = double("PagerIO", write: nil, close: false)
      expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

      pager.write("test")

      expect(pager.close).to eq(false)
    end
  end

  describe "#command_exists?" do
    subject(:pager) { described_class }

    it "successfully checks command exists on the system" do
      allow(ENV).to receive(:fetch).with("PATHEXT", "").and_return("")
      allow(ENV).to receive(:fetch).with("PATH", "").and_return("/usr/bin/")
      allow(::File).to receive(:exist?)
        .with(::File.join("/usr/bin", "less")).and_return(true)

      expect(pager.command_exist?("less")).to eq(true)
    end

    it "successfully checks command exists via an absolute path" do
      allow(ENV).to receive(:fetch).with("PATHEXT", "").and_return("")
      allow(ENV).to receive(:fetch).with("PATH", "").and_return("/usr/bin/")
      allow(::File).to receive(:exist?)
        .with("/other/path/to/less").and_return(true)

      expect(pager.command_exist?("/other/path/to/less")).to eq(true)
    end

    it "successfully checks command with extensions exists on the system" do
      allow(ENV).to receive(:fetch).with("PATHEXT", "").and_return(".exe")
      allow(ENV).to receive(:fetch).with("PATH", "").and_return("/usr/bin/")
      allow(::File).to receive(:exist?)
        .with(::File.join("/usr/bin", "less")).and_return(false)
      allow(::File).to receive(:exist?)
        .with(::File.join("/usr/bin", "less.exe")).and_return(true)

      expect(pager.command_exist?("less.exe")).to eq(true)
    end

    it "fails to check command exists on the system" do
      allow(ENV).to receive(:fetch).with("PATHEXT", "").and_return("")
      allow(ENV).to receive(:fetch).with("PATH", "").and_return("/usr/bin/")
      allow(::File).to receive(:exist?)
        .with(::File.join("/usr/bin", "less")).and_return(false)

      expect(pager.command_exist?("less")).to eq(false)
    end
  end

  describe ".executables" do
    it "provides executable names" do
      allow(ENV).to receive(:[]).with("GIT_PAGER").and_return(nil)
      allow(ENV).to receive(:[]).with("PAGER").and_return(nil)
      allow(described_class).to receive(:command_exist?).with("git").and_return(false)

      expect(described_class.executables).to eq([
        "less -r", "more -r", "most", "pg", "cat", "pager"
      ])
    end
  end

  describe "#find_executable" do
    let(:execs) { ["less", "more"] }

    subject(:pager) { described_class }

    it "finds available command" do
      allow(pager).to receive(:executables).and_return(execs)
      allow(pager).to receive(:command_exist?).with("less") { true }
      allow(pager).to receive(:command_exist?).with("more") { false }
      expect(pager.find_executable).to eql("less")
    end

    it "doesn't find command" do
      allow(pager).to receive(:executables).and_return(execs)
      allow(pager).to receive(:command_exist?) { false }
      expect(pager.find_executable).to be_nil
    end

    it "takes precedence over other commands" do
      allow(pager).to receive(:command_exist?).with("more") { true }
      expect(pager.find_executable("more")).to eql("more")
    end

    it "allows to query for available command" do
      allow(pager).to receive(:find_executable).with("less") { true }
      expect(pager.exec_available?("less")).to eq(true)
    end

    context "when given nil, blank, and whitespace commands" do
      let(:execs) { [nil, "", "   ", "less"] }

      it "does not error" do
        allow(pager).to receive(:executables).and_return(execs)
        allow(pager).to receive(:command_exist?).with("less") { true }
        expect(pager.find_executable).to eql("less")
      end
    end

    context "when given a multi-word executable" do
      let(:execs) { ["diff-so-fancy | less --tabs=4 -RFX"] }

      it "finds the command" do
        allow(pager).to receive(:executables).and_return(execs)
        allow(pager).to receive(:command_exist?).with("diff-so-fancy") { true }
        expect(pager.find_executable).to eql(execs.first)
      end
    end
  end

  describe "#new" do
    it "raises error if system paging is not supported" do
      allow(TTY::Pager::SystemPager).to receive(:find_executable).and_return(nil)

      expect {
        TTY::Pager::SystemPager.new
      }.to raise_error(TTY::Pager::Error, "TTY::Pager::SystemPager cannot be used on your system due to lack of appropriate pager executable. Install `less` like pager or try using `BasicPager` instead.")
    end

    it "accepts multiple commands" do
      allow(TTY::Pager::SystemPager)
        .to receive(:find_executable).and_return("more -r")

      TTY::Pager::SystemPager.new(command: ["less -r", "more -r"])

      expect(TTY::Pager::SystemPager)
        .to have_received(:find_executable).with("less -r", "more -r")
    end
  end

  describe ".page" do
    it "executes the pager command in a subprocess" do
      allow(described_class).to receive(:find_executable) { "less" }
      text     = "I try all things, I achieve what I can.\n"
      output   = double(:output, :tty? => true)
      pager    = described_class.new(output: output)
      write_io = spy
      pid      = 12345

      allow(IO).to receive(:popen).and_return(write_io)
      allow(write_io).to receive(:pid).and_return(pid)
      allow(write_io).to receive(:closed?).and_return(false)
      status = double(:status, :success? => true)
      allow(Process).to receive(:waitpid2).with(pid, any_args).and_return([1, status])

      pager.page(text)
      expect(write_io).to have_received(:write).with(text)
      expect(write_io).to have_received(:close)
    end

    it "strips command from unsupported flags" do
      text = "I try all things, I achieve what I can.\n"
      exec = "less --unknown"
      allow(described_class).to receive(:find_executable) { exec }
      allow(described_class).to receive(:run_command).with(exec) { false }
      system_pager = described_class.new(command: exec)
      write_io = spy(:write_io)
      allow(IO).to receive(:popen).and_return(write_io)

      system_pager.page(text)

      expect(IO).to have_received(:popen).with("less", "w")
    end

    it "streams individual line and raises PagerClosed error" do
      allow(described_class).to receive(:find_executable) { "less" }
      allow(described_class).to receive(:run_command).and_return("")
      system_pager = described_class.new
      command_io = spy(:command_io)
      allow(IO).to receive(:popen).and_return(command_io)
      allow(command_io).to receive(:public_send).and_raise(Errno::EPIPE)

      expect {
        system_pager << "I try all things, I achieve what I can."
      }.to raise_error(TTY::Pager::PagerClosed,
                       "The pager process (`less`) was closed")
    end

    it "pages content from a file path" do
      allow(described_class).to receive(:find_executable) { "more" }
      system_pager = described_class.new
      allow(system_pager).to receive(:write)
      allow(described_class).to receive(:new) { system_pager }
      text = "I try all things, I achieve what I can.\n"
      allow(IO).to receive(:foreach).and_yield(text)

      instance = described_class.new
      instance.page(path: "/some/file/path.txt")

      expect(system_pager).to have_received(:write).with(text)
    end

    context "block form" do
      it "calls .close when the block is done" do
        system_pager = spy(:system_pager)
        allow(described_class).to receive(:exec_available?) { true }
        allow(described_class).to receive(:new) { system_pager }

        text = "I try all things, I achieve what I can.\n"
        described_class.page do |pager|
          pager.write(text)
        end

        expect(system_pager).to have_received(:write).with(text)
        expect(system_pager).to have_received(:close)
      end
    end
  end

  context "writing" do
    before :each do
      allow(described_class).to receive(:find_executable) { "less" }
    end

    it "spawns an internal pager exactly once" do
      pager    = described_class.new
      pager_io = spy(:pager_io)
      allow(pager).to receive(:spawn_pager).and_return(pager_io)

      pager.puts("one")
      pager.write("two")
      pager.try_write("three")

      expect(pager).to have_received(:spawn_pager).once
    end

    it "delegates any writing calls to the internal pager" do
      pager = described_class.new
      pager_io = StringIO.new

      allow(pager).to receive(:spawn_pager).once.and_return(pager_io)

      pager.puts("one")
      pager.write("two ")
      pager.try_write("three\n")
      pager.close

      expect(pager_io.string).to eq("one\ntwo three\n")
    end

    it "invokes IO calls on the internal pager" do
      allow(described_class).to receive(:run_command).with("less") { "" }
      pager_io = spy(:pager_io, :closed? => false)
      allow(IO).to receive(:popen).and_return(pager_io)
      result = [nil, spy(:result)]
      allow(Process).to receive(:waitpid2).and_return(result)

      pager = described_class.new
      pager.puts("one")
      pager.write("two")
      pager.try_write("three")
      pager.close

      expect(pager_io).to have_received(:puts).with("one").once
      expect(pager_io).to have_received(:write).
        with("two").once.
        with("three").once
      expect(pager_io).to have_received(:close).once
    end

    it "raises no child process error" do
      allow(described_class).to receive(:find_executable) { "less" }
      allow(described_class).to receive(:run_command).with("less") { "" }
      pager_io = spy(:pager_io, :closed? => false, pid: 999)
      allow(IO).to receive(:popen).and_return(pager_io)
      allow(Process).to receive(:waitpid2).and_raise(Errno::ECHILD)

      pager = described_class.new

      pager.puts("one")
      pager.write("two")
      pager.try_write("three")

      expect(pager.close).to eq(true)
    end
  end

  describe "#try_write" do
    it "writes content and returns true" do
      allow(described_class).to receive(:find_executable) { "less" }
      pager = described_class.new
      allow(pager).to receive(:write)

      expect(pager.try_write("one")).to eq(true)
    end

    it "catches a PagerClosed error when writing and returns false" do
      allow(described_class).to receive(:find_executable) { "less" }
      pager = described_class.new
      allow(pager).to receive(:write).and_raise(TTY::Pager::PagerClosed)

      expect(pager.try_write("one")).to eq(false)
    end
  end

  describe "#write" do
    it "is aliased to <<" do
      allow(described_class).to receive(:find_executable) { "less" }
      pager = described_class.new
      pager_io = spy("PagerIO")

      expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

      pager << "one" << "two"

      expect(pager_io).to have_received(:write).twice
    end
  end
end
