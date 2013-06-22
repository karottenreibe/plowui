#!/usr/bin/ruby

require_relative 'base.rb'

# Sends download URL.
class Plowshare::Bridge::Download< Plowshare::Bridge::Base

  def initialize(dir, my_lock, other_lock, debug, cookie_path, download_url, file_name)
    super(dir, my_lock, other_lock, debug)
    self.send("download", cookie_path, download_url, file_name)
    # wait for one more message so we can be sure the other end has read
    # the cookie file
    self.receive()
    # Tell the other end we are done
    self.send_shutdown()
    exit 0
  end

end

dir = ARGV[0]
my_lock = ARGV[1]
other_lock = ARGV[2]
debug = ARGV[3] == "true"

cookie_path = ARGV[6]
download_url = ARGV[7]
file_name = ARGV[8]
Plowshare::Bridge::Download.new(dir, my_lock, other_lock, debug, cookie_path, download_url, file_name)
