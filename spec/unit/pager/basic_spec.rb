# frozen_string_literal: true

RSpec.describe TTY::Pager::BasicPager do
  let(:input)  { StringIO.new }
  let(:output) { StringIO.new }

  describe "#page" do
    it "doesn't paginate empty string" do
      pager = described_class.new(output: output, input: input)
      pager.page("")
      expect(output.string).to eq("")
    end

    it "doesn't paginate text that fits on screen" do
      text = "I try all things, I achieve what I can.\n"
      pager = described_class.new(output: output, width: 100, height: 10)
      pager.page(text)
      expect(output.string).to eq(text)
    end

    it "pages a long text without newlines exceeding terminal page size" do
      text = "The more so, I say, because truly to enjoy bodily warmth, " \
             "some small part of you must be cold, for there is no quality " \
             "in this world that is not what it is merely by contrast.\n" \
             "Nothing exists in itself.\n"
      input << "\n\n"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 40, height: 5)
      pager.page(text)
      expect(output.string).to eq([
        "The more so, I say, because truly to ",
        "enjoy bodily warmth, some small part of ",
        "",
        "--- Page -1- Press enter/return to ",
        "continue (or q to quit) ---",
        "you must be cold, for there is no ",
        "quality in this world that is not what ",
        "it is merely by contrast.",
        "Nothing exists in itself.\n"
      ].join("\n"))
    end

    it "pages text with number of lines that match the terminal page height" do
      text = "one\ntwo\nthree\nfour\nfive"
      input << "\n"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 80, height: 5)
      pager.page(text)
      expect(output.string).to eq([
        "one",
        "two",
        "three",
        "",
        "--- Page -1- Press enter/return to continue (or q to quit) ---",
        "four",
        "five"
      ].join("\n"))
    end

    it "breaks down text and prompt exceeding terminal width" do
      text = "It is not down on any map; true places never are.\n"
      input << "\n"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 10, height: 6)
      pager.page(text)
      expect(output.string).to eq([
        "It is not ",
        "down on ",
        "any map; ",
        "true ",
        "places ",
        "never are.\n"
      ].join("\n"))
    end

    it "continues paging when enter is pressed" do
      text = []
      10.times { text << "I try all things, I achieve what I can.\n"}
      input << "\n\n\n"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 100, height: 5)
      pager.page(text.join)
      expect(output.string).to eq([
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "",
        "--- Page -1- Press enter/return to continue (or q to quit) ---",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "",
        "--- Page -2- Press enter/return to continue (or q to quit) ---",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "",
        "--- Page -3- Press enter/return to continue (or q to quit) ---",
        "I try all things, I achieve what I can.\n"
      ].join("\n"))
    end

    it "stops paging when q is pressed" do
      text = []
      10.times { text << "I try all things, I achieve what I can.\n"}
      input << "\nq"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 100, height: 5)
      pager.page(text.join)
      expect(output.string).to eq([
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "",
        "--- Page -1- Press enter/return to continue (or q to quit) ---",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "",
        "--- Page -2- Press enter/return to continue (or q to quit) ---\n",
      ].join("\n"))
    end

    it "allows to change paging prompt" do
      text = []
      5.times { text << "I try all things, I achieve what I can.\n"}
      input << "\n"
      input.rewind
      prompt = ->(page) { "Page -#{page}-" }
      pager = described_class.new(output: output, input: input,
                                  width: 100, height: 5, prompt: prompt)
      pager.page(text.join)
      expect(output.string).to eq([
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "I try all things, I achieve what I can.",
        "Page -1-",
        "I try all things, I achieve what I can.\n",
      ].join("\n"))
    end

    it "preserves new lines when breaking" do
      text = "a\na\na\na\na\na\na\na\na\na"
      input << "\n\n\n"
      input.rewind
      pager = described_class.new(output: output, input: input,
                                  width: 80, height: 5)
      pager.page(text)
      expect(output.string).to eq([
        "a",
        "a",
        "a",
        "",
        "--- Page -1- Press enter/return to continue (or q to quit) ---",
        "a",
        "a",
        "a",
        "",
        "--- Page -2- Press enter/return to continue (or q to quit) ---",
        "a",
        "a",
        "a",
        "",
        "--- Page -3- Press enter/return to continue (or q to quit) ---",
        "a"
      ].join("\n"))
    end

    it "streams individual lines and quits raising PagerClosed error" do
      pager = described_class.new(output: output, input: input,
                                  width: 100, height: 5)

      input << "q"
      input.rewind

      expect {
        3.times { pager.puts("I try all things, I achieve what I can.") }
      }.to raise_error(TTY::Pager::PagerClosed, "The pager tool was closed")
    end
  end

  describe ".page" do
    it "calls .close when the block is done" do
      basic_pager = spy(:basic_pager)
      allow(described_class).to receive(:new) { basic_pager }

      text = "I try all things, I achieve what I can.\n"
      described_class.page do |pager|
        pager.write(text)
      end

      expect(basic_pager).to have_received(:write).with(text)
      expect(basic_pager).to have_received(:close)
    end
  end
end
