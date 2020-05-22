# frozen_string_literal: true

module TTY
  RSpec.describe Pager do
    context ".new" do
      it "selects NullPager when disabled and passes through options" do
        stream = double(:stream)
        pager = described_class.new(enabled: false, input: stream, output: stream)

        expect(pager).to be_kind_of(Pager::NullPager)
        expect(pager.enabled?).to eq(false)
        expect(pager.instance_variable_get("@input")).to eq(stream)
        expect(pager.instance_variable_get("@output")).to eq(stream)
      end

      it "selects SystemPager when command available" do
        allow(TTY::Pager::SystemPager).to receive(:find_executable) { "more" }

        pager = described_class.new(command: "pager")

        expect(Pager::SystemPager).to have_received(:find_executable).
          with("pager").twice
        expect(pager).to be_kind_of(Pager::SystemPager)
      end

      it "selects BasicPager when no command available" do
        allow(TTY::Pager::SystemPager).to receive(:find_executable) { nil }
        prompt = ->(page) { "Page #{page}\non multiline\n" }

        pager = described_class.new(width: 80, height: 30, prompt: prompt)

        expect(pager).to be_kind_of(Pager::BasicPager)
        expect(pager.instance_variable_get("@width")).to eq(80)
        expect(pager.instance_variable_get("@height")).to eq(28)
        expect(pager.instance_variable_get("@prompt")).to eq(prompt)
      end
    end
  end
end
