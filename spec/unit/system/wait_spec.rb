# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.wait' do
  it "succeeds if a pager hasn't been spawned" do
    pager = described_class.new

    expect(pager).to receive(:start).never
    expect(pager.wait).to be_truthy
  end

  it "succeeds if the pager exits successfully" do
    pager = described_class.new
    pager_io = double("PagerIO", write: nil, close: double(success?: true))
    expect(pager).to receive(:start).once.and_return(pager_io)

    pager.write("test")

    expect(pager.wait).to be_truthy
  end

  it "fails if the pager exits with a failure" do
    pager = described_class.new
    pager_io = double("PagerIO", write: nil, close: double(success?: false))
    expect(pager).to receive(:start).once.and_return(pager_io)

    pager.write("test")

    expect(pager.wait).to be_falsey
  end
end
