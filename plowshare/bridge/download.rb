#!/usr/bin/ruby

require_relative 'base.rb'

# Sends download URL.
class Plowshare::Bridge::Download< Plowshare::Bridge::Base

  def initialize(fifo_in, fifo_out, cookie_path, download_url, file_name)
    super(fifo_in, fifo_out)
    self.send("download")
    self.wait_for_sync
    self.send(cookie_path, download_url, file_name)
    exit 0
  end

end

fifo_in = ARGV[0]
fifo_out = ARGV[1]
cookie_path = ARGV[4]
download_url = ARGV[5]
file_name = ARGV[6]
Plowshare::Bridge::Download.new(fifo_in, fifo_out, cookie_path, download_url, file_name)

