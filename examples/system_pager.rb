# encoding: utf-8

require 'tty-pager'

ENV['PAGER']='less'

pager = TTY::Pager::SystemPager.new
file = File.join(File.dirname(__FILE__), 'temp.txt')
pager.page(File.read(file))
