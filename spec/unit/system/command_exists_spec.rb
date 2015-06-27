# coding: utf-8

RSpec.describe TTY::Pager::SystemPager, '#command_exists?' do
  subject(:pager) { described_class }

  it "successfully checks command exists on the system" do
    allow(TTY::Which).to receive(:which).with('less').and_return('/usr/bin/less')
    expect(pager.command_exists?('less')).to eq(true)
  end

  it "fails to check command exists on the system" do
    allow(TTY::Which).to receive(:which).with('less').and_return(nil)
    expect(pager.command_exists?('less')).to eq(false)
  end
end
