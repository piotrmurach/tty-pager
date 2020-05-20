# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.write' do
  it "triggers a `spawn_pager` call exactly once" do
    allow(described_class).to receive(:find_executable) { "less" }
    output   = double(:output, :tty? => true)
    pager    = described_class.new(output: output)
    pager_io = double(:pager_io, write: nil, close: true)

    expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

    pager.write("one")
    pager.write("two")
    pager.close
  end

  it "delegates any write calls to the internal pager" do
    allow(described_class).to receive(:find_executable) { "less" }
    pager = described_class.new
    pager_io = StringIO.new

    expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

    pager.write("one")
    pager.write("two")

    expect(pager_io.string).to eq("onetwo")
  end

  it "is aliased to <<" do
    allow(described_class).to receive(:find_executable) { "less" }
    pager = described_class.new
    pager_io = spy("PagerIO")

    expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

    pager << "one"

    expect(pager_io).to have_received(:write)
  end
end
