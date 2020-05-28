# frozen_string_literal: true

require "tmpdir"

RSpec.describe TTY::Pager::SystemPager do
  around :each do |example|
    Dir.mktmpdir do |dir|
      FileUtils.cd(dir) do
        example.run
      end
    end
  end

  it "paginates some text" do
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("cat.rb")} > #{output_path}"
    described_class.page("Some text", command: pager_command)

    expect(output_path.read).to eq("Some text")
  end

  it "paginates text from a file path" do
    file_path = fixtures_path("copy.txt")
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("cat.rb")} > #{output_path}"

    described_class.page(path: file_path, command: pager_command)

    expect(output_path.read).to eq("one\ntwo\nthree\n")
  end

  it "allows pagination to happen asynchronously" do
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("external_pager.rb")} #{output_path}"

    described_class.page(command: pager_command) do |pager|
      pager.puts("one")
      pager.write("two\n")
      pager.try_write("three\n")
    end

    expect(output_path.read).to eq("one\ntwo\nthree\n")
  end

  it "stops paginating once external tool is closed" do
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("broken_pager.rb")} > #{output_path}"

    described_class.page(command: pager_command) do |pager|
      pager.puts("one")
      pager.puts("two")
      # Script finishes after two lines, this `puts` call should raise `PagerClosed`
      pager.puts("KILL_PROCESS")
      pager.puts("three")
    end

    expect(output_path.read).to eq("one\ntwo\n")
  end
end
