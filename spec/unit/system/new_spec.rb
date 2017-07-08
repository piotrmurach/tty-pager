# encoding: utf-8

RSpec.describe TTY::Pager::SystemPager, '#new' do
  it "raises error if system paging is not supported" do
    allow(TTY::Pager::SystemPager).to receive(:can?).and_return(false)
    expect {
      TTY::Pager::SystemPager.new
    }.to raise_error(TTY::Pager::Error, "TTY::Pager::SystemPager cannot be used on your system. Try using BasicPager instead.")
  end
end
