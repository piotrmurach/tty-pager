# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, "#write" do
  it "spawns an internal pager exactly once" do
    allow(described_class).to receive(:find_executable) { "less" }
    pager    = described_class.new
    pager_io = spy(:pager_io)
    allow(pager).to receive(:spawn_pager).and_return(pager_io)

    pager.write("one")
    pager.write("two")
    pager.write("three")

    expect(pager).to have_received(:spawn_pager).once
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

  it "invokes write calls directly on the internal pager" do
    allow(described_class).to receive(:find_executable) { "less" }
    allow(described_class).to receive(:run_command).with("less") { "" }
    pager_io = spy(:pager_io, :closed? => false)
    allow(IO).to receive(:popen).and_return(pager_io)
    result = [nil, spy(:result)]
    allow(Process).to receive(:waitpid2).and_return(result)

    pager = described_class.new
    pager.write("one")
    pager.write("two")
    pager.close

    expect(pager_io).to have_received(:write).with("one").once.with("two").once
    expect(pager_io).to have_received(:close).once
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
