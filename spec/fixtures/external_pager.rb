output_file = ARGV.first or raise "No output file given!"

STDIN.each_line do |line|
  File.open(output_file, 'a') do |output|
    output.puts(line)
    output.flush
  end
end
