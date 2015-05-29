# coding: utf-8

RSpec.describe TTY::Pager, '.page' do
  let(:output) { StringIO.new }

  it "selects null pager when disabled" do
    null_pager = spy(:null_pager)
    allow(TTY::Pager::NullPager).to receive(:new) { null_pager }

    pager = described_class.new(enabled: false)
    text = "I try all things, I achieve what I can.\n"
    pager.page(text)

    expect(TTY::Pager::NullPager).to have_received(:new)
  end

  it "selects basic pager on non tty systems" do
    basic_pager = spy(:basic_pager)
    allow(TTY::Pager::SystemPager).to receive(:available?) { false }
    allow(TTY::Pager::BasicPager).to receive(:new) { basic_pager }

    pager = described_class.new
    text = "I try all things, I achieve what I can.\n"
    pager.page(text)

    expect(basic_pager).to have_received(:page).with(text)
  end

  it "selects system pager on systems with tty" do
    system_pager = spy(:system_pager)
    allow(TTY::Pager::SystemPager).to receive(:available?) { true }
    allow(described_class).to receive(:jruby?) { false }
    allow(TTY::Pager::SystemPager).to receive(:new) { system_pager }

    pager = described_class.new
    text = "I try all things, I achieve what I can.\n"
    pager.page(text)

    expect(system_pager).to have_received(:page).with(text)
  end
end
