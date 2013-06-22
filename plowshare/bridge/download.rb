#!/usr/bin/ruby

require_relative 'base.rb'

# Sends download URL.
class Plowshare::Bridge::Download< Plowshare::Bridge::Base

  def initialize(dir, my_lock, other_lock, cookie_path, download_url, file_name)
    super(dir, my_lock, other_lock)
    self.send("download", cookie_path, download_url, file_name)
    # wait for one more message so we can be sure the other end has read
    # the cookie file
    self.receive()
    # Tell the other end we have received the message.
    self.send()
    exit 0
  end

end

dir = ARGV[0]
my_lock = ARGV[1]
other_lock = ARGV[2]
cookie_path = ARGV[5]
download_url = ARGV[6]
file_name = ARGV[7]
Plowshare::Bridge::Download.new(dir, my_lock, other_lock, cookie_path, download_url, file_name)
