# frozen_string_literal: true

require_relative "../lib/tty-pager"

pager = TTY::Pager::BasicPager.new(width: 80)
pager.page(path: File.join(__dir__, "temp.txt"))
