# frozen_string_literal: true

require_relative "../lib/tty-pager"

ENV["PAGER"]="less"

pager = TTY::Pager::SystemPager.new
pager.page(path: File.join(__dir__, "temp.txt"))
