# frozen_string_literal: true

RSpec.describe TTY::Pager::NullPager do
  let(:output)   { StringIO.new }

  context "page" do
    it "prints content to stdout when tty device" do
      allow(output).to receive(:tty?).and_return(true)
      pager = described_class.new(output: output)
      text = "I try all things, I achieve what I can.\n"

      pager.page(text)

      expect(output.string).to eq(text)
    end

    it "returns text when non-tty device" do
      pager = described_class.new(output: output)
      text = "I try all things, I achieve what I can.\n"

      expect(pager.page(text)).to eq(text)
      expect(output.string).to eq("")
    end

    it "doesn't write a newline if one wasn't given" do
      allow(output).to receive(:tty?).and_return(true)
      pager = described_class.new(output: output)
      text = "I try all things, I achieve what I can."

      pager.page(text)

      expect(output.string).to eq(text)
    end
  end

  context "puts" do
    it "writes content to terminal with a newline" do
      allow(output).to receive(:tty?).and_return(true)
      text = "I try all things, I achieve what I can."
      pager = described_class.new(output: output)

      pager.puts(text)

      expect(output.string).to eq(text + "\n")
    end

    it "returns content on non tty device" do
      allow(output).to receive(:tty?).and_return(false)
      text = "I try all things, I achieve what I can."
      pager = described_class.new(output: output)

      expect(pager.puts(text)).to eq(text)

      expect(output.string).to eq("")
    end
  end
end
