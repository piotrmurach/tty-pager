# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.close' do
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
