# coding: utf-8

RSpec.describe TTY::Pager::NullPager, '.page' do
  let(:output)   { StringIO.new }

  it "doesn't paginate empty string" do
    pager = described_class.new(output: output)
    text = "I try all things, I achieve what I can.\n"
    pager.page(text)
    expect(output.string).to eq(text)
  end
end
