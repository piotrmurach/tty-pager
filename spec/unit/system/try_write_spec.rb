# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, "#try_write" do
  it "writes content and returns true" do
    allow(described_class).to receive(:find_executable) { "less" }
    pager = described_class.new
    allow(pager).to receive(:write)

    expect(pager.try_write("one")).to eq(true)
  end

  it "raises PagerClosed error when writing and returns false" do
    allow(described_class).to receive(:find_executable) { "less" }
    pager = described_class.new
    allow(pager).to receive(:write).and_raise(TTY::Pager::PagerClosed)

    expect(pager.try_write("one")).to eq(false)
  end
end
