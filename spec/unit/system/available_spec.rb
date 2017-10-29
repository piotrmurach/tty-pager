RSpec.describe TTY::Pager::SystemPager, '#available' do
  let(:execs)   { ['less', 'more'] }

  subject(:pager) { described_class }

  it 'finds available command' do
    allow(pager).to receive(:executables).and_return(execs)
    allow(pager).to receive(:command_exists?).with('less') { true }
    allow(pager).to receive(:command_exists?).with('more') { false }
    expect(pager.available).to eql('less')
  end

  it "doesn't find command" do
    allow(pager).to receive(:executables).and_return(execs)
    allow(pager).to receive(:command_exists?) { false }
    expect(pager.available).to be_nil
  end

  it "takes precedence over other commands" do
    allow(pager).to receive(:command_exists?).with('more') { true }
    expect(pager.available('more')).to eql('more')
  end

  it "allows to query for available command" do
    allow(pager).to receive(:available).with('less') { true }
    expect(pager.available?('less')).to eq(true)
  end

  context "when given nil, blank, and whitespace commands" do
    let(:execs) { [nil, "", "   ", "less"] }

    it "does not error" do
      allow(pager).to receive(:executables).and_return(execs)
      allow(pager).to receive(:command_exists?).with('less') { true }
      expect(pager.available).to eql('less')
    end
  end

  context "when given a multi-word executable" do
    let(:execs) { ["diff-so-fancy | less --tabs=4 -RFX"] }

    it "finds the command" do
      allow(pager).to receive(:executables).and_return(execs)
      allow(pager).to receive(:command_exists?).with("diff-so-fancy") { true }
      expect(pager.available).to eql(execs.first)
    end
  end
end
