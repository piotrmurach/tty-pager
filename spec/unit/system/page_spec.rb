# coding: utf-8

RSpec.describe TTY::Pager::SystemPager, '.page' do
  let(:input)    { StringIO.new }
  let(:output)   { StringIO.new }

  it "executes the pager command in a subprocess" do
    text = "I try all things, I achieve what I can.\n"
    pager = described_class.new(output: output, input: input)

    allow(pager).to receive(:exec)
    allow(pager).to receive(:fork).and_return(true)
    allow(pager).to receive(:pager_command).and_return('less')
    allow(IO).to receive(:select)
    allow(input).to receive(:reopen)

    pager.page(text)

    expect(IO).to have_received(:select).with([input])
    expect(pager).to have_received(:exec).with('less')
    expect(output.read).to eq('')
  end
end
