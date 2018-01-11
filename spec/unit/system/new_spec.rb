RSpec.describe TTY::Pager::SystemPager, '#new' do
  it "raises error if system paging is not supported" do
    allow(TTY::Pager::SystemPager).to receive(:exec_available?).and_return(false)
    expect {
      TTY::Pager::SystemPager.new
    }.to raise_error(TTY::Pager::Error, "TTY::Pager::SystemPager cannot be used on your system due to lack of appropriate pager executable. Install `less` like pager or try using `BasicPager` instead.")
  end
end
