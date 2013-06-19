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

fifo_in = ARGV[1]
fifo_out = ARGV[2]
cookie_path = ARGV[5]
download_url = ARGV[6]
file_name = ARGV[7]
Plowshare::Bridge::Download.new(fifo_in, fifo_out, cookie_path, download_url, file_name)

