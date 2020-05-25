ARGF.each do |line|
  File.open('external_pager_output.txt', 'a') do |output|
    output.puts(line)
    output.flush
  end
end
