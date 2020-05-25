# frozen_string_literal: true

require 'tmpdir'

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
    described_class.page("Some text", command: "ruby #{fixtures_path("cat.rb")} > #{output_path}")

    expect(output_path.read).to eq "Some text"
  end

  it "allows pagination to happen asynchronously" do
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("external_pager.rb")} #{output_path}"

    described_class.page(command: pager_command) do |pager|
      pager.puts("one")
      pager.write("two\n")
      pager.try_write("three\n")
    end

    expect(output_path.read).to eq "one\ntwo\nthree\n"
  end

  it "stops paginating once external tool is closed" do
    output_path = Pathname.new("output.txt")
    pager_command = "ruby #{fixtures_path("external_pager.rb")} #{output_path}"

    described_class.page(command: pager_command) do |pager|
      pager.puts("one")
      pager.puts("two")

      # wait for script to finish writing
      sleep 0.5

      pid = pager.instance_variable_get("@pager_io").instance_variable_get("@pid")
      Process.kill("KILL", pid)
      Process.waitpid(pid)

      # Script finishes after two lines, this `puts` call should raise `PagerClosed`
      pager.puts("three")
      raise "Should not be called"
    end

    expect(output_path.read).to eq "one\ntwo\n"
  end
end
