# coding: utf-8

RSpec.describe TTY::Pager::SystemPager, '.page' do
  let(:input)  { StringIO.new }
  let(:output) { StringIO.new }

  it "executes the pager command in a subprocess" do
    text     = "I try all things, I achieve what I can.\n"
    pager    = described_class.new(output: output, input: input)
    read_io  = spy
    write_io = spy

    if !pager.respond_to?(:fork)
      described_class.send :define_method, :fork, lambda { |*args|
        yield if block_given?
      }
    end

    allow(IO).to receive(:pipe).and_return([read_io, write_io])

    allow(pager).to receive(:fork) do |&block|
      allow(input).to receive(:reopen)
      allow(IO).to receive(:select)
      allow(pager).to receive(:pager_command).and_return('less')
      allow(pager).to receive(:exec)
      block.call
    end.and_return(12345)

    status = double(:status, :success? => true)
    allow(Process).to receive(:waitpid2).with(12345).and_return([1, status])

    expect(pager.page(text)).to eq(true)

    expect(IO).to have_received(:select).with([input])
    expect(pager).to have_received(:exec).with('less')
    expect(output.read).to eq('')
  end
end
