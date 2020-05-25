ARGF.read.each_line do |line|
  exit(1) if line.match(/KILL_PROCESS/)

  STDOUT.write(line)
end
