# frozen_string_literal: true

RSpec.describe TTY::Pager::Abstract do
  it "configures instance to be enabled by default" do
    pager = described_class.new

    expect(pager.enabled?).to eq(true)
  end

  it "configures instance to be enabled" do
    pager = described_class.new(enabled: false)

    expect(pager.enabled?).to eq(false)
  end

  it "exposes class-level `page` implementation" do
    pager_instance = spy(:pager)
    allow(described_class).to receive(:new) { pager_instance }

    expect { |block|
      described_class.page(command: "test", &block)
    }.to yield_with_args(pager_instance)

    expect(pager_instance).to have_received(:close)
  end

  it "exposes instance-level `page` implementation" do
    pager = described_class.new
    allow(pager).to receive(:write)
    allow(pager).to receive(:close)

    pager.page("some text")

    expect(pager).to have_received(:write).with("some text")
    expect(pager).to have_received(:close)
  end

  it "requires `write` method implementation" do
    pager = described_class.new

    expect {
      pager.write
    }.to raise_error(TTY::Pager::Abstract::UndefinedMethodError)
  end

  it "requires `puts` method implementation" do
    pager = described_class.new

    expect {
      pager.puts
    }.to raise_error(TTY::Pager::Abstract::UndefinedMethodError)
  end

  it "requires `close` method implementation" do
    pager = described_class.new

    expect {
      pager.close
    }.to raise_error(TTY::Pager::Abstract::UndefinedMethodError)
  end
end
