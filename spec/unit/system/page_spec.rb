# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.page' do
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

  describe "block form" do
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
