# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.write' do
  it "triggers a start call exactly once" do
    allow(TTY::Pager::SystemPager).to receive(:exec_available?).and_return(true)
    output   = double(:output, :tty? => true)
    pager    = described_class.new(output: output)
    pager_io = double(:pager_io, write: nil, close: double(:success? => true))

    expect(pager).to receive(:start).once.and_return(pager_io)

    pager.write("one")
    pager.write("two")
    pager.wait
  end
end
